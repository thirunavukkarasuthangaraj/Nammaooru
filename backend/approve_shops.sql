-- Update all grocery shops to be approved and active
UPDATE shops 
SET 
    status = 'APPROVED',
    is_active = true,
    is_verified = true,
    updated_at = NOW()
WHERE business_type = 'GROCERY' AND status = 'PENDING';

-- Verify the update
SELECT id, name, business_type, status, is_active, is_verified 
FROM shops 
WHERE business_type = 'GROCERY';