-- V23: Create promotion_usage table for tracking promo code usage by customers and devices
-- This enables user-based and device-based promo code validation

CREATE TABLE IF NOT EXISTS promotion_usage (
    id BIGSERIAL PRIMARY KEY,
    promotion_id BIGINT NOT NULL,
    customer_id BIGINT,
    order_id BIGINT,
    device_uuid VARCHAR(100),
    customer_phone VARCHAR(15),
    customer_email VARCHAR(100),
    discount_applied DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    order_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_first_order BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shop_id BIGINT,
    notes VARCHAR(500),

    -- Foreign Keys
    CONSTRAINT fk_promotion_usage_promotion FOREIGN KEY (promotion_id)
        REFERENCES promotions(id) ON DELETE CASCADE,
    CONSTRAINT fk_promotion_usage_customer FOREIGN KEY (customer_id)
        REFERENCES customers(id) ON DELETE SET NULL,
    CONSTRAINT fk_promotion_usage_order FOREIGN KEY (order_id)
        REFERENCES orders(id) ON DELETE SET NULL,

    -- Unique Constraints: Prevent duplicate usage
    -- One promotion per customer per order
    CONSTRAINT uk_promotion_customer_order UNIQUE (promotion_id, customer_id, order_id),
    -- One promotion per device per order (for guest users)
    CONSTRAINT uk_promotion_device_order UNIQUE (promotion_id, device_uuid, order_id)
);

-- Indexes for fast lookups
CREATE INDEX idx_promotion_customer ON promotion_usage(promotion_id, customer_id);
CREATE INDEX idx_promotion_device ON promotion_usage(promotion_id, device_uuid);
CREATE INDEX idx_customer_usage ON promotion_usage(customer_id, used_at);
CREATE INDEX idx_promotion_usage_date ON promotion_usage(promotion_id, used_at);
CREATE INDEX idx_device_usage ON promotion_usage(device_uuid, used_at);

-- Comments
COMMENT ON TABLE promotion_usage IS 'Tracks promotion code usage by customers and devices to prevent abuse';
COMMENT ON COLUMN promotion_usage.device_uuid IS 'Mobile device UUID for tracking guest users and preventing duplicate usage';
COMMENT ON COLUMN promotion_usage.customer_phone IS 'Customer phone for additional validation';
COMMENT ON COLUMN promotion_usage.is_first_order IS 'Indicates if this was customers first order (for first-time-only promotions)';
COMMENT ON COLUMN promotion_usage.ip_address IS 'IP address for fraud detection';
COMMENT ON COLUMN promotion_usage.user_agent IS 'Browser/app user agent for device tracking';
