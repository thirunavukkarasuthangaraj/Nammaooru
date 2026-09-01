-- Weight variants (500g, 250g, 100g) for every vegetable already listed
-- in Murugesan Supermarket (shop_id = 2), reusing the same photo, name,
-- and tags as the original — ONLY base_weight/base_unit differ between
-- variants (the app already shows weight as its own line under the
-- product name, so a distinct name per size would be redundant).
-- 1kg is intentionally NOT generated: the existing listing is already the
-- 1kg-equivalent size for most of these vegetables, so adding a separate
-- "1kg" would show as a visible duplicate card next to the original.
-- Price is scaled from the current listing (treated as the 1kg reference).
-- Fully idempotent — every INSERT uses ON CONFLICT DO NOTHING, and each
-- step is independent so it's safe to re-run if one step needs a retry.

-- Step 1: create the 3 weight-variant master products for each vegetable
-- currently listed in shop 2 (source of truth is live data, not a guess).
-- SKU must still be unique per row (weight-suffixed), but name/name_tamil/
-- description/tags are copied through unchanged.
INSERT INTO master_products
    (name, name_tamil, description, sku, category_id, brand,
     base_unit, base_weight, tags, status, is_featured, is_global,
     created_by, updated_by, created_at, updated_at)
SELECT
    mp.name,
    mp.name_tamil,
    mp.description,
    mp.sku || '-' || upper(v.suffix),
    mp.category_id,
    mp.brand,
    'kg',
    v.weight,
    mp.tags,
    'ACTIVE', false, true,
    'system_seed', 'system_seed', NOW(), NOW()
FROM master_products mp
JOIN shop_products sp ON sp.master_product_id = mp.id AND sp.shop_id = 2
CROSS JOIN (VALUES ('500g', 0.500, 0.50),
                    ('250g', 0.250, 0.25),
                    ('100g', 0.100, 0.10)) AS v(suffix, weight, price_fraction)
WHERE mp.sku LIKE 'VEG-%'
  -- exclude already-generated variants so a second run of this script
  -- can't create variants-of-variants (e.g. ...-500G-500G)
  AND mp.sku !~ '-(500G|250G|100G)$'
ON CONFLICT (sku) DO NOTHING;

-- Step 2: copy the same primary image onto each new variant — pure DB
-- copy of the existing image_url string, no re-upload of any kind
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
   AND basemp.sku !~ '-(500G|250G|100G)$'
   AND newmp.sku LIKE basemp.sku || '-%'
   AND newmp.sku IN (basemp.sku || '-500G', basemp.sku || '-250G', basemp.sku || '-100G')
JOIN master_product_images src_img
    ON src_img.master_product_id = basemp.id AND src_img.is_primary = true
WHERE NOT EXISTS (
    SELECT 1 FROM master_product_images existing WHERE existing.master_product_id = newmp.id
);

-- Step 3: list each new variant in Murugesan Supermarket's shop, price
-- scaled from the base listing's current price (base = 1kg reference)
INSERT INTO shop_products
    (shop_id, master_product_id, price, stock_quantity, min_stock_level,
     max_stock_level, track_inventory, status, is_available, is_featured,
     base_weight, base_unit, created_by, updated_by, created_at, updated_at)
SELECT
    2,
    newmp.id,
    ROUND(sp.price * v.price_fraction, 2),
    sp.stock_quantity,
    sp.min_stock_level,
    sp.max_stock_level,
    sp.track_inventory,
    'ACTIVE', true, false,
    v.weight, 'kg',
    'system_seed', 'system_seed', NOW(), NOW()
FROM master_products newmp
JOIN master_products basemp
    ON basemp.sku LIKE 'VEG-%'
   AND basemp.sku !~ '-(500G|250G|100G)$'
   AND newmp.sku IN (basemp.sku || '-500G', basemp.sku || '-250G', basemp.sku || '-100G')
JOIN shop_products sp ON sp.master_product_id = basemp.id AND sp.shop_id = 2
CROSS JOIN (VALUES ('500G', 0.500, 0.50),
                    ('250G', 0.250, 0.25),
                    ('100G', 0.100, 0.10)) AS v(suffix, weight, price_fraction)
WHERE newmp.sku = basemp.sku || '-' || v.suffix
ON CONFLICT (shop_id, master_product_id) DO NOTHING;
