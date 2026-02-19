-- Add FSSAI certificate number and grocery license number to shops table
ALTER TABLE shops ADD COLUMN IF NOT EXISTS fssai_certificate_number VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS grocery_license_number VARCHAR(30);
