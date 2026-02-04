CREATE TABLE IF NOT EXISTS marketplace_posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1000),
    price DECIMAL(10,2),
    image_url VARCHAR(500),
    voice_url VARCHAR(500),
    seller_user_id BIGINT NOT NULL,
    seller_name VARCHAR(200),
    seller_phone VARCHAR(20) NOT NULL,
    category VARCHAR(100),
    location VARCHAR(200),
    status VARCHAR(30) DEFAULT 'PENDING_APPROVAL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_marketplace_seller FOREIGN KEY (seller_user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_status ON marketplace_posts(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_seller ON marketplace_posts(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_category ON marketplace_posts(category);
CREATE INDEX IF NOT EXISTS idx_marketplace_created ON marketplace_posts(created_at DESC);
