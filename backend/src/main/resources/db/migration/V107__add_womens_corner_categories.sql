-- Add more Women's Corner categories (currently only 6: Tailoring, Makeup
-- Artist, Fashion & Dress, Beauty Parlour, Accessories, Mehndi). Guarded on
-- `name` so this is safe to re-run without creating duplicates.

INSERT INTO womens_corner_categories (name, tamil_name, color, is_active, display_order, created_at, updated_at)
SELECT 'Social Awareness', 'சமூக விழிப்புணர்வு', '#009688', true, 7, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM womens_corner_categories WHERE name = 'Social Awareness');

INSERT INTO womens_corner_categories (name, tamil_name, color, is_active, display_order, created_at, updated_at)
SELECT 'Jewelry', 'நகைகள்', '#FFC107', true, 8, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM womens_corner_categories WHERE name = 'Jewelry');

INSERT INTO womens_corner_categories (name, tamil_name, color, is_active, display_order, created_at, updated_at)
SELECT 'Cosmetics & Beauty', 'அழகுசாதனம்', '#F06292', true, 9, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM womens_corner_categories WHERE name = 'Cosmetics & Beauty');

INSERT INTO womens_corner_categories (name, tamil_name, color, is_active, display_order, created_at, updated_at)
SELECT 'Footwear', 'காலணி', '#795548', true, 10, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM womens_corner_categories WHERE name = 'Footwear');

INSERT INTO womens_corner_categories (name, tamil_name, color, is_active, display_order, created_at, updated_at)
SELECT 'Daily Tips', 'தினசரி குறிப்புகள்', '#8BC34A', true, 11, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM womens_corner_categories WHERE name = 'Daily Tips');
