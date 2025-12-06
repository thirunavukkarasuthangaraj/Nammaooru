-- Move Canned Goods to appear AFTER main grocery staples
-- Current: sortOrder = 1 (same as Rice, Dals, Staples)
-- New: sortOrder = 5 (still grocery, but after the main staples)
-- Order will be: Rice, Dals, Staples, etc. (1) → Canned Goods (5) → Masala (6)

UPDATE product_categories
SET sort_order = 5, updated_at = NOW()
WHERE name = 'Canned Goods';

-- Verify the change
SELECT name, sort_order
FROM product_categories
WHERE name = 'Canned Goods';
