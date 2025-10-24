-- Set PostgreSQL database timezone to Indian Standard Time
-- This ensures all timestamp operations use IST by default

ALTER DATABASE shop_management_db SET timezone TO 'Asia/Kolkata';

-- Verify the timezone setting
SELECT current_setting('TIMEZONE') as current_timezone;
