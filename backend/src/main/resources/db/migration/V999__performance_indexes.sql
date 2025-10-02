-- Performance optimization indexes
-- Created for improved query performance across the application

-- Orders table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_shop_id ON orders(shop_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_order_number ON orders(order_number);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status_created_at ON orders(status, created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_shop_status ON orders(shop_id, status);

-- Users table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_mobile_number ON users(mobile_number);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_last_login ON users(last_login_at);

-- Shops table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_status ON shops(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_shop_id ON shops(shop_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_slug ON shops(slug);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_owner_id ON shops(owner_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_business_type ON shops(business_type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_created_at ON shops(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_location ON shops(latitude, longitude);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_status_business_type ON shops(status, business_type);

-- Shop Products table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_shop_id ON shop_products(shop_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_master_product_id ON shop_products(master_product_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_status ON shop_products(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_price ON shop_products(price);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_stock ON shop_products(stock_quantity);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_shop_status ON shop_products(shop_id, status);

-- Order Assignments table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_assignments_order_id ON order_assignments(order_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_assignments_delivery_partner_id ON order_assignments(delivery_partner_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_assignments_status ON order_assignments(assignment_status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_assignments_created_at ON order_assignments(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_assignments_partner_status ON order_assignments(delivery_partner_id, assignment_status);

-- Delivery Partners table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_user_id ON delivery_partners(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_status ON delivery_partners(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_is_online ON delivery_partners(is_online);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_location ON delivery_partners(current_latitude, current_longitude);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_created_at ON delivery_partners(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_partners_online_status ON delivery_partners(is_online, status);

-- Customers table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_referral_code ON customers(referral_code);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_created_at ON customers(created_at);

-- Notifications table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at);

-- FCM Tokens table indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fcm_tokens_device_type ON fcm_tokens(device_type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fcm_tokens_updated_at ON fcm_tokens(updated_at);

-- Order Items table indexes (if exists)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Address table indexes (if exists)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_addresses_customer_id ON customer_addresses(customer_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_addresses_type ON customer_addresses(type);

-- Full-text search indexes for better search performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shops_name_search ON shops USING gin(to_tsvector('english', name));
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_name_search ON master_products USING gin(to_tsvector('english', name));
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_search ON master_products USING gin(to_tsvector('english', category));

-- Composite indexes for common query patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_status_date ON orders(customer_id, status, created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_shop_status_date ON orders(shop_id, status, created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shop_products_shop_status_price ON shop_products(shop_id, status, price);

-- Partial indexes for active/enabled records only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_active_shops ON shops(id) WHERE status = 'ACTIVE';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_active_products ON shop_products(id) WHERE status = 'ACTIVE';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_online_partners ON delivery_partners(id) WHERE is_online = true;

-- Indexes for reporting queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_date_range ON orders(created_at) WHERE created_at >= '2024-01-01';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_monthly_orders ON orders(date_trunc('month', created_at), status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_orders ON orders(date_trunc('day', created_at), status);

COMMIT;