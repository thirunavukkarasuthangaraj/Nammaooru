-- Add the explicit 1kg variant that V99 intentionally skipped. On review
-- of the actual admin product list, the original (unlabeled) listing
-- doesn't visibly read as "1kg" next to the clearly-suffixed 500g/250g/
-- 100g rows, so add it explicitly too — same pattern as V99: same name,
-- tags, description, and photo (copied image_url, no re-upload), only
-- base_weight/base_unit/price differ.
-- Idempotent and safe to re-run.

-- Step 1: create the 1kg variant for each vegetable currently listed in
-- shop 2 that doesn't already have a weight-suffixed SKU
INSERT INTO master_products
    (name, name_tamil, description, sku, category_id, brand,
     base_unit, base_weight, tags, status, is_featured, is_global,
     created_by, updated_by, created_at, updated_at)
SELECT
    mp.name,
    mp.name_tamil,
    mp.description,
    mp.sku || '-1KG',
    mp.category_id,
    mp.brand,
    'kg',
    1.000,
    mp.tags,
    'ACTIVE', false, true,
    'system_seed', 'system_seed', NOW(), NOW()
FROM master_products mp
JOIN shop_products sp ON sp.master_product_id = mp.id AND sp.shop_id = 2
WHERE mp.sku LIKE 'VEG-%'
  AND mp.sku !~ '-(1KG|500G|250G|100G)$'
ON CONFLICT (sku) DO NOTHING;

-- Step 2: copy the same primary image onto the new 1kg variant
INSERT INTO master_product_images
    (master_product_id, image_url, alt_text, is_primary, sort_order, created_by, created_at)
SELECT
    newmp.id,
    src_img.image_url,
    newmp.name,
    true,
    0,
    'system_seed',
    NOW()
FROM master_products newmp
JOIN master_products basemp
    ON basemp.sku LIKE 'VEG-%'
   AND basemp.sku !~ '-(1KG|500G|250G|100G)$'
   AND newmp.sku = basemp.sku || '-1KG'
JOIN master_product_images src_img
    ON src_img.master_product_id = basemp.id AND src_img.is_primary = true
WHERE NOT EXISTS (
    SELECT 1 FROM master_product_images existing WHERE existing.master_product_id = newmp.id
);

-- Step 3: list the 1kg variant in Murugesan Supermarket's shop at the
-- base listing's current price (full price — this IS the 1kg reference)
INSERT INTO shop_products
    (shop_id, master_product_id, price, stock_quantity, min_stock_level,
     max_stock_level, track_inventory, status, is_available, is_featured,
     base_weight, base_unit, created_by, updated_by, created_at, updated_at)
SELECT
    2,
    newmp.id,
    sp.price,
    sp.stock_quantity,
    sp.min_stock_level,
    sp.max_stock_level,
    sp.track_inventory,
    'ACTIVE', true, false,
    1.000, 'kg',
    'system_seed', 'system_seed', NOW(), NOW()
FROM master_products newmp
JOIN master_products basemp
    ON basemp.sku LIKE 'VEG-%'
   AND basemp.sku !~ '-(1KG|500G|250G|100G)$'
   AND newmp.sku = basemp.sku || '-1KG'
JOIN shop_products sp ON sp.master_product_id = basemp.id AND sp.shop_id = 2
ON CONFLICT (shop_id, master_product_id) DO NOTHING;
