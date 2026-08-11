ALTER TABLE shops
    ADD COLUMN IF NOT EXISTS bill_settings_json TEXT;
