import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate } from "../middleware/auth.js";
import { z } from "zod";

const addItem = z.object({
  productId: z.string(),
  quantity: z.number().positive().default(1),
});

export async function cartRoutes(app: FastifyInstance) {
  app.addHook("onRequest", authenticate);

  app.get("/", async (request) => {
    const items = await prisma.cartItem.findMany({
      where: { userId: request.userId },
      include: {
        product: {
          include: {
            farmer: { include: { user: { select: { name: true } } } },
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });
    return items;
  });

  app.post("/", async (request, reply) => {
    const body = addItem.parse(request.body);

    const existing = await prisma.cartItem.findUnique({
      where: { userId_productId: { userId: request.userId, productId: body.productId } },
    });

    if (existing) {
      const updated = await prisma.cartItem.update({
        where: { id: existing.id },
        data: { quantity: existing.quantity + body.quantity },
        include: { product: true },
      });
      return updated;
    }

    const item = await prisma.cartItem.create({
      data: {
        userId: request.userId,
        productId: body.productId,
        quantity: body.quantity,
      },
      include: { product: true },
    });
    return reply.status(201).send(item);
  });

  app.put("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const body = request.body as { quantity: number };
    const item = await prisma.cartItem.findFirst({
      where: { id, userId: request.userId },
    });
    if (!item) return reply.status(404).send({ error: "Item not found" });

    if (body.quantity <= 0) {
      await prisma.cartItem.delete({ where: { id } });
      return { deleted: true };
    }

    const updated = await prisma.cartItem.update({
      where: { id },
      data: { quantity: body.quantity },
    });
    return updated;
  });

  app.delete("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const item = await prisma.cartItem.findFirst({
      where: { id, userId: request.userId },
    });
    if (!item) return reply.status(404).send({ error: "Item not found" });
    await prisma.cartItem.delete({ where: { id } });
    return { deleted: true };
  });

  app.delete("/", async () => {
    await prisma.cartItem.deleteMany({ where: { userId: "me" } });
    return { deleted: true };
  });
}
