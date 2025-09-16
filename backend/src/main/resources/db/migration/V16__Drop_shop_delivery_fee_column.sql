-- Drop delivery_fee column from shops table as we now use distance-based delivery fee ranges
ALTER TABLE shops DROP COLUMN IF EXISTS delivery_fee;