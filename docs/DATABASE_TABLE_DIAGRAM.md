# Database Table Structure Diagram - Multi-Shop Pricing

## 📊 Complete Database Schema with Data Examples

### 🗄️ Table Structure and Relationships

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATABASE SCHEMA                             │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │ MASTER_PRODUCTS  │
                    ├──────────────────┤
                    │ 🔑 id (PK)       │
                    │ name             │
                    │ sku              │
                    │ barcode          │
                    │ brand            │
                    │ category_id (FK) │
                    │ description      │
                    │ created_at       │
                    │ updated_at       │
                    └────────┬─────────┘
                             │
                             │ 1
                             │
                             │ * (One-to-Many)
                             ▼
                    ┌──────────────────┐
                    │  SHOP_PRODUCTS   │
                    ├──────────────────┤
    ┌───────────────┤ 🔑 id (PK)       │
    │               │ 🔗 shop_id (FK)  │───────────┐
    │               │ 🔗 master_product│           │
    │               │    _id (FK)      │           │
    │               │ 💰 price         │           │
    │               │ 💰 original_price│           │
    │               │ 💰 cost_price    │           │
    │               │ stock_quantity   │           │
    │               │ custom_name      │           │
    │               │ is_available     │           │
    │               │ created_at       │           │
    │               │ updated_at       │           │
    │               └──────────────────┘           │
    │                        │                      │
    │ Many                   │ 1                   │ Many
    │                        │                      │
    │                        │ * (One-to-Many)     │
    ▼                        ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│      SHOPS       │  │ PRICE_VARIATIONS │  │  PRODUCT_IMAGES  │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ 🔑 id (PK)       │  │ 🔑 id (PK)       │  │ 🔑 id (PK)       │
│ name             │  │ 🔗 shop_product  │  │ 🔗 shop_product  │
│ shop_id (unique) │  │    _id (FK)      │  │    _id (FK)      │
│ owner_name       │  │ special_price    │  │ image_url        │
│ owner_email      │  │ start_date       │  │ is_primary       │
│ owner_phone      │  │ end_date         │  │ sort_order       │
│ address          │  │ type             │  └──────────────────┘
│ city             │  └──────────────────┘
│ status           │
└──────────────────┘
```

## 🗂️ Actual Table Data Storage

### 1️⃣ **MASTER_PRODUCTS Table** (Shared Product Catalog)
```
┌──────────────────────────────────────────────────────────────────────┐
│                          MASTER_PRODUCTS                             │
├────┬──────────────────────┬──────────────┬─────────────┬────────────┤
│ id │ name                 │ sku          │ brand       │ category_id│
├────┼──────────────────────┼──────────────┼─────────────┼────────────┤
│101 │ Basmati Rice 5kg     │ RICE-BAS-5   │ India Gate  │     1      │
│102 │ Wheat Flour 10kg     │ FLOUR-WHT-10 │ Aashirvaad  │     1      │
│103 │ Sugar 1kg            │ SUGAR-WHT-1  │ Madhur      │     1      │
│104 │ Toor Dal 1kg         │ DAL-TOOR-1   │ Tata Sampann│     1      │
│105 │ Cooking Oil 1L       │ OIL-SUN-1    │ Fortune     │     2      │
└────┴──────────────────────┴──────────────┴─────────────┴────────────┘
                    ⚠️ NOTE: NO PRICE COLUMNS HERE!
```

### 2️⃣ **SHOPS Table** (Store Information)
```
┌────────────────────────────────────────────────────────────────────────┐
│                              SHOPS                                     │
├────┬─────────────────┬──────────┬──────────────┬──────────────────────┤
│ id │ name            │ shop_id  │ owner_name   │ city                 │
├────┼─────────────────┼──────────┼──────────────┼──────────────────────┤
│ 1  │ Super Mart      │ SM001    │ Raj Kumar    │ Mumbai               │
│ 2  │ Budget Bazaar   │ BB002    │ Priya Shah   │ Delhi                │
│ 3  │ Wholesale Hub   │ WH003    │ Ahmed Ali    │ Bangalore            │
└────┴─────────────────┴──────────┴──────────────┴──────────────────────┘
```

### 3️⃣ **SHOP_PRODUCTS Table** (WHERE PRICING HAPPENS!) 💰
```
┌───────────────────────────────────────────────────────────────────────────────┐
│                             SHOP_PRODUCTS                                     │
├────┬─────────┬────────────────┬────────┬──────────────┬───────────┬──────────┤
│ id │ shop_id │ master_product │ price  │ original_    │ cost_     │ stock_   │
│    │         │ _id            │        │ price        │ price     │ quantity │
├────┼─────────┼────────────────┼────────┼──────────────┼───────────┼──────────┤
│ 1  │    1    │      101       │ 320.00 │    350.00    │  240.00   │   100    │
│ 2  │    2    │      101       │ 280.00 │    350.00    │  240.00   │   150    │
│ 3  │    3    │      101       │ 260.00 │    350.00    │  240.00   │   500    │
│ 4  │    1    │      102       │ 450.00 │    500.00    │  380.00   │    50    │
│ 5  │    2    │      102       │ 420.00 │    500.00    │  380.00   │    80    │
│ 6  │    3    │      102       │ 400.00 │    500.00    │  380.00   │   300    │
│ 7  │    1    │      103       │  45.00 │     50.00    │   35.00   │   200    │
│ 8  │    2    │      103       │  42.00 │     50.00    │   35.00   │   250    │
│ 9  │    3    │      103       │  40.00 │     50.00    │   35.00   │  1000    │
└────┴─────────┴────────────────┴────────┴──────────────┴───────────┴──────────┘

UNIQUE CONSTRAINT: (shop_id, master_product_id) - Each shop can have each product only once
```

## 🔍 How Data is Linked - Visual Example

```
MASTER_PRODUCTS                         SHOP_PRODUCTS
┌─────────────┐                   ┌──────────────────────────┐
│ id: 101     │◄──────────────────│ master_product_id: 101  │
│ Rice 5kg    │                   │ shop_id: 1               │
└─────────────┘                   │ price: 320.00            │
       ▲                          └──────────────────────────┘
       │                          
       │                          ┌──────────────────────────┐
       │                          │ master_product_id: 101  │
       └──────────────────────────│ shop_id: 2               │
                                  │ price: 280.00            │
                                  └──────────────────────────┘
                                  
                                  ┌──────────────────────────┐
                                  │ master_product_id: 101  │
                                  │ shop_id: 3               │
                                  │ price: 260.00            │
                                  └──────────────────────────┘
```

## 📐 SQL Table Creation Scripts

### Create Master Products Table
```sql
CREATE TABLE master_products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    brand VARCHAR(100),
    category_id BIGINT,
    description TEXT,
    base_unit VARCHAR(50),
    specifications JSON,
    status ENUM('ACTIVE', 'INACTIVE', 'DISCONTINUED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_sku (sku),
    INDEX idx_category (category_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Create Shops Table
```sql
CREATE TABLE shops (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shop_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    owner_name VARCHAR(255) NOT NULL,
    owner_email VARCHAR(255) NOT NULL,
    owner_phone VARCHAR(20) NOT NULL,
    business_type ENUM('RETAIL', 'WHOLESALE', 'BOTH') DEFAULT 'RETAIL',
    address_line1 VARCHAR(500) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_shop_id (shop_id),
    INDEX idx_status (status),
    INDEX idx_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Create Shop Products Table (PRICING TABLE)
```sql
CREATE TABLE shop_products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    master_product_id BIGINT NOT NULL,
    
    -- PRICING COLUMNS
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    cost_price DECIMAL(10,2),
    
    -- INVENTORY COLUMNS
    stock_quantity INT DEFAULT 0,
    min_stock_level INT DEFAULT 10,
    track_inventory BOOLEAN DEFAULT TRUE,
    
    -- CUSTOMIZATION COLUMNS
    custom_name VARCHAR(255),
    custom_description TEXT,
    
    -- STATUS COLUMNS
    status ENUM('ACTIVE', 'INACTIVE', 'OUT_OF_STOCK') DEFAULT 'ACTIVE',
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- TIMESTAMPS
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- CONSTRAINTS
    FOREIGN KEY (shop_id) REFERENCES shops(id) ON DELETE CASCADE,
    FOREIGN KEY (master_product_id) REFERENCES master_products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_shop_product (shop_id, master_product_id),
    
    -- INDEXES FOR PERFORMANCE
    INDEX idx_shop (shop_id),
    INDEX idx_product (master_product_id),
    INDEX idx_price (price),
    INDEX idx_status (status),
    INDEX idx_availability (is_available, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 🔄 Data Flow Example - Adding a New Product to Multiple Shops

```sql
-- Step 1: Add product to master catalog
INSERT INTO master_products (name, sku, brand, category_id)
VALUES ('Masoor Dal 1kg', 'DAL-MASOOR-1', 'Tata Sampann', 1);
-- Returns: id = 106

-- Step 2: Each shop adds the product with their own price
-- Shop 1 (Premium pricing)
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price, stock_quantity)
VALUES (1, 106, 120.00, 130.00, 85.00, 50);

-- Shop 2 (Competitive pricing)
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price, stock_quantity)
VALUES (2, 106, 110.00, 130.00, 85.00, 75);

-- Shop 3 (Wholesale pricing)
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price, stock_quantity)
VALUES (3, 106, 105.00, 130.00, 85.00, 200);
```

## 🔍 Query Examples

### Get all prices for a product across shops
```sql
SELECT 
    s.name AS shop_name,
    mp.name AS product_name,
    sp.price,
    sp.original_price,
    sp.stock_quantity,
    (sp.original_price - sp.price) AS discount,
    ROUND(((sp.original_price - sp.price) / sp.original_price * 100), 2) AS discount_percent
FROM shop_products sp
JOIN shops s ON s.id = sp.shop_id
JOIN master_products mp ON mp.id = sp.master_product_id
WHERE mp.id = 101
ORDER BY sp.price ASC;
```

Result:
```
┌─────────────────┬──────────────────┬────────┬───────────────┬────────────────┬──────────┬─────────────────┐
│ shop_name       │ product_name     │ price  │ original_price│ stock_quantity │ discount │ discount_percent│
├─────────────────┼──────────────────┼────────┼───────────────┼────────────────┼──────────┼─────────────────┤
│ Wholesale Hub   │ Basmati Rice 5kg │ 260.00 │ 350.00        │ 500            │ 90.00    │ 25.71           │
│ Budget Bazaar   │ Basmati Rice 5kg │ 280.00 │ 350.00        │ 150            │ 70.00    │ 20.00           │
│ Super Mart      │ Basmati Rice 5kg │ 320.00 │ 350.00        │ 100            │ 30.00    │ 8.57            │
└─────────────────┴──────────────────┴────────┴───────────────┴────────────────┴──────────┴─────────────────┘
```

## 📊 Index Strategy for Performance

```sql
-- Critical indexes for fast queries
ALTER TABLE shop_products
ADD INDEX idx_shop_product_price (shop_id, master_product_id, price),
ADD INDEX idx_available_products (is_available, status, shop_id),
ADD INDEX idx_featured (is_featured, shop_id),
ADD INDEX idx_stock (stock_quantity, shop_id);
```

## 🎯 Key Points

1. **Master Products**: Product catalog WITHOUT prices
2. **Shop Products**: Each shop's pricing for master products
3. **One Product → Many Shops → Different Prices**
4. **Unique Constraint**: Prevents duplicate products in same shop
5. **Foreign Keys**: Maintain data integrity
6. **Indexes**: Optimize query performance

This structure allows complete pricing independence for each shop while maintaining a centralized product catalog!