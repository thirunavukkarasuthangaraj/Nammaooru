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

-- Report count column
ALTER TABLE marketplace_posts ADD COLUMN IF NOT EXISTS report_count INTEGER DEFAULT 0;

-- Reports table
CREATE TABLE IF NOT EXISTS marketplace_reports (
    id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    reporter_user_id BIGINT NOT NULL,
    reason VARCHAR(100) NOT NULL,
    details VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_report_post FOREIGN KEY (post_id) REFERENCES marketplace_posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_report_user FOREIGN KEY (reporter_user_id) REFERENCES users(id),
    CONSTRAINT uq_report_user_post UNIQUE (post_id, reporter_user_id)
);

CREATE INDEX IF NOT EXISTS idx_report_post ON marketplace_reports(post_id);
