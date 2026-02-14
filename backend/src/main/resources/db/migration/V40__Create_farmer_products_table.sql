CREATE TABLE IF NOT EXISTS farmer_products (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    price DECIMAL(10,2),
    unit VARCHAR(20),
    image_url VARCHAR(500),
    seller_user_id BIGINT NOT NULL,
    seller_name VARCHAR(200),
    seller_phone VARCHAR(20) NOT NULL,
    category VARCHAR(100),
    location VARCHAR(200),
    report_count INTEGER DEFAULT 0,
    status VARCHAR(30) DEFAULT 'PENDING_APPROVAL',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_farmer_product_seller FOREIGN KEY (seller_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_farmer_products_status ON farmer_products(status);
CREATE INDEX IF NOT EXISTS idx_farmer_products_seller ON farmer_products(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_farmer_products_category ON farmer_products(category);
CREATE INDEX IF NOT EXISTS idx_farmer_products_created ON farmer_products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_farmer_products_report_count ON farmer_products(report_count);
