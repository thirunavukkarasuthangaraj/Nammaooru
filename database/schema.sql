-- Drop existing tables
DROP TABLE IF EXISTS shops CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS shop_images CASCADE;

-- Create users table for authentication
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'USER' CHECK (role IN ('ADMIN', 'USER', 'SHOP_OWNER')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create shops table (independent module)
CREATE TABLE shops (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    shop_id VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    
    -- Owner Information
    owner_name VARCHAR(255) NOT NULL,
    owner_email VARCHAR(255) NOT NULL,
    owner_phone VARCHAR(20) NOT NULL,
    business_name VARCHAR(255),
    business_type VARCHAR(20) CHECK (business_type IN ('GROCERY', 'PHARMACY', 'RESTAURANT', 'GENERAL')) NOT NULL,
    
    -- Address Information
    address_line1 VARCHAR(500) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    
    -- Business Settings
    min_order_amount DECIMAL(10, 2) DEFAULT 0,
    delivery_radius DECIMAL(8, 2) DEFAULT 5,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    free_delivery_above DECIMAL(10, 2),
    commission_rate DECIMAL(5, 2) DEFAULT 15,
    
    -- Legal Information
    gst_number VARCHAR(15),
    pan_number VARCHAR(10),
    
    -- Status and Flags
    status VARCHAR(20) CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED')) DEFAULT 'PENDING',
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    
    -- Performance Metrics
    rating DECIMAL(3, 2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    
    -- Audit Fields
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create shop_images table (part of shop module)
CREATE TABLE shop_images (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT REFERENCES shops(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    image_type VARCHAR(20) DEFAULT 'GALLERY' CHECK (image_type IN ('LOGO', 'BANNER', 'GALLERY')),
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_shops_status ON shops(status);
CREATE INDEX idx_shops_business_type ON shops(business_type);
CREATE INDEX idx_shops_city ON shops(city);
CREATE INDEX idx_shops_location ON shops(latitude, longitude);
CREATE INDEX idx_shops_active ON shops(is_active);
CREATE INDEX idx_shops_rating ON shops(rating);
CREATE INDEX idx_shops_created_at ON shops(created_at);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Insert default admin user (password: admin123)
INSERT INTO users (username, email, password, role) VALUES 
('admin', 'admin@shopmanagement.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iYqiSfFGdMGCdOtY4w3PgV/.2Tsu', 'ADMIN');

-- Insert sample shop data
INSERT INTO shops (name, description, shop_id, slug, owner_name, owner_email, owner_phone, business_name, business_type, address_line1, city, state, postal_code, country, latitude, longitude, min_order_amount, delivery_radius, delivery_fee, free_delivery_above, commission_rate, status, is_active, is_verified, rating, total_orders, created_by) VALUES
('Fresh Mart', 'Your neighborhood grocery store', 'FM001', 'fresh-mart-chennai', 'Raj Kumar', 'raj@freshmart.com', '+91 9876543210', 'Fresh Mart Pvt Ltd', 'GROCERY', '123 Main Street, T. Nagar', 'Chennai', 'Tamil Nadu', '600001', 'India', 13.0827, 80.2707, 100.00, 5.0, 30.00, 500.00, 15.00, 'APPROVED', true, true, 4.5, 156, 'admin'),
('HealthCare Pharmacy', '24/7 Medical store', 'HC002', 'healthcare-pharmacy-bangalore', 'Dr. Priya', 'priya@healthcare.com', '+91 9876543211', 'HealthCare Medical Store', 'PHARMACY', '456 Health Avenue', 'Bangalore', 'Karnataka', '560001', 'India', 12.9716, 77.5946, 50.00, 3.0, 25.00, 300.00, 10.00, 'PENDING', true, false, 4.2, 89, 'admin');