-- Proper Database Cleanup - Delete in correct order to avoid foreign key errors
-- Execute these commands ONE BY ONE in your PostgreSQL client

-- Step 1: Delete order-related data first (they reference shop_products)
DELETE FROM order_items;
DELETE FROM orders;

-- Step 2: Delete product images (they reference shop_products and master_products)
DELETE FROM shop_product_images;
DELETE FROM master_product_images;

-- Step 3: Delete shop-related data (they reference shops)
DELETE FROM shop_images;
DELETE FROM shop_documents;

-- Step 4: Delete shop products (pricing data)
DELETE FROM shop_products;

-- Step 5: Delete shops
DELETE FROM shops;

-- Step 6: Delete master products
DELETE FROM master_products;

-- Step 7: Delete other related data if exists
DELETE FROM promotions;
DELETE FROM notifications WHERE type = 'SHOP' OR type = 'PRODUCT';

-- Step 8: Reset sequences
SELECT setval('orders_id_seq', 1, false);
SELECT setval('order_items_id_seq', 1, false);
SELECT setval('shops_id_seq', 1, false);
SELECT setval('master_products_id_seq', 1, false);
SELECT setval('shop_products_id_seq', 1, false);
SELECT setval('shop_product_images_id_seq', 1, false);
SELECT setval('master_product_images_id_seq', 1, false);
SELECT setval('shop_images_id_seq', 1, false);
SELECT setval('shop_documents_id_seq', 1, false);

-- Verification - All should return 0
SELECT COUNT(*) as orders FROM orders;
SELECT COUNT(*) as order_items FROM order_items;
SELECT COUNT(*) as shop_products FROM shop_products;
SELECT COUNT(*) as shops FROM shops;
SELECT COUNT(*) as master_products FROM master_products;