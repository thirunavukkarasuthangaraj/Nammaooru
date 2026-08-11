-- Keep the database constraint aligned with Shop.BusinessType and the shop
-- create/update validation used by the role-specific POS experience.
ALTER TABLE shops
    DROP CONSTRAINT IF EXISTS shops_business_type_check;

ALTER TABLE shops
    ADD CONSTRAINT shops_business_type_check
    CHECK (business_type IN ('GROCERY', 'FASHION', 'PHARMACY', 'RESTAURANT', 'GENERAL'));
