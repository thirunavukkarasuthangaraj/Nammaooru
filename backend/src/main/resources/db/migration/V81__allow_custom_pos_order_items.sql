-- POS custom items (ad-hoc name + price typed at the counter) have no catalog product
ALTER TABLE order_items ALTER COLUMN shop_product_id DROP NOT NULL;
