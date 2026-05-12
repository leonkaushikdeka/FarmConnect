import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate, requireRole } from "../middleware/auth.js";
import { z } from "zod";
import type { Prisma } from "@prisma/client";

const createProduct = z.object({
  name: z.string().min(1),
  category: z.string().min(1),
  description: z.string().min(1),
  price: z.number().positive(),
  unit: z.string().min(1),
  quantity: z.number().positive(),
  emoji: z.string().optional(),
  organic: z.boolean().default(true),
  inSeason: z.boolean().default(true),
});

export async function productRoutes(app: FastifyInstance) {
  app.get("/", async (request) => {
    const query = request.query as Record<string, string>;
    const where: Prisma.ProductWhereInput = { available: true };

    if (query.category && query.category !== "All") {
      where.category = query.category;
    }
    if (query.farmerId) {
      where.farmerId = query.farmerId;
    }
    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: "insensitive" } },
        { farmer: { farmName: { contains: query.search, mode: "insensitive" } } },
      ];
    }
    if (query.organic === "true") where.organic = true;
    if (query.inSeason === "true") where.inSeason = true;

    const products = await prisma.product.findMany({
      where,
      include: {
        farmer: {
          include: { user: { select: { name: true } } },
        },
      },
      orderBy: { createdAt: "desc" },
    });
    return products;
  });

  app.get("/categories", async () => {
    const products = await prisma.product.findMany({
      where: { available: true },
      select: { category: true },
      distinct: ["category"],
    });
    return products.map((p) => p.category).sort();
  });

  app.get("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        farmer: {
          include: { user: { select: { name: true } } },
        },
      },
    });
    if (!product) return reply.status(404).send({ error: "Product not found" });
    return product;
  });

  app.post("/", { preHandler: [authenticate, requireRole("FARMER")] }, async (request, reply) => {
    const body = createProduct.parse(request.body);
    const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
    if (!farmer) return reply.status(400).send({ error: "Complete farmer profile first" });

    const product = await prisma.product.create({
      data: { ...body, farmerId: farmer.id },
      include: { farmer: true },
    });
    return reply.status(201).send(product);
  });

  app.put("/:id", { preHandler: [authenticate, requireRole("FARMER")] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
    const product = await prisma.product.findUnique({ where: { id } });
    if (!product || !farmer || product.farmerId !== farmer.id) {
      return reply.status(403).send({ error: "Not your product" });
    }
    const body = request.body as Partial<typeof createProduct._type>;
    const updated = await prisma.product.update({ where: { id }, data: body });
    return updated;
  });

  app.delete("/:id", { preHandler: [authenticate, requireRole("FARMER")] }, async (request, reply) => {
    const { id } = request.params as { id: string };
    const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
    const product = await prisma.product.findUnique({ where: { id } });
    if (!product || !farmer || product.farmerId !== farmer.id) {
      return reply.status(403).send({ error: "Not your product" });
    }
    await prisma.product.update({ where: { id }, data: { available: false } });
    return { success: true };
  });
}
