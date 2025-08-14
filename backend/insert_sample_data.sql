-- Insert sample product categories if they don't exist
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, full_path, created_by, created_at, updated_at)
VALUES 
    ('Electronics', 'Electronic devices and accessories', 'electronics', NULL, true, 1, 'Electronics', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Clothing', 'Apparel and fashion items', 'clothing', NULL, true, 2, 'Clothing', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Food & Beverages', 'Food items and drinks', 'food-beverages', NULL, true, 3, 'Food & Beverages', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Home & Garden', 'Home improvement and gardening items', 'home-garden', NULL, true, 4, 'Home & Garden', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Books', 'Books and educational materials', 'books', NULL, true, 5, 'Books', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- Insert sample master products if they don't exist
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('Samsung Galaxy S24', 'Latest Samsung smartphone with advanced camera', 'SGS24-001', '1234567890123', (SELECT id FROM product_categories WHERE slug = 'electronics' LIMIT 1), 'Samsung', 'pcs', 0.168, 'Display: 6.2 inches, RAM: 8GB, Storage: 256GB', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Nike Air Max 270', 'Comfortable running shoes', 'NAM270-001', '2345678901234', (SELECT id FROM product_categories WHERE slug = 'clothing' LIMIT 1), 'Nike', 'pcs', 0.5, 'Size: Various, Color: Multiple options available', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Organic Green Tea', 'Premium organic green tea leaves', 'OGT-001', '3456789012345', (SELECT id FROM product_categories WHERE slug = 'food-beverages' LIMIT 1), 'Twinings', 'box', 0.1, 'Weight: 100g, Organic certified, 20 tea bags', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Apple MacBook Air', 'Lightweight laptop with M2 chip', 'APPLE-MBA-001', '4567890123456', (SELECT id FROM product_categories WHERE slug = 'electronics' LIMIT 1), 'Apple', 'pcs', 1.24, '13-inch display, 8GB RAM, 256GB SSD, M2 chip', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Adidas Ultraboost 22', 'High-performance running shoes', 'ADIDAS-UB22-001', '5678901234567', (SELECT id FROM product_categories WHERE slug = 'clothing' LIMIT 1), 'Adidas', 'pcs', 0.48, 'Boost midsole, Primeknit upper, Continental rubber outsole', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;

-- Verify the data
SELECT 'Categories Count: ' || COUNT(*) as info FROM product_categories;
SELECT 'Products Count: ' || COUNT(*) as info FROM master_products;