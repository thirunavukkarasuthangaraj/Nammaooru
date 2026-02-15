CREATE TABLE feature_configs (
    id BIGSERIAL PRIMARY KEY,
    feature_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    display_name_tamil VARCHAR(200),
    icon VARCHAR(50),
    color VARCHAR(20),
    route VARCHAR(200),
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    radius_km DOUBLE PRECISION DEFAULT 50,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- Seed default features (center: Tirupattur 12.4966, 78.5729)
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order) VALUES
('GROCERY', 'Grocery', 'மளிகை', 'shopping_basket_rounded', '#4CAF50', '/customer/shops?category=grocery', 12.4966000, 78.5729000, 100, true, 1),
('FOOD', 'Food', 'உணவு', 'restaurant_rounded', '#FF5722', '/customer/shops?category=food', 12.4966000, 78.5729000, 100, true, 2),
('MARKETPLACE', 'Marketplace', 'சந்தை', 'storefront_rounded', '#2196F3', '/customer/marketplace', 12.4966000, 78.5729000, 100, true, 3),
('FARM_PRODUCTS', 'Farm Products', 'விவசாயம்', 'eco_rounded', '#2E7D32', '/customer/farmer-products', 12.4966000, 78.5729000, 100, true, 4),
('LABOURS', 'Labours', 'தொழிலாளர்', 'construction_rounded', '#1565C0', '/customer/labours', 12.4966000, 78.5729000, 50, true, 5),
('TRAVELS', 'Travels', 'பயணங்கள்', 'directions_bus_rounded', '#00897B', '/customer/travels', 12.4966000, 78.5729000, 50, true, 6),
('PARCEL_SERVICE', 'Parcel Service', 'பார்சல் சேவை', 'local_shipping_rounded', '#E65100', '/customer/parcels', 12.4966000, 78.5729000, 50, true, 7),
('BUS_TIMING', 'Bus Timing', 'பேருந்து நேரம்', 'directions_bus_rounded', '#9C27B0', '/customer/bus-timing', 12.4966000, 78.5729000, 50, true, 8);
