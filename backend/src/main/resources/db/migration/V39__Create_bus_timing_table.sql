-- Create bus_timings table for bus schedule master data
CREATE TABLE bus_timings (
    id BIGSERIAL PRIMARY KEY,
    bus_number VARCHAR(50) NOT NULL,
    bus_name VARCHAR(255),
    route_from VARCHAR(255) NOT NULL,
    route_to VARCHAR(255) NOT NULL,
    via_stops TEXT,
    departure_time VARCHAR(20) NOT NULL,
    arrival_time VARCHAR(20),
    bus_type VARCHAR(20) NOT NULL DEFAULT 'GOVERNMENT',
    operating_days VARCHAR(50) NOT NULL DEFAULT 'DAILY',
    fare DECIMAL(10, 2),
    location_area VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX idx_bus_timings_location_area ON bus_timings(location_area);
CREATE INDEX idx_bus_timings_is_active ON bus_timings(is_active);
CREATE INDEX idx_bus_timings_departure_time ON bus_timings(departure_time);

-- Insert sample bus timings for Thirupattur area
INSERT INTO bus_timings (bus_number, bus_name, route_from, route_to, via_stops, departure_time, arrival_time, bus_type, operating_days, fare, location_area) VALUES
('TVR-001', 'Thirupattur - Vellore', 'Thirupattur', 'Vellore', 'Natrampalli, Vaniyambadi, Ambur', '06:00 AM', '08:30 AM', 'GOVERNMENT', 'DAILY', 45.00, 'Thirupattur'),
('TVR-002', 'Thirupattur - Chennai', 'Thirupattur', 'Chennai', 'Vellore, Ranipet, Kanchipuram', '07:00 AM', '12:00 PM', 'GOVERNMENT', 'DAILY', 180.00, 'Thirupattur'),
('TVR-003', 'Thirupattur - Bangalore', 'Thirupattur', 'Bangalore', 'Vaniyambadi, Ambur, Krishnagiri', '06:30 AM', '11:00 AM', 'PRIVATE', 'DAILY', 250.00, 'Thirupattur'),
('TVR-004', 'Thirupattur - Salem', 'Thirupattur', 'Salem', 'Harur, Dharmapuri', '08:00 AM', '11:30 AM', 'GOVERNMENT', 'DAILY', 120.00, 'Thirupattur'),
('TVR-005', 'Natrampalli - Vellore', 'Natrampalli', 'Vellore', 'Vaniyambadi, Ambur', '06:30 AM', '08:30 AM', 'GOVERNMENT', 'DAILY', 35.00, 'Natrampalli'),
('TVR-006', 'Vaniyambadi - Chennai', 'Vaniyambadi', 'Chennai', 'Ambur, Vellore, Ranipet', '05:30 AM', '10:30 AM', 'GOVERNMENT', 'DAILY', 160.00, 'Vaniyambadi'),
('TVR-007', 'Ambur - Vellore', 'Ambur', 'Vellore', 'Vaniyambadi', '07:00 AM', '08:30 AM', 'GOVERNMENT', 'DAILY', 30.00, 'Ambur'),
('TVR-008', 'Thirupattur - Tiruvannamalai', 'Thirupattur', 'Tiruvannamalai', 'Polur', '09:00 AM', '12:00 PM', 'GOVERNMENT', 'DAILY', 90.00, 'Thirupattur');
