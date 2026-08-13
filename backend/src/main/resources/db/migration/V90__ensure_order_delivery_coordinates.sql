-- Delivery coordinates on orders: used to validate the delivery address against
-- the shop's delivery radius and available to delivery partners for navigation.
-- Columns may already exist from the pre-Flyway ddl-auto era, hence IF NOT EXISTS.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_latitude NUMERIC(10, 6);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_longitude NUMERIC(10, 6);
