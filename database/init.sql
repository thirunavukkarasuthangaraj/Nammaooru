-- Initialize database with test data

-- Test users with BCrypt hashed passwords
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, created_at, updated_at) VALUES
('testwork', 'test@work.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Test', 'Work', 'SUPER_ADMIN', 'ACTIVE', true, true, NOW(), NOW()),
('admin1', 'admin@shop.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', 'ADMIN', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (username) DO UPDATE SET 
    password = EXCLUDED.password,
    role = EXCLUDED.role,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active;

-- Test customers
INSERT INTO customers (first_name, last_name, email, mobile_number, address_line1, city, state, postal_code, country, status, is_active, is_verified, created_at, updated_at) VALUES
('John', 'Doe', 'john@customer.com', '+919876543210', '123 MG Road', 'Bangalore', 'Karnataka', '560001', 'India', 'ACTIVE', true, true, NOW(), NOW()),
('Jane', 'Smith', 'jane@customer.com', '+919876543211', '456 Brigade Road', 'Bangalore', 'Karnataka', '560002', 'India', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- Product categories
INSERT INTO product_categories (name, description, is_active, created_by, created_at, updated_at) VALUES
('Electronics', 'Electronic items and gadgets', true, 'admin', NOW(), NOW()),
('Clothing', 'Fashion and clothing items', true, 'admin', NOW(), NOW()),
('Food', 'Food and beverages', true, 'admin', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- Master products
INSERT INTO master_products (name, description, category_id, base_price, is_active, created_by, created_at, updated_at) VALUES
('Samsung Galaxy S24', 'Latest Samsung smartphone', (SELECT id FROM product_categories WHERE name = 'Electronics'), 75000.00, true, 'admin', NOW(), NOW()),
('iPhone 15', 'Apple iPhone 15', (SELECT id FROM product_categories WHERE name = 'Electronics'), 85000.00, true, 'admin', NOW(), NOW()),
('T-Shirt', 'Cotton T-Shirt', (SELECT id FROM product_categories WHERE name = 'Clothing'), 500.00, true, 'admin', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;