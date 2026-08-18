-- Tamil is display-only; English remains the category/filter key.
ALTER TABLE product_categories ADD COLUMN IF NOT EXISTS name_tamil VARCHAR(100);
