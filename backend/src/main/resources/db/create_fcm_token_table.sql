-- Create FCM Token table for PostgreSQL
CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    fcm_token VARCHAR(500) NOT NULL,
    device_type VARCHAR(20),
    device_id VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_fcm_user_id ON user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_token ON user_fcm_tokens(fcm_token);
CREATE INDEX IF NOT EXISTS idx_user_fcm_active ON user_fcm_tokens(user_id, is_active);

-- Create or replace function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update the updated_at column
DROP TRIGGER IF EXISTS update_user_fcm_tokens_updated_at ON user_fcm_tokens;
CREATE TRIGGER update_user_fcm_tokens_updated_at
    BEFORE UPDATE ON user_fcm_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();