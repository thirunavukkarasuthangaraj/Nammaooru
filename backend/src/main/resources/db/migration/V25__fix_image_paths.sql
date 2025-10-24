-- Fix image paths that have absolute server paths
-- Run this migration to normalize all image URLs to relative paths

-- Fix shop product images
UPDATE shop_product_images
SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/')
WHERE image_url LIKE '/opt/shop-management/uploads/%';

UPDATE shop_product_images
SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/')
WHERE image_url LIKE '/app/uploads/%';

-- Fix master product images
UPDATE master_product_images
SET image_url = REPLACE(image_url, '/opt/shop-management/uploads/', '/uploads/')
WHERE image_url LIKE '/opt/shop-management/uploads/%';

UPDATE master_product_images
SET image_url = REPLACE(image_url, '/app/uploads/', '/uploads/')
WHERE image_url LIKE '/app/uploads/%';

-- Log results
DO $$
DECLARE
    shop_count INTEGER;
    master_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO shop_count FROM shop_product_images WHERE image_url LIKE '/uploads/products/%';
    SELECT COUNT(*) INTO master_count FROM master_product_images WHERE image_url LIKE '/uploads/products/%';

    RAISE NOTICE 'Image path migration completed:';
    RAISE NOTICE '  Shop product images: %', shop_count;
    RAISE NOTICE '  Master product images: %', master_count;
END $$;
