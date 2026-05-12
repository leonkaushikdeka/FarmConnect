import type { FastifyInstance } from "fastify";
import { prisma } from "../services/prisma.js";
import { authenticate, requireRole } from "../middleware/auth.js";

export async function farmerRoutes(app: FastifyInstance) {
  app.get("/", async (request) => {
    const query = request.query as Record<string, string>;
    const where: Record<string, unknown> = { active: true };

    if (query.search) {
      where.OR = [
        { farmName: { contains: query.search, mode: "insensitive" } },
        { user: { name: { contains: query.search, mode: "insensitive" } } },
      ];
    }
    if (query.lat && query.lng) {
      const lat = Number(query.lat);
      const lng = Number(query.lng);
      const maxDist = Number(query.radius) || 50;
      const farmers = await prisma.$queryRaw`
        SELECT * FROM "Farmer"
        WHERE active = true
        AND lat IS NOT NULL AND lng IS NOT NULL
        AND earth_distance(ll_to_earth(lat, lng), ll_to_earth(${lat}, ${lng})) / 1000 < ${maxDist}
        ORDER BY earth_distance(ll_to_earth(lat, lng), ll_to_earth(${lat}, ${lng}))
        LIMIT 50
      `;
      return farmers;
    }

    const farmers = await prisma.farmer.findMany({
      where,
      include: {
        user: { select: { name: true, email: true, imageUrl: true } },
        _count: { select: { products: true, orders: true } },
      },
      orderBy: { rating: "desc" },
    });
    return farmers;
  });

  app.get("/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    const farmer = await prisma.farmer.findUnique({
      where: { id },
      include: {
        user: { select: { name: true, email: true, imageUrl: true } },
        products: { where: { available: true } },
      },
    });
    if (!farmer) return reply.status(404).send({ error: "Farmer not found" });
    return farmer;
  });

  app.put("/profile", { preHandler: [authenticate, requireRole("FARMER")] }, async (request, reply) => {
    const body = request.body as Record<string, unknown>;
    const farmer = await prisma.farmer.findUnique({ where: { userId: request.userId } });
    if (!farmer) return reply.status(404).send({ error: "Farmer profile not found" });

    const updated = await prisma.farmer.update({
      where: { id: farmer.id },
      data: {
        farmName: body.farmName as string | undefined,
        description: body.description as string | undefined,
        story: body.story as string | undefined,
        address: body.address as string | undefined,
        phone: body.phone as string | undefined,
        lat: body.lat as number | undefined,
        lng: body.lng as number | undefined,
        certifications: body.certifications as string[] | undefined,
        deliveryRadius: body.deliveryRadius as number | undefined,
        minOrder: body.minOrder as number | undefined,
      },
    });
    return updated;
  });
}
