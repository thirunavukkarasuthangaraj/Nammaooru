-- Post payments table for pay-per-post feature
CREATE TABLE IF NOT EXISTS post_payments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    razorpay_order_id VARCHAR(100) NOT NULL,
    razorpay_payment_id VARCHAR(100),
    razorpay_signature VARCHAR(255),
    amount INTEGER NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    post_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    consumed BOOLEAN NOT NULL DEFAULT FALSE,
    consumed_post_id BIGINT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMP,
    consumed_at TIMESTAMP,
    CONSTRAINT fk_post_payments_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_post_payments_user_id ON post_payments(user_id);
CREATE INDEX idx_post_payments_razorpay_order_id ON post_payments(razorpay_order_id);
CREATE INDEX idx_post_payments_status ON post_payments(status);

-- Insert default settings for paid posts
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.enabled', 'true', 'Enable pay-per-post when limit is reached', 'PAID_POSTS', 'BOOLEAN', 'GLOBAL', true, true, false, 'true', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.enabled');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.price', '10', 'Price per paid post in INR', 'PAID_POSTS', 'INTEGER', 'GLOBAL', true, true, false, '10', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.price');

INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at)
SELECT 'paid_post.currency', 'INR', 'Currency for paid posts', 'PAID_POSTS', 'STRING', 'GLOBAL', true, true, false, 'INR', 'system', 'system', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM settings WHERE setting_key = 'paid_post.currency');
