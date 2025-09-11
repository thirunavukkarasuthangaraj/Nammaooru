-- Manual Database Cleanup - Execute these commands in your PostgreSQL client
-- This will remove ALL data from product and shop related tables

-- Step 1: Check current data count
SELECT 
    'master_products' as table_name, COUNT(*) as count FROM master_products
UNION ALL
SELECT 
    'shop_products' as table_name, COUNT(*) as count FROM shop_products
UNION ALL
SELECT 
    'shops' as table_name, COUNT(*) as count FROM shops
UNION ALL
SELECT 
    'shop_product_images' as table_name, COUNT(*) as count FROM shop_product_images
UNION ALL
SELECT 
    'master_product_images' as table_name, COUNT(*) as count FROM master_product_images;

-- Step 2: Manual cleanup in proper order (run these one by one)

-- Remove images first
DELETE FROM shop_product_images;
DELETE FROM master_product_images;
DELETE FROM shop_images;
DELETE FROM shop_documents;

-- Remove shop products (pricing data)
DELETE FROM shop_products;

-- Remove shops
DELETE FROM shops;

-- Remove master products
DELETE FROM master_products;

-- Optional: Remove categories if you want to start completely fresh
-- DELETE FROM product_categories;

-- Step 3: Reset sequences (PostgreSQL auto-increment)
SELECT setval('shops_id_seq', 1, false);
SELECT setval('master_products_id_seq', 1, false);
SELECT setval('shop_products_id_seq', 1, false);
SELECT setval('shop_product_images_id_seq', 1, false);
SELECT setval('master_product_images_id_seq', 1, false);
SELECT setval('shop_images_id_seq', 1, false);
SELECT setval('shop_documents_id_seq', 1, false);

-- Step 4: Verify cleanup (all should return 0)
SELECT 
    'master_products' as table_name, COUNT(*) as count FROM master_products
UNION ALL
SELECT 
    'shop_products' as table_name, COUNT(*) as count FROM shop_products
UNION ALL
SELECT 
    'shops' as table_name, COUNT(*) as count FROM shops
UNION ALL
SELECT 
    'shop_product_images' as table_name, COUNT(*) as count FROM shop_product_images
UNION ALL
SELECT 
    'master_product_images' as table_name, COUNT(*) as count FROM master_product_images;