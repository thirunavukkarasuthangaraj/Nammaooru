-- Insert admin user with bcrypt hashed password for 'admin123'
-- Password: admin123 -> BCrypt hash
INSERT INTO users (username, email, password, first_name, last_name, role, enabled, created_at, updated_at)
VALUES (
    'admin',
    'admin@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'System',
    'Admin',
    'ADMIN',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO UPDATE
SET password = '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy',
    email = 'admin@shopmanagement.com',
    role = 'ADMIN',
    enabled = true,
    updated_at = CURRENT_TIMESTAMP;

-- Insert a shop owner user
INSERT INTO users (username, email, password, first_name, last_name, role, enabled, created_at, updated_at)
VALUES (
    'shopowner',
    'shopowner@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'Shop',
    'Owner',
    'SHOP_OWNER',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO NOTHING;

-- Insert a regular user
INSERT INTO users (username, email, password, first_name, last_name, role, enabled, created_at, updated_at)
VALUES (
    'user',
    'user@shopmanagement.com',
    '$2a$10$TkFJqCLjeEGmW5OESQ5cLOxbnrx3a2GG5p9nnixNHJKKLXqEKq3vy', -- admin123
    'Regular',
    'User',
    'USER',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (username) DO NOTHING;

-- Insert sample product categories
INSERT INTO product_categories (name, description, slug, parent_id, is_active, sort_order, full_path, created_by, created_at, updated_at)
VALUES 
    ('Electronics', 'Electronic devices and accessories', 'electronics', NULL, true, 1, 'Electronics', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Clothing', 'Apparel and fashion items', 'clothing', NULL, true, 2, 'Clothing', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Food & Beverages', 'Food items and drinks', 'food-beverages', NULL, true, 3, 'Food & Beverages', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Home & Garden', 'Home improvement and gardening items', 'home-garden', NULL, true, 4, 'Home & Garden', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Books', 'Books and educational materials', 'books', NULL, true, 5, 'Books', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (slug) DO NOTHING;

-- Insert sample master products
INSERT INTO master_products (name, description, sku, barcode, category_id, brand, base_unit, base_weight, specifications, status, is_featured, is_global, created_by, updated_by, created_at, updated_at)
VALUES 
    ('Samsung Galaxy S24', 'Latest Samsung smartphone with advanced camera', 'SGS24-001', '1234567890123', (SELECT id FROM product_categories WHERE slug = 'electronics'), 'Samsung', 'pcs', 0.168, 'Display: 6.2 inches, RAM: 8GB, Storage: 256GB', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Nike Air Max 270', 'Comfortable running shoes', 'NAM270-001', '2345678901234', (SELECT id FROM product_categories WHERE slug = 'clothing'), 'Nike', 'pcs', 0.5, 'Size: Various, Color: Multiple options available', 'ACTIVE', true, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('Organic Green Tea', 'Premium organic green tea leaves', 'OGT-001', '3456789012345', (SELECT id FROM product_categories WHERE slug = 'food-beverages'), 'Twinings', 'box', 0.1, 'Weight: 100g, Organic certified, 20 tea bags', 'ACTIVE', false, true, 'admin', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (sku) DO NOTHING;