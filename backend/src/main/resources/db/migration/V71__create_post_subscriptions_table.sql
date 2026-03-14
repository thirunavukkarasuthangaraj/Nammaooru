-- Post Subscriptions: Monthly auto-debit per post
CREATE TABLE IF NOT EXISTS post_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    post_id BIGINT,                          -- set after post is created/linked
    post_type VARCHAR(50) NOT NULL,
    razorpay_plan_id VARCHAR(100),
    razorpay_subscription_id VARCHAR(100) UNIQUE,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    -- Status values: CREATED, AUTHENTICATED, ACTIVE, HALTED, CANCELLED, EXPIRED, COMPLETED
    amount INTEGER NOT NULL,                 -- monthly price in rupees
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    start_at TIMESTAMP,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_post_subs_user_id ON post_subscriptions(user_id);
CREATE INDEX idx_post_subs_post_id ON post_subscriptions(post_id);
CREATE INDEX idx_post_subs_status ON post_subscriptions(status);
CREATE INDEX idx_post_subs_razorpay_sub_id ON post_subscriptions(razorpay_subscription_id);
CREATE INDEX idx_post_subs_user_active ON post_subscriptions(user_id, status);

-- Default subscription prices per post type
INSERT INTO settings (setting_key, setting_value, description, category, setting_type, scope, is_active, is_required, is_read_only, default_value, created_by, updated_by, created_at, updated_at) VALUES
('subscription.enabled',              'true', 'Enable monthly subscription model for posts',              'SUBSCRIPTION', 'BOOLEAN', 'GLOBAL', true, false, false, 'true',  'system', 'system', NOW(), NOW()),
('subscription.price.MARKETPLACE',    '49',   'Monthly subscription price for Marketplace posts (INR)',   'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '49',    'system', 'system', NOW(), NOW()),
('subscription.price.FARM_PRODUCTS',  '29',   'Monthly subscription price for Farm Products posts (INR)', 'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '29',    'system', 'system', NOW(), NOW()),
('subscription.price.LABOURS',        '29',   'Monthly subscription price for Labour posts (INR)',        'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '29',    'system', 'system', NOW(), NOW()),
('subscription.price.TRAVELS',        '29',   'Monthly subscription price for Travel posts (INR)',        'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '29',    'system', 'system', NOW(), NOW()),
('subscription.price.PARCEL_SERVICE', '29',   'Monthly subscription price for Parcel Service posts (INR)','SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '29',    'system', 'system', NOW(), NOW()),
('subscription.price.REAL_ESTATE',    '49',   'Monthly subscription price for Real Estate posts (INR)',   'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '49',    'system', 'system', NOW(), NOW()),
('subscription.price.RENTAL',         '49',   'Monthly subscription price for Rental posts (INR)',        'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '49',    'system', 'system', NOW(), NOW()),
('subscription.price.WOMENS_CORNER',  '29',   'Monthly subscription price for Women Corner posts (INR)',  'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '29',    'system', 'system', NOW(), NOW()),
('subscription.price.BANNER_HOME',    '199',  'Monthly subscription price for Home Banner (INR)',          'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '199',   'system', 'system', NOW(), NOW()),
('subscription.price.BANNER_FEATURED','99',   'Monthly subscription price for Featured Slot (INR)',        'SUBSCRIPTION', 'INTEGER', 'GLOBAL', true, false, false, '99',    'system', 'system', NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;
