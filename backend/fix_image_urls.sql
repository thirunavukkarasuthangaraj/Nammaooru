-- Fix image URLs from port 8082 to 8080
UPDATE master_product_images
SET image_url = REPLACE(image_url, ':8082/', ':8080/')
WHERE image_url LIKE '%:8082/%';

-- Check the results
SELECT id, image_url
FROM master_product_images
WHERE image_url LIKE '%:8080/%'
LIMIT 5;