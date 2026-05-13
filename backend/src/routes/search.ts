import type { FastifyInstance, FastifyRequest } from "fastify";
import { prisma } from "../services/prisma.js";
import { findNearbyFarmers, findProductsNearLocation } from "../services/geolocation.js";
import { z } from "zod";

const nearbyQuerySchema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  radius: z.coerce.number().min(1).max(500).default(50),
  limit: z.coerce.number().optional().default(50),
  category: z.string().optional(),
  organic: z.coerce.boolean().optional(),
  inSeason: z.coerce.boolean().optional(),
  search: z.string().optional(),
});

type NearbyQuery = z.infer<typeof nearbyQuerySchema>;

interface SearchRequest extends FastifyRequest {
  query: {
    lat: string;
    lng: string;
    radius?: string;
    limit?: string;
    category?: string;
    organic?: string;
    inSeason?: string;
    search?: string;
  };
}

function parseQuery(raw: Record<string, unknown>): NearbyQuery {
  return nearbyQuerySchema.parse(raw);
}

export async function searchRoutes(app: FastifyInstance) {
  // Combined nearby search: farmers + their products
  app.get<{ Querystring: SearchRequest["query"] }>("/nearby", async (request, reply) => {
    const query = parseQuery(request.query as Record<string, unknown>);

    try {
      const farmers = await findNearbyFarmers({
        lat: query.lat,
        lng: query.lng,
        radiusKm: query.radius,
        limit: query.limit,
        includeProducts: true,
        category: query.category,
        organic: query.organic,
        inSeason: query.inSeason,
        search: query.search,
      });

      const products = await findProductsNearLocation({
        lat: query.lat,
        lng: query.lng,
        radiusKm: query.radius,
        limit: query.limit,
        category: query.category,
        organic: query.organic,
        inSeason: query.inSeason,
        search: query.search,
      });

      return {
        farmers,
        products,
        meta: {
          lat: query.lat,
          lng: query.lng,
          radiusKm: query.radius,
          farmerCount: (farmers as unknown[]).length,
          productCount: (products as unknown[]).length,
        },
      };
    } catch (err: any) {
      app.log.error(err);
      return reply.status(500).send({ error: "Failed to perform nearby search" });
    }
  });

  // Nearby farmers only
  app.get<{ Querystring: SearchRequest["query"] }>("/farmers", async (request, reply) => {
    const query = parseQuery(request.query as Record<string, unknown>);

    try {
      const farmers = await findNearbyFarmers({
        lat: query.lat,
        lng: query.lng,
        radiusKm: query.radius,
        limit: query.limit,
        includeProducts: false,
      });

      return {
        farmers,
        meta: {
          lat: query.lat,
          lng: query.lng,
          radiusKm: query.radius,
          count: (farmers as unknown[]).length,
        },
      };
    } catch (err: any) {
      app.log.error(err);
      return reply.status(500).send({ error: "Failed to find nearby farmers" });
    }
  });

  // Nearby products only
  app.get<{ Querystring: SearchRequest["query"] }>("/products", async (request, reply) => {
    const query = parseQuery(request.query as Record<string, unknown>);

    try {
      const products = await findProductsNearLocation({
        lat: query.lat,
        lng: query.lng,
        radiusKm: query.radius,
        limit: query.limit,
        category: query.category,
        organic: query.organic,
        inSeason: query.inSeason,
        search: query.search,
      });

      return {
        products,
        meta: {
          lat: query.lat,
          lng: query.lng,
          radiusKm: query.radius,
          count: (products as unknown[]).length,
        },
      };
    } catch (err: any) {
      app.log.error(err);
      return reply.status(500).send({ error: "Failed to search nearby products" });
    }
  });
}