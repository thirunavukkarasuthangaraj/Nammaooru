-- V41: Migrate farmer_products from single image_url to multi image_urls
ALTER TABLE farmer_products ADD COLUMN image_urls VARCHAR(2500);

-- Migrate existing data
UPDATE farmer_products SET image_urls = image_url WHERE image_url IS NOT NULL;

-- Drop old column
ALTER TABLE farmer_products DROP COLUMN image_url;
