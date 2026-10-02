-- Transport / fleet tracking: transporters (fleet owners), vehicles of any
-- type, routes with stops, drivers, trips, and live GPS positions.

CREATE TABLE IF NOT EXISTS transporters (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id),
    company_name VARCHAR(200) NOT NULL,
    owner_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transport_routes (
    id BIGSERIAL PRIMARY KEY,
    transporter_id BIGINT NOT NULL REFERENCES transporters(id),
    name VARCHAR(200) NOT NULL,
    source VARCHAR(200) NOT NULL,
    destination VARCHAR(200) NOT NULL,
    stops_json TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_transport_routes_transporter ON transport_routes(transporter_id);

CREATE TABLE IF NOT EXISTS transport_drivers (
    id BIGSERIAL PRIMARY KEY,
    transporter_id BIGINT NOT NULL REFERENCES transporters(id),
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_transport_drivers_transporter ON transport_drivers(transporter_id);
CREATE INDEX IF NOT EXISTS idx_transport_drivers_phone ON transport_drivers(phone);

CREATE TABLE IF NOT EXISTS transport_vehicles (
    id BIGSERIAL PRIMARY KEY,
    transporter_id BIGINT NOT NULL REFERENCES transporters(id),
    vehicle_type VARCHAR(20) NOT NULL DEFAULT 'BUS',
    reg_no VARCHAR(30) NOT NULL,
    name VARCHAR(200) NOT NULL,
    route_id BIGINT REFERENCES transport_routes(id),
    driver_id BIGINT REFERENCES transport_drivers(id),
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_transport_vehicles_transporter ON transport_vehicles(transporter_id);
CREATE INDEX IF NOT EXISTS idx_transport_vehicles_driver ON transport_vehicles(driver_id);
CREATE INDEX IF NOT EXISTS idx_transport_vehicles_public ON transport_vehicles(is_public, status);

CREATE TABLE IF NOT EXISTS transport_trips (
    id BIGSERIAL PRIMARY KEY,
    transporter_id BIGINT NOT NULL REFERENCES transporters(id),
    vehicle_id BIGINT NOT NULL REFERENCES transport_vehicles(id),
    driver_id BIGINT NOT NULL REFERENCES transport_drivers(id),
    route_id BIGINT REFERENCES transport_routes(id),
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    distance_km NUMERIC(10,2),
    status VARCHAR(20) NOT NULL DEFAULT 'RUNNING'
);
CREATE INDEX IF NOT EXISTS idx_transport_trips_vehicle ON transport_trips(vehicle_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_transport_trips_driver_status ON transport_trips(driver_id, status);

-- One live row per vehicle, upserted on every GPS send.
CREATE TABLE IF NOT EXISTS transport_vehicle_positions (
    vehicle_id BIGINT PRIMARY KEY REFERENCES transport_vehicles(id),
    trip_id BIGINT,
    driver_id BIGINT,
    latitude NUMERIC(10,7) NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    speed_kmh NUMERIC(6,1),
    heading NUMERIC(5,1),
    accuracy_m NUMERIC(7,1),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Trail points for trip history.
CREATE TABLE IF NOT EXISTS transport_position_history (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    trip_id BIGINT NOT NULL,
    latitude NUMERIC(10,7) NOT NULL,
    longitude NUMERIC(10,7) NOT NULL,
    speed_kmh NUMERIC(6,1),
    recorded_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_transport_position_history_trip ON transport_position_history(trip_id, recorded_at);

-- Customer app tile (admin can hide/show it in App Visibility Control)
INSERT INTO feature_configs (feature_name, display_name, display_name_tamil, icon, color, route, latitude, longitude, radius_km, is_active, display_order, max_posts_per_user)
VALUES ('TRANSPORT', 'Where is Bus', 'பஸ் எங்கே', 'directions_bus_rounded', '#1565C0', '/customer/transport', 12.4966000, 78.5729000, 50, true, 16, 0)
ON CONFLICT (feature_name) DO NOTHING;
