-- Performance indexes for Haversine location queries on post tables
-- These enable bounding box pre-filtering before expensive trig calculations

CREATE INDEX IF NOT EXISTS idx_marketplace_posts_status_location ON marketplace_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_farmer_products_status_location ON farmer_products(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_labour_posts_status_location ON labour_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_travel_posts_status_location ON travel_posts(status, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_parcel_service_posts_status_location ON parcel_service_posts(status, latitude, longitude);

-- Also index users table for nearby customer/driver queries
CREATE INDEX IF NOT EXISTS idx_users_location ON users(current_latitude, current_longitude) WHERE current_latitude IS NOT NULL AND current_longitude IS NOT NULL;
