-- V102 hotlinked the 34 food-shop dish photos directly from Wikimedia Commons.
-- In production, CachedNetworkImage on-device failed to load them (grey
-- placeholder icon on every item) even though the URLs work fine in a
-- browser — most likely Wikimedia's CDN rejecting the request based on
-- User-Agent policy. Every other product image in this catalog is served
-- from our own /uploads/products/master/ storage, so switching to the same
-- pattern: the actual files were downloaded server-side into
-- /mnt/HC_Volume_104749884/products/master/<SKU>.jpg (backing the
-- /uploads/products/master/ path), and this migration repoints the DB rows
-- to match. Idempotent: only touches rows still holding a Wikimedia URL.

UPDATE master_product_images mpi
SET image_url = '/uploads/products/master/' || mp.sku || '.jpg'
FROM master_products mp
WHERE mpi.master_product_id = mp.id
  AND mp.sku LIKE 'FOOD-%'
  AND mpi.image_url LIKE 'https://upload.wikimedia.org/%';
