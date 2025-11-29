-- Fix ALL Product Image URLs for Production
-- This script updates image URLs in both master_product and shop_product tables

-- Step 1: Check current image URLs in master_product
SELECT
    'Master Products - Current URLs' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN image_url LIKE '%/bigbasket/%' THEN 1 END) as with_bigbasket_folder
FROM master_product;

-- Step 2: Check current image URLs in shop_product
SELECT
    'Shop Products - Current URLs' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN image_url LIKE '%/bigbasket/%' THEN 1 END) as with_bigbasket_folder
FROM shop_product;

-- Step 3: Update master_product image URLs
UPDATE master_product
SET image_url = REPLACE(image_url, '/uploads/products/master/bigbasket/', '/uploads/products/master/')
WHERE image_url LIKE '%/uploads/products/master/bigbasket/%';

-- Step 4: Update shop_product image URLs
UPDATE shop_product
SET image_url = REPLACE(image_url, '/uploads/products/master/bigbasket/', '/uploads/products/master/')
WHERE image_url LIKE '%/uploads/products/master/bigbasket/%';

-- Also check for shop-specific paths
UPDATE shop_product
SET image_url = REPLACE(image_url, '/uploads/products/shop/bigbasket/', '/uploads/products/shop/')
WHERE image_url LIKE '%/uploads/products/shop/bigbasket/%';

-- Step 5: Verify the updates
SELECT
    'Master Products - After Update' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN image_url LIKE '%/bigbasket/%' THEN 1 END) as still_with_bigbasket,
    COUNT(CASE WHEN image_url LIKE '/uploads/products/master/%' AND image_url NOT LIKE '%/bigbasket/%' THEN 1 END) as fixed_urls
FROM master_product;

SELECT
    'Shop Products - After Update' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN image_url LIKE '%/bigbasket/%' THEN 1 END) as still_with_bigbasket,
    COUNT(CASE WHEN image_url LIKE '/uploads/products/%' AND image_url NOT LIKE '%/bigbasket/%' THEN 1 END) as fixed_urls
FROM shop_product;

-- Step 6: Show sample of updated URLs
SELECT 'Sample Master Product URLs' as type, id, name, image_url
FROM master_product
WHERE image_url IS NOT NULL
LIMIT 5;

SELECT 'Sample Shop Product URLs' as type, id, product_name as name, image_url
FROM shop_product
WHERE image_url IS NOT NULL
LIMIT 5;
