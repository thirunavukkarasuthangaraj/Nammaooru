-- Update existing order statuses to match new enum values
-- Run this script to migrate existing data

UPDATE orders 
SET status = 'READY' 
WHERE status = 'READY_FOR_PICKUP';

UPDATE orders 
SET status = 'COMPLETED' 
WHERE status = 'DELIVERED';

UPDATE orders 
SET status = 'COMPLETED' 
WHERE status = 'OUT_FOR_DELIVERY';

-- Add constraint to ensure only valid statuses
ALTER TABLE orders 
DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE orders 
ADD CONSTRAINT orders_status_check 
CHECK (status IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED', 'REFUNDED'));

-- Update any remaining invalid statuses to PENDING
UPDATE orders 
SET status = 'PENDING' 
WHERE status NOT IN ('PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED', 'REFUNDED');