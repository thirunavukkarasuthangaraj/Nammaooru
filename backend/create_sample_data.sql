-- =============================================
-- COMPREHENSIVE SAMPLE DATA CREATION SCRIPT
-- Shop Management System
-- =============================================

-- Clear existing sample data (optional)
-- DELETE FROM master_products WHERE created_by = 'system';
-- DELETE FROM product_categories WHERE created_by = 'system';

-- =============================================
-- 1. ROOT CATEGORIES
-- =============================================
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, full_path, created_by, created_at, updated_at)
VALUES 
    ('Electronics', 'Electronic devices, gadgets, and technology products', 'electronics', NULL, true, 1, 'Electronics', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Fashion & Clothing', 'Apparel, footwear, and fashion accessories for all', 'fashion-clothing', NULL, true, 2, 'Fashion & Clothing', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Home & Garden', 'Home improvement, furniture, and gardening supplies', 'home-garden', NULL, true, 3, 'Home & Garden', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Health & Beauty', 'Personal care, cosmetics, and health products', 'health-beauty', NULL, true, 4, 'Health & Beauty', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Sports & Outdoors', 'Athletic gear, outdoor equipment, and fitness products', 'sports-outdoors', NULL, true, 5, 'Sports & Outdoors', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Books & Media', 'Books, movies, music, and educational materials', 'books-media', NULL, true, 6, 'Books & Media', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Food & Beverages', 'Groceries, snacks, beverages, and specialty foods', 'food-beverages', NULL, true, 7, 'Food & Beverages', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Toys & Games', 'Toys, games, and entertainment for all ages', 'toys-games', NULL, true, 8, 'Toys & Games', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Automotive', 'Car accessories, parts, and automotive supplies', 'automotive', NULL, true, 9, 'Automotive', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Office Supplies', 'Stationery, office equipment, and business supplies', 'office-supplies', NULL, true, 10, 'Office Supplies', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- 2. ELECTRONICS SUBCATEGORIES
-- =============================================
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, full_path, created_by, created_at, updated_at)
VALUES 
    ('Smartphones', 'Mobile phones and accessories', 'smartphones', (SELECT id FROM product_categories WHERE slug = 'electronics'), true, 1, 'Electronics > Smartphones', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Laptops & Computers', 'Desktop computers, laptops, and peripherals', 'laptops-computers', (SELECT id FROM product_categories WHERE slug = 'electronics'), true, 2, 'Electronics > Laptops & Computers', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Audio & Headphones', 'Speakers, headphones, and audio equipment', 'audio-headphones', (SELECT id FROM product_categories WHERE slug = 'electronics'), true, 3, 'Electronics > Audio & Headphones', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Gaming', 'Gaming consoles, games, and gaming accessories', 'gaming', (SELECT id FROM product_categories WHERE slug = 'electronics'), true, 4, 'Electronics > Gaming', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Smart Home', 'Smart devices and home automation products', 'smart-home', (SELECT id FROM product_categories WHERE slug = 'electronics'), true, 5, 'Electronics > Smart Home', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- 3. FASHION SUBCATEGORIES
-- =============================================
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, full_path, created_by, created_at, updated_at)
VALUES 
    ('Men''s Clothing', 'Clothing and apparel for men', 'mens-clothing', (SELECT id FROM product_categories WHERE slug = 'fashion-clothing'), true, 1, 'Fashion & Clothing > Men''s Clothing', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Women''s Clothing', 'Clothing and apparel for women', 'womens-clothing', (SELECT id FROM product_categories WHERE slug = 'fashion-clothing'), true, 2, 'Fashion & Clothing > Women''s Clothing', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Shoes & Footwear', 'Footwear for all occasions and styles', 'shoes-footwear', (SELECT id FROM product_categories WHERE slug = 'fashion-clothing'), true, 3, 'Fashion & Clothing > Shoes & Footwear', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Bags & Accessories', 'Handbags, wallets, and fashion accessories', 'bags-accessories', (SELECT id FROM product_categories WHERE slug = 'fashion-clothing'), true, 4, 'Fashion & Clothing > Bags & Accessories', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Kids'' Clothing', 'Clothing and apparel for children', 'kids-clothing', (SELECT id FROM product_categories WHERE slug = 'fashion-clothing'), true, 5, 'Fashion & Clothing > Kids'' Clothing', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- =============================================
-- 4. SAMPLE PRODUCTS - ELECTRONICS
-- =============================================
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    -- Smartphones
    ('iPhone 15 Pro', 'Latest Apple iPhone with advanced camera system and A17 Pro chip', 'APPLE-IP15PRO-128', '1234567890001', (SELECT id FROM product_categories WHERE slug = 'smartphones'), 'Apple', 'pcs', 0.187, 'Display: 6.1-inch Super Retina XDR, Storage: 128GB, Camera: 48MP Pro camera system', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Samsung Galaxy S24 Ultra', 'Premium Samsung smartphone with S Pen and 200MP camera', 'SAMSUNG-S24U-256', '1234567890002', (SELECT id FROM product_categories WHERE slug = 'smartphones'), 'Samsung', 'pcs', 0.232, 'Display: 6.8-inch Dynamic AMOLED 2X, Storage: 256GB, Camera: 200MP quad camera', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Google Pixel 8', 'Google''s flagship phone with advanced AI photography', 'GOOGLE-PIX8-128', '1234567890003', (SELECT id FROM product_categories WHERE slug = 'smartphones'), 'Google', 'pcs', 0.187, 'Display: 6.2-inch Actua display, Storage: 128GB, Camera: 50MP dual camera with AI', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Laptops
    ('MacBook Air M3', 'Ultra-thin laptop with Apple M3 chip and all-day battery', 'APPLE-MBA-M3-256', '1234567890004', (SELECT id FROM product_categories WHERE slug = 'laptops-computers'), 'Apple', 'pcs', 1.24, 'Display: 13.6-inch Liquid Retina, Processor: Apple M3, Storage: 256GB SSD, RAM: 8GB', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Dell XPS 13', 'Premium ultrabook with Intel Core i7 and InfinityEdge display', 'DELL-XPS13-512', '1234567890005', (SELECT id FROM product_categories WHERE slug = 'laptops-computers'), 'Dell', 'pcs', 1.19, 'Display: 13.4-inch FHD+, Processor: Intel Core i7-1360P, Storage: 512GB SSD, RAM: 16GB', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('HP Pavilion 15', 'Versatile laptop for work and entertainment', 'HP-PAV15-512', '1234567890006', (SELECT id FROM product_categories WHERE slug = 'laptops-computers'), 'HP', 'pcs', 1.75, 'Display: 15.6-inch FHD, Processor: AMD Ryzen 5, Storage: 512GB SSD, RAM: 8GB', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Audio
    ('Sony WH-1000XM5', 'Industry-leading noise canceling wireless headphones', 'SONY-WH1000XM5', '1234567890007', (SELECT id FROM product_categories WHERE slug = 'audio-headphones'), 'Sony', 'pcs', 0.25, 'Type: Over-ear wireless, Noise Canceling: Yes, Battery: 30 hours, Features: Touch controls', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Apple AirPods Pro 2', 'Wireless earbuds with active noise cancellation', 'APPLE-AIRPODS-PRO2', '1234567890008', (SELECT id FROM product_categories WHERE slug = 'audio-headphones'), 'Apple', 'pcs', 0.056, 'Type: In-ear wireless, Noise Canceling: Yes, Battery: 6 hours + 30 hours case', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('JBL Charge 5', 'Portable Bluetooth speaker with powerbank feature', 'JBL-CHARGE5-BLK', '1234567890009', (SELECT id FROM product_categories WHERE slug = 'audio-headphones'), 'JBL', 'pcs', 0.96, 'Type: Portable speaker, Connectivity: Bluetooth 5.1, Battery: 20 hours, Waterproof: IP67', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- =============================================
-- 5. SAMPLE PRODUCTS - FASHION
-- =============================================
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    -- Men's Clothing
    ('Levi''s 501 Original Jeans', 'Classic straight-fit jeans in original blue denim', 'LEVIS-501-ORIG-32', '2345678900001', (SELECT id FROM product_categories WHERE slug = 'mens-clothing'), 'Levi''s', 'pcs', 0.8, 'Material: 100% Cotton, Fit: Straight, Sizes: 28-40 waist, Color: Original Blue', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Nike Dri-FIT T-Shirt', 'Moisture-wicking athletic t-shirt for active lifestyle', 'NIKE-DFIT-TEE-M', '2345678900002', (SELECT id FROM product_categories WHERE slug = 'mens-clothing'), 'Nike', 'pcs', 0.2, 'Material: 100% Polyester, Technology: Dri-FIT, Sizes: S-XXL, Colors: Multiple', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Adidas Hoodie', 'Comfortable pullover hoodie with classic 3-stripes', 'ADIDAS-HOOD-M-L', '2345678900003', (SELECT id FROM product_categories WHERE slug = 'mens-clothing'), 'Adidas', 'pcs', 0.6, 'Material: Cotton blend, Style: Pullover, Sizes: S-XXL, Features: Kangaroo pocket', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    
    -- Shoes
    ('Nike Air Max 270', 'Lifestyle sneakers with Max Air cushioning', 'NIKE-AM270-BLK-10', '2345678900004', (SELECT id FROM product_categories WHERE slug = 'shoes-footwear'), 'Nike', 'pcs', 0.5, 'Type: Lifestyle sneakers, Cushioning: Max Air, Sizes: 6-13 US, Colors: Black/White', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Adidas Ultraboost 22', 'High-performance running shoes with Boost technology', 'ADIDAS-UB22-WHT-9', '2345678900005', (SELECT id FROM product_categories WHERE slug = 'shoes-footwear'), 'Adidas', 'pcs', 0.48, 'Type: Running shoes, Technology: Boost midsole, Sizes: 6-13 US, Colors: White/Black', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Converse Chuck Taylor', 'Classic canvas high-top sneakers', 'CONVERSE-CT-HI-BLK', '2345678900006', (SELECT id FROM product_categories WHERE slug = 'shoes-footwear'), 'Converse', 'pcs', 0.4, 'Type: Canvas sneakers, Style: High-top, Sizes: 5-13 US, Colors: Black, White, Red', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- =============================================
-- 6. SAMPLE PRODUCTS - FOOD & BEVERAGES
-- =============================================
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('Organic Green Tea', 'Premium organic green tea leaves with antioxidants', 'TWININGS-GT-ORG-100', '3456789000001', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Twinings', 'box', 0.1, 'Type: Green tea, Weight: 100g, Quantity: 50 tea bags, Certification: Organic', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Coca-Cola Classic', 'Original Coca-Cola soft drink', 'COCACOLA-CLASSIC-330', '3456789000002', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Coca-Cola', 'can', 0.33, 'Type: Soft drink, Volume: 330ml, Packaging: Aluminum can, Caffeine: Yes', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Lay''s Classic Potato Chips', 'Crispy potato chips with classic salt flavor', 'LAYS-CLASSIC-150G', '3456789000003', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Lay''s', 'bag', 0.15, 'Type: Potato chips, Weight: 150g, Flavor: Classic salted, Packaging: Resealable bag', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Starbucks Pike Place Coffee', 'Medium roast ground coffee beans', 'STARBUCKS-PP-340G', '3456789000004', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Starbucks', 'bag', 0.34, 'Type: Ground coffee, Weight: 340g, Roast: Medium, Origin: Latin America', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- =============================================
-- 7. SAMPLE PRODUCTS - HOME & GARDEN
-- =============================================
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('IKEA Lack Side Table', 'Simple and modern side table for any room', 'IKEA-LACK-WHT-45', '4567890000001', (SELECT id FROM product_categories WHERE slug = 'home-garden'), 'IKEA', 'pcs', 7.5, 'Dimensions: 45x45x45 cm, Material: Particleboard with paint finish, Colors: White, Black', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Philips LED Bulb 9W', 'Energy-efficient LED light bulb', 'PHILIPS-LED-9W-WW', '4567890000002', (SELECT id FROM product_categories WHERE slug = 'home-garden'), 'Philips', 'pcs', 0.06, 'Wattage: 9W, Equivalent: 60W, Color: Warm white, Lifespan: 15,000 hours', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Plant Pot Terra Cotta', 'Classic terra cotta plant pot for indoor/outdoor use', 'GENERIC-POT-TC-20CM', '4567890000003', (SELECT id FROM product_categories WHERE slug = 'home-garden'), 'Generic', 'pcs', 0.8, 'Material: Terra cotta, Diameter: 20cm, Height: 18cm, Drainage: Yes', 'ACTIVE', false, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- =============================================
-- 8. SAMPLE PRODUCTS - BOOKS & MEDIA
-- =============================================
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('The Psychology of Money', 'Bestselling book about wealth, greed, and happiness by Morgan Housel', 'BOOK-POM-HOUSEL', '5678900000001', (SELECT id FROM product_categories WHERE slug = 'books-media'), 'Harriman House', 'pcs', 0.3, 'Author: Morgan Housel, Pages: 256, Format: Paperback, Genre: Finance/Psychology', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Atomic Habits', 'Guide to building good habits and breaking bad ones by James Clear', 'BOOK-AH-CLEAR', '5678900000002', (SELECT id FROM product_categories WHERE slug = 'books-media'), 'Avery', 'pcs', 0.35, 'Author: James Clear, Pages: 320, Format: Paperback, Genre: Self-help', 'ACTIVE', true, true, 'system', 'system', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Count categories and products
SELECT 
    'Categories Created' as type, 
    COUNT(*) as count 
FROM product_categories 
WHERE created_by = 'system'

UNION ALL

SELECT 
    'Products Created' as type, 
    COUNT(*) as count 
FROM master_products 
WHERE created_by = 'system'

UNION ALL

SELECT 
    'Root Categories' as type, 
    COUNT(*) as count 
FROM product_categories 
WHERE parent_id IS NULL AND created_by = 'system'

UNION ALL

SELECT 
    'Subcategories' as type, 
    COUNT(*) as count 
FROM product_categories 
WHERE parent_id IS NOT NULL AND created_by = 'system';

-- Show category hierarchy
SELECT 
    CASE WHEN pc.parent_id IS NULL THEN pc.name 
         ELSE CONCAT('  └─ ', pc.name) 
    END as category_hierarchy,
    pc.slug,
    pc.is_active,
    COUNT(mp.id) as product_count
FROM product_categories pc
LEFT JOIN master_products mp ON pc.id = mp.category_id AND mp.created_by = 'system'
WHERE pc.created_by = 'system'
GROUP BY pc.id, pc.name, pc.slug, pc.is_active, pc.parent_id, pc.sort_order
ORDER BY 
    COALESCE(pc.parent_id, pc.id), 
    pc.parent_id NULLS FIRST, 
    pc.sort_order;