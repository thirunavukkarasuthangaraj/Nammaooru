-- Add trigger to maintain only last 5 location updates per partner
CREATE OR REPLACE FUNCTION maintain_last_five_locations()
RETURNS TRIGGER AS $$
DECLARE
    location_count INTEGER;
BEGIN
    -- Count existing locations for this partner
    SELECT COUNT(*) INTO location_count
    FROM delivery_partner_locations
    WHERE partner_id = NEW.partner_id;

    -- If we have 5 or more locations, delete the oldest ones
    IF location_count >= 5 THEN
        DELETE FROM delivery_partner_locations
        WHERE id IN (
            SELECT id FROM delivery_partner_locations
            WHERE partner_id = NEW.partner_id
            ORDER BY recorded_at ASC
            LIMIT (location_count - 4)
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run after each insert
DROP TRIGGER IF EXISTS maintain_location_history ON delivery_partner_locations;
CREATE TRIGGER maintain_location_history
AFTER INSERT ON delivery_partner_locations
FOR EACH ROW
EXECUTE FUNCTION maintain_last_five_locations();

-- Function to get last 5 locations for a partner (for map display)
CREATE OR REPLACE FUNCTION get_partner_location_history(p_partner_id BIGINT)
RETURNS TABLE(
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    recorded_at TIMESTAMP,
    is_moving BOOLEAN,
    speed DECIMAL(5, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT dpl.latitude, dpl.longitude, dpl.recorded_at, dpl.is_moving, dpl.speed
    FROM delivery_partner_locations dpl
    WHERE dpl.partner_id = p_partner_id
    ORDER BY dpl.recorded_at DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Function to insert location and auto-cleanup old ones
CREATE OR REPLACE FUNCTION insert_partner_location(
    p_partner_id BIGINT,
    p_latitude DECIMAL(10, 8),
    p_longitude DECIMAL(11, 8),
    p_accuracy DECIMAL(5, 2) DEFAULT NULL,
    p_speed DECIMAL(5, 2) DEFAULT NULL,
    p_heading DECIMAL(5, 2) DEFAULT NULL,
    p_altitude DECIMAL(8, 2) DEFAULT NULL,
    p_is_moving BOOLEAN DEFAULT false,
    p_battery_level INTEGER DEFAULT NULL,
    p_network_type VARCHAR(20) DEFAULT NULL,
    p_assignment_id BIGINT DEFAULT NULL,
    p_order_status VARCHAR(50) DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Insert new location
    INSERT INTO delivery_partner_locations (
        partner_id, latitude, longitude, accuracy, speed, heading, altitude,
        is_moving, battery_level, network_type, assignment_id, order_status
    ) VALUES (
        p_partner_id, p_latitude, p_longitude, p_accuracy, p_speed, p_heading, p_altitude,
        p_is_moving, p_battery_level, p_network_type, p_assignment_id, p_order_status
    );
END;
$$ LANGUAGE plpgsql;

-- View to get partners with their location trail (last 5 points)
CREATE OR REPLACE VIEW partner_location_trails AS
WITH ranked_locations AS (
    SELECT
        partner_id,
        latitude,
        longitude,
        recorded_at,
        is_moving,
        speed,
        ROW_NUMBER() OVER (PARTITION BY partner_id ORDER BY recorded_at DESC) as rn
    FROM delivery_partner_locations
)
SELECT
    u.id as partner_id,
    u.first_name || ' ' || u.last_name as partner_name,
    u.is_online,
    u.is_available,
    u.ride_status,
    ARRAY_AGG(
        json_build_object(
            'lat', rl.latitude,
            'lng', rl.longitude,
            'time', rl.recorded_at,
            'speed', rl.speed
        ) ORDER BY rl.recorded_at DESC
    ) FILTER (WHERE rl.rn <= 5) as location_trail
FROM users u
LEFT JOIN ranked_locations rl ON rl.partner_id = u.id
WHERE u.role = 'DELIVERY_PARTNER'
GROUP BY u.id, u.first_name, u.last_name, u.is_online, u.is_available, u.ride_status;

-- Sample query to test location insertion
-- This will automatically maintain only 5 records per partner
/*
SELECT insert_partner_location(
    39, -- partner_id
    13.0900, -- latitude
    80.2750, -- longitude
    10.5, -- accuracy
    25.5, -- speed in km/h
    NULL, -- heading
    NULL, -- altitude
    true, -- is_moving
    85, -- battery_level
    '4G', -- network_type
    NULL, -- assignment_id
    NULL -- order_status
);
*/