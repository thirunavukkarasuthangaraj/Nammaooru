-- Fix existing orders with NULL delivery_type
UPDATE orders SET delivery_type = 'HOME_DELIVERY' WHERE delivery_type IS NULL;

-- Set default for future inserts
ALTER TABLE orders ALTER COLUMN delivery_type SET DEFAULT 'HOME_DELIVERY';

-- Verify the update
SELECT COUNT(*) as updated_orders FROM orders WHERE delivery_type = 'HOME_DELIVERY';
