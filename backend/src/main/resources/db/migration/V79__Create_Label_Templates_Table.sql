-- Barcode label template designs (size + JSON field layout) for the Print Label feature
CREATE TABLE IF NOT EXISTS label_templates (
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    shop_id         BIGINT,
    label_width_mm  DOUBLE PRECISION NOT NULL DEFAULT 50,
    label_height_mm DOUBLE PRECISION NOT NULL DEFAULT 20,
    is_default      BOOLEAN NOT NULL DEFAULT TRUE,
    design          TEXT,
    created_by      VARCHAR(255),
    updated_by      VARCHAR(255),
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_label_templates_is_default ON label_templates (is_default);
CREATE INDEX IF NOT EXISTS idx_label_templates_shop_id ON label_templates (shop_id);
