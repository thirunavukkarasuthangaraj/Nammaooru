-- Add health_tip_notifications_enabled column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS health_tip_notifications_enabled BOOLEAN DEFAULT true;
