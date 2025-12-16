-- Drop the old check constraint
ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_status_check;

-- Add the new check constraint with SELF_PICKUP_COLLECTED status
ALTER TABLE orders ADD CONSTRAINT orders_status_check
CHECK (status IN (
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'READY',
    'READY_FOR_PICKUP',
    'OUT_FOR_DELIVERY',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
    'REFUNDED',
    'SELF_PICKUP_COLLECTED'
));
