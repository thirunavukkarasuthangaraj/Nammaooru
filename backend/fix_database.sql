-- Fix NULL delivery_type values in orders table
UPDATE orders SET delivery_type = 'HOME_DELIVERY' WHERE delivery_type IS NULL;

-- Verify the fix
SELECT COUNT(*) as null_count FROM orders WHERE delivery_type IS NULL;
