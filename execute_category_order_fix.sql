-- Complete script to fix category ordering
-- Execute this entire script in pgAdmin
-- Order: Grocery, Masala, Oil, Atta, Milk, Vegetables, Others

-- 1. Grocery/Staples categories (sort_order 1-5)
UPDATE product_categories
SET sort_order = 1, updated_at = NOW()
WHERE name IN ('Staples', 'Rice', 'Dals & Pulses', 'Canned Goods', 'Dried Goods',
               'Salt & Sugar', 'Syrups & Sweeteners', 'Millets');

-- 2. Masala/Spices categories (sort_order 6-10)
UPDATE product_categories
SET sort_order = 6, updated_at = NOW()
WHERE name IN ('Spices', 'Masala Mixes', 'Pickles & Pastes', 'Sauces & Condiments');

-- 3. Oil categories (sort_order 11-15)
UPDATE product_categories
SET sort_order = 11, updated_at = NOW()
WHERE name IN ('Cooking Oil');

-- 4. Atta/Flour categories (sort_order 16-20)
UPDATE product_categories
SET sort_order = 16, updated_at = NOW()
WHERE name IN ('Flours & Grains', 'Pasta & Vermicelli', 'Ready Mixes',
               'Breakfast Cereals', 'Baking Needs');

-- 5. Milk/Dairy categories (sort_order 21-30)
UPDATE product_categories
SET sort_order = 21, updated_at = NOW()
WHERE LOWER(name) LIKE '%milk%' OR LOWER(name) LIKE '%dairy%' OR LOWER(name) LIKE '%curd%'
   OR LOWER(name) LIKE '%yogurt%' OR LOWER(name) LIKE '%paneer%' OR LOWER(name) LIKE '%cheese%'
   OR LOWER(name) LIKE '%butter%' OR name LIKE 'Frozen & Dairy';

-- 6. Vegetables categories (sort_order 31-35)
UPDATE product_categories
SET sort_order = 31, updated_at = NOW()
WHERE LOWER(name) LIKE '%vegetable%' OR LOWER(name) LIKE '%veggie%';

-- 7. Fruits (sort_order 36-40)
UPDATE product_categories
SET sort_order = 36, updated_at = NOW()
WHERE LOWER(name) LIKE '%fruit%' OR name = 'Dry Fruits & Nuts';

-- 8. Beverages (sort_order 41-50)
UPDATE product_categories
SET sort_order = 41, updated_at = NOW()
WHERE LOWER(name) LIKE '%beverage%' OR LOWER(name) LIKE '%drink%' OR LOWER(name) LIKE '%juice%'
   OR LOWER(name) LIKE '%tea%' OR LOWER(name) LIKE '%coffee%' OR name IN ('Tea', 'Coffee', 'Health Drinks', 'Juices & Drinks');

-- 9. Snacks (sort_order 51-60)
UPDATE product_categories
SET sort_order = 51, updated_at = NOW()
WHERE LOWER(name) LIKE '%snack%' OR LOWER(name) LIKE '%chips%' OR LOWER(name) LIKE '%biscuit%'
   OR LOWER(name) LIKE '%cookie%' OR name IN ('Biscuits & Cookies', 'Chips & Crisps', 'Savory Snacks (Namkeen)', 'Confectionery');

-- 10. Bakery (sort_order 61-70)
UPDATE product_categories
SET sort_order = 61, updated_at = NOW()
WHERE LOWER(name) LIKE '%bakery%' OR LOWER(name) LIKE '%bread%' OR LOWER(name) LIKE '%cake%'
   OR name IN ('Bakery & Rusks', 'Bakery & Bread');

-- 11. Personal Care (sort_order 71-80)
UPDATE product_categories
SET sort_order = 71, updated_at = NOW()
WHERE LOWER(name) LIKE '%personal%' OR LOWER(name) LIKE '%care%' OR LOWER(name) LIKE '%hygiene%'
   OR LOWER(name) LIKE '%cosmetic%' OR LOWER(name) LIKE '%grooming%'
   OR name IN ('Hair Care', 'Oral Care', 'Body Care', 'Skin Care', 'Hand Care',
               'Shoe Care', 'Personal Care', 'Automotive Care', 'Feminine Hygiene',
               'Baby Care', 'Men''s Grooming', 'Bathing Soap', 'Body Wash', 'Bathing Accessories');

-- 12. Household (sort_order 81-90)
UPDATE product_categories
SET sort_order = 81, updated_at = NOW()
WHERE LOWER(name) LIKE '%household%' OR LOWER(name) LIKE '%cleaning%' OR LOWER(name) LIKE '%laundry%'
   OR name IN ('Cleaning & Household', 'Household & Misc', 'Laundry', 'Pest Control', 'Disposable Items');

-- All other categories (sort_order 100)
UPDATE product_categories
SET sort_order = 100, updated_at = NOW()
WHERE sort_order = 0 OR sort_order IS NULL;

-- Show results to verify
SELECT name, sort_order
FROM product_categories
ORDER BY sort_order, name;
