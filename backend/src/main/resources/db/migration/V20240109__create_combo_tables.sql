-- Create product_combos table
CREATE TABLE IF NOT EXISTS product_combos (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id),
    name VARCHAR(255) NOT NULL,
    name_tamil VARCHAR(255),
    description TEXT,
    description_tamil TEXT,
    banner_image_url VARCHAR(500),
    combo_price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NOT NULL,
    discount_percentage DECIMAL(5,2),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    max_quantity_per_order INTEGER DEFAULT 5,
    total_quantity_available INTEGER,
    total_sold INTEGER DEFAULT 0,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255),
    updated_by VARCHAR(255)
);

-- Create combo_items table
CREATE TABLE IF NOT EXISTS combo_items (
    id BIGSERIAL PRIMARY KEY,
    combo_id BIGINT NOT NULL REFERENCES product_combos(id) ON DELETE CASCADE,
    shop_product_id BIGINT NOT NULL REFERENCES shop_products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(combo_id, shop_product_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_product_combos_shop_id ON product_combos(shop_id);
CREATE INDEX IF NOT EXISTS idx_product_combos_active ON product_combos(is_active);
CREATE INDEX IF NOT EXISTS idx_product_combos_dates ON product_combos(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_combo_items_combo_id ON combo_items(combo_id);
CREATE INDEX IF NOT EXISTS idx_combo_items_shop_product_id ON combo_items(shop_product_id);
