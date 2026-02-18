-- Add latitude/longitude columns to marketplace_posts
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);

-- Add latitude/longitude columns to farmer_products
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8);
ALTER TABLE farmer_products ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
