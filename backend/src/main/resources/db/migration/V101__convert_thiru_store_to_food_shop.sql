-- Convert shop id=1 ("Thiru store", currently GROCERY, Tirupattur village,
-- the real active/approved shop) into a food shop, and seed it with 34
-- real Tamil Nadu village-style food items across tiffin, rice/biryani,
-- chicken, mutton, beef, and regular curries/sides.
-- No images are attached (none exist for these new dishes yet) — the
-- product cards will show the default placeholder icon until the shop
-- owner uploads real photos, same as how the vegetable catalog started.
-- Idempotent: category/product inserts use WHERE NOT EXISTS / ON CONFLICT.

-- Step 1: update shop identity/type — only name, Tamil name, description,
-- business type and business name change; address/contact/commission etc
-- are left untouched.
UPDATE shops
SET business_type = 'RESTAURANT',
    name = 'Thiru Food Shop',
    name_tamil = 'திரு உணவகம்',
    description = 'Authentic Tamil Nadu food — tiffin, biryani, chicken, mutton & more, freshly made daily.',
    business_name = 'Thiru Food Shop',
    updated_at = NOW()
WHERE id = 1;

-- Step 2: create the food categories (shop-owned, scoped to shop 1)
INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Tiffin', 'டிபன்', 'Breakfast tiffin items', 'tiffin', NULL, true, 1, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'tiffin');

INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Biryani & Rice', 'பிரியாணி & சாதம்', 'Biryani and rice varieties', 'biryani-rice', NULL, true, 2, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'biryani-rice');

INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Chicken', 'கோழி', 'Chicken dishes', 'chicken', NULL, true, 3, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'chicken');

INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Mutton', 'ஆட்டு இறைச்சி', 'Mutton dishes', 'mutton', NULL, true, 4, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'mutton');

INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Beef', 'மாட்டிறைச்சி', 'Beef dishes', 'beef', NULL, true, 5, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'beef');

INSERT INTO product_categories (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Curries & Sides', 'குழம்பு & சைடு', 'Curries, soups and side items', 'curries-sides', NULL, true, 6, 1, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM product_categories WHERE slug = 'curries-sides');

-- Step 3: master products (the dishes)
INSERT INTO master_products
    (name, name_tamil, description, sku, barcode, category_id, brand,
     base_unit, base_weight, tags, status, is_featured, is_global,
     created_by, updated_by, created_at, updated_at)
VALUES
    -- Tiffin
    ('Idli (2 pcs)', 'இட்லி (2)', 'Steamed rice cakes, served with chutney and sambar', 'FOOD-IDLI-001', '8909988870001', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'idli, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Plain Dosa', 'தோசை', 'Crispy rice crepe, served with chutney and sambar', 'FOOD-DOSA-002', '8909988870002', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'dosa, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Masala Dosa', 'மசாலா தோசை', 'Dosa stuffed with spiced potato masala', 'FOOD-MDOSA-003', '8909988870003', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'dosa, masala, tiffin, breakfast', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Pongal', 'பொங்கல்', 'Soft rice and lentil porridge with ghee and pepper', 'FOOD-PONGAL-004', '8909988870004', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'pongal, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Vada (2 pcs)', 'வடை (2)', 'Crispy savoury lentil doughnuts', 'FOOD-VADA-005', '8909988870005', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'vada, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Uttapam', 'உத்தப்பம்', 'Thick savoury pancake with onion and chilli', 'FOOD-UTTAPAM-006', '8909988870006', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'uttapam, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Poori (2 pcs)', 'பூரி (2)', 'Deep-fried puffed wheat bread with potato masala', 'FOOD-POORI-007', '8909988870007', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'poori, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Idiyappam', 'இடியாப்பம்', 'Steamed rice noodles, served with curry', 'FOOD-IDIYAPPAM-008', '8909988870008', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'idiyappam, tiffin, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Parotta (2 pcs)', 'பரோட்டா (2)', 'Layered flaky flatbread', 'FOOD-PAROTTA-009', '8909988870009', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'parotta, prato, bread, dinner', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Chapati (2 pcs)', 'சப்பாத்தி (2)', 'Soft whole wheat flatbread', 'FOOD-CHAPATI-010', '8909988870010', (SELECT id FROM product_categories WHERE slug='tiffin'), NULL, 'plate', 1, 'chapati, bread, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),

    -- Biryani & Rice
    ('Chicken Biryani', 'சிக்கன் பிரியாணி', 'Fragrant spiced rice with tender chicken', 'FOOD-CBIRYANI-011', '8909988870011', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'biryani, chicken, lunch, dinner', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Mutton Biryani', 'மட்டன் பிரியாணி', 'Fragrant spiced rice with tender mutton', 'FOOD-MBIRYANI-012', '8909988870012', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'biryani, mutton, lunch, dinner', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Egg Biryani', 'எக் பிரியாணி', 'Fragrant spiced rice with boiled eggs', 'FOOD-EBIRYANI-013', '8909988870013', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'biryani, egg, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Veg Biryani', 'காய்கறி பிரியாணி', 'Fragrant spiced rice with mixed vegetables', 'FOOD-VBIRYANI-014', '8909988870014', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'biryani, vegetable, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Plain Rice', 'சாதம்', 'Steamed white rice', 'FOOD-RICE-015', '8909988870015', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'rice, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Curd Rice', 'தயிர் சாதம்', 'Rice mixed with fresh curd, tempered', 'FOOD-CURDRICE-016', '8909988870016', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'curd rice, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Lemon Rice', 'எலுமிச்சை சாதம்', 'Tangy rice tempered with lemon and peanuts', 'FOOD-LEMONRICE-017', '8909988870017', (SELECT id FROM product_categories WHERE slug='biryani-rice'), NULL, 'plate', 1, 'lemon rice, lunch', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),

    -- Chicken
    ('Chicken Curry', 'கோழி குழம்பு', 'Traditional spiced chicken gravy', 'FOOD-CCURRY-018', '8909988870018', (SELECT id FROM product_categories WHERE slug='chicken'), NULL, 'plate', 1, 'chicken, curry, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Chicken 65', 'சிக்கன் 65', 'Spicy deep-fried chicken bites', 'FOOD-C65-019', '8909988870019', (SELECT id FROM product_categories WHERE slug='chicken'), NULL, 'plate', 1, 'chicken, starter, dinner', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Chicken Fry', 'கோழி வறுவல்', 'Dry roasted spiced chicken', 'FOOD-CFRY-020', '8909988870020', (SELECT id FROM product_categories WHERE slug='chicken'), NULL, 'plate', 1, 'chicken, fry, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Pepper Chicken', 'மிளகு கோழி', 'Chicken tossed in black pepper masala', 'FOOD-PEPCHICKEN-021', '8909988870021', (SELECT id FROM product_categories WHERE slug='chicken'), NULL, 'plate', 1, 'chicken, pepper, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),

    -- Mutton
    ('Mutton Curry', 'ஆட்டு குழம்பு', 'Traditional spiced mutton gravy', 'FOOD-MCURRY-022', '8909988870022', (SELECT id FROM product_categories WHERE slug='mutton'), NULL, 'plate', 1, 'mutton, curry, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Mutton Chukka', 'மட்டன் சுக்கா', 'Dry-roasted spiced mutton', 'FOOD-MCHUKKA-023', '8909988870023', (SELECT id FROM product_categories WHERE slug='mutton'), NULL, 'plate', 1, 'mutton, chukka, dinner', 'ACTIVE', true, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Mutton Fry', 'ஆட்டு வறுவல்', 'Pan-fried spiced mutton pieces', 'FOOD-MFRY-024', '8909988870024', (SELECT id FROM product_categories WHERE slug='mutton'), NULL, 'plate', 1, 'mutton, fry, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),

    -- Beef
    ('Beef Curry', 'மாட்டிறைச்சி குழம்பு', 'Traditional spiced beef gravy', 'FOOD-BCURRY-025', '8909988870025', (SELECT id FROM product_categories WHERE slug='beef'), NULL, 'plate', 1, 'beef, curry, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Beef Fry', 'மாட்டிறைச்சி வறுவல்', 'Dry roasted spiced beef', 'FOOD-BFRY-026', '8909988870026', (SELECT id FROM product_categories WHERE slug='beef'), NULL, 'plate', 1, 'beef, fry, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Beef Ularthiyathu', 'பீஃப் உளர்த்தியது', 'Slow-roasted beef with coconut and spices', 'FOOD-BULARTHI-027', '8909988870027', (SELECT id FROM product_categories WHERE slug='beef'), NULL, 'plate', 1, 'beef, ularthiyathu, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),

    -- Curries & sides
    ('Fish Fry', 'மீன் வறுவல்', 'Pan-fried spiced fish', 'FOOD-FISHFRY-028', '8909988870028', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'plate', 1, 'fish, fry, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Egg Curry', 'முட்டை குழம்பு', 'Boiled eggs in spiced gravy', 'FOOD-EGGCURRY-029', '8909988870029', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'plate', 1, 'egg, curry, lunch, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Egg Omelette', 'ஆம்லெட்', 'Spiced Indian-style omelette', 'FOOD-OMELETTE-030', '8909988870030', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'plate', 1, 'egg, omelette, breakfast', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Rasam', 'ரசம்', 'Tangy tamarind and pepper soup', 'FOOD-RASAM-031', '8909988870031', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'bowl', 1, 'rasam, side, lunch', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Sambar', 'சாம்பார்', 'Lentil and vegetable stew', 'FOOD-SAMBAR-032', '8909988870032', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'bowl', 1, 'sambar, side, lunch', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Chicken Soup', 'சிக்கன் சூப்', 'Warm spiced chicken broth', 'FOOD-CSOUP-033', '8909988870033', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'bowl', 1, 'chicken, soup, dinner', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Buttermilk', 'மோர்', 'Chilled spiced buttermilk', 'FOOD-BUTTERMILK-034', '8909988870034', (SELECT id FROM product_categories WHERE slug='curries-sides'), NULL, 'glass', 1, 'buttermilk, drink, lunch', 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW())
ON CONFLICT (sku) DO NOTHING;

-- Step 4: list every one of these dishes for sale in shop 1
INSERT INTO shop_products
    (shop_id, master_product_id, price, stock_quantity, track_inventory, status, is_available, is_featured, created_by, updated_by, created_at, updated_at)
SELECT 1, mp.id,
    CASE mp.sku
        WHEN 'FOOD-IDLI-001' THEN 30 WHEN 'FOOD-DOSA-002' THEN 35 WHEN 'FOOD-MDOSA-003' THEN 50
        WHEN 'FOOD-PONGAL-004' THEN 35 WHEN 'FOOD-VADA-005' THEN 25 WHEN 'FOOD-UTTAPAM-006' THEN 45
        WHEN 'FOOD-POORI-007' THEN 35 WHEN 'FOOD-IDIYAPPAM-008' THEN 35 WHEN 'FOOD-PAROTTA-009' THEN 30
        WHEN 'FOOD-CHAPATI-010' THEN 25 WHEN 'FOOD-CBIRYANI-011' THEN 150 WHEN 'FOOD-MBIRYANI-012' THEN 220
        WHEN 'FOOD-EBIRYANI-013' THEN 100 WHEN 'FOOD-VBIRYANI-014' THEN 90 WHEN 'FOOD-RICE-015' THEN 40
        WHEN 'FOOD-CURDRICE-016' THEN 40 WHEN 'FOOD-LEMONRICE-017' THEN 45 WHEN 'FOOD-CCURRY-018' THEN 130
        WHEN 'FOOD-C65-019' THEN 140 WHEN 'FOOD-CFRY-020' THEN 150 WHEN 'FOOD-PEPCHICKEN-021' THEN 150
        WHEN 'FOOD-MCURRY-022' THEN 220 WHEN 'FOOD-MCHUKKA-023' THEN 230 WHEN 'FOOD-MFRY-024' THEN 240
        WHEN 'FOOD-BCURRY-025' THEN 150 WHEN 'FOOD-BFRY-026' THEN 160 WHEN 'FOOD-BULARTHI-027' THEN 170
        WHEN 'FOOD-FISHFRY-028' THEN 140 WHEN 'FOOD-EGGCURRY-029' THEN 60 WHEN 'FOOD-OMELETTE-030' THEN 25
        WHEN 'FOOD-RASAM-031' THEN 25 WHEN 'FOOD-SAMBAR-032' THEN 30 WHEN 'FOOD-CSOUP-033' THEN 60
        WHEN 'FOOD-BUTTERMILK-034' THEN 15
        ELSE 50
    END,
    30, true, 'ACTIVE', true, false, 'system_seed', 'system_seed', NOW(), NOW()
FROM master_products mp
WHERE mp.sku LIKE 'FOOD-%'
ON CONFLICT (shop_id, master_product_id) DO NOTHING;
