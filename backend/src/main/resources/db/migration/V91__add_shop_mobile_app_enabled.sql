-- Per-shop "Mobile App" approval toggle controlled by super admin.
-- Default TRUE so existing live shops keep showing in the customer app after deploy.
ALTER TABLE shops ADD COLUMN IF NOT EXISTS mobile_app_enabled BOOLEAN NOT NULL DEFAULT TRUE;
