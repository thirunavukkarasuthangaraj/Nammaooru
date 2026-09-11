-- V82 fixed the created_by tag on categories auto-created during bulk import
-- (e.g. Murugesan's "Dental Care", "Health & Hygiene") but never set their
-- owner_shop_id, leaving them neither properly shop-private nor truly global.
-- A now-fixed bug in category-list scoping (ProductCategoryService) used to
-- return every category unfiltered, which accidentally made these visible
-- everywhere - masking this gap. Now that scoping is correct, these orphaned
-- categories vanish from their real owner's own Categories page and from the
-- customer-facing website (whose category list is scoped by product/shop,
-- not by this ownership field the same way).
--
-- Step 1: attach each orphaned category to the shop its creator actually owns,
-- so it becomes properly shop-private again instead of falling through every
-- visibility rule. Mirrors the app's own "resolve shop by username" logic:
-- try shops.created_by first, then the user's account email against
-- shops.owner_email.
-- "AND (SELECT COUNT...) = 1" guards below: only backfill when the creator
-- resolves to exactly one shop - an ambiguous match (creator tied to more
-- than one shop, e.g. a shared admin/dev account) is left alone rather than
-- risking attaching a category to the wrong shop.
UPDATE product_categories pc
SET owner_shop_id = s.id,
    updated_at = NOW()
FROM shops s
WHERE pc.owner_shop_id IS NULL
  AND pc.created_by IS NOT NULL
  AND pc.created_by NOT IN ('admin', 'superadmin')
  AND s.created_by = pc.created_by
  AND (SELECT COUNT(*) FROM shops s2 WHERE s2.created_by = pc.created_by) = 1;

UPDATE product_categories pc
SET owner_shop_id = s.id,
    updated_at = NOW()
FROM users u
JOIN shops s ON s.owner_email = u.email
WHERE pc.owner_shop_id IS NULL
  AND pc.created_by IS NOT NULL
  AND pc.created_by NOT IN ('admin', 'superadmin')
  AND u.username = pc.created_by
  AND (SELECT COUNT(*) FROM shops s2 WHERE s2.owner_email = u.email) = 1;

-- Step 2: trim stray leading/trailing whitespace from category names. Bulk
-- import left some with an invisible leading space (e.g. " Health & Hygiene"),
-- which reads identically to a clean "Health & Hygiene" on screen but is a
-- different row - the customer app then shows both as separate categories.
UPDATE product_categories
SET name = TRIM(name), updated_at = NOW()
WHERE name <> TRIM(name);

UPDATE product_categories
SET name_tamil = TRIM(name_tamil), updated_at = NOW()
WHERE name_tamil IS NOT NULL AND name_tamil <> TRIM(name_tamil);

-- Step 3: after trimming and re-attaching ownership, some categories are now
-- exact duplicates (same name, same parent, same owner scope) - e.g. the
-- whitespace-only "Health & Hygiene" pair. Merge each duplicate group into
-- one "keeper" (lowest id = oldest/first created): move its products and
-- child subcategories over, then delete the redundant rows.
WITH dupes AS (
    SELECT id, parent_id, owner_shop_id,
           MIN(id) OVER (
               PARTITION BY LOWER(name), COALESCE(parent_id, -1), COALESCE(owner_shop_id, -1)
           ) AS keeper_id
    FROM product_categories
),
losers AS (
    SELECT id, keeper_id FROM dupes WHERE id <> keeper_id
)
UPDATE master_products mp
SET category_id = losers.keeper_id,
    updated_at = NOW()
FROM losers
WHERE mp.category_id = losers.id;

WITH dupes AS (
    SELECT id, parent_id, owner_shop_id,
           MIN(id) OVER (
               PARTITION BY LOWER(name), COALESCE(parent_id, -1), COALESCE(owner_shop_id, -1)
           ) AS keeper_id
    FROM product_categories
),
losers AS (
    SELECT id, keeper_id FROM dupes WHERE id <> keeper_id
)
UPDATE product_categories pc
SET parent_id = losers.keeper_id,
    updated_at = NOW()
FROM losers
WHERE pc.parent_id = losers.id;

-- Bump shop_products so the POS/My-Products delta sync (which filters on
-- ShopProduct.updatedAt) picks up the re-categorization promptly instead of
-- waiting for the next full 24h resync (same reasoning as ProductCategoryService
-- .updateCategory's touchProductsByCategoryId).
WITH dupes AS (
    SELECT id,
           MIN(id) OVER (
               PARTITION BY LOWER(name), COALESCE(parent_id, -1), COALESCE(owner_shop_id, -1)
           ) AS keeper_id
    FROM product_categories
),
affected_master_products AS (
    SELECT DISTINCT mp.id
    FROM master_products mp
    JOIN dupes ON dupes.keeper_id = mp.category_id AND dupes.id <> dupes.keeper_id
)
UPDATE shop_products sp
SET updated_at = NOW()
FROM affected_master_products amp
WHERE sp.master_product_id = amp.id;

WITH dupes AS (
    SELECT id, parent_id, owner_shop_id,
           MIN(id) OVER (
               PARTITION BY LOWER(name), COALESCE(parent_id, -1), COALESCE(owner_shop_id, -1)
           ) AS keeper_id
    FROM product_categories
)
DELETE FROM product_categories pc
USING dupes
WHERE pc.id = dupes.id AND dupes.id <> dupes.keeper_id;
