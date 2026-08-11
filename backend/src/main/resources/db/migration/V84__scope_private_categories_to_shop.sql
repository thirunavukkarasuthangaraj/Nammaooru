ALTER TABLE product_categories
    ADD COLUMN IF NOT EXISTS owner_shop_id BIGINT;

ALTER TABLE product_categories
    ADD CONSTRAINT fk_product_categories_owner_shop
    FOREIGN KEY (owner_shop_id) REFERENCES shops(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_product_categories_owner_shop
    ON product_categories(owner_shop_id);

-- Preserve platform categories as global. Categories created by a shop-owner login
-- become private to that owner's shop.
UPDATE product_categories pc
SET owner_shop_id = s.id
FROM shops s
WHERE pc.owner_shop_id IS NULL
  AND pc.created_by IS NOT NULL
  AND (s.created_by = pc.created_by OR s.owner_email = pc.created_by);

-- Seeded/private categories may have been created by the system account. If every
-- product using a category belongs to exactly one shop, ownership is unambiguous.
UPDATE product_categories pc
SET owner_shop_id = owned.shop_id
FROM (
    SELECT mp.category_id, MIN(sp.shop_id) AS shop_id
    FROM master_products mp
    JOIN shop_products sp ON sp.master_product_id = mp.id
    WHERE mp.category_id IS NOT NULL
    GROUP BY mp.category_id
    HAVING COUNT(DISTINCT sp.shop_id) = 1
) owned
WHERE pc.id = owned.category_id
  AND pc.owner_shop_id IS NULL;
