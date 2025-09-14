-- Fix order_assignments table structure
-- The error suggests there's a partner_id column that should be populated

-- Check if partner_id column exists and add constraint
ALTER TABLE order_assignments
DROP CONSTRAINT IF EXISTS order_assignments_partner_id_fkey;

-- Add partner_id as an alias/trigger to populate from delivery_partner_id
UPDATE order_assignments
SET partner_id = delivery_partner_id
WHERE partner_id IS NULL AND delivery_partner_id IS NOT NULL;

-- For future inserts, create a trigger to auto-populate partner_id from delivery_partner_id
CREATE OR REPLACE FUNCTION sync_partner_id()
RETURNS TRIGGER AS $$
BEGIN
    NEW.partner_id := NEW.delivery_partner_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_partner_id_trigger ON order_assignments;
CREATE TRIGGER sync_partner_id_trigger
    BEFORE INSERT OR UPDATE ON order_assignments
    FOR EACH ROW
    EXECUTE FUNCTION sync_partner_id();