-- Migration: Enable PostGIS and create distance function
-- Run with: psql -d your_database -f prisma/migrations/20260512000000_init_postgis.sql

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create a function to calculate distance using PostGIS ST_DWithin
-- This uses meters for radius
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
            ST_SetSRID(ST_MakePoint(f.lng, f.lat), 4326)::geography,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) / 1000.0 AS distance_km
    FROM "Farmer" f
    WHERE f.active = true
      AND f.lat IS NOT NULL
      AND f.lng IS NOT NULL
      AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(f.lng, f.lat), 4326)::geography,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_km * 1000.0
          )
    ORDER BY distance_km
    LIMIT 50;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to find products from nearby farmers
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
            ST_SetSRID(ST_MakePoint(f.lng, f.lat), 4326)::geography,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) / 1000.0 AS distance_km,
        u.name AS farmer_name,
        f.farm_name
    FROM "Product" p
    JOIN "Farmer" f ON f.id = p.farmer_id
    JOIN "User" u ON u.id = f.user_id
    WHERE p.available = true
      AND f.active = true
      AND f.lat IS NOT NULL
      AND f.lng IS NOT NULL
      AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(f.lng, f.lat), 4326)::geography,
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
    ORDER BY distance_km
    LIMIT 100;
END;
$$ LANGUAGE plpgsql STABLE;