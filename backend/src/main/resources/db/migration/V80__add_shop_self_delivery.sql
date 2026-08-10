-- Shop owners can deliver orders themselves without a delivery partner
ALTER TABLE shops ADD COLUMN IF NOT EXISTS self_delivery_enabled BOOLEAN NOT NULL DEFAULT FALSE;
