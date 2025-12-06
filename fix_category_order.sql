-- Fix Flyway failed migration and update category sort order

-- Delete failed migration record
DELETE FROM flyway_schema_history WHERE version = '33';

-- Set Grocery categories first (sort_order 1-10)
UPDATE product_categories
SET sort_order = 1, updated_at = NOW()
WHERE LOWER(name) LIKE '%grocery%' OR LOWER(name) LIKE '%groceries%';

-- Set Vegetables categories second (sort_order 11-20)
UPDATE product_categories
SET sort_order = 11, updated_at = NOW()
WHERE LOWER(name) LIKE '%vegetable%' OR LOWER(name) LIKE '%veggie%' OR LOWER(name) = 'vegetables';

-- Set Milk/Dairy categories third (sort_order 21-30)
UPDATE product_categories
SET sort_order = 21, updated_at = NOW()
WHERE LOWER(name) LIKE '%milk%' OR LOWER(name) LIKE '%dairy%' OR LOWER(name) LIKE '%curd%' OR LOWER(name) LIKE '%yogurt%' OR LOWER(name) LIKE '%paneer%' OR LOWER(name) LIKE '%cheese%' OR LOWER(name) LIKE '%butter%';

-- Set Fruits category (sort_order 31-40)
UPDATE product_categories
SET sort_order = 31, updated_at = NOW()
WHERE LOWER(name) LIKE '%fruit%';

-- Set Beverages category (sort_order 41-50)
UPDATE product_categories
SET sort_order = 41, updated_at = NOW()
WHERE LOWER(name) LIKE '%beverage%' OR LOWER(name) LIKE '%drink%' OR LOWER(name) LIKE '%juice%' OR LOWER(name) LIKE '%tea%' OR LOWER(name) LIKE '%coffee%';

-- Set Snacks category (sort_order 51-60)
UPDATE product_categories
SET sort_order = 51, updated_at = NOW()
WHERE LOWER(name) LIKE '%snack%' OR LOWER(name) LIKE '%chips%' OR LOWER(name) LIKE '%biscuit%' OR LOWER(name) LIKE '%cookie%';

-- Set Bakery category (sort_order 61-70)
UPDATE product_categories
SET sort_order = 61, updated_at = NOW()
WHERE LOWER(name) LIKE '%bakery%' OR LOWER(name) LIKE '%bread%' OR LOWER(name) LIKE '%cake%';

-- Set Personal Care category (sort_order 71-80)
UPDATE product_categories
SET sort_order = 71, updated_at = NOW()
WHERE LOWER(name) LIKE '%personal%' OR LOWER(name) LIKE '%care%' OR LOWER(name) LIKE '%hygiene%' OR LOWER(name) LIKE '%cosmetic%';

-- Set Household category (sort_order 81-90)
UPDATE product_categories
SET sort_order = 81, updated_at = NOW()
WHERE LOWER(name) LIKE '%household%' OR LOWER(name) LIKE '%cleaning%' OR LOWER(name) LIKE '%detergent%';

-- Leave other categories with default sort_order (100+)
UPDATE product_categories
SET sort_order = COALESCE(NULLIF(sort_order, 0), 100), updated_at = NOW()
WHERE sort_order = 0 OR sort_order IS NULL;

-- Show results
SELECT id, name, sort_order FROM product_categories ORDER BY sort_order, name;
