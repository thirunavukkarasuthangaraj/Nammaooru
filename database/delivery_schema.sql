-- =============================================
-- DELIVERY PARTNER & TRACKING SYSTEM SCHEMA
-- =============================================

-- Delivery Partners Table
CREATE TABLE delivery_partners (
    id BIGSERIAL PRIMARY KEY,
    partner_id VARCHAR(20) UNIQUE NOT NULL, -- Format: DP + 8 characters
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    
    -- Personal Information
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    alternate_phone VARCHAR(15),
    email VARCHAR(255) UNIQUE NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    
    -- Address Information
    address_line1 VARCHAR(500) NOT NULL,
    address_line2 VARCHAR(500),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    
    -- Vehicle Information
    vehicle_type VARCHAR(20) CHECK (vehicle_type IN ('BIKE', 'SCOOTER', 'BICYCLE', 'CAR', 'AUTO')) NOT NULL,
    vehicle_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_model VARCHAR(100),
    vehicle_color VARCHAR(50),
    license_number VARCHAR(30) UNIQUE NOT NULL,
    license_expiry_date DATE NOT NULL,
    
    -- Bank Information
    bank_account_number VARCHAR(20),
    bank_ifsc_code VARCHAR(11),
    bank_name VARCHAR(100),
    account_holder_name VARCHAR(255),
    
    -- Service Areas (JSON array of postal codes/areas they can serve)
    service_areas JSONB,
    max_delivery_radius DECIMAL(8, 2) DEFAULT 10, -- in kilometers
    
    -- Status and Verification
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'SUSPENDED', 'BLOCKED', 'ACTIVE')),
    verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    is_online BOOLEAN DEFAULT FALSE,
    is_available BOOLEAN DEFAULT FALSE,
    
    -- Performance Metrics
    rating DECIMAL(3, 2) DEFAULT 5.00,
    total_deliveries INTEGER DEFAULT 0,
    successful_deliveries INTEGER DEFAULT 0,
    total_earnings DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Current Location (for tracking)
    current_latitude DECIMAL(10, 6),
    current_longitude DECIMAL(10, 6),
    last_location_update TIMESTAMP,
    
    -- Audit Fields
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'system',
    updated_by VARCHAR(100) DEFAULT 'system',
    
    -- Additional fields
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(15),
    profile_image_url VARCHAR(500),
    
    CONSTRAINT unique_partner_user UNIQUE(user_id)
);

-- Delivery Partner Documents Table
CREATE TABLE delivery_partner_documents (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN (
        'DRIVING_LICENSE', 'AADHAR_CARD', 'PAN_CARD', 'VEHICLE_RC', 
        'INSURANCE_CERTIFICATE', 'POLICE_VERIFICATION', 'PROFILE_PHOTO',
        'BANK_PASSBOOK', 'VEHICLE_PHOTO'
    )),
    document_url VARCHAR(500) NOT NULL,
    document_number VARCHAR(100),
    verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    verified_by BIGINT REFERENCES users(id),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Assignments Table
CREATE TABLE order_assignments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT REFERENCES orders(id) ON DELETE CASCADE,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    
    -- Assignment Details
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by BIGINT REFERENCES users(id),
    assignment_type VARCHAR(20) DEFAULT 'AUTO' CHECK (assignment_type IN ('AUTO', 'MANUAL')),
    
    -- Status Tracking
    status VARCHAR(30) DEFAULT 'ASSIGNED' CHECK (status IN (
        'ASSIGNED', 'ACCEPTED', 'REJECTED', 'PICKED_UP', 'IN_TRANSIT', 
        'DELIVERED', 'FAILED', 'CANCELLED', 'RETURNED'
    )),
    
    -- Time Tracking
    accepted_at TIMESTAMP,
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    
    -- Delivery Details
    pickup_latitude DECIMAL(10, 6),
    pickup_longitude DECIMAL(10, 6),
    delivery_latitude DECIMAL(10, 6),
    delivery_longitude DECIMAL(10, 6),
    
    -- Financial
    delivery_fee DECIMAL(10, 2) NOT NULL,
    partner_commission DECIMAL(10, 2),
    
    -- Additional Info
    rejection_reason TEXT,
    delivery_notes TEXT,
    customer_rating INTEGER CHECK (customer_rating BETWEEN 1 AND 5),
    customer_feedback TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time Tracking Table
CREATE TABLE delivery_tracking (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT REFERENCES order_assignments(id) ON DELETE CASCADE,
    
    -- Location Data
    latitude DECIMAL(10, 6) NOT NULL,
    longitude DECIMAL(10, 6) NOT NULL,
    accuracy DECIMAL(8, 2), -- GPS accuracy in meters
    altitude DECIMAL(8, 2),
    speed DECIMAL(8, 2), -- in km/h
    heading DECIMAL(5, 2), -- compass direction in degrees
    
    -- Tracking Details
    tracked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    battery_level INTEGER, -- 0-100%
    is_moving BOOLEAN DEFAULT FALSE,
    
    -- Estimated Times
    estimated_arrival_time TIMESTAMP,
    distance_to_destination DECIMAL(8, 2), -- in kilometers
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Partner Earnings Table
CREATE TABLE partner_earnings (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    assignment_id BIGINT REFERENCES order_assignments(id) ON DELETE CASCADE,
    
    -- Earning Details
    base_amount DECIMAL(10, 2) NOT NULL,
    incentive_amount DECIMAL(10, 2) DEFAULT 0.00,
    bonus_amount DECIMAL(10, 2) DEFAULT 0.00,
    penalty_amount DECIMAL(10, 2) DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    
    -- Payment Status
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN (
        'PENDING', 'PROCESSED', 'PAID', 'FAILED', 'HOLD'
    )),
    payment_date TIMESTAMP,
    payment_reference VARCHAR(100),
    payment_method VARCHAR(20) CHECK (payment_method IN ('BANK_TRANSFER', 'UPI', 'CASH', 'WALLET')),
    
    -- Calculation Details
    distance_covered DECIMAL(8, 2),
    time_taken INTEGER, -- in minutes
    surge_multiplier DECIMAL(3, 2) DEFAULT 1.00,
    
    earning_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Partner Availability Table
CREATE TABLE partner_availability (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    
    -- Availability Schedule
    day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    
    -- Special availability (overrides weekly schedule)
    specific_date DATE,
    is_special_schedule BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(partner_id, day_of_week, start_time) DEFERRABLE INITIALLY DEFERRED
);

-- Delivery Zones Table
CREATE TABLE delivery_zones (
    id BIGSERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    zone_code VARCHAR(20) UNIQUE NOT NULL,
    
    -- Geographic Boundaries (Polygon as JSON)
    boundaries JSONB NOT NULL, -- Array of lat/lng coordinates defining the zone
    
    -- Zone Properties
    delivery_fee DECIMAL(10, 2) DEFAULT 0.00,
    min_order_amount DECIMAL(10, 2) DEFAULT 0.00,
    max_delivery_time INTEGER DEFAULT 60, -- in minutes
    
    -- Service Status
    is_active BOOLEAN DEFAULT TRUE,
    service_start_time TIME DEFAULT '06:00:00',
    service_end_time TIME DEFAULT '23:00:00',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Partner Zone Assignments
CREATE TABLE partner_zone_assignments (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    zone_id BIGINT REFERENCES delivery_zones(id) ON DELETE CASCADE,
    priority INTEGER DEFAULT 1, -- 1=highest priority for this zone
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(partner_id, zone_id)
);

-- Delivery Notifications Table
CREATE TABLE delivery_notifications (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT REFERENCES order_assignments(id) ON DELETE CASCADE,
    partner_id BIGINT REFERENCES delivery_partners(id) ON DELETE CASCADE,
    customer_id BIGINT REFERENCES customers(id) ON DELETE CASCADE,
    
    -- Notification Details
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN (
        'ORDER_ASSIGNED', 'ORDER_ACCEPTED', 'ORDER_PICKED_UP', 'OUT_FOR_DELIVERY',
        'DELIVERED', 'DELAYED', 'CANCELLED', 'LOCATION_UPDATE'
    )),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Delivery Channels
    send_push BOOLEAN DEFAULT TRUE,
    send_sms BOOLEAN DEFAULT FALSE,
    send_email BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_sent BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP,
    delivery_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Additional Data
    metadata JSONB, -- Store additional context data
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Delivery Partners Indexes
CREATE INDEX idx_delivery_partners_status ON delivery_partners(status);
CREATE INDEX idx_delivery_partners_is_online ON delivery_partners(is_online);
CREATE INDEX idx_delivery_partners_is_available ON delivery_partners(is_available);
CREATE INDEX idx_delivery_partners_location ON delivery_partners(current_latitude, current_longitude);
CREATE INDEX idx_delivery_partners_partner_id ON delivery_partners(partner_id);

-- Order Assignments Indexes
CREATE INDEX idx_order_assignments_order_id ON order_assignments(order_id);
CREATE INDEX idx_order_assignments_partner_id ON order_assignments(partner_id);
CREATE INDEX idx_order_assignments_status ON order_assignments(status);
CREATE INDEX idx_order_assignments_assigned_at ON order_assignments(assigned_at);

-- Delivery Tracking Indexes
CREATE INDEX idx_delivery_tracking_assignment_id ON delivery_tracking(assignment_id);
CREATE INDEX idx_delivery_tracking_tracked_at ON delivery_tracking(tracked_at);
CREATE INDEX idx_delivery_tracking_location ON delivery_tracking(latitude, longitude);

-- Partner Earnings Indexes
CREATE INDEX idx_partner_earnings_partner_id ON partner_earnings(partner_id);
CREATE INDEX idx_partner_earnings_earning_date ON partner_earnings(earning_date);
CREATE INDEX idx_partner_earnings_payment_status ON partner_earnings(payment_status);

-- Partner Availability Indexes
CREATE INDEX idx_partner_availability_partner_id ON partner_availability(partner_id);
CREATE INDEX idx_partner_availability_day_of_week ON partner_availability(day_of_week);

-- Delivery Notifications Indexes
CREATE INDEX idx_delivery_notifications_assignment_id ON delivery_notifications(assignment_id);
CREATE INDEX idx_delivery_notifications_partner_id ON delivery_notifications(partner_id);
CREATE INDEX idx_delivery_notifications_customer_id ON delivery_notifications(customer_id);
CREATE INDEX idx_delivery_notifications_type ON delivery_notifications(notification_type);

-- =============================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- =============================================

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_delivery_partners_updated_at BEFORE UPDATE ON delivery_partners FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_delivery_partner_documents_updated_at BEFORE UPDATE ON delivery_partner_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_order_assignments_updated_at BEFORE UPDATE ON order_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_partner_earnings_updated_at BEFORE UPDATE ON partner_earnings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_partner_availability_updated_at BEFORE UPDATE ON partner_availability FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_delivery_zones_updated_at BEFORE UPDATE ON delivery_zones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SAMPLE DATA INSERTION
-- =============================================

-- Insert default delivery zones
INSERT INTO delivery_zones (zone_name, zone_code, boundaries, delivery_fee, min_order_amount) VALUES
('Central Zone', 'CZ001', '{"coordinates": [[12.9716, 77.5946], [12.9816, 77.6046], [12.9616, 77.6146], [12.9516, 77.5846]]}', 25.00, 100.00),
('North Zone', 'NZ001', '{"coordinates": [[12.9916, 77.5946], [13.0016, 77.6046], [12.9816, 77.6146], [12.9716, 77.5846]]}', 30.00, 150.00),
('South Zone', 'SZ001', '{"coordinates": [[12.9516, 77.5946], [12.9616, 77.6046], [12.9416, 77.6146], [12.9316, 77.5846]]}', 35.00, 200.00);

-- Update existing orders table to support delivery assignments (if needed)
-- This adds a foreign key reference to order_assignments
-- ALTER TABLE orders ADD COLUMN current_assignment_id BIGINT REFERENCES order_assignments(id);