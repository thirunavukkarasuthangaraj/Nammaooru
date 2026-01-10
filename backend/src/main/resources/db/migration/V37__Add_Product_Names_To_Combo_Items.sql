-- Add product names columns to combo_items for historical tracking
ALTER TABLE combo_items ADD COLUMN IF NOT EXISTS product_name VARCHAR(255);
ALTER TABLE combo_items ADD COLUMN IF NOT EXISTS product_name_tamil VARCHAR(255);

-- Populate existing records with product names from shop_products
UPDATE combo_items ci
SET product_name = COALESCE(sp.custom_name, mp.name),
    product_name_tamil = mp.name_tamil
FROM shop_products sp
LEFT JOIN master_products mp ON sp.master_product_id = mp.id
WHERE ci.shop_product_id = sp.id
  AND (ci.product_name IS NULL OR ci.product_name_tamil IS NULL);
