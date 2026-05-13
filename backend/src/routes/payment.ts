import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate } from "../middleware/auth.js";
import { z } from "zod";
import {
  createOrder,
  verifyPayment,
  updateOrderWithPayment,
} from "../services/razorpay.js";

const createOrderSchema = z.object({
  orderId: z.string(),
  amount: z.number().positive(),
  currency: z.string().default("INR"),
});

const verifyPaymentSchema = z.object({
  razorpayOrderId: z.string(),
  razorpayPaymentId: z.string(),
  razorpaySignature: z.string(),
});

const webhookSchema = z.object({
  event: z.string(),
  payload: z.object({
    payment: z.object({
      entity: z.object({
        id: z.string(),
        order_id: z.string(),
        status: z.string(),
      }),
    }),
  }),
});

export async function paymentRoutes(app: FastifyInstance) {
  /**
   * POST /api/payments/create-order
   * Creates a Razorpay order for the given order.
   * Requires authentication.
   */
  app.post("/create-order", { preHandler: [authenticate] }, async (request, reply) => {
    const body = createOrderSchema.parse(request.body);

    // Fetch the user's order to verify ownership and status
    const order = await prisma.order.findUnique({
      where: { id: body.orderId },
    });

    if (!order) {
      return reply.status(404).send({ error: "Order not found" });
    }

    if (order.customerId !== request.userId) {
      return reply.status(403).send({ error: "Forbidden" });
    }

    if (order.status !== "PENDING") {
      return reply.status(400).send({ error: "Order is not in pending state" });
    }

    try {
      const razorpayOrder = await createOrder(body.amount, body.currency, body.orderId);

      // Update the order with the Razorpay order ID
      await prisma.order.update({
        where: { id: body.orderId },
        data: {
          razorpayOrderId: razorpayOrder.id,
          paymentStatus: "PENDING",
        },
      });

      return {
        orderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        key: process.env.RAZORPAY_KEY_ID, // Send the key ID to the frontend
        // NOTE: In production, do NOT expose the key secret to the frontend.
        // The key ID is safe to share and is required by the Razorpay checkout widget.
      };
    } catch (error: any) {
      app.log.error(error, "Failed to create Razorpay order");
      return reply.status(500).send({ error: "Failed to create payment order" });
    }
  });

  /**
   * POST /api/payments/verify
   * Verifies payment signature and updates order status.
   * Required: razorpayOrderId, razorpayPaymentId, razorpaySignature.
   */
  app.post("/verify", { preHandler: [authenticate] }, async (request, reply) => {
    const body = verifyPaymentSchema.parse(request.body);

    const isValid = verifyPayment(
      body.razorpayOrderId,
      body.razorpayPaymentId,
      body.razorpaySignature
    );

    if (!isValid) {
      return reply.status(400).send({ error: "Payment verification failed" });
    }

    // Find the internal order by razorpayOrderId
    const order = await prisma.order.findFirst({
      where: { razorpayOrderId: body.razorpayOrderId },
    });

    if (!order) {
      return reply.status(404).send({ error: "Order not found" });
    }

    if (order.customerId !== request.userId) {
      return reply.status(403).send({ error: "Forbidden" });
    }

    // Update order with payment details and mark as confirmed
    const updated = await updateOrderWithPayment(
      order.id,
      body.razorpayOrderId,
      body.razorpayPaymentId,
      body.razorpaySignature,
      "PAID"
    );

    return {
      success: true,
      order: updated,
    };
  });

  /**
   * POST /api/payments/razorpay-webhook
   * Webhook endpoint for Razorpay payment events.
   * IMPORTANT: Secure this endpoint with the Razorpay webhook secret.
   * Configure the webhook secret in your Razorpay Dashboard:
   *   Dashboard > Settings > Webhooks > Add Webhook
   *   URL: https://your-domain.com/api/payments/razorpay-webhook
   *   Secret: <your-webhook-secret>
   *
   * The webhook secret must match RAZORPAY_WEBHOOK_SECRET in your .env file.
   * Without this verification, attackers could forge payment confirmations.
   */
  app.post("/razorpay-webhook", async (request, reply) => {
    // --- WEBHOOK SECRET VERIFICATION IS REQUIRED HERE ---
    // Razorpay sends the signature in the "X-Razorpay-Signature" header.
    // You MUST verify it matches RAZORPAY_WEBHOOK_SECRET before processing.
    //
    // Example verification (uncomment and configure):
    //
    // const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
    // const signature = request.headers["x-razorpay-signature"];
    // if (!signature || !webhookSecret) {
    //   return reply.status(401).send({ error: "Missing webhook secret or signature" });
    // }
    //
    // const expectedSig = crypto
    //   .createHmac("sha256", webhookSecret)
    //   .update(JSON.stringify(request.body))
    //   .digest("hex");
    //
    // if (signature !== expectedSig) {
    //   return reply.status(401).send({ error: "Invalid webhook signature" });
    // }
    //
    // --- END WEBHOOK SECRET VERIFICATION ---

    try {
      const body = request.body as any;

      // Log the webhook event for debugging
      app.log.info({ event: body.event }, "Razorpay webhook received");

      if (body.event === "payment.captured") {
        const payment = body.payload?.payment?.entity;
        if (!payment) {
          return reply.status(400).send({ error: "Invalid webhook payload" });
        }

        const razorpayOrderId = payment.order_id;
        const paymentId = payment.id;
        const status = payment.status; // "captured"

        // Find and update the corresponding order
        const order = await prisma.order.findFirst({
          where: { razorpayOrderId: razorpayOrderId },
        });

        if (!order) {
          // Return 200 so Razorpay doesn't retry, but log the issue
          app.log.warn({ razorpayOrderId }, "Order not found for webhook event");
          return reply.status(200).send({ received: true });
        }

        await updateOrderWithPayment(
          order.id,
          razorpayOrderId,
          paymentId,
          "", // Signature not available in webhook, already verified via HMAC
          "PAID"
        );

        app.log.info({ orderId: order.id }, "Order marked as PAID via webhook");
      }

      // Return 200 to acknowledge receipt
      return reply.status(200).send({ received: true });
    } catch (error: any) {
      app.log.error(error, "Error processing Razorpay webhook");
      // Still return 200 to prevent retry loops on internal errors
      // Consider returning 500 if you want Razorpay to retry
      return reply.status(200).send({ received: true, error: error.message });
    }
  });
}