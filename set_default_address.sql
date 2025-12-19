-- Set Office address (id: 3) as default and others as non-default
UPDATE customer_addresses SET is_default = false WHERE customer_id = (SELECT customer_id FROM customer_addresses WHERE id = 3);
UPDATE customer_addresses SET is_default = true WHERE id = 3;

-- Verify the update
SELECT id, address_type, flat_house, city, is_default
FROM customer_addresses
WHERE id IN (3, 4)
ORDER BY id;
