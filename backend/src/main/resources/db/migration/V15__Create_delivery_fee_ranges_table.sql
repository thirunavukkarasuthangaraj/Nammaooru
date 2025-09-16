-- Create delivery_fee_ranges table
CREATE TABLE delivery_fee_ranges (
    id BIGSERIAL PRIMARY KEY,
    min_distance_km DECIMAL(10,2) NOT NULL,
    max_distance_km DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    partner_commission DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index for distance-based queries
CREATE INDEX idx_delivery_fee_ranges_distance ON delivery_fee_ranges(min_distance_km, max_distance_km, is_active);

-- Insert default delivery fee ranges
INSERT INTO delivery_fee_ranges (min_distance_km, max_distance_km, delivery_fee, partner_commission, is_active, created_at, updated_at) VALUES
(0.0, 2.0, 30.00, 25.00, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(2.0, 5.0, 40.00, 30.00, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(5.0, 10.0, 60.00, 45.00, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(10.0, 20.0, 80.00, 60.00, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(20.0, 999.0, 100.00, 75.00, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);