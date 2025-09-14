-- Create delivery partner location tracking table
CREATE TABLE IF NOT EXISTS delivery_partner_locations (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    accuracy DECIMAL(5, 2),
    speed DECIMAL(5, 2),
    heading DECIMAL(5, 2),
    altitude DECIMAL(8, 2),
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_moving BOOLEAN DEFAULT false,
    battery_level INTEGER,
    network_type VARCHAR(20),
    assignment_id BIGINT,
    order_status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_partner_location_user
        FOREIGN KEY (partner_id) REFERENCES users(id),
    CONSTRAINT fk_location_assignment
        FOREIGN KEY (assignment_id) REFERENCES order_assignments(id)
);

-- Create indexes for fast queries
CREATE INDEX idx_partner_time ON delivery_partner_locations(partner_id, recorded_at DESC);
CREATE INDEX idx_location_spatial ON delivery_partner_locations(latitude, longitude);
CREATE INDEX idx_recorded_at ON delivery_partner_locations(recorded_at);

-- Function to get latest location for a partner
CREATE OR REPLACE FUNCTION get_latest_partner_location(p_partner_id BIGINT)
RETURNS TABLE(
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    recorded_at TIMESTAMP,
    is_moving BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT dpl.latitude, dpl.longitude, dpl.recorded_at, dpl.is_moving
    FROM delivery_partner_locations dpl
    WHERE dpl.partner_id = p_partner_id
    ORDER BY dpl.recorded_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate distance between two points (Haversine formula)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL(10, 8), lon1 DECIMAL(11, 8),
    lat2 DECIMAL(10, 8), lon2 DECIMAL(11, 8)
) RETURNS DECIMAL(10, 2) AS $$
DECLARE
    R CONSTANT DECIMAL := 6371; -- Earth radius in km
    dLat DECIMAL;
    dLon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dLat := RADIANS(lat2 - lat1);
    dLon := RADIANS(lon2 - lon1);

    a := SIN(dLat/2) * SIN(dLat/2) +
         COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
         SIN(dLon/2) * SIN(dLon/2);

    c := 2 * ATAN2(SQRT(a), SQRT(1-a));

    RETURN R * c; -- Distance in km
END;
$$ LANGUAGE plpgsql;

-- View for partners with their latest location and distance from a point
CREATE OR REPLACE VIEW partner_locations_latest AS
SELECT
    u.id as partner_id,
    u.first_name || ' ' || u.last_name as partner_name,
    u.is_online,
    u.is_available,
    u.ride_status,
    loc.latitude,
    loc.longitude,
    loc.recorded_at,
    loc.is_moving,
    loc.speed,
    EXTRACT(EPOCH FROM (NOW() - loc.recorded_at))/60 as minutes_since_update
FROM users u
LEFT JOIN LATERAL (
    SELECT * FROM delivery_partner_locations dpl
    WHERE dpl.partner_id = u.id
    ORDER BY dpl.recorded_at DESC
    LIMIT 1
) loc ON true
WHERE u.role = 'DELIVERY_PARTNER';