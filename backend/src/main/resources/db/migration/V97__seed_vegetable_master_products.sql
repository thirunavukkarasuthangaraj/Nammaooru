-- Seed common vegetables into the master product catalog under a
-- "Vegetables" category, with generated (non-real) EAN-13-style barcodes.
-- Safe to re-run: category insert is guarded, product inserts use
-- ON CONFLICT (sku) DO NOTHING since sku is UNIQUE NOT NULL.
--
-- NOTE: a "Vegetables" category already exists in production (shop-owned,
-- owner_shop_id NOT NULL). Its `slug` ('vegetables') is globally unique
-- across ALL categories regardless of ownership, so this migration must
-- reuse that existing row rather than assume a separate global one is
-- needed — the first attempt filtered on owner_shop_id IS NULL and tried
-- to insert a second row with the same slug, which failed the deploy.

-- 1. Ensure a "Vegetables" category exists (reuse any existing one, global
--    or shop-owned — slug is unique platform-wide either way)
INSERT INTO product_categories
    (name, name_tamil, description, slug, parent_id, is_active, sort_order, owner_shop_id, created_by, updated_by, created_at, updated_at)
SELECT 'Vegetables', 'காய்கறிகள்', 'Fresh vegetables', 'vegetables', NULL, true, 1, NULL, 'system_seed', 'system_seed', NOW(), NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM product_categories WHERE name = 'Vegetables'
);

-- 2. Seed vegetables as master products (global catalog, isGlobal = true)
INSERT INTO master_products
    (name, name_tamil, description, sku, barcode, category_id, brand, base_unit, base_weight,
     status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES
    ('Tomato',          'தக்காளி',           'Fresh tomatoes',            'VEG-TOMATO-001',     '8901234560011', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Onion',           'வெங்காயம்',          'Fresh onions',               'VEG-ONION-002',      '8901234560028', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Potato',          'உருளைக்கிழங்கு',      'Fresh potatoes',             'VEG-POTATO-003',     '8901234560035', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Brinjal',         'கத்தரிக்காய்',        'Fresh brinjal / eggplant',   'VEG-BRINJAL-004',    '8901234560042', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Carrot',          'கேரட்',              'Fresh carrots',              'VEG-CARROT-005',     '8901234560059', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Cabbage',         'முட்டைக்கோஸ்',       'Fresh cabbage',              'VEG-CABBAGE-006',    '8901234560066', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Cauliflower',     'காலிஃபிளவர்',        'Fresh cauliflower',          'VEG-CAULIFLOWER-007','8901234560073', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'piece', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Beans',           'பீன்ஸ்',             'Fresh green beans',          'VEG-BEANS-008',      '8901234560080', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Ladies Finger',   'வெண்டைக்காய்',        'Fresh okra / ladies finger', 'VEG-OKRA-009',       '8901234560097', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Bottle Gourd',    'சுரைக்காய்',          'Fresh bottle gourd',         'VEG-BOTTLEGOURD-010','8901234560103', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'piece', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Bitter Gourd',    'பாகற்காய்',           'Fresh bitter gourd',         'VEG-BITTERGOURD-011','8901234560110', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Ridge Gourd',     'பீர்க்கங்காய்',        'Fresh ridge gourd',          'VEG-RIDGEGOURD-012', '8901234560127', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Pumpkin',         'பரங்கிக்காய்',        'Fresh pumpkin',              'VEG-PUMPKIN-013',    '8901234560134', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Drumstick',       'முருங்கைக்காய்',       'Fresh drumstick',            'VEG-DRUMSTICK-014',  '8901234560141', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'piece', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Green Chilli',    'பச்சை மிளகாய்',       'Fresh green chillies',       'VEG-GREENCHILLI-015','8901234560158', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 0.250, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Capsicum',        'குடமிளகாய்',          'Fresh capsicum',             'VEG-CAPSICUM-016',   '8901234560165', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Cucumber',        'வெள்ளரிக்காய்',       'Fresh cucumbers',            'VEG-CUCUMBER-017',   '8901234560172', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Radish',          'முள்ளங்கி',           'Fresh radish',               'VEG-RADISH-018',     '8901234560189', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Beetroot',        'பீட்ரூட்',            'Fresh beetroot',             'VEG-BEETROOT-019',   '8901234560196', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 1.000, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Spinach',         'பசலைக்கீரை',          'Fresh spinach / keerai',     'VEG-SPINACH-020',    '8901234560202', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'bunch', 0.500, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Garlic',          'பூண்டு',              'Fresh garlic',               'VEG-GARLIC-021',     '8901234560219', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 0.250, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Ginger',          'இஞ்சி',              'Fresh ginger',               'VEG-GINGER-022',     '8901234560226', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'kg', 0.250, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Curry Leaves',    'கறிவேப்பிலை',         'Fresh curry leaves',         'VEG-CURRYLEAVES-023','8901234560233', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'bunch', 0.100, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW()),
    ('Coriander Leaves','கொத்தமல்லி',          'Fresh coriander leaves',     'VEG-CORIANDER-024',  '8901234560240', (SELECT id FROM product_categories WHERE name = 'Vegetables' ORDER BY id LIMIT 1), NULL, 'bunch', 0.100, 'ACTIVE', false, true, 'system_seed', 'system_seed', NOW(), NOW())
ON CONFLICT (sku) DO NOTHING;
