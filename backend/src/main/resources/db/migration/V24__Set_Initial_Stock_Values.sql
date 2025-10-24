-- Set initial stock values for existing shop products
-- This migration ensures all products have stock quantities and inventory tracking enabled

-- Update existing products that have NULL stock_quantity to have a default value
UPDATE shop_products
SET stock_quantity = 50
WHERE stock_quantity IS NULL OR stock_quantity = 0;

-- Ensure track_inventory is enabled for all products (default behavior)
UPDATE shop_products
SET track_inventory = TRUE
WHERE track_inventory IS NULL;

-- Set reasonable min and max stock levels for products that don't have them
UPDATE shop_products
SET min_stock_level = 10
WHERE min_stock_level IS NULL;

UPDATE shop_products
SET max_stock_level = 100
WHERE max_stock_level IS NULL;

-- Update product status based on current stock
UPDATE shop_products
SET status = 'OUT_OF_STOCK', is_available = FALSE
WHERE stock_quantity = 0 AND status != 'OUT_OF_STOCK';

UPDATE shop_products
SET status = 'ACTIVE', is_available = TRUE
WHERE stock_quantity > 0 AND status = 'OUT_OF_STOCK';

-- Add comment for tracking
COMMENT ON COLUMN shop_products.stock_quantity IS 'Current stock quantity - automatically reduced when orders are placed';
COMMENT ON COLUMN shop_products.track_inventory IS 'Whether to track and enforce stock limits for this product';
