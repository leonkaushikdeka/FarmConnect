import Razorpay from "razorpay";
import crypto from "node:crypto";
import { config } from "../config/index.js";
import { prisma } from "./prisma.js";

// Initialize Razorpay instance
function getRazorpayInstance(): Razorpay {
  return new Razorpay({
    key_id: config.RAZORPAY_KEY_ID!,
    key_secret: config.RAZORPAY_KEY_SECRET!,
  });
}

/**
 * Creates a Razorpay order.
 * @param amount - Amount in rupees (INR)
 * @param currency - Currency code, defaults to "INR"
 * @param receipt - Optional receipt ID for the order
 * @returns Razorpay order object
 */
export async function createOrder(
  amount: number,
  currency: string = "INR",
  receipt?: string
) {
  if (!config.RAZORPAY_KEY_ID || !config.RAZORPAY_KEY_SECRET) {
    throw new Error("Razorpay credentials not configured");
  }

  const razorpay = getRazorpayInstance();
  const options: Record<string, unknown> = {
    amount: amount * 100, // Razorpay expects amount in paise
    currency,
  };

  if (receipt) {
    options.receipt = receipt;
  }

  const order = await razorpay.orders.create(options);
  return order;
}

/**
 * Verifies a Razorpay payment signature using HMAC-SHA256.
 * @param orderId - The Razorpay order ID (razorpay_order_id)
 * @param paymentId - The Razorpay payment ID (razorpay_payment_id)
 * @param signature - The signature provided by Razorpay (razorpay_signature)
 * @returns true if signature is valid, false otherwise
 */
export function verifyPayment(
  orderId: string,
  paymentId: string,
  signature: string
): boolean {
  if (!config.RAZORPAY_KEY_SECRET) {
    throw new Error("Razorpay secret key not configured");
  }

  const generatedSignature = crypto
    .createHmac("sha256", config.RAZORPAY_KEY_SECRET!)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  return generatedSignature === signature;
}

/**
 * Updates an order in the database with Razorpay payment details.
 * @param dbOrderId - The internal database order ID
 * @param razorpayOrderId - The Razorpay order ID
 * @param paymentId - The Razorpay payment ID
 * @param signature - The payment signature
 * @param status - Payment status ("PAID" | "PENDING")
 * @returns Updated order record
 */
export async function updateOrderWithPayment(
  dbOrderId: string,
  razorpayOrderId: string,
  paymentId: string,
  signature: string,
  status: "PAID" | "PENDING" = "PAID"
) {
  return prisma.order.update({
    where: { id: dbOrderId },
    data: {
      razorpayOrderId,
      paymentStatus: status,
      status: status === "PAID" ? "CONFIRMED" : "PENDING",
    },
    include: {
      items: true,
      farmer: { include: { user: { select: { name: true } } } },
    },
  });
}