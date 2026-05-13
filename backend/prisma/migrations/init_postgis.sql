-- Database Setup Script for FarmConnect
-- Run this once to set up PostGIS and required functions
-- Usage: psql -d your_database_name -f prisma/migrations/init_postgis.sql

-- 1. Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Verify PostGIS is enabled
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE EXCEPTION 'PostGIS extension could not be installed';
  END IF;
END
$$;

-- 3. Create index on lat/lng columns for fallback queries
CREATE INDEX IF NOT EXISTS idx_farmer_lat_lng ON "Farmer" (lat, lng);
CREATE INDEX IF NOT EXISTS idx_user_lat_lng ON "User" (lat, lng);

-- 4. Create a spatial index for efficient geospatial queries (PostGIS 2.3+)
-- This creates a GiST index on a geography column computed from lat/lng
ALTER TABLE "Farmer" ADD COLUMN IF NOT EXISTS geo_location geography(Point, 4326);
UPDATE "Farmer" SET geo_location = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  WHERE lat IS NOT NULL AND lng IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_farmer_geo ON "Farmer" USING GIST (geo_location);

-- 5. Trigger to keep geo_location in sync with lat/lng updates
CREATE OR REPLACE FUNCTION update_farmer_geo()
RETURNS TRIGGER AS $$
BEGIN
  NEW.geo_location = ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_farmer_geo_update ON "Farmer";
CREATE TRIGGER trg_farmer_geo_update
  BEFORE INSERT OR UPDATE ON "Farmer"
  FOR EACH ROW
  EXECUTE FUNCTION update_farmer_geo();

ALTER TABLE "User" ADD COLUMN IF NOT EXISTS geo_location geography(Point, 4326);
UPDATE "User" SET geo_location = ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
  WHERE lat IS NOT NULL AND lng IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_geo ON "User" USING GIST (geo_location);

CREATE OR REPLACE FUNCTION update_user_geo()
RETURNS TRIGGER AS $$
BEGIN
  NEW.geo_location = ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_geo_update ON "User";
CREATE TRIGGER trg_user_geo_update
  BEFORE INSERT OR UPDATE ON "User"
  FOR EACH ROW
  EXECUTE FUNCTION update_user_geo();

-- 6. Create optimized function to find nearby farmers using spatial index
CREATE OR REPLACE FUNCTION find_nearby_farmers(
    p_lat double precision,
    p_lng double precision,
    p_radius_km double precision
)
RETURNS TABLE (
    id text,
    user_id text,
    farm_name text,
    description text,
    story text,
    image_url text,
    cover_url text,
    phone text,
    address text,
    lat double precision,
    lng double precision,
    rating double precision,
    review_count integer,
    certifications text[],
    delivery_radius integer,
    min_order double precision,
    active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    distance_km double precision
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id,
        f.user_id,
        f.farm_name,
        f.description,
        f.story,
        f.image_url,
        f.cover_url,
        f.phone,
        f.address,
        f.lat,
        f.lng,
        f.rating,
        f.review_count,
        f.certifications,
        f.delivery_radius,
        f.min_order,
        f.active,
        f.created_at,
        f.updated_at,
        ST_Distance(
            f.geo_location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) / 1000.0 AS distance_km
    FROM "Farmer" f
    WHERE f.active = true
      AND f.geo_location IS NOT NULL
      AND ST_DWithin(
            f.geo_location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_km * 1000.0
          )
    ORDER BY f.geo_location <-> ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE;

-- 7. Create function for nearby product search with filters
CREATE OR REPLACE FUNCTION find_products_near_location(
    p_lat double precision,
    p_lng double precision,
    p_radius_km double precision,
    p_category text DEFAULT NULL,
    p_organic boolean DEFAULT NULL,
    p_in_season boolean DEFAULT NULL,
    p_search text DEFAULT NULL
)
RETURNS TABLE (
    product_id text,
    farmer_id text,
    name text,
    category text,
    description text,
    price double precision,
    unit text,
    quantity double precision,
    emoji text,
    organic boolean,
    in_season boolean,
    available boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    distance_km double precision,
    farmer_name text,
    farm_name text
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id AS product_id,
        p.farmer_id,
        p.name,
        p.category,
        p.description,
        p.price,
        p.unit,
        p.quantity,
        p.emoji,
        p.organic,
        p.in_season,
        p.available,
        p.created_at,
        p.updated_at,
        ST_Distance(
            f.geo_location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) / 1000.0 AS distance_km,
        u.name AS farmer_name,
        f.farm_name
    FROM "Product" p
    JOIN "Farmer" f ON f.id = p.farmer_id
    JOIN "User" u ON u.id = f.user_id
    WHERE p.available = true
      AND f.active = true
      AND f.geo_location IS NOT NULL
      AND ST_DWithin(
            f.geo_location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_km * 1000.0
          )
      AND (p_category IS NULL OR p.category = p_category)
      AND (p_organic IS NULL OR p.organic = p_organic)
      AND (p_in_season IS NULL OR p.in_season = p_in_season)
      AND (
            p_search IS NULL
            OR p.name ILIKE '%' || p_search || '%'
            OR f.farm_name ILIKE '%' || p_search || '%'
          )
    ORDER BY f.geo_location <-> ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    LIMIT 100;
END;
$$ LANGUAGE plpgsql STABLE;

-- 8. Create index for text search on products
CREATE INDEX IF NOT EXISTS idx_product_name ON "Product" (name);
CREATE INDEX IF NOT EXISTS idx_farmer_farm_name ON "Farmer" (farm_name);
CREATE INDEX IF NOT EXISTS idx_product_category ON "Product" (category);
CREATE INDEX IF NOT EXISTS idx_product_available ON "Product" (available);