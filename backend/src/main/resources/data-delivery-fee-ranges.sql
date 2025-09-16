-- Insert default delivery fee ranges
INSERT INTO delivery_fee_ranges (min_distance_km, max_distance_km, delivery_fee, partner_commission, is_active, created_at, updated_at) VALUES
(0.0, 2.0, 30.00, 25.00, true, NOW(), NOW()),
(2.0, 5.0, 40.00, 30.00, true, NOW(), NOW()),
(5.0, 10.0, 60.00, 45.00, true, NOW(), NOW()),
(10.0, 20.0, 80.00, 60.00, true, NOW(), NOW()),
(20.0, 999.0, 100.00, 75.00, true, NOW(), NOW());