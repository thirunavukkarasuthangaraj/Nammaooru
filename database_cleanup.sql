-- Database Cleanup Script - Remove All Data for Fresh Start
-- Execute this script to clean all shops, products, and images

-- ⚠️ WARNING: This will delete ALL data! Make sure you have backups if needed.

-- Disable foreign key checks temporarily (for MySQL/MariaDB)
-- SET FOREIGN_KEY_CHECKS = 0;

-- For PostgreSQL, we need to truncate in the right order due to foreign keys

-- Step 1: Remove all product images first (they reference shop_products)
DELETE FROM shop_product_images;
DELETE FROM master_product_images;

-- Step 2: Remove all price variations (they reference shop_products)
DELETE FROM price_variations;

-- Step 3: Remove all bulk pricing tiers (they reference shop_products)
DELETE FROM bulk_pricing_tiers;

-- Step 4: Remove all customer group pricing (they reference shop_products)
DELETE FROM customer_group_pricing;

-- Step 5: Remove all shop products (main pricing table)
DELETE FROM shop_products;

-- Step 6: Remove all shop images (they reference shops)
DELETE FROM shop_images;

-- Step 7: Remove all shop documents (they reference shops)
DELETE FROM shop_documents;

-- Step 8: Remove all shops
DELETE FROM shops;

-- Step 9: Remove all master products
DELETE FROM master_products;

-- Step 10: Remove all product categories (if you want to clean these too)
-- DELETE FROM product_categories;

-- Step 11: Reset auto-increment sequences (PostgreSQL)
ALTER SEQUENCE IF EXISTS shops_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS master_products_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS shop_products_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS shop_product_images_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS master_product_images_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS shop_images_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS shop_documents_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS price_variations_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS bulk_pricing_tiers_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS customer_group_pricing_id_seq RESTART WITH 1;

-- For MySQL/MariaDB, use this instead:
-- ALTER TABLE shops AUTO_INCREMENT = 1;
-- ALTER TABLE master_products AUTO_INCREMENT = 1;
-- ALTER TABLE shop_products AUTO_INCREMENT = 1;
-- ALTER TABLE shop_product_images AUTO_INCREMENT = 1;
-- ALTER TABLE master_product_images AUTO_INCREMENT = 1;
-- ALTER TABLE shop_images AUTO_INCREMENT = 1;
-- ALTER TABLE shop_documents AUTO_INCREMENT = 1;
-- ALTER TABLE price_variations AUTO_INCREMENT = 1;
-- ALTER TABLE bulk_pricing_tiers AUTO_INCREMENT = 1;
-- ALTER TABLE customer_group_pricing AUTO_INCREMENT = 1;

-- Re-enable foreign key checks
-- SET FOREIGN_KEY_CHECKS = 1;

-- Verification queries - Run these to confirm cleanup
SELECT COUNT(*) as shop_products_count FROM shop_products;
SELECT COUNT(*) as shops_count FROM shops;
SELECT COUNT(*) as master_products_count FROM master_products;
SELECT COUNT(*) as shop_images_count FROM shop_product_images;
SELECT COUNT(*) as master_images_count FROM master_product_images;

-- All counts should be 0 after cleanup