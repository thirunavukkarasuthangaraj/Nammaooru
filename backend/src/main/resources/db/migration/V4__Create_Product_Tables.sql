-- Product Categories Table
CREATE TABLE product_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    slug VARCHAR(100) UNIQUE,
    parent_id BIGINT REFERENCES product_categories(id),
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER,
    icon_url VARCHAR(255),
    created_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Master Products Table
CREATE TABLE master_products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(100) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    category_id BIGINT NOT NULL REFERENCES product_categories(id),
    brand VARCHAR(100),
    base_unit VARCHAR(50),
    base_weight DECIMAL(10,3),
    specifications TEXT, -- JSON string
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'DISCONTINUED')),
    is_featured BOOLEAN DEFAULT FALSE,
    is_global BOOLEAN DEFAULT TRUE,
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Master Product Images Table
CREATE TABLE master_product_images (
    id BIGSERIAL PRIMARY KEY,
    master_product_id BIGINT NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Shop Products Table
CREATE TABLE shop_products (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    master_product_id BIGINT NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
    
    -- Pricing
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    
    -- Inventory
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER,
    max_stock_level INTEGER,
    track_inventory BOOLEAN DEFAULT TRUE,
    
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'OUT_OF_STOCK', 'DISCONTINUED')),
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Customizations
    custom_name VARCHAR(255),
    custom_description TEXT,
    custom_attributes TEXT, -- JSON string
    
    -- Display
    display_order INTEGER,
    tags VARCHAR(1000),
    
    created_by VARCHAR(255),
    updated_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(shop_id, master_product_id)
);

-- Shop Product Images Table
CREATE TABLE shop_product_images (
    id BIGSERIAL PRIMARY KEY,
    shop_product_id BIGINT NOT NULL REFERENCES shop_products(id) ON DELETE CASCADE,
    image_url VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255),
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_by VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_master_products_category ON master_products(category_id);
CREATE INDEX idx_master_products_sku ON master_products(sku);
CREATE INDEX idx_master_products_status ON master_products(status);
CREATE INDEX idx_master_products_brand ON master_products(brand);

CREATE INDEX idx_shop_products_shop ON shop_products(shop_id);
CREATE INDEX idx_shop_products_master ON shop_products(master_product_id);
CREATE INDEX idx_shop_products_status ON shop_products(status);
CREATE INDEX idx_shop_products_available ON shop_products(is_available);

CREATE INDEX idx_product_categories_parent ON product_categories(parent_id);
CREATE INDEX idx_product_categories_active ON product_categories(is_active);

-- Ensure only one primary image per product
CREATE UNIQUE INDEX idx_master_product_primary_image 
ON master_product_images(master_product_id) 
WHERE is_primary = TRUE;

CREATE UNIQUE INDEX idx_shop_product_primary_image 
ON shop_product_images(shop_product_id) 
WHERE is_primary = TRUE;