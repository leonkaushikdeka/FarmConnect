import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate, requireRole } from "../middleware/auth.js";
import { z } from "zod";
import { notifyOrderPlaced, notifyOrderStatusChanged } from "../services/notification.js";

const placeOrder = z.object({
  farmerId: z.string(),
  items: z.array(z.object({
    productId: z.string(),
    quantity: z.number().positive(),
  })),
  deliveryAddress: z.string().min(5),
  customerPhone: z.string(),
  customerName: z.string().min(1),
  notes: z.string().optional(),
  paymentMethod: z.enum(["COD", "UPI", "CARD", "NET_BANKING"]).default("COD"),
});

let orderCounter = 0;

function generateOrderNo(): string {
  orderCounter++;
  const date = new Date();
  const d = date.toISOString().slice(2, 10).replace(/-/g, "");
  return `FC${d}${orderCounter.toString().padStart(5, "0")}`;
}

export async function orderRoutes(app: FastifyInstance) {
  app.post("/", { preHandler: [authenticate] }, async (request, reply) => {
    const body = placeOrder.parse(request.body);
    const farmer = await prisma.farmer.findUnique({ where: { id: body.farmerId } });
    if (!farmer) return reply.status(404).send({ error: "Farmer not found" });

    const productIds = body.items.map((i) => i.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds }, available: true },
    });

    if (products.length !== body.items.length) {
      return reply.status(400).send({ error: "Some products unavailable" });
    }

    let totalAmount = 0;
    const orderItems = body.items.map((item) => {
      const product = products.find((p) => p.id === item.productId)!;
      totalAmount += product.price * item.quantity;
      return {
        productId: product.id,
        productName: product.name,
        productEmoji: product.emoji,
        price: product.price,
        quantity: item.quantity,
        unit: product.unit,
      };
    });

    const order = await prisma.order.create({
      data: {
        orderNo: generateOrderNo(),
        customerId: request.userId,
        farmerId: body.farmerId,
        totalAmount,
        deliveryAddress: body.deliveryAddress,
        customerPhone: body.customerPhone,
        customerName: body.customerName,
        notes: body.notes,
        paymentMethod: body.paymentMethod,
        items: { create: orderItems },
      },
      include: {
        items: true,
        farmer: { include: { user: { select: { name: true } } } },
      },
    });

    // Send notifications to farmer and customer
    await notifyOrderPlaced({
      id: order.id,
      orderNo: order.orderNo,
      customerId: order.customerId,
      farmerId: order.farmerId,
      customerName: order.customerName,
      totalAmount: order.totalAmount,
      itemCount: orderItems.length,
      status: order.status,
    });

    return reply.status(201).send(order);
  });

  app.get("/", { preHandler: [authenticate] }, async (request) => {
    const role = request.userRole;
    const where: Record<string, unknown> = {};

    if (role === "CUSTOMER") where.customerId = request.userId;
    else if (role === "FARMER") {
      const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
      if (farmer) where.farmerId = farmer.id;
    }

    const orders = await prisma.order.findMany({
      where,
      include: {
        items: true,
        farmer: {
          include: { user: { select: { name: true } } },
        },
      },
      orderBy: { createdAt: "desc" },
      take: 50,
    });
    return orders;
  });

  app.get("/:id", { preHandler: [authenticate] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const order = await prisma.order.findUnique({
      where: { id },
      include: { items: true, farmer: { include: { user: { select: { name: true } } } } },
    });
    if (!order) return reply.status(404).send({ error: "Order not found" });
    if (order.customerId !== request.userId && request.userRole !== "ADMIN") {
      const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
      if (!farmer || order.farmerId !== farmer.id) {
        return reply.status(403).send({ error: "Forbidden" });
      }
    }
    return order;
  });

  app.patch("/:id/status", { preHandler: [authenticate, requireRole("FARMER")] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { status: string };
    const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order || !farmer || order.farmerId !== farmer.id) {
      return reply.status(403).send({ error: "Not your order" });
    }

    const data: Record<string, unknown> = { status: body.status };
    if (body.status === "DELIVERED") data.deliveredAt = new Date();

    const updated = await prisma.order.update({ where: { id }, data });

    // Notify the customer about the status change
    await notifyOrderStatusChanged({
      id: updated.id,
      orderNo: updated.orderNo,
      customerId: updated.customerId,
      status: updated.status,
      totalAmount: updated.totalAmount,
    });

    return updated;
  });
}