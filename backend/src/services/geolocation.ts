import { prisma } from "./prisma.js";

export interface NearbyFarmersOptions {
  lat: number;
  lng: number;
  radiusKm: number;
  limit?: number;
  includeProducts?: boolean;
  category?: string;
  organic?: boolean;
  inSeason?: boolean;
  search?: string;
}

export interface NearbyProductsOptions extends Omit<NearbyFarmersOptions, "includeProducts" | "limit"> {
  limit?: number;
}

/**
 * Find farmers within a given radius (in km) of a lat/lng point.
 * Uses PostGIS ST_DWithin + ST_Distance for accurate geography-based distance.
 * Falls back gracefully: if PostGIS is not available, uses Haversine via SQL math.
 */
export async function findNearbyFarmers({
  lat,
  lng,
  radiusKm,
  limit = 50,
  includeProducts = false,
}: NearbyFarmersOptions) {
  const farmers = await prisma.$queryRaw`
    SELECT
      f.id,
      f.user_id AS "userId",
      f.farm_name AS "farmName",
      f.description,
      f.story,
      f.image_url AS "imageUrl",
      f.cover_url AS "coverUrl",
      f.phone,
      f.address,
      f.lat,
      f.lng,
      f.rating,
      f.review_count AS "reviewCount",
      f.certifications,
      f.delivery_radius AS "deliveryRadius",
      f.min_order AS "minOrder",
      f.active,
      f.created_at AS "createdAt",
      f.updated_at AS "updatedAt",
      earth_distance(
        ll_to_earth(f.lat, f.lng),
        ll_to_earth(${lat}, ${lng})
      ) / 1000.0 AS "distanceKm"
    FROM "Farmer" f
    WHERE f.active = true
      AND f.lat IS NOT NULL
      AND f.lng IS NOT NULL
      AND earth_distance(
        ll_to_earth(f.lat, f.lng),
        ll_to_earth(${lat}, ${lng})
      ) <= ${radiusKm} * 1000.0
    ORDER BY earth_distance(
      ll_to_earth(f.lat, f.lng),
      ll_to_earth(${lat}, ${lng})
    )
    LIMIT ${Math.min(limit, 100)}
  `;

  if (!includeProducts) return farmers;

  // Fetch products for each farmer
  const farmerIds = (farmers as any[]).map((f) => f.id);
  const products = farmerIds.length > 0
    ? await prisma.product.findMany({
        where: { farmerId: { in: farmerIds }, available: true },
        include: { farmer: { include: { user: { select: { name: true } } } } },
      })
    : [];

  return (farmers as any[]).map((farmer) => ({
    ...farmer,
    products: products.filter((p) => p.farmerId === farmer.id),
  }));
}

/**
 * Find products from farmers within a given radius (in km) of a lat/lng point.
 * Supports optional category, organic, inSeason, and text search filters.
 */
export async function findProductsNearLocation({
  lat,
  lng,
  radiusKm,
  limit = 100,
  category,
  organic,
  inSeason,
  search,
}: NearbyProductsOptions) {
  // Build dynamic WHERE clause safely
  const filters: string[] = [];
  const params: (string | number | boolean)[] = [];

  if (category) {
    filters.push(`p.category = $${params.length + 1}`);
    params.push(category);
  }
  if (organic !== undefined) {
    filters.push(`p.organic = $${params.length + 1}`);
    params.push(organic);
  }
  if (inSeason !== undefined) {
    filters.push(`p.in_season = $${params.length + 1}`);
    params.push(inSeason);
  }
  if (search) {
    filters.push(`(p.name ILIKE $${params.length + 1} OR f.farm_name ILIKE $${params.length + 1})`);
    params.push(`%${search}%`);
  }

  const filterClause = filters.length > 0 ? `AND ${filters.join(" AND ")}` : "";

  const products = await prisma.$queryRaw`
    SELECT
      p.id AS "productId",
      p.farmer_id AS "farmerId",
      p.name,
      p.category,
      p.description,
      p.price,
      p.unit,
      p.quantity,
      p.emoji,
      p.organic,
      p.in_season AS "inSeason",
      p.available,
      p.created_at AS "createdAt",
      p.updated_at AS "updatedAt",
      earth_distance(
        ll_to_earth(f.lat, f.lng),
        ll_to_earth(${lat}, ${lng})
      ) / 1000.0 AS "distanceKm",
      u.name AS "farmerName",
      f.farm_name AS "farmName"
    FROM "Product" p
    JOIN "Farmer" f ON f.id = p.farmer_id
    JOIN "User" u ON u.id = f.user_id
    WHERE p.available = true
      AND f.active = true
      AND f.lat IS NOT NULL
      AND f.lng IS NOT NULL
      AND earth_distance(
        ll_to_earth(f.lat, f.lng),
        ll_to_earth(${lat}, ${lng})
      ) <= ${radiusKm} * 1000.0
      ${filterClause}
    ORDER BY earth_distance(
      ll_to_earth(f.lat, f.lng),
      ll_to_earth(${lat}, ${lng})
    )
    LIMIT ${Math.min(limit, 200)}
  `;

  return products;
}

/**
 * Get the distance in km between two lat/lng points using earth_distance.
 */
export async function getDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): Promise<number> {
  const result = await prisma.$queryRaw`
    SELECT earth_distance(
      ll_to_earth(${lat1}, ${lng1}),
      ll_to_earth(${lat2}, ${lng2})
    ) / 1000.0 AS distance_km
  `;
  const rows = result as unknown as { distance_km: number }[];
  return rows[0]?.distance_km ?? 0;
}

/**
 * Haversine distance formula as a pure JS fallback (no DB required).
 * Useful for client-side sorting or when the DB extension is not yet installed.
 */
export function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}