-- Add driver search tracking fields to orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_search_started_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_search_attempts INTEGER DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS driver_search_completed BOOLEAN DEFAULT FALSE;

-- Add index for scheduler query
CREATE INDEX IF NOT EXISTS idx_orders_driver_search ON orders(status, driver_search_started_at, driver_search_completed)
WHERE driver_search_started_at IS NOT NULL AND driver_search_completed = FALSE;
