-- Create mobile_otps table for SMS OTP functionality
CREATE TABLE IF NOT EXISTS mobile_otps (
    id BIGSERIAL PRIMARY KEY,
    mobile_number VARCHAR(15) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    attempt_count INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    device_id VARCHAR(255),
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    ip_address VARCHAR(45),
    session_id VARCHAR(255),
    verified_at TIMESTAMP,
    verified_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_mobile_otps_mobile_number ON mobile_otps(mobile_number);
CREATE INDEX IF NOT EXISTS idx_mobile_otps_expires_at ON mobile_otps(expires_at);
CREATE INDEX IF NOT EXISTS idx_mobile_otps_created_at ON mobile_otps(created_at);
CREATE INDEX IF NOT EXISTS idx_mobile_otps_is_active ON mobile_otps(is_active);
CREATE INDEX IF NOT EXISTS idx_mobile_otps_mobile_purpose ON mobile_otps(mobile_number, purpose);
