# 🏗️ NammaOoru Thiru Software System - Technical Architecture

## 📋 Document Overview

**Purpose**: Comprehensive technical architecture documentation with detailed system diagrams and database schema  
**Audience**: Developers, System Architects, DevOps Engineers, Technical Stakeholders  
**Last Updated**: January 2025  

---

## 🌐 System Architecture Diagram

### High-Level System Overview
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           NammaOoru Thiru Software System                          │
│                                 Multi-Platform Architecture                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Mobile App     │    │  Web Frontend   │    │  Admin Panel    │    │  Partner App    │
│  (Flutter)      │    │  (Angular 15+)  │    │  (Angular)      │    │  (Mobile)       │
│                 │    │                 │    │                 │    │                 │
│ - Customer App  │    │ - Customer UI   │    │ - Admin Portal  │    │ - Partner UI    │
│ - Shop Owner    │    │ - Shop Owner    │    │ - Analytics     │    │ - Delivery      │
│ - Auth & OTP    │    │ - Auth & OTP    │    │ - Management    │    │ - Tracking      │
│ Port: Mobile    │    │ Port: 4200      │    │ Port: 4200      │    │ Port: Mobile    │
└─────┬───────────┘    └─────┬───────────┘    └─────┬───────────┘    └─────┬───────────┘
      │                      │                      │                      │
      │                      │                      │                      │
      └──────────────────────┼──────────────────────┼──────────────────────┘
                             │                      │
                    ┌────────▼──────────────────────▼────────┐
                    │        API Gateway / Load Balancer     │
                    │              (nginx)                   │
                    │                                        │
                    │ - SSL Termination (Let's Encrypt)     │
                    │ - Request Routing                      │
                    │ - Rate Limiting                        │
                    │ - CORS Handling                        │
                    │ Domain: api.nammaoorudelivary.in       │
                    └────────────────┬───────────────────────┘
                                     │
                          ┌──────────▼──────────┐
                          │   Backend Services   │
                          │   (Spring Boot)     │
                          │                     │
                          │ - REST API Server   │
                          │ - Business Logic    │
                          │ - Authentication    │
                          │ - File Management   │
                          │ Port: 8080/8081     │
                          └──────────┬──────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
┌─────────▼───────┐        ┌─────────▼─────────┐      ┌─────────▼─────────┐
│   PostgreSQL    │        │   External APIs   │      │   File Storage    │
│   Database      │        │                   │      │                   │
│                 │        │ - MSG91 (SMS/WA)  │      │ - Product Images  │
│ - User Data     │        │ - Firebase (Push) │      │ - Shop Documents  │
│ - Orders        │        │ - Google Maps     │      │ - User Avatars    │
│ - Products      │        │ - Email SMTP      │      │ - Invoice Files   │
│ - Delivery      │        │                   │      │                   │
│ Port: 5432      │        │                   │      │ Local/Cloud       │
└─────────────────┘        └───────────────────┘      └───────────────────┘
```

---

## 🔧 Microservice Architecture Breakdown

### Core Service Components
```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Backend Service Architecture                        │
│                            (Spring Boot Application)                       │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Auth Service   │    │  Order Service  │    │ Delivery Service│
│                 │    │                 │    │                 │
│ - JWT Tokens    │    │ - Order Mgmt    │    │ - Assignment    │
│ - OTP Auth      │    │ - Cart Mgmt     │    │ - Tracking      │
│ - User Mgmt     │    │ - Payment Flow  │    │ - Partner Mgmt  │
│ - Role Control  │    │ - Status Track  │    │ - Earnings      │
└─────┬───────────┘    └─────┬───────────┘    └─────┬───────────┘
      │                      │                      │
      └──────────┬───────────┼──────────────────────┘
                 │           │
┌─────────────────▼───────────▼─────────────────┐
│          Common Services Layer              │
│                                             │
│ - Email Service (SMTP)                     │
│ - SMS/WhatsApp Service (MSG91)             │
│ - Firebase Service (Push Notifications)    │
│ - File Upload Service                      │
│ - Validation Service                       │
│ - Audit Service                           │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼─────────────────┐
│         Data Access Layer         │
│                                   │
│ - JPA Repositories               │
│ - Database Connection Pool       │
│ - Transaction Management         │
│ - Query Optimization            │
└───────────────────────────────────┘
```

---

## 🗄️ Complete Database Schema

### Entity Relationship Diagram
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Database Schema (PostgreSQL)                          │
│                                shop_management_db                                   │
└─────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌─────────────────┐
                                    │      users      │
                                    │─────────────────│
                                    │ id (PK)         │
                                    │ email           │
                                    │ password        │
                                    │ mobile_number   │
                                    │ first_name      │
                                    │ last_name       │
                                    │ role            │
                                    │ is_active       │
                                    │ created_at      │
                                    │ updated_at      │
                                    └─────┬───────────┘
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │                     │                     │
          ┌─────────▼─────────┐    ┌──────▼──────┐    ┌─────────▼─────────┐
          │      shops        │    │  customers  │    │ delivery_partners │
          │───────────────────│    │─────────────│    │───────────────────│
          │ id (PK)           │    │ id (PK)     │    │ id (PK)           │
          │ owner_id (FK)     │    │ user_id(FK) │    │ user_id (FK)      │
          │ name              │    │ address     │    │ partner_id        │
          │ description       │    │ latitude    │    │ vehicle_type      │
          │ phone             │    │ longitude   │    │ license_number    │
          │ address           │    │ created_at  │    │ is_available      │
          │ latitude          │    │ updated_at  │    │ rating            │
          │ longitude         │    └─────────────┘    │ total_deliveries  │
          │ is_approved       │                       │ success_rate      │
          │ created_at        │                       │ created_at        │
          │ updated_at        │                       │ updated_at        │
          └─────┬─────────────┘                       └─────┬─────────────┘
                │                                           │
                │                                           │
          ┌─────▼─────────┐                           ┌─────▼─────────┐
          │   products    │                           │partner_earnings│
          │───────────────│                           │───────────────│
          │ id (PK)       │                           │ id (PK)       │
          │ shop_id (FK)  │                           │ partner_id(FK)│
          │ name          │                           │ assignment_id │
          │ description   │                           │ base_amount   │
          │ price         │                           │ bonus_amount  │
          │ category      │                           │ total_amount  │
          │ image_url     │                           │ payment_status│
          │ is_available  │                           │ paid_at       │
          │ stock_qty     │                           │ created_at    │
          │ created_at    │                           │ updated_at    │
          │ updated_at    │                           └───────────────┘
          └─────┬─────────┘
                │
                │
          ┌─────▼─────────┐
          │    orders     │
          │───────────────│
          │ id (PK)       │
          │ order_number  │
          │ customer_id(FK)│
          │ shop_id (FK)  │
          │ total_amount  │
          │ delivery_fee  │
          │ status        │
          │ delivery_addr │
          │ delivery_lat  │
          │ delivery_lng  │
          │ payment_method│
          │ payment_status│
          │ order_date    │
          │ delivery_time │
          │ created_at    │
          │ updated_at    │
          └─────┬─────────┘
                │
                │
    ┌───────────┼───────────┐
    │           │           │
┌───▼────┐ ┌────▼────┐ ┌────▼─────────────┐
│order_  │ │ order_  │ │ order_assignments│
│items   │ │payments │ │──────────────────│
│────────│ │─────────│ │ id (PK)          │
│id (PK) │ │id (PK)  │ │ order_id (FK)    │
│order_id│ │order_id │ │ partner_id (FK)  │
│prod_id │ │amount   │ │ assigned_at      │
│quantity│ │method   │ │ accepted_at      │
│price   │ │status   │ │ pickup_time      │
│subtotal│ │ref_id   │ │ delivery_time    │
└────────┘ │paid_at  │ │ status           │
           │created_ │ │ delivery_fee     │
           │at       │ │ commission       │
           └─────────┘ │ rating           │
                       │ feedback         │
                       │ created_at       │
                       │ updated_at       │
                       └──────────────────┘
```

### Detailed Table Schemas

#### 1. Core User Management Tables

**users** - Central user authentication table
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255),
    mobile_number VARCHAR(15) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
    is_active BOOLEAN DEFAULT TRUE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_mobile_verified BOOLEAN DEFAULT FALSE,
    profile_image_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_mobile ON users(mobile_number);
CREATE INDEX idx_users_role ON users(role);
```

**customers** - Customer-specific information
```sql
CREATE TABLE customers (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    default_address TEXT,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0.00,
    loyalty_points INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_location ON customers(latitude, longitude);
```

#### 2. Thiru Software Tables

**shops** - Shop information and management
```sql
CREATE TABLE shops (
    id BIGSERIAL PRIMARY KEY,
    shop_id VARCHAR(50) UNIQUE NOT NULL,
    owner_id BIGINT NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(255),
    address TEXT NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    category VARCHAR(100),
    image_url VARCHAR(500),
    is_approved BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    rating DECIMAL(2,1) DEFAULT 0.0,
    total_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(12,2) DEFAULT 0.00,
    commission_rate DECIMAL(3,2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shops_shop_id ON shops(shop_id);
CREATE INDEX idx_shops_owner_id ON shops(owner_id);
CREATE INDEX idx_shops_location ON shops(latitude, longitude);
CREATE INDEX idx_shops_approved ON shops(is_approved, is_active);
```

**shop_business_hours** - Operating hours management
```sql
CREATE TABLE shop_business_hours (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL, -- 1=Monday, 7=Sunday
    opening_time TIME,
    closing_time TIME,
    is_closed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(shop_id, day_of_week)
);

CREATE INDEX idx_shop_hours_shop_day ON shop_business_hours(shop_id, day_of_week);
```

#### 3. Product Catalog Tables

**products** - Product information and inventory
```sql
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    discounted_price DECIMAL(10,2),
    category VARCHAR(100),
    subcategory VARCHAR(100),
    unit VARCHAR(50),
    weight DECIMAL(8,2),
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    sku VARCHAR(100),
    barcode VARCHAR(100),
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_shop_id ON products(shop_id);
CREATE INDEX idx_products_category ON products(category, subcategory);
CREATE INDEX idx_products_availability ON products(is_available, is_featured);
CREATE INDEX idx_products_price ON products(price);
```

**product_images** - Product image management
```sql
CREATE TABLE product_images (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INTEGER DEFAULT 0,
    alt_text VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_images_product ON product_images(product_id);
CREATE INDEX idx_product_images_primary ON product_images(product_id, is_primary);
```

#### 4. Order Management Tables

**orders** - Main order tracking table
```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL REFERENCES customers(id),
    shop_id BIGINT NOT NULL REFERENCES shops(id),
    total_amount DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(8,2) DEFAULT 0.00,
    discount_amount DECIMAL(8,2) DEFAULT 0.00,
    tax_amount DECIMAL(8,2) DEFAULT 0.00,
    final_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDING',
    payment_method VARCHAR(50),
    payment_status VARCHAR(30) DEFAULT 'PENDING',
    
    -- Delivery Information
    delivery_address TEXT NOT NULL,
    delivery_latitude DECIMAL(10,6),
    delivery_longitude DECIMAL(10,6),
    delivery_phone VARCHAR(15),
    delivery_notes TEXT,
    
    -- Timing Information
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    
    -- Additional Information
    special_instructions TEXT,
    cancellation_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_shop ON orders(shop_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);
```

**order_items** - Individual items in orders
```sql
CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INTEGER NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
```

#### 5. Delivery Partner Management

**delivery_partners** - Partner profiles and performance
```sql
CREATE TABLE delivery_partners (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    partner_id VARCHAR(50) UNIQUE NOT NULL,
    
    -- Vehicle Information
    vehicle_type VARCHAR(50) NOT NULL,
    vehicle_number VARCHAR(20),
    license_number VARCHAR(50) NOT NULL,
    license_expiry DATE,
    
    -- Performance Metrics
    is_available BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    rating DECIMAL(2,1) DEFAULT 0.0,
    total_deliveries INTEGER DEFAULT 0,
    successful_deliveries INTEGER DEFAULT 0,
    cancelled_deliveries INTEGER DEFAULT 0,
    success_rate DECIMAL(5,2) DEFAULT 0.00,
    
    -- Financial Information
    commission_rate DECIMAL(5,2) DEFAULT 80.00,
    total_earnings DECIMAL(12,2) DEFAULT 0.00,
    pending_earnings DECIMAL(12,2) DEFAULT 0.00,
    
    -- Location Information
    current_latitude DECIMAL(10,6),
    current_longitude DECIMAL(10,6),
    last_location_update TIMESTAMP,
    
    -- Additional Information
    emergency_contact VARCHAR(15),
    bank_account_number VARCHAR(50),
    ifsc_code VARCHAR(20),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_delivery_partners_partner_id ON delivery_partners(partner_id);
CREATE INDEX idx_delivery_partners_user ON delivery_partners(user_id);
CREATE INDEX idx_delivery_partners_availability ON delivery_partners(is_available, is_active);
CREATE INDEX idx_delivery_partners_location ON delivery_partners(current_latitude, current_longitude);
```

#### 6. Order Assignment & Tracking Tables

**order_assignments** - Delivery partner assignments
```sql
CREATE TABLE order_assignments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    partner_id BIGINT NOT NULL REFERENCES delivery_partners(id),
    assigned_by BIGINT REFERENCES users(id),
    
    -- Assignment Information
    assignment_type VARCHAR(20) DEFAULT 'AUTO',
    status VARCHAR(30) DEFAULT 'ASSIGNED',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP,
    pickup_time TIMESTAMP,
    delivery_time TIMESTAMP,
    
    -- Location Information
    pickup_latitude DECIMAL(10,6),
    pickup_longitude DECIMAL(10,6),
    delivery_latitude DECIMAL(10,6),
    delivery_longitude DECIMAL(10,6),
    
    -- Financial Information
    delivery_fee DECIMAL(10,2) NOT NULL,
    partner_commission DECIMAL(10,2),
    
    -- Additional Information
    rejection_reason TEXT,
    delivery_notes TEXT,
    customer_rating INTEGER,
    customer_feedback TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assignments_order ON order_assignments(order_id);
CREATE INDEX idx_assignments_partner ON order_assignments(partner_id);
CREATE INDEX idx_assignments_status ON order_assignments(status);
CREATE INDEX idx_assignments_date ON order_assignments(assigned_at);
```

**delivery_tracking** - Real-time location tracking
```sql
CREATE TABLE delivery_tracking (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES order_assignments(id) ON DELETE CASCADE,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50),
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tracking_assignment ON delivery_tracking(assignment_id);
CREATE INDEX idx_tracking_timestamp ON delivery_tracking(timestamp);
```

**partner_earnings** - Earnings and payment tracking
```sql
CREATE TABLE partner_earnings (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES delivery_partners(id),
    assignment_id BIGINT NOT NULL REFERENCES order_assignments(id),
    
    -- Earning Breakdown
    base_amount DECIMAL(10,2) NOT NULL,
    bonus_amount DECIMAL(10,2) DEFAULT 0.00,
    tip_amount DECIMAL(10,2) DEFAULT 0.00,
    penalty_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL,
    
    -- Payment Information
    payment_status VARCHAR(30) DEFAULT 'PENDING',
    paid_at TIMESTAMP,
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    
    -- Additional Information
    earning_date DATE DEFAULT CURRENT_DATE,
    description TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_earnings_partner ON partner_earnings(partner_id);
CREATE INDEX idx_earnings_assignment ON partner_earnings(assignment_id);
CREATE INDEX idx_earnings_status ON partner_earnings(payment_status);
CREATE INDEX idx_earnings_date ON partner_earnings(earning_date);
```

---

## 🔄 Data Flow Architecture

### Order Processing Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Order Processing Workflow                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

Customer Mobile/Web App
           │
           ▼
┌──────────────────────────┐
│    1. Browse Products    │ ────► products table
│   - View shop products   │       (filtered by shop_id)
│   - Add to cart          │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│    2. Place Order       │ ────► orders table
│   - Create order record  │       (status: PENDING)
│   - Save order items     │ ────► order_items table
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│  3. Shop Notification   │
│   - Real-time alert      │ ────► Firebase Push
│   - Email/SMS notify     │ ────► MSG91 API
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│   4. Shop Confirmation  │ ────► orders table
│   - Accept/reject order  │       (status: CONFIRMED)
│   - Set preparation time │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│  5. Delivery Assignment │ ────► order_assignments table
│   - Find available       │       (status: ASSIGNED)
│     delivery partner     │ ────► delivery_partners table
│   - Auto/manual assign   │       (location-based)
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│ 6. Partner Notification │
│   - Assignment alert     │ ────► Firebase Push
│   - WhatsApp/SMS        │ ────► MSG91 API
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│  7. Partner Response    │ ────► order_assignments table
│   - Accept/reject        │       (status: ACCEPTED/REJECTED)
│   - If rejected, retry   │
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│    8. Order Pickup      │ ────► order_assignments table
│   - Partner arrives      │       (status: PICKED_UP)
│   - Update location      │ ────► delivery_tracking table
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│   9. Delivery Transit   │ ────► order_assignments table
│   - Real-time tracking   │       (status: IN_TRANSIT)
│   - Location updates     │ ────► delivery_tracking table
└─────────┬────────────────┘
          │
          ▼
┌──────────────────────────┐
│  10. Order Delivered    │ ────► orders table
│   - Customer confirmation│       (status: DELIVERED)
│   - Payment processing   │ ────► partner_earnings table
│   - Rating & feedback    │
└──────────────────────────┘
```

### Authentication Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Authentication & Authorization Flow                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

Mobile/Web Application
           │
           ▼
┌──────────────────────────┐
│   Login Method Choice    │
│                          │
├─────────┬────────────────┤
│ Email/  │  Mobile/OTP    │
│Password │  Authentication│
└─────────┼────────────────┘
          │                │
          ▼                ▼
┌─────────────────┐  ┌─────────────────┐
│ Email Login     │  │ OTP Login       │
│                 │  │                 │
│ POST /api/auth/ │  │ POST /api/auth/ │
│ login           │  │ send-otp        │
│                 │  │                 │ ────► MSG91 API
│ - Validate      │  │ - Generate OTP  │       (WhatsApp/SMS)
│   credentials   │  │ - Store in cache│
│ - Check user    │  │ - Send via MSG91│
│   status        │  └─────────────────┘
│                 │           │
└─────────────────┘           ▼
          │            ┌─────────────────┐
          │            │ OTP Verification│
          │            │                 │
          │            │ POST /api/auth/ │
          │            │ verify-otp      │
          │            │                 │
          │            │ - Validate OTP  │
          │            │ - Create/login  │
          │            │   user          │
          │            └─────────────────┘
          │                     │
          └─────────────────────┼─────────────────────┐
                                │                     │
                                ▼                     │
                     ┌─────────────────┐              │
                     │ JWT Generation  │              │
                     │                 │              │
                     │ - Create token  │              │
                     │ - Set expiry    │              │
                     │ - Include roles │              │
                     │ - Return to app │              │
                     └─────────────────┘              │
                                │                     │
                                ▼                     │
                     ┌─────────────────┐              │
                     │ Token Storage   │              │
                     │                 │              │
                     │ - localStorage  │              │
                     │ - Secure cookies│              │
                     │ - Session mgmt  │              │
                     └─────────────────┘              │
                                │                     │
                                ▼                     │
                     ┌─────────────────┐              │
                     │ Authenticated   │              │
                     │ API Requests    │              │
                     │                 │              │
                     │ Authorization:  │              │
                     │ Bearer <token>  │              │
                     └─────────────────┘              │
                                │                     │
                                ▼                     │
                     ┌─────────────────┐              │
                     │ Role-based      │              │
                     │ Access Control  │              │
                     │                 │              │
                     │ - CUSTOMER      │              │
                     │ - SHOP_OWNER    │              │
                     │ - DELIVERY_     │              │
                     │   PARTNER       │              │
                     │ - ADMIN         │              │
                     └─────────────────┘              │
                                                      │
                     Token Refresh/Expiry ───────────┘
                     (Automatic renewal)
```

---

## 🚀 Technology Stack Deep Dive

### Frontend Architecture (Angular)
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Angular Frontend Architecture                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Presentation │    │   Business      │    │     Data        │
│      Layer      │    │     Layer       │    │    Access       │
│                 │    │                 │    │     Layer       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │
│ ● Components    │◄──►│ ● Services      │◄──►│ ● HTTP Client   │
│   - Smart       │    │   - Business    │    │   - API Calls   │
│   - Dumb        │    │     Logic       │    │   - Interceptors│
│                 │    │   - State Mgmt  │    │   - Error       │
│ ● Templates     │    │                 │    │     Handling    │
│   - HTML        │    │ ● Guards        │    │                 │
│   - Directives  │    │   - Auth Guard  │    │ ● Models/DTOs   │
│                 │    │   - Role Guard  │    │   - Interfaces  │
│ ● Styling       │    │                 │    │   - Enums       │
│   - SCSS        │    │ ● Interceptors  │    │                 │
│   - Material    │    │   - Auth Token  │    │ ● Validators    │
│                 │    │   - Error       │    │   - Custom      │
│ ● Routing       │    │   - Loading     │    │   - Built-in    │
│   - Lazy Load   │    │                 │    │                 │
│   - Guards      │    │ ● Validators    │    │                 │
│                 │    │   - Forms       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Backend Architecture (Spring Boot)
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Spring Boot Backend Architecture                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │    │   Integration   │
│     Layer       │    │     Layer       │    │     Access      │    │     Layer       │
│                 │    │                 │    │     Layer       │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│                 │    │                 │    │                 │    │                 │
│ ● Controllers   │◄──►│ ● Services      │◄──►│ ● Repositories  │◄──►│ ● External APIs │
│   - REST APIs   │    │   - Business    │    │   - JPA         │    │   - MSG91       │
│   - Error       │    │     Logic       │    │   - Custom      │    │   - Firebase    │
│     Handling    │    │   - Validation  │    │     Queries     │    │   - Google Maps │
│                 │    │   - Transaction │    │                 │    │   - SMTP        │
│ ● DTOs          │    │                 │    │ ● Entities      │    │                 │
│   - Request     │    │ ● Mappers       │    │   - JPA         │    │ ● File Storage  │
│   - Response    │    │   - Entity-DTO  │    │   - Relations   │    │   - Local       │
│                 │    │                 │    │   - Audit       │    │   - Cloud       │
│ ● Validation    │    │ ● Components    │    │                 │    │                 │
│   - Bean Val    │    │   - Utilities   │    │ ● Configuration │    │ ● Messaging     │
│   - Custom      │    │   - Helpers     │    │   - DB Config   │    │   - Queues      │
│                 │    │                 │    │   - Connection  │    │   - Events      │
│ ● Security      │    │                 │    │     Pool        │    │                 │
│   - JWT         │    │                 │    │                 │    │                 │
│   - CORS        │    │                 │    │                 │    │                 │
│                 │    │                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 📊 Performance & Monitoring Architecture

### System Monitoring Stack
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           Monitoring & Performance Stack                           │
└─────────────────────────────────────────────────────────────────────────────────────┘

Application Layer
├─ Spring Boot Actuator    ────► Health Checks, Metrics
├─ Custom Metrics          ────► Business KPIs
└─ Performance Logging     ────► Response Times, Errors

                    │
                    ▼
Infrastructure Monitoring
├─ System Resources        ────► CPU, Memory, Disk
├─ Database Monitoring     ────► Query Performance, Connections
├─ Network Monitoring      ────► Latency, Throughput
└─ External API Monitoring ────► MSG91, Firebase, Maps API

                    │
                    ▼
Log Aggregation
├─ Application Logs        ────► Structured JSON Logs
├─ Error Tracking          ────► Exception Details
├─ Access Logs            ────► Request/Response Data
└─ Security Logs          ────► Auth, Failed Attempts

                    │
                    ▼
Alerting System
├─ Performance Alerts      ────► Response Time > 500ms
├─ Error Rate Alerts       ────► Error Rate > 5%
├─ Resource Alerts         ────► CPU/Memory > 80%
└─ Business Alerts         ────► Order Failure Rate
```

### Key Performance Indicators (KPIs)
```sql
-- System Performance KPIs
SELECT 
    'API Response Time' as metric,
    AVG(response_time_ms) as avg_value,
    MAX(response_time_ms) as max_value,
    'Target: <500ms' as target
FROM api_performance_logs
WHERE created_at >= NOW() - INTERVAL '1 hour';

-- Business Performance KPIs
SELECT 
    DATE(order_date) as date,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) as delivered_orders,
    ROUND(COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) * 100.0 / COUNT(*), 2) as success_rate,
    SUM(final_amount) as total_revenue
FROM orders 
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(order_date)
ORDER BY date DESC;

-- Delivery Partner Performance
SELECT 
    dp.partner_id,
    u.first_name,
    dp.total_deliveries,
    dp.success_rate,
    dp.rating,
    dp.total_earnings
FROM delivery_partners dp
JOIN users u ON dp.user_id = u.id
WHERE dp.is_active = true
ORDER BY dp.rating DESC, dp.success_rate DESC;
```

---

## 🔒 Security Architecture

### Security Implementation Layers
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Security Architecture                                  │
└─────────────────────────────────────────────────────────────────────────────────────┘

Network Security
├─ SSL/TLS Encryption      ────► HTTPS Only (Let's Encrypt)
├─ Firewall Rules          ────► Port Restrictions
├─ Rate Limiting           ────► DDoS Protection
└─ CORS Configuration      ────► Cross-Origin Control

                    │
                    ▼
Application Security
├─ JWT Authentication      ────► Stateless Tokens
├─ Role-based Access       ────► RBAC Implementation
├─ Input Validation        ────► XSS/Injection Prevention
├─ File Upload Security    ────► Type/Size Restrictions
└─ Password Security       ────► BCrypt Hashing

                    │
                    ▼
Data Security
├─ Database Encryption     ────► Encrypted at Rest
├─ Sensitive Data Masking  ────► PII Protection
├─ Connection Pool Security────► Encrypted Connections
└─ Backup Encryption       ────► Secure Backups

                    │
                    ▼
Infrastructure Security
├─ Environment Variables   ────► Secret Management
├─ Container Security      ────► Docker Best Practices
├─ Server Hardening        ────► OS Security Updates
└─ Access Control          ────► SSH Key Authentication
```

---

## 📱 Mobile App Architecture (Flutter)

### Overview

The NammaOoru platform includes **two fully-functional Flutter mobile applications** providing complete e-commerce and delivery management capabilities:

1. **🏪 Shop Owner Mobile App** - Complete business management for shop owners
2. **🚚 Delivery Partner Mobile App** - GPS-enabled delivery tracking and order management

Both apps are **production-ready** with comprehensive backend API integration, real-time updates, and professional UI/UX.

---

### 🏪 Shop Owner Mobile App

**Status**: ✅ **Fully Implemented and Operational**

**Platform Support**: iOS, Android, Web (Chrome)

**Key Features**:
- ✅ Complete product catalog management (CRUD operations)
- ✅ Real-time order processing with WebSocket integration
- ✅ Firebase Cloud Messaging for push notifications
- ✅ Audio alerts for important events (new orders, payments, etc.)
- ✅ Revenue analytics with charts and graphs
- ✅ Business hours and shop profile management
- ✅ Multi-image upload with caching
- ✅ Payment tracking and financial dashboard

**Architecture Highlights**:
```
┌──────────────────────────────────────────────┐
│         Shop Owner App Architecture          │
├──────────────────────────────────────────────┤
│ Presentation Layer                           │
│ ├─ Dashboard, Products, Orders, Finance      │
│ ├─ Analytics, Notifications, Profile         │
│ └─ Settings, Business Hours                  │
├──────────────────────────────────────────────┤
│ State Management (Provider Pattern)          │
│ ├─ AuthProvider                              │
│ ├─ OrderProvider (Real-time updates)         │
│ └─ ProductProvider                           │
├──────────────────────────────────────────────┤
│ Business Logic Layer                         │
│ ├─ API Service (HTTP + JWT Auth)            │
│ ├─ WebSocket Service (Real-time orders)     │
│ ├─ Firebase Messaging (Push notifications)  │
│ ├─ Audio Service (Sound alerts)             │
│ └─ Storage Service (Local cache)            │
├──────────────────────────────────────────────┤
│ Data Layer                                   │
│ ├─ Backend API: http://192.168.1.11:8080    │
│ ├─ Firebase Cloud Messaging                 │
│ └─ SharedPreferences (Local storage)        │
└──────────────────────────────────────────────┘
```

**API Integration**: 23 REST endpoints including:
- Authentication & JWT tokens
- Product CRUD operations
- Order management & status updates
- Real-time WebSocket for order notifications
- Firebase FCM token registration
- Business analytics and revenue tracking

**Dependencies**:
- `provider: ^6.0.5` - State management
- `http: ^1.1.0` - API client
- `firebase_messaging: ^15.1.5` - Push notifications
- `websocket_service` - Real-time updates
- `fl_chart: ^0.66.2` - Analytics charts
- `audioplayers: ^5.2.1` - Audio alerts

**📖 Complete Documentation**: See [SHOP_OWNER_APP_ARCHITECTURE.md](SHOP_OWNER_APP_ARCHITECTURE.md)

---

### 🚚 Delivery Partner Mobile App

**Status**: ✅ **Fully Implemented with GPS Tracking**

**Platform Support**: iOS, Android, Web (Chrome with limitations)

**Key Features**:
- ✅ Real-time GPS location tracking (10s local, 30s server sync)
- ✅ Google Maps integration with turn-by-turn navigation
- ✅ Order acceptance and delivery workflow
- ✅ OTP verification for pickup and delivery
- ✅ Live route display with polylines
- ✅ ETA calculations based on GPS coordinates
- ✅ Earnings tracking (daily, weekly, monthly)
- ✅ Push notifications for order assignments
- ✅ Battery and network status monitoring

**Architecture Highlights**:
```
┌──────────────────────────────────────────────┐
│      Delivery Partner App Architecture       │
├──────────────────────────────────────────────┤
│ Presentation Layer                           │
│ ├─ Dashboard, Available Orders, Active       │
│ ├─ Navigation Screen (Google Maps)           │
│ ├─ OTP Handover, Delivery Completion         │
│ └─ Earnings, Profile, Settings               │
├──────────────────────────────────────────────┤
│ State Management (Provider Pattern)          │
│ ├─ DeliveryPartnerProvider                   │
│ ├─ LocationProvider (GPS tracking)           │
│ └─ OrderProvider                             │
├──────────────────────────────────────────────┤
│ Business Logic Layer                         │
│ ├─ API Service (HTTP + JWT Auth)            │
│ ├─ Location Service (GPS + Geolocator)      │
│ ├─ Firebase Messaging (Order assignments)   │
│ ├─ Delivery Confirmation Service (OTP)      │
│ └─ Google Maps Service (Routes, Directions) │
├──────────────────────────────────────────────┤
│ Data Layer                                   │
│ ├─ Backend API: http://192.168.1.11:8080    │
│ ├─ Google Maps API (Directions & Geocoding) │
│ ├─ GPS Hardware (Real-time coordinates)     │
│ └─ SharedPreferences (Token & cache)        │
└──────────────────────────────────────────────┘
```

**Complete Delivery Workflow**:
```
1. Partner logs in → Fetches available orders
2. Accepts order → GPS tracking starts
3. Navigate to shop → Real-time route display
4. Arrive at shop → OTP verification for pickup
5. Pickup confirmed → Navigate to customer
6. Arrive at customer → OTP verification for delivery
7. Delivery confirmed → Optional photo/signature
8. Earnings updated → Return to dashboard
```

**Location Tracking System**:
- **Update Frequency**: 10 seconds (local UI updates)
- **Server Sync**: 30 seconds (backend location storage)
- **Accuracy**: High (GPS + Network combined)
- **Additional Data**: Battery level, network type, speed, heading
- **Background Tracking**: Supported on iOS/Android

**API Integration**: 11 REST endpoints including:
- Authentication & profile management
- Available/active order queries
- Order acceptance and status updates
- GPS location updates with assignment tracking
- ETA calculations based on coordinates
- OTP verification for pickup/delivery
- Earnings and statistics retrieval

**Dependencies**:
- `google_maps_flutter: ^2.5.0` - Map display
- `geolocator: ^10.1.0` - GPS location tracking
- `flutter_polyline_points: ^2.0.0` - Route polylines
- `geocoding: ^2.1.1` - Address lookup
- `provider: ^6.0.5` - State management
- `http: ^1.1.0` - API client

**Google Maps API Key**: Set via environment variable or `AndroidManifest.xml`

**📖 Complete Documentation**: See [DELIVERY_PARTNER_APP_ARCHITECTURE.md](DELIVERY_PARTNER_APP_ARCHITECTURE.md)

---

### Mobile App Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Flutter 3.0+ | Cross-platform mobile development |
| **Language** | Dart | Primary programming language |
| **State Management** | Provider Pattern | Reactive state updates |
| **HTTP Client** | http package | REST API communication |
| **Real-time** | WebSocket + FCM | Live order updates |
| **Maps** | Google Maps Flutter | Navigation and routing |
| **Location** | Geolocator | GPS tracking |
| **Storage** | SharedPreferences | Local data persistence |
| **Notifications** | Firebase Cloud Messaging | Push notifications |
| **Charts** | fl_chart | Analytics visualization |
| **Audio** | audioplayers | Sound alerts |

---

### Mobile-Backend Integration

**Authentication Flow**:
1. App sends credentials → Backend validates
2. Backend generates JWT token (24h expiry)
3. App stores token in SharedPreferences
4. All API calls include `Authorization: Bearer <token>` header
5. Token auto-refresh on expiration

**Real-time Communication**:
- **WebSocket**: Order status updates for shop owners
- **Firebase FCM**: Push notifications for both apps
- **GPS Polling**: Location updates every 30s during deliveries
- **HTTP Long Polling**: Fallback for WebSocket

**Data Synchronization**:
- **Online Mode**: Direct API calls with real-time updates
- **Offline Cache**: Critical data stored locally
- **Auto-sync**: On network restoration
- **Conflict Resolution**: Server-side timestamp priority

---

### Deployment Configuration

**Development Environment**:
```dart
// lib/utils/app_config.dart
static String get apiBaseUrl {
  if (kIsProduction) {
    return 'https://api.nammaooru.com';
  } else {
    return 'http://192.168.1.11:8080/api';  // Local dev
  }
}
```

**Production Build Commands**:
```bash
# Shop Owner App
cd mobile/shop-owner-app
flutter build apk --release
flutter build appbundle --release
flutter build ios --release

# Delivery Partner App
cd mobile/nammaooru_delivery_partner
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

**Environment Variables**:
- `API_URL` - Backend API base URL
- `GOOGLE_MAPS_API_KEY` - Maps API key
- `FIREBASE_PROJECT_ID` - Firebase project

---

### Performance Metrics

**App Performance**:
- Cold start time: < 2 seconds
- Hot reload time: < 500ms
- API response time: < 300ms average
- GPS location accuracy: ±10 meters
- Battery consumption: ~5% per hour (GPS tracking)

**Network Optimization**:
- Image caching with `cached_network_image`
- API request debouncing (300ms)
- Batch location updates (30s intervals)
- Gzip compression for API responses

---

### 📚 Detailed Documentation References

For complete architecture diagrams, API call flows, and implementation details:

1. **Shop Owner App**: [SHOP_OWNER_APP_ARCHITECTURE.md](SHOP_OWNER_APP_ARCHITECTURE.md)
   - Complete screen flow diagrams
   - API call sequence diagrams
   - State management patterns
   - WebSocket integration details

2. **Delivery Partner App**: [DELIVERY_PARTNER_APP_ARCHITECTURE.md](DELIVERY_PARTNER_APP_ARCHITECTURE.md)
   - GPS location tracking system
   - Google Maps integration
   - Complete delivery workflow
   - OTP verification process

---

### Legacy Information

#### Current Implementation Status
```
✅ COMPLETED FEATURES (Flutter UI)
├─ Authentication Flow
│  ├─ WhatsApp OTP Login Screen
│  └─ Phone Number Verification
│
├─ Main Dashboard
│  ├─ Earnings Overview Widget
│  ├─ Available Orders List
│  └─ Quick Stats Cards
│
├─ Earnings Management
│  ├─ Daily/Weekly/Monthly Views
│  ├─ Withdrawal Request System
│  └─ Transaction History
│
├─ Profile Management
│  ├─ Personal Information
│  ├─ Vehicle Details
│  └─ Document Upload
│
└─ Analytics Screen
   ├─ Performance Metrics
   ├─ Delivery Statistics
   └─ Achievement Badges
```

#### Current Mock API Implementation (Port 8082)

**Base URL**: `http://localhost:8082/api/mobile/delivery-partner`

**✅ IMPLEMENTED API Endpoints (Mock Responses)**

**1. Login with Phone Number**
- **Endpoint**: `POST /login`
- **Request Body**:
```json
{
  "phoneNumber": "9876543210"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "OTP sent to 9876543210",
  "otpSent": true
}
```

**2. Verify OTP**
- **Endpoint**: `POST /verify-otp`
- **Request Body**:
```json
{
  "phoneNumber": "9876543210",
  "otp": "123456"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "token": "sample-jwt-token",
  "partnerId": "DP001"
}
```

**3. Get Profile**
- **Endpoint**: `GET /profile/{partnerId}`
- **Response**:
```json
{
  "partnerId": "DP001",
  "name": "Test Delivery Partner",
  "phoneNumber": "9876543210",
  "isOnline": true,
  "isAvailable": true
}
```

**4. Get Available Orders**
- **Endpoint**: `GET /orders/{partnerId}/available`
- **Response**:
```json
{
  "orders": [],
  "totalCount": 0,
  "message": "No available orders at the moment"
}
```

**5. Get Leaderboard**
- **Endpoint**: `GET /leaderboard`
- **Response**:
```json
{
  "leaderboard": [],
  "message": "Leaderboard functionality implemented"
}
```

**Testing Commands**:
```bash
# Test Login
curl -X POST "http://localhost:8082/api/mobile/delivery-partner/login" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"9876543210\"}"

# Test Profile
curl -X GET "http://localhost:8082/api/mobile/delivery-partner/profile/DP001"

# Test Leaderboard
curl -X GET "http://localhost:8082/api/mobile/delivery-partner/leaderboard"
```

**❌ PLANNED BUT NOT IMPLEMENTED APIs**:
- Update Profile (`PUT /profile/{partnerId}`)
- Upload Profile Image (`POST /profile/{partnerId}/image`)
- Update Online Status (`PUT /status/{partnerId}`)
- Accept Order (`POST /orders/{orderId}/accept`)
- Reject Order (`POST /orders/{orderId}/reject`)
- Pickup Order (`POST /orders/{orderId}/pickup`)
- Deliver Order (`POST /orders/{orderId}/deliver`)
- Get Earnings (`GET /earnings/{partnerId}`)
- Request Withdrawal (`POST /withdrawals/request`)
- Get Withdrawal History (`GET /withdrawals/{partnerId}`)
- Upload Documents (`POST /documents/{partnerId}`)
- Get Documents (`GET /documents/{partnerId}`)
- Get Stats (`GET /stats/{partnerId}`)
- Update Location (`PUT /location/{partnerId}`)
- Get Notifications (`GET /notifications/{partnerId}`)
- Mark Notification Read (`PUT /notifications/{notificationId}/read`)
- Create Support Ticket (`POST /support/tickets`)

#### Complete User Flow Architecture

**1. Registration & Onboarding Flow**
```
Partner Opens App → Enter Phone Number → Receive WhatsApp OTP → Verify OTP 
→ Create Profile → Upload Documents → KYC Verification → Account Activated
```

**Detailed Steps:**
1. **Phone Number Entry**: Partner enters mobile number
2. **OTP Generation**: System sends OTP via WhatsApp/SMS using MSG91
3. **OTP Verification**: Partner enters OTP for verification
4. **Profile Creation**: Basic details (name, address, vehicle info)
5. **Document Upload**: License, vehicle RC, identity proof
6. **Admin Verification**: Admin reviews and approves documents
7. **Activation**: Partner account activated for deliveries

**2. Order Management Flow**
```
New Order → Push Notification → View Order Details → Accept/Reject
→ Navigate to Pickup → Mark Picked Up → Navigate to Customer 
→ Mark Delivered → Earnings Updated
```

**Detailed Steps:**
1. **Order Assignment**: System assigns order based on proximity
2. **Notification**: Partner receives push notification
3. **Order Review**: Partner views order details, distance, earnings
4. **Decision**: Accept or reject within time limit
5. **Pickup**: Navigate to shop, collect order
6. **Delivery**: Navigate to customer, deliver order
7. **Completion**: Mark delivered, earnings credited

**3. Earnings & Withdrawal Flow**
```
Complete Delivery → Earnings Credited → View Earnings Dashboard 
→ Request Withdrawal → Enter Bank Details → Withdrawal Processing 
→ Admin Approval → Bank Transfer → Confirmation
```

**Detailed Steps:**
1. **Earnings Calculation**: Per delivery + incentives + tips
2. **Dashboard View**: Daily, weekly, monthly earnings
3. **Withdrawal Request**: Minimum balance required
4. **Bank Verification**: One-time bank account setup
5. **Processing**: 24-48 hour processing time
6. **Transfer**: Direct bank transfer
7. **Notification**: SMS/App notification on completion

#### Production API Architecture (Planned)

**Authentication Flow:**
```
1. Login Request (Phone Number)
   POST /api/mobile/delivery-partner/login
   → Generate OTP → Send via WhatsApp/SMS

2. OTP Verification
   POST /api/mobile/delivery-partner/verify-otp
   → Validate OTP → Generate JWT Token

3. Authenticated Requests
   Headers: Authorization: Bearer {JWT_TOKEN}
   → Validate Token → Process Request
```

**Real-time Updates (WebSocket):**
```
Connection: ws://localhost:8082/ws/delivery-partner
Topics:
  - /topic/orders/{partnerId}       # New orders
  - /topic/earnings/{partnerId}     # Earnings updates
  - /topic/notifications/{partnerId} # General notifications
```

**Additional Database Tables for Delivery Partners:**

*withdrawal_requests*
```sql
CREATE TABLE withdrawal_requests (
    id BIGSERIAL PRIMARY KEY,
    withdrawal_id VARCHAR(50) UNIQUE NOT NULL,
    partner_id BIGINT NOT NULL REFERENCES delivery_partners(id),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL, -- PENDING, APPROVED, REJECTED, COMPLETED
    bank_name VARCHAR(100),
    account_number VARCHAR(50),
    ifsc_code VARCHAR(20),
    requested_at TIMESTAMP NOT NULL,
    approved_at TIMESTAMP,
    completed_at TIMESTAMP,
    rejected_at TIMESTAMP,
    rejection_reason VARCHAR(200),
    transaction_id VARCHAR(100),
    transaction_status VARCHAR(50),
    FOREIGN KEY (partner_id) REFERENCES delivery_partners(id)
);
```

*partner_achievements*
```sql
CREATE TABLE partner_achievements (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES delivery_partners(id),
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    points_awarded INTEGER DEFAULT 0,
    badge_icon_url VARCHAR(500)
);
```

*partner_notifications*
```sql
CREATE TABLE partner_notifications (
    id BIGSERIAL PRIMARY KEY,
    partner_id BIGINT NOT NULL REFERENCES delivery_partners(id),
    notification_type VARCHAR(30) NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    action_type VARCHAR(30),
    action_data JSON,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);
```

#### System Integration Points

**External Services Integration:**
- **MSG91**: SMS/WhatsApp OTP delivery
- **Google Maps**: Navigation and location services
- **Firebase**: Push notifications for real-time alerts
- **Payment Gateway**: For instant withdrawal processing

**Security Implementation:**
- Phone number + OTP based authentication
- JWT tokens with 24-hour expiry
- Device binding for enhanced security
- Role-based access control (RBAC)
- Encrypted sensitive data storage

#### Performance & Monitoring

**Key Performance Indicators:**
- API Response Time: < 200ms (p95)
- App Launch Time: < 2 seconds
- Crash Rate: < 0.1%
- Order Acceptance Rate
- Average Delivery Time
- Partner Utilization Rate
- Earnings per Partner

**Monitoring Stack:**
- Application Performance Monitoring (APM)
- Real-time error tracking
- Business metrics dashboards
- Infrastructure monitoring
- Automated alerting system

### Flutter Application Structure
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              Flutter Mobile Architecture                           │
└─────────────────────────────────────────────────────────────────────────────────────┘

lib/
├─ main.dart                   ────► Application Entry Point
│
├─ core/                       ────► Core Application Components
│  ├─ constants/               ────► API URLs, App Constants
│  ├─ services/                ────► HTTP Client, Storage
│  ├─ utils/                   ────► Helper Functions
│  └─ theme/                   ────► App Theming
│
├─ features/                   ────► Feature-based Modules
│  ├─ auth/                    ────► Authentication Features
│  │  ├─ models/               ────► User, Login Models
│  │  ├─ services/             ────► Auth API Calls
│  │  ├─ screens/              ────► Login, Register Screens
│  │  └─ widgets/              ────► Auth-specific Widgets
│  │
│  ├─ customer/                ────► Customer Features
│  │  ├─ models/               ────► Shop, Product Models
│  │  ├─ services/             ────► Customer API Calls
│  │  ├─ screens/              ────► Shop List, Product Details
│  │  └─ widgets/              ────► Customer Widgets
│  │
│  ├─ orders/                  ────► Order Management
│  │  ├─ models/               ────► Order Models
│  │  ├─ services/             ────► Order API Calls
│  │  ├─ screens/              ────► Order History, Tracking
│  │  └─ widgets/              ────► Order Widgets
│  │
│  └─ delivery/                ────► Delivery Partner Features
│     ├─ models/               ────► Assignment Models
│     ├─ services/             ────► Delivery API Calls
│     ├─ screens/              ────► Assignment List, Tracking
│     └─ widgets/              ────► Delivery Widgets
│
├─ shared/                     ────► Shared Components
│  ├─ widgets/                 ────► Common Widgets
│  ├─ models/                  ────► Base Models
│  └─ services/                ────► Common Services
│
└─ config/                     ────► Configuration Files
   ├─ routes.dart              ────► App Routing
   ├─ dependencies.dart        ────► Dependency Injection
   └─ environment.dart         ────► Environment Config
```

---

## 🔄 Deployment Architecture

### Production Deployment Structure
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                             Production Infrastructure                               │
│                            Hetzner Cloud (65.21.4.236)                           │
└─────────────────────────────────────────────────────────────────────────────────────┘

Internet Traffic
        │
        ▼
┌─────────────────┐
│   Domain DNS    │
│                 │ ────► nammaoorudelivary.in
│ - Main Domain   │ ────► api.nammaoorudelivary.in
│ - API Subdomain │ ────► admin.nammaoorudelivary.in
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│ Load Balancer   │
│    (nginx)      │ ────► SSL Termination (Let's Encrypt)
│                 │ ────► Request Routing
│ Port 80/443     │ ────► Rate Limiting
└─────────┬───────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose Stack                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Frontend   │  │   Backend   │  │  Database   │         │
│  │  (nginx)    │  │ (Spring     │  │(PostgreSQL) │         │
│  │             │  │  Boot)      │  │             │         │
│  │ Port: 80    │  │ Port: 8080  │  │ Port: 5432  │         │
│  │             │  │             │  │             │         │
│  │ - Angular   │  │ - REST API  │  │ - Persistent│         │
│  │   SPA       │  │ - Business  │  │   Storage   │         │
│  │ - Static    │  │   Logic     │  │ - Backups   │         │
│  │   Assets    │  │ - Security  │  │ - Indexing  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                   Shared Volumes                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Uploads   │  │    Logs     │  │   Backups   │         │
│  │             │  │             │  │             │         │
│  │ - Product   │  │ - App Logs  │  │ - DB Dumps  │         │
│  │   Images    │  │ - Access    │  │ - File      │         │
│  │ - Documents │  │   Logs      │  │   Archives  │         │
│  │ - User      │  │ - Error     │  │ - Automated │         │
│  │   Avatars   │  │   Logs      │  │   Backups   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### Container Configuration
```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      - DB_URL=jdbc:postgresql://postgres:5432/shop_management_db
      - DB_USERNAME=postgres
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - MSG91_AUTH_KEY=${MSG91_AUTH_KEY}
    volumes:
      - uploads:/app/uploads
      - logs:/app/logs
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=shop_management_db
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - backups:/backups
    ports:
      - "5432:5432"
    restart: unless-stopped

  frontend:
    build: ./frontend
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ssl_certificates:/etc/ssl/certs
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
  uploads:
  logs:
  backups:
  ssl_certificates:
```

---

## 📈 Scalability Considerations

### Horizontal Scaling Strategy
```
Current Single-Server Setup
┌─────────────────────────────────┐
│        Single Server            │
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐     │
│  │Web  │  │ API │  │ DB  │     │
│  │     │  │     │  │     │     │
│  └─────┘  └─────┘  └─────┘     │
│                                 │
│  Pros: Simple, Cost-effective  │
│  Cons: Single point of failure │
└─────────────────────────────────┘

Future Scaled Architecture
┌─────────────────────────────────────────────────────────────────────┐
│                        Load Balancer                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐         │
│  │  Web    │    │  Web    │    │   API   │    │   API   │         │
│  │Server 1 │    │Server 2 │    │Server 1 │    │Server 2 │         │
│  └─────────┘    └─────────┘    └─────────┘    └─────────┘         │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                        Database Cluster                            │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                         │
│  │ Primary │    │ Read    │    │ Read    │                         │
│  │Database │    │Replica 1│    │Replica 2│                         │
│  └─────────┘    └─────────┘    └─────────┘                         │
└─────────────────────────────────────────────────────────────────────┘

Benefits:
- High Availability
- Load Distribution  
- Fault Tolerance
- Better Performance
```

---

## 🎯 API Documentation Standards

### RESTful API Design Principles
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                API Design Standards                                 │
└─────────────────────────────────────────────────────────────────────────────────────┘

Resource Naming Convention:
├─ /api/customers                  ────► GET, POST (Collection)
├─ /api/customers/{id}            ────► GET, PUT, DELETE (Resource)
├─ /api/customers/{id}/orders     ────► GET, POST (Sub-collection)
└─ /api/customers/{id}/orders/{orderId} ─► GET, PUT, DELETE (Sub-resource)

HTTP Status Codes:
├─ 200 OK                         ────► Successful GET, PUT
├─ 201 Created                    ────► Successful POST
├─ 204 No Content                 ────► Successful DELETE
├─ 400 Bad Request                ────► Client Error
├─ 401 Unauthorized              ────► Authentication Required
├─ 403 Forbidden                 ────► Access Denied
├─ 404 Not Found                 ────► Resource Not Found
├─ 422 Unprocessable Entity      ────► Validation Error
└─ 500 Internal Server Error     ────► Server Error

Response Format:
{
  "success": boolean,
  "message": "string",
  "data": object|array,
  "timestamp": "ISO8601",
  "errors": [
    {
      "field": "string",
      "message": "string",
      "code": "string"
    }
  ],
  "pagination": {
    "page": number,
    "size": number,
    "totalElements": number,
    "totalPages": number
  }
}
```

---

## 📚 Additional Resources

### Development Setup Commands
```bash
# Backend Setup
cd backend
./mvnw clean install
./mvnw spring-boot:run

# Frontend Setup  
cd frontend
npm install
npm start

# Database Setup
createdb shop_management_db
psql -d shop_management_db -f schema.sql

# Mobile Setup
cd mobile/nammaooru_mobile_app
flutter pub get
flutter run
```

### Useful Database Queries
```sql
-- Get system statistics
SELECT 
  (SELECT COUNT(*) FROM users) as total_users,
  (SELECT COUNT(*) FROM shops WHERE is_approved = true) as active_shops,
  (SELECT COUNT(*) FROM orders WHERE order_date >= CURRENT_DATE) as today_orders,
  (SELECT COUNT(*) FROM delivery_partners WHERE is_available = true) as available_partners;

-- Performance analysis
SELECT 
  DATE(created_at) as date,
  COUNT(*) as total_requests,
  AVG(response_time_ms) as avg_response_time,
  MAX(response_time_ms) as max_response_time
FROM api_logs 
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

---

## 🚚 Delivery Partner Document Management System

### Overview
A comprehensive document lifecycle management system integrated into the delivery partner management workflow, providing secure document upload, verification, and compliance tracking.

### System Architecture

#### Document Management Components
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        Delivery Partner Document Management                         │
└─────────────────────────────────────────────────────────────────────────────────────┘

Frontend Components                Backend Services                Database Tables
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│  User List      │              │  Document Service   │          │ delivery_       │
│  Component      │◄────────────►│                     │◄────────►│ partner_        │
│                 │              │ - Upload handling   │          │ documents       │
│ - Role-based    │              │ - File validation   │          │                 │
│   menu options  │              │ - Storage mgmt      │          │ - Document      │
│ - Document      │              │                     │          │   metadata      │
│   access        │              │                     │          │ - Verification  │
│                 │              │                     │          │   status        │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
         │                                   │                            │
         ▼                                   ▼                            ▼
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│ Document Upload │              │  Document           │          │ File Storage    │
│ Component       │              │  Controller         │          │                 │
│                 │              │                     │          │ - Secure paths  │
│ - 4 Doc types   │              │ - REST endpoints    │          │ - Unique names  │
│ - Progress      │              │ - Security layer    │          │ - Type/size     │
│   tracking      │              │ - Download mgmt     │          │   validation    │
│ - Validation    │              │                     │          │                 │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
         │                                   │
         ▼                                   ▼
┌─────────────────┐              ┌─────────────────────┐
│ Document Viewer │              │  Verification       │
│ Component       │              │  Workflow           │
│                 │              │                     │
│ - Modal view    │              │ - Admin approval    │
│ - Admin verify  │              │ - Status tracking   │
│ - Download      │              │ - Audit trail       │
│ - Full screen   │              │                     │
└─────────────────┘              └─────────────────────┘
```

#### Document Types and Requirements
```
Required Documents for Delivery Partners:
├─ DRIVER_PHOTO
│  ├─ Purpose: Partner identification
│  ├─ Format: JPG, PNG (Max 5MB)
│  └─ Validation: Face recognition, clarity
│
├─ DRIVING_LICENSE
│  ├─ Purpose: Legal driving authorization
│  ├─ Format: PDF, JPG, PNG (Max 10MB)
│  ├─ Metadata: License number, expiry date
│  └─ Validation: Government document verification
│
├─ VEHICLE_PHOTO
│  ├─ Purpose: Vehicle identification & condition
│  ├─ Format: JPG, PNG (Max 5MB)
│  ├─ Metadata: Vehicle registration number
│  └─ Validation: Clear vehicle visibility
│
└─ RC_BOOK
   ├─ Purpose: Vehicle registration proof
   ├─ Format: PDF, JPG, PNG (Max 10MB)
   ├─ Validation: Government registration document
   └─ Verification: Vehicle ownership proof
```

### Database Schema

#### delivery_partner_documents Table
```sql
CREATE TABLE delivery_partner_documents (
    id BIGSERIAL PRIMARY KEY,
    delivery_partner_id BIGINT NOT NULL REFERENCES users(id),
    document_type VARCHAR(50) NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(100),
    file_size BIGINT NOT NULL,

    -- Verification Information
    verification_status VARCHAR(20) DEFAULT 'PENDING',
    verification_notes TEXT,
    verified_by VARCHAR(100),
    verified_at TIMESTAMP,

    -- Document Metadata
    license_number VARCHAR(50),
    vehicle_number VARCHAR(20),
    expiry_date DATE,
    is_required BOOLEAN DEFAULT TRUE,

    -- Audit Information
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_delivery_partner_docs_partner ON delivery_partner_documents(delivery_partner_id);
CREATE INDEX idx_delivery_partner_docs_type ON delivery_partner_documents(document_type);
CREATE INDEX idx_delivery_partner_docs_status ON delivery_partner_documents(verification_status);
CREATE INDEX idx_delivery_partner_docs_created ON delivery_partner_documents(created_at);

-- Constraints
ALTER TABLE delivery_partner_documents
ADD CONSTRAINT uk_partner_doc_type UNIQUE (delivery_partner_id, document_type);
```

### API Endpoints

#### Document Management API
```yaml
Base URL: /api/delivery/partners

Endpoints:
  GET /{partnerId}/documents:
    Description: Retrieve all documents for a delivery partner
    Authorization: ADMIN, DELIVERY_PARTNER
    Response: List of DeliveryPartnerDocumentResponse

  POST /{partnerId}/documents/upload:
    Description: Upload a new document
    Authorization: ADMIN, DELIVERY_PARTNER
    Content-Type: multipart/form-data
    Parameters:
      - file: MultipartFile (required)
      - documentType: DeliveryPartnerDocument.DocumentType (required)
      - documentName: String (required)
      - licenseNumber: String (optional)
      - vehicleNumber: String (optional)
    Response: DeliveryPartnerDocumentResponse

  GET /{partnerId}/documents/{documentId}/download:
    Description: Download a specific document
    Authorization: ADMIN, DELIVERY_PARTNER
    Response: Binary file stream

  PUT /{partnerId}/documents/{documentId}/verify:
    Description: Admin verification of document
    Authorization: ADMIN only
    Request Body: DocumentVerificationRequest
    Response: DeliveryPartnerDocumentResponse

  DELETE /{partnerId}/documents/{documentId}:
    Description: Delete a document
    Authorization: ADMIN only
    Response: Success message

  GET /{partnerId}/documents/status:
    Description: Get document completion status
    Authorization: ADMIN, DELIVERY_PARTNER
    Response: Document status summary
```

### Security Implementation

#### File Security Measures
```yaml
Upload Security:
  - File type validation (PDF, JPG, PNG, DOCX only)
  - File size limits (10MB maximum)
  - Filename sanitization
  - Virus scanning (planned)
  - Content-type verification

Storage Security:
  - Files stored outside web root
  - Unique filename generation
  - Directory structure per partner
  - Access control through API only

Download Security:
  - Authentication required
  - Role-based access control
  - Secure file serving
  - Audit logging
```

### User Flow Integration

#### Document Upload Process
```
1. User Creation (Admin)
   ├─ Create delivery partner user
   ├─ Role assignment: DELIVERY_PARTNER
   └─ User appears in user list

2. Document Access (UI)
   ├─ Admin navigates to Users → Delivery Partners
   ├─ Actions menu shows document options for delivery partners only
   ├─ "View Documents": Check existing documents
   └─ "Manage Documents": Navigate to upload interface

3. Document Upload (Partner/Admin)
   ├─ Navigate to /users/{userId}/documents
   ├─ Upload interface with 4 document types
   ├─ Progress tracking and validation
   ├─ Metadata capture (license/vehicle numbers)
   └─ Real-time status updates

4. Admin Verification
   ├─ View all partner documents
   ├─ Preview/download capability
   ├─ Approve/reject with notes
   └─ Status updates and notifications

5. Compliance Tracking
   ├─ Document completion status
   ├─ Expiry date tracking
   ├─ Renewal notifications
   └─ Audit trail maintenance
```

### Performance Considerations

#### Optimization Strategies
```yaml
File Handling:
  - Chunked upload for large files
  - Progress tracking with WebSocket updates
  - Asynchronous processing
  - Image thumbnail generation

Caching:
  - Document metadata caching
  - Verification status caching
  - User permission caching

Database:
  - Proper indexing strategy
  - Efficient query optimization
  - Connection pool management

Storage:
  - CDN integration (planned)
  - Compressed storage
  - Regular cleanup of orphaned files
```

### Monitoring & Analytics

#### Key Metrics
```yaml
Document Management KPIs:
  - Document upload success rate
  - Average verification time
  - Document compliance percentage
  - Partner onboarding completion rate

Performance Metrics:
  - File upload speeds
  - API response times
  - Storage utilization
  - Error rates by document type

Business Metrics:
  - Partner verification completion
  - Document rejection reasons
  - Compliance audit results
  - Partner activation timelines
```

## 🌐 Real-time Delivery Partner Status Tracking System

### Overview
A comprehensive real-time status monitoring system for delivery partners that provides live online/offline status tracking, ride status management, and location-based updates integrated into the Angular frontend and Spring Boot backend.

### System Architecture

#### Status Tracking Components
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                     Real-time Delivery Partner Status System                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

Frontend Components              Backend Services                Database Enhancements
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│  User List      │              │  Status Tracking    │          │ users table     │
│  Component      │◄────────────►│  API Endpoints      │◄────────►│                 │
│                 │              │                     │          │ + is_online     │
│ - Dual status   │              │ - Online status     │          │ + is_available  │
│   indicators    │              │ - Ride status       │          │ + ride_status   │
│ - Real-time     │              │ - Location tracking │          │ + current_lat   │
│   updates       │              │ - Activity mgmt     │          │ + current_lng   │
│ - Color coding  │              │                     │          │ + last_activity │
│                 │              │                     │          │ + last_location │
│                 │              │                     │          │   _update       │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
         │                                   │                            │
         ▼                                   ▼                            ▼
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│ Status Display  │              │  UserRepository     │          │ New Repository  │
│ Components      │              │  Enhancements       │          │ Methods         │
│                 │              │                     │          │                 │
│ - Online/Offline│              │ - Status queries    │          │ - By online     │
│ - Ride Status   │              │ - Location queries  │          │   status        │
│ - Animations    │              │ - Activity tracking │          │ - By ride status│
│ - Tooltips      │              │ - Performance opt   │          │ - With location │
│ - Visual cues   │              │                     │          │ - Inactive      │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
```

#### Status Types and States

**Online/Offline Status:**
```yaml
Online Status Types:
  ONLINE:
    - Color: Green gradient with pulsing animation
    - Icon: wifi
    - Meaning: Partner is actively connected and responsive
    - Auto-update: Based on last activity timestamp

  OFFLINE:
    - Color: Gray gradient
    - Icon: wifi_off
    - Meaning: Partner is not connected or inactive
    - Auto-update: After 10 minutes of inactivity
```

**Ride Status Types:**
```yaml
Ride Status Types:
  AVAILABLE:
    - Color: Green gradient with pulse animation
    - Icon: check_circle
    - Meaning: Online and ready to accept orders
    - Prerequisites: Must be online

  ON_RIDE:
    - Color: Blue gradient with spinning animation
    - Icon: directions_bike
    - Meaning: Currently on active delivery
    - Auto-transition: From pickup to delivery complete

  BUSY:
    - Color: Yellow/Orange gradient with pulse animation
    - Icon: hourglass_empty
    - Meaning: Occupied but not on delivery
    - Usage: Multiple orders, break time

  ON_BREAK:
    - Color: Purple gradient
    - Icon: coffee
    - Meaning: Temporarily unavailable by choice
    - Manual: Partner-controlled status

  OFFLINE:
    - Color: Red gradient
    - Icon: offline_pin
    - Meaning: Not available for assignments
    - Auto-set: When going offline
```

### Database Schema Enhancements

#### Enhanced users Table
```sql
-- New columns added to existing users table for delivery partner status tracking
ALTER TABLE users
ADD COLUMN is_online BOOLEAN DEFAULT FALSE,
ADD COLUMN is_available BOOLEAN DEFAULT FALSE,
ADD COLUMN ride_status VARCHAR(20) DEFAULT 'AVAILABLE',
ADD COLUMN current_latitude DECIMAL(10,6),
ADD COLUMN current_longitude DECIMAL(10,6),
ADD COLUMN last_location_update TIMESTAMP,
ADD COLUMN last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Indexes for performance optimization
CREATE INDEX idx_users_online_status ON users(is_online) WHERE role = 'DELIVERY_PARTNER';
CREATE INDEX idx_users_ride_status ON users(ride_status) WHERE role = 'DELIVERY_PARTNER';
CREATE INDEX idx_users_location ON users(current_latitude, current_longitude) WHERE role = 'DELIVERY_PARTNER';
CREATE INDEX idx_users_last_activity ON users(last_activity) WHERE role = 'DELIVERY_PARTNER';

-- Composite index for efficient partner queries
CREATE INDEX idx_users_partner_status ON users(role, is_online, ride_status, is_available);
```

#### Enum Definitions
```java
public enum RideStatus {
    AVAILABLE,     // Ready to accept new orders
    ON_RIDE,      // Currently delivering an order
    BUSY,         // Occupied with multiple tasks
    ON_BREAK,     // Taking a break
    OFFLINE       // Not available for assignments
}
```

### API Endpoints

#### Delivery Partner Status Management
```yaml
Base URL: /api/delivery/partners

Status Management Endpoints:

  PUT /{partnerId}/online-status:
    Description: Update online/offline status
    Authorization: ADMIN, DELIVERY_PARTNER
    Request Body: { "isOnline": boolean }
    Response: StatusUpdateResponse
    Side Effects: Auto-updates availability and activity timestamp

  PUT /{partnerId}/ride-status:
    Description: Update current ride status
    Authorization: ADMIN, DELIVERY_PARTNER
    Request Body: { "rideStatus": "AVAILABLE|ON_RIDE|BUSY|ON_BREAK|OFFLINE" }
    Response: StatusUpdateResponse
    Business Logic: Automatically manages online status based on ride status

  PUT /{partnerId}/location:
    Description: Update current GPS location
    Authorization: DELIVERY_PARTNER
    Request Body: {
      "latitude": number,
      "longitude": number,
      "accuracy": number (optional)
    }
    Response: LocationUpdateResponse
    Side Effects: Updates last_activity and location timestamps

  PUT /{partnerId}/availability:
    Description: Update availability for new orders
    Authorization: ADMIN, DELIVERY_PARTNER
    Request Body: { "isAvailable": boolean }
    Response: StatusUpdateResponse

  GET /all-partners-status:
    Description: Get comprehensive status overview for all partners
    Authorization: ADMIN
    Response: {
      "partners": [...],
      "statistics": {
        "total": number,
        "online": number,
        "available": number,
        "on_ride": number,
        "busy": number
      }
    }

  GET /{partnerId}/status-history:
    Description: Get historical status changes
    Authorization: ADMIN
    Query Parameters: startDate, endDate, limit
    Response: List of status change events

  POST /batch-status-update:
    Description: Update multiple partners' status
    Authorization: ADMIN
    Request Body: [{ "partnerId": string, "updates": {...} }]
    Response: BatchUpdateResponse
```

### Frontend Implementation

#### Angular Component Structure
```typescript
// Enhanced User Interface for Status Display
interface User {
  // Existing fields...

  // New status tracking fields
  isOnline?: boolean;
  isAvailable?: boolean;
  rideStatus?: 'AVAILABLE' | 'ON_RIDE' | 'BUSY' | 'ON_BREAK' | 'OFFLINE';
  currentLatitude?: number;
  currentLongitude?: number;
  lastLocationUpdate?: string;
  lastActivity?: string;
}

// Status Display Methods
class UserListComponent {
  // Online status helpers
  getOnlineStatusTooltip(user: User): string {
    const lastActivity = user.lastActivity ?
      new Date(user.lastActivity).toLocaleString() : 'Never';
    return user.isOnline ?
      `Partner is online. Last activity: ${lastActivity}` :
      `Partner is offline. Last activity: ${lastActivity}`;
  }

  // Ride status helpers
  getRideStatusIcon(rideStatus: string): string {
    const iconMap = {
      'AVAILABLE': 'check_circle',
      'ON_RIDE': 'directions_bike',
      'BUSY': 'hourglass_empty',
      'ON_BREAK': 'coffee',
      'OFFLINE': 'offline_pin'
    };
    return iconMap[rideStatus] || 'help_outline';
  }

  getRideStatusDisplay(rideStatus: string): string {
    const displayMap = {
      'AVAILABLE': 'Available',
      'ON_RIDE': 'On Ride',
      'BUSY': 'Busy',
      'ON_BREAK': 'Break',
      'OFFLINE': 'Offline'
    };
    return displayMap[rideStatus] || 'Unknown';
  }

  // Real-time status updates
  updatePartnerStatus(partnerId: string, statusUpdate: any): void {
    this.deliveryPartnerService.updateStatus(partnerId, statusUpdate)
      .subscribe(response => {
        this.refreshUserList();
        this.notificationService.success('Status updated successfully');
      });
  }
}
```

#### CSS Styling with Animations
```scss
// Delivery partner status indicators with advanced styling
.delivery-status {
  display: flex;
  flex-direction: column;
  gap: 4px;
  align-items: flex-start;

  .status-chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 16px;
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border: 1px solid transparent;
    transition: all 0.2s ease;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

    // Online status styling with gradient backgrounds
    &.online-status-online {
      background: linear-gradient(135deg, #e6fffa 0%, #ccfbf1 100%);
      color: #047857;
      border: 1px solid #10b981;

      .status-icon {
        color: #059669;
        animation: pulse-online 2s ease-in-out infinite;
      }
    }

    &.online-status-offline {
      background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
      color: #6b7280;
      border: 1px solid #9ca3af;
    }

    // Ride status styling with unique animations
    &.ride-status-available {
      background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
      color: #065f46;

      .status-icon {
        animation: pulse-available 3s ease-in-out infinite;
      }
    }

    &.ride-status-on-ride {
      background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
      color: #1e40af;

      .status-icon {
        animation: spin 2s linear infinite;
      }
    }

    &.ride-status-busy {
      background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
      color: #92400e;

      .status-icon {
        animation: pulse-busy 1.5s ease-in-out infinite;
      }
    }

    // Hover effects for better interaction
    &:hover {
      transform: translateY(-1px);
      box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
    }
  }
}

// Keyframe animations for visual feedback
@keyframes pulse-online {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

@keyframes pulse-available {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(0.95); }
}

@keyframes pulse-busy {
  0%, 100% { opacity: 1; }
  25% { opacity: 0.6; }
  50% { opacity: 1; }
  75% { opacity: 0.8; }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
```

### Repository Enhancements

#### New Query Methods
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Status-based queries for delivery partners
    List<User> findByRoleAndIsOnline(UserRole role, Boolean isOnline);

    List<User> findByRoleAndIsAvailable(UserRole role, Boolean isAvailable);

    List<User> findByRoleAndRideStatus(UserRole role, RideStatus rideStatus);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.isOnline = true AND " +
           "u.currentLatitude IS NOT NULL AND u.currentLongitude IS NOT NULL")
    List<User> findOnlinePartnersWithLocation(@Param("role") UserRole role);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.lastActivity < :cutoffTime")
    List<User> findInactivePartners(@Param("role") UserRole role,
                                   @Param("cutoffTime") LocalDateTime cutoffTime);

    // Statistical queries for dashboard
    @Query("SELECT u.rideStatus, COUNT(u) FROM User u WHERE u.role = 'DELIVERY_PARTNER' " +
           "GROUP BY u.rideStatus")
    List<Object[]> getPartnerCountByRideStatus();

    @Query("SELECT COUNT(u) FROM User u WHERE u.role = 'DELIVERY_PARTNER' AND u.isOnline = true")
    Long countOnlinePartners();
}
```

### Performance Optimizations

#### Caching Strategy
```java
@Service
public class PartnerStatusService {

    @Cacheable(value = "partnerStatus", key = "#partnerId")
    public PartnerStatusDTO getPartnerStatus(String partnerId) {
        // Implementation with caching
    }

    @CacheEvict(value = "partnerStatus", key = "#partnerId")
    public void updatePartnerStatus(String partnerId, StatusUpdateRequest request) {
        // Cache invalidation on status update
    }

    @Scheduled(fixedRate = 60000) // Every minute
    public void updateInactivePartners() {
        LocalDateTime cutoff = LocalDateTime.now().minus(10, ChronoUnit.MINUTES);
        List<User> inactivePartners = userRepository.findInactivePartners(
            UserRole.DELIVERY_PARTNER, cutoff);

        // Auto-mark as offline
        inactivePartners.forEach(partner -> {
            partner.setIsOnline(false);
            partner.setRideStatus(RideStatus.OFFLINE);
        });
        userRepository.saveAll(inactivePartners);
    }
}
```

### Business Logic Rules

#### Automatic Status Management
```yaml
Status Transition Rules:

  Going Online:
    - Set is_online = true
    - Set last_activity = current_timestamp
    - Default ride_status = AVAILABLE
    - Set is_available = true

  Going Offline:
    - Set is_online = false
    - Set ride_status = OFFLINE
    - Set is_available = false
    - Maintain last_activity timestamp

  Starting Ride:
    - Ensure is_online = true
    - Set ride_status = ON_RIDE
    - Set is_available = false
    - Update location if provided

  Completing Ride:
    - Set ride_status = AVAILABLE
    - Set is_available = true
    - Update earnings and stats
    - Reset location tracking

  Inactivity Detection:
    - Monitor last_activity timestamp
    - Auto-offline after 10 minutes
    - Send push notification before auto-offline
    - Allow manual override
```

### Monitoring and Analytics

#### Key Performance Indicators
```sql
-- Partner utilization metrics
SELECT
    DATE(last_activity) as activity_date,
    COUNT(*) as total_partners,
    COUNT(CASE WHEN is_online = true THEN 1 END) as online_partners,
    COUNT(CASE WHEN ride_status = 'AVAILABLE' THEN 1 END) as available_partners,
    COUNT(CASE WHEN ride_status = 'ON_RIDE' THEN 1 END) as active_deliveries,
    ROUND(COUNT(CASE WHEN is_online = true THEN 1 END) * 100.0 / COUNT(*), 2) as online_percentage
FROM users
WHERE role = 'DELIVERY_PARTNER'
    AND last_activity >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(last_activity)
ORDER BY activity_date DESC;

-- Average response time for status updates
SELECT
    AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_response_time_seconds,
    COUNT(*) as total_updates
FROM partner_status_logs
WHERE created_at >= CURRENT_DATE - INTERVAL '1 day';
```

### Future Enhancements

#### Planned Features
```yaml
Real-time Updates:
  - WebSocket integration for live status broadcasting
  - Push notifications for status changes
  - Real-time dashboard updates

Advanced Analytics:
  - Partner performance scoring
  - Predictive availability modeling
  - Geographic heat mapping
  - Peak hours analysis

Mobile Integration:
  - Automatic status detection based on app state
  - Battery-optimized location tracking
  - Background activity monitoring
  - Smart status suggestions
```

## 🚚 Distance-Based Delivery Fee System

### Overview
A comprehensive distance-based delivery fee calculation system that replaces fixed shop-based delivery fees with dynamic pricing based on the distance between shops and customers. This system provides fair, transparent, and scalable delivery fee management.

### System Architecture

#### Delivery Fee Components
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        Distance-Based Delivery Fee System                          │
└─────────────────────────────────────────────────────────────────────────────────────┘

Frontend (Super Admin)          Backend Services               Database Layer
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│  Delivery Fee   │              │  DeliveryFeeService │          │ delivery_fee_   │
│  Management     │◄────────────►│                     │◄────────►│ ranges          │
│  Component      │              │ - Distance calc     │          │                 │
│                 │              │ - Fee lookup        │          │ - Range tiers   │
│ - Range CRUD    │              │ - Haversine formula │          │ - Fees & comm   │
│ - Distance calc │              │                     │          │ - Active status │
│ - Preview       │              │                     │          │                 │
│ - Bulk ops      │              │                     │          │                 │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
         │                                   │                            │
         ▼                                   ▼                            ▼
┌─────────────────┐              ┌─────────────────────┐          ┌─────────────────┐
│ Order Flow      │              │  Order Assignment   │          │ Integration     │
│ Integration     │              │  Service            │          │ Points          │
│                 │              │                     │          │                 │
│ - Auto fee calc │              │ - Auto distance     │          │ - Shop coords   │
│ - Real-time     │              │   calculation       │          │ - Customer addr │
│   updates       │              │ - Fee assignment    │          │ - Order table   │
│ - Order display │              │ - Commission calc   │          │ - Assignment    │
└─────────────────┘              └─────────────────────┘          └─────────────────┘
```

#### Distance Calculation Flow
```
Customer Places Order → Get Shop Coordinates → Get Customer Coordinates
                                ↓                        ↓
                        (Latitude, Longitude)    (Address Geocoding)
                                ↓                        ↓
                        Calculate Distance using Haversine Formula
                                        ↓
                              Distance in Kilometers
                                        ↓
                        Query delivery_fee_ranges Table
                                        ↓
                        SELECT * FROM delivery_fee_ranges
                        WHERE ? BETWEEN min_distance_km AND max_distance_km
                                        ↓
                              Extract Fee & Commission
                                        ↓
                        Update Order.deliveryFee & Assignment.commission
```

### Database Schema

#### delivery_fee_ranges Table
```sql
CREATE TABLE delivery_fee_ranges (
    id BIGSERIAL PRIMARY KEY,
    min_distance_km DOUBLE PRECISION NOT NULL,
    max_distance_km DOUBLE PRECISION,
    delivery_fee DECIMAL(10,2) NOT NULL,
    partner_commission DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data with 4-tier distance ranges
INSERT INTO delivery_fee_ranges (min_distance_km, max_distance_km, delivery_fee, partner_commission, is_active) VALUES
(0.0, 5.0, 20.00, 15.00, true),    -- Short distance: ₹20 (Partner gets ₹15)
(5.0, 10.0, 40.00, 30.00, true),   -- Medium distance: ₹40 (Partner gets ₹30)
(10.0, 20.0, 60.00, 45.00, true),  -- Long distance: ₹60 (Partner gets ₹45)
(20.0, NULL, 100.00, 75.00, true); -- Very long distance: ₹100 (Partner gets ₹75)

-- Indexes for performance
CREATE INDEX idx_delivery_fee_ranges_distance ON delivery_fee_ranges(min_distance_km, max_distance_km);
CREATE INDEX idx_delivery_fee_ranges_active ON delivery_fee_ranges(is_active);
```

#### Database Migration Changes
```sql
-- V15__Create_delivery_fee_ranges_table.sql
-- Creates the new delivery fee ranges table with initial data

-- V16__Drop_shop_delivery_fee_column.sql
-- Removes the old shop-based delivery fee column
ALTER TABLE shops DROP COLUMN IF EXISTS delivery_fee;
```

### API Endpoints

#### Super Admin Delivery Fee Management
```yaml
Base URL: /api/super-admin/delivery-fee-ranges

Endpoints:
  GET /:
    Description: Get all delivery fee ranges
    Authorization: SUPER_ADMIN only
    Response: List of DeliveryFeeRange entities

  POST /:
    Description: Create new delivery fee range
    Authorization: SUPER_ADMIN only
    Request Body: {
      "minDistanceKm": number,
      "maxDistanceKm": number|null,
      "deliveryFee": number,
      "partnerCommission": number
    }
    Response: Created DeliveryFeeRange

  PUT /{id}:
    Description: Update existing range
    Authorization: SUPER_ADMIN only
    Request Body: DeliveryFeeRange updates
    Response: Updated DeliveryFeeRange

  DELETE /{id}:
    Description: Delete delivery fee range
    Authorization: SUPER_ADMIN only
    Response: Success confirmation

  PUT /{id}/toggle-status:
    Description: Toggle active/inactive status
    Authorization: SUPER_ADMIN only
    Response: Updated status
```

#### Distance Calculation Service
```java
@Service
public class DeliveryFeeService {

    public Double calculateDistance(Double lat1, Double lon1, Double lat2, Double lon2) {
        double R = 6371; // Earth's radius in kilometers
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return R * c; // Distance in kilometers
    }

    public DeliveryFeeRange findByDistance(Double distance) {
        return deliveryFeeRangeRepository.findByDistanceRange(distance)
            .orElseThrow(() -> new RuntimeException("No delivery fee range found for distance: " + distance));
    }
}
```

### Frontend Implementation

#### Super Admin Management Component
```typescript
@Component({
  selector: 'app-delivery-fee-management',
  template: `
    <mat-card class="management-card">
      <mat-card-header>
        <mat-card-title>Distance-Based Delivery Fee Management</mat-card-title>
        <mat-card-subtitle>Configure delivery fees based on distance ranges</mat-card-subtitle>
      </mat-card-header>

      <mat-card-content>
        <!-- Distance Calculator -->
        <mat-expansion-panel class="calculator-panel">
          <mat-expansion-panel-header>
            <mat-panel-title>Distance Calculator</mat-panel-title>
          </mat-expansion-panel-header>

          <div class="calculator-form">
            <!-- Coordinate inputs and calculation -->
          </div>
        </mat-expansion-panel>

        <!-- Fee Ranges Table -->
        <div class="ranges-table">
          <table mat-table [dataSource]="ranges" class="full-width-table">
            <ng-container matColumnDef="distance">
              <th mat-header-cell *matHeaderCellDef>Distance Range (km)</th>
              <td mat-cell *matCellDef="let range">
                {{range.minDistanceKm}} - {{range.maxDistanceKm || '∞'}}
              </td>
            </ng-container>

            <ng-container matColumnDef="fee">
              <th mat-header-cell *matHeaderCellDef>Delivery Fee</th>
              <td mat-cell *matCellDef="let range">₹{{range.deliveryFee}}</td>
            </ng-container>

            <ng-container matColumnDef="commission">
              <th mat-header-cell *matHeaderCellDef>Partner Commission</th>
              <td mat-cell *matCellDef="let range">₹{{range.partnerCommission}}</td>
            </ng-container>

            <ng-container matColumnDef="actions">
              <th mat-header-cell *matHeaderCellDef>Actions</th>
              <td mat-cell *matCellDef="let range">
                <button mat-icon-button (click)="editRange(range)">
                  <mat-icon>edit</mat-icon>
                </button>
                <button mat-icon-button (click)="toggleStatus(range)">
                  <mat-icon>{{range.isActive ? 'toggle_on' : 'toggle_off'}}</mat-icon>
                </button>
              </td>
            </ng-container>

            <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
            <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
          </table>
        </div>
      </mat-card-content>
    </mat-card>
  `
})
export class DeliveryFeeManagementComponent {
  ranges: DeliveryFeeRange[] = [];
  displayedColumns: string[] = ['distance', 'fee', 'commission', 'actions'];

  constructor(private deliveryFeeService: DeliveryFeeService) {}

  ngOnInit(): void {
    this.loadRanges();
  }

  loadRanges(): void {
    this.deliveryFeeService.getAllRanges().subscribe(ranges => {
      this.ranges = ranges;
    });
  }
}
```

### Integration Points

#### Order Assignment Integration
```java
@Service
public class OrderAssignmentService {

    public void assignOrderToDeliveryPartner(Order order, DeliveryPartner partner) {
        // Calculate distance between shop and customer
        Double distance = deliveryFeeService.calculateDistance(
            order.getShop().getLatitude().doubleValue(),
            order.getShop().getLongitude().doubleValue(),
            order.getDeliveryLatitude().doubleValue(),
            order.getDeliveryLongitude().doubleValue()
        );

        // Find appropriate fee range and set delivery fee
        DeliveryFeeRange feeRange = deliveryFeeService.findByDistance(distance);
        order.setDeliveryFee(feeRange.getDeliveryFee());

        // Create assignment with partner commission
        OrderAssignment assignment = OrderAssignment.builder()
            .order(order)
            .partner(partner)
            .deliveryFee(feeRange.getDeliveryFee())
            .commission(feeRange.getPartnerCommission())
            .status(AssignmentStatus.ASSIGNED)
            .build();

        orderAssignmentRepository.save(assignment);
        orderRepository.save(order);
    }
}
```

#### Frontend Shop Integration
```typescript
// Shop components updated to show "Distance-based pricing" instead of fixed fees
export class ShopCardComponent {
  // In shop-card.component.ts line 79
  getDeliveryInfo(): string {
    return "Distance-based pricing"; // Replaces: `₹${shop.deliveryFee}`
  }
}
```

### Security Implementation

#### Super Admin Access Control
```java
@RestController
@RequestMapping("/api/super-admin/delivery-fee-ranges")
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminDeliveryFeeController {

    @PostMapping
    public ResponseEntity<Map<String, Object>> createRange(@RequestBody DeliveryFeeRange range) {
        // Validation and creation logic
        validateRangeOverlap(range);
        DeliveryFeeRange savedRange = deliveryFeeRangeRepository.save(range);

        return ResponseEntity.ok(Map.of(
            "success", true,
            "message", "Delivery fee range created successfully",
            "data", savedRange
        ));
    }

    private void validateRangeOverlap(DeliveryFeeRange newRange) {
        List<DeliveryFeeRange> existingRanges = deliveryFeeRangeRepository.findByIsActiveTrue();
        // Check for overlapping ranges and throw exception if found
    }
}
```

### Performance Considerations

#### Caching Strategy
```java
@Service
public class DeliveryFeeService {

    @Cacheable(value = "deliveryFeeRanges", key = "'all'")
    public List<DeliveryFeeRange> getAllActiveRanges() {
        return deliveryFeeRangeRepository.findByIsActiveTrueOrderByMinDistanceKm();
    }

    @CacheEvict(value = "deliveryFeeRanges", allEntries = true)
    public DeliveryFeeRange saveRange(DeliveryFeeRange range) {
        return deliveryFeeRangeRepository.save(range);
    }
}
```

#### Database Optimization
```sql
-- Efficient range lookup query with proper indexing
SELECT id, min_distance_km, max_distance_km, delivery_fee, partner_commission
FROM delivery_fee_ranges
WHERE is_active = true
  AND min_distance_km <= ?
  AND (max_distance_km IS NULL OR max_distance_km >= ?)
ORDER BY min_distance_km
LIMIT 1;
```

### Sample Calculations

#### Distance-Fee Examples
| Distance | Range Selected | Customer Pays | Partner Gets | Platform Keeps |
|----------|---------------|---------------|--------------|----------------|
| 3 km     | 0-5 km       | ₹20          | ₹15         | ₹5            |
| 7 km     | 5-10 km      | ₹40          | ₹30         | ₹10           |
| 15 km    | 10-20 km     | ₹60          | ₹45         | ₹15           |
| 25 km    | 20+ km       | ₹100         | ₹75         | ₹25           |

### Business Benefits

#### Advantages Over Fixed Shop Fees
```yaml
Fairness:
  - Customers pay based on actual delivery distance
  - No arbitrary shop-based pricing differences
  - Transparent and predictable pricing

Scalability:
  - Easy to add new distance ranges
  - Centralized fee management
  - Consistent pricing across all shops

Partner Incentives:
  - Higher commission for longer distances
  - Fair compensation for delivery effort
  - Reduced rejection of distant orders

Platform Revenue:
  - Optimized pricing strategy
  - Distance-based margin optimization
  - Reduced customer complaints about pricing
```

---

**📋 Document Status**
- **Created**: January 2025
- **Version**: 1.2
- **Last Updated**: September 2025 - Added Distance-Based Delivery Fee System
- **Next Review**: When additional delivery features are added
- **Maintainer**: Development Team

**🔄 Change Log**
- v1.0: Initial comprehensive architecture documentation
- Added detailed database schema with all tables
- Included complete system diagrams
- Added deployment and scalability considerations
- v1.1: Added Delivery Partner Document Management System
- Included document management components and workflows
- Added security implementation details
- Added performance optimization strategies
- v1.2: Added Distance-Based Delivery Fee System
- Comprehensive delivery fee calculation architecture
- Database schema changes and migration details
- Super admin management interface
- Integration with order assignment flow
- Performance optimizations and caching strategy
- v1.3: Added Firebase Notification System
- Complete FCM integration across platforms
- Real-time push notification architecture
- Notification management and monitoring

---

## 🔔 Firebase Notification System

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────────┐
│                  Firebase Cloud Messaging (FCM)                 │
│                      Notification System                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Backend    │────►│   Firebase   │────►│   Clients    │
│  Spring Boot │     │     FCM      │     │              │
│              │     │              │     │ - Angular    │
│ - Events     │     │ - Message    │     │ - Flutter    │
│ - Triggers   │     │   Routing    │     │ - iOS/Android│
│ - Token Mgmt │     │ - Delivery   │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Component Integration

#### Backend Services
```java
FirebaseService.java
├── sendNotificationToUser(userId, title, body)
├── sendNotificationToShop(shopId, notification)
├── sendBulkNotifications(tokens[], message)
└── removeExpiredTokens()

NotificationTriggerService.java
├── onOrderPlaced(order) → Shop notification
├── onOrderAccepted(order) → Customer notification
├── onOrderStatusChange(order, status)
├── onDeliveryAssignment(assignment) → Partner notification
└── onPaymentSuccess(payment) → Confirmation notifications
```

#### Database Schema
```sql
-- FCM Token Management
CREATE TABLE user_fcm_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL,
    device_type VARCHAR(50),
    device_info TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_fcm_user_id ON user_fcm_tokens(user_id);
CREATE INDEX idx_fcm_token ON user_fcm_tokens(token);
CREATE INDEX idx_fcm_active ON user_fcm_tokens(is_active);
```

### Notification Flow Diagrams

#### Order Notification Flow
```
Customer Places Order
        │
        ▼
Backend Creates Order
        │
        ▼
NotificationTriggerService.onOrderPlaced()
        │
        ├─────► FirebaseService.sendNotificationToShop()
        │              │
        │              ▼
        │       Get Shop Owner FCM Tokens
        │              │
        │              ▼
        │       Send via Firebase Admin SDK
        │              │
        │              ▼
        │       Shop Owner Devices Receive Push
        │
        └─────► EmailService.sendOrderEmail()
```

#### Real-time Notification Updates
```
┌──────────────────────────────────────────────┐
│           Shop Owner Dashboard               │
│                                              │
│  ┌────────────────────────────────────┐     │
│  │    Notification Bell Icon 🔔       │     │
│  │    Badge: 3 unread                 │     │
│  └────────────────────────────────────┘     │
│                    │                         │
│                    ▼                         │
│  ┌────────────────────────────────────┐     │
│  │    Notification Center              │     │
│  │                                     │     │
│  │ • New Order #1234 - ₹500           │     │
│  │ • Order #1233 Delivered            │     │
│  │ • Order #1232 Cancelled            │     │
│  └────────────────────────────────────┘     │
└──────────────────────────────────────────────┘
```

### Frontend Implementation

#### Angular Service Structure
```typescript
FirebaseService.ts
├── requestPermission()
├── getToken() → Register with backend
├── onMessageReceived() → Handle foreground
├── showNotification(title, body)
└── debouncing → Prevent duplicates

NotificationOrchestratorService.ts
├── handleNotification(event)
├── routeToChannel(firebase/email/sms)
├── updateNotificationUI()
└── syncWithBackend()
```

#### Flutter Mobile Implementation
```dart
FirebaseNotificationService.dart
├── initialize()
├── getToken() → Store in backend
├── setupMessageHandlers()
│   ├── onMessage → Foreground
│   ├── onBackgroundMessage → Background
│   └── onMessageOpenedApp → Tap action
└── showLocalNotification()
```

### Notification Types & Templates

| Event | Recipient | Title | Body | Priority |
|-------|-----------|-------|------|----------|
| Order Placed | Shop Owner | 🆕 New Order | Order #1234 from {customer} - ₹{amount} | High |
| Order Accepted | Customer | ✅ Order Accepted | Your order is being prepared | High |
| Out for Delivery | Customer | 🚚 Out for Delivery | Your order is on the way! | High |
| Order Delivered | Customer | ✔️ Delivered | Order successfully delivered | Medium |
| Order Cancelled | Both | ❌ Cancelled | Order #{id} has been cancelled | High |
| Order Returned | Shop | ↩️ Returned | Order #{id} returned by customer | High |

### Performance & Optimization

#### Caching Strategy
```yaml
Token Cache:
  - Redis cache for FCM tokens
  - 15-minute TTL
  - Reduces database queries

Notification Queue:
  - RabbitMQ for high volume
  - Batch processing (500 max)
  - Retry mechanism for failures

Debouncing:
  - 1-second minimum gap
  - Prevents duplicate sounds
  - Client-side implementation
```

#### Monitoring & Analytics
```
Metrics Tracked:
- Delivery success rate
- Token expiration rate
- Click-through rate
- Device type distribution
- Peak notification hours

Logging:
- INFO: Notification sent to user {id}
- WARN: FCM token expired for {id}
- ERROR: Failed to deliver: {reason}
```

### Security Considerations

1. **Token Security**
   - Encrypted storage in database
   - HTTPS-only transmission
   - Regular token rotation

2. **Authentication**
   - JWT validation before token registration
   - User-device binding
   - Rate limiting on endpoints

3. **Privacy**
   - No sensitive data in notifications
   - User preference management
   - GDPR compliance for EU users

### Configuration Files

#### Firebase Configuration
```json
// firebase-service-account.json
{
  "type": "service_account",
  "project_id": "grocery-5ecc5",
  "private_key_id": "***",
  "private_key": "***",
  "client_email": "firebase-adminsdk@grocery-5ecc5.iam.gserviceaccount.com"
}

// google-services.json (Android)
{
  "project_info": {
    "project_number": "368788713881",
    "project_id": "grocery-5ecc5"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "1:368788713881:android:7c1dba64bacddbfd866308",
      "android_client_info": {
        "package_name": "com.nammaooru.app"
      }
    }
  }]
}
```

### API Endpoints

```yaml
Notification APIs:
  POST /api/firebase/register-token:
    - Register FCM token
    - Body: { token, deviceType, deviceInfo }

  DELETE /api/firebase/unregister-token:
    - Remove FCM token
    - Body: { token }

  POST /api/firebase/send-notification:
    - Send manual notification
    - Body: { userId, title, body, data }

  GET /api/firebase/test-notification:
    - Send test notification to logged user

  GET /api/notifications/unread-count:
    - Get unread notification count
```

### Troubleshooting Guide

| Issue | Cause | Solution |
|-------|-------|----------|
| No notifications received | Permission denied | Check browser/app permissions |
| Duplicate sounds | Multiple listeners | Implement debouncing |
| Token expired | Old token | Auto-refresh mechanism |
| Service worker error | HTTPS required | Use HTTPS or localhost |
| iOS not working | APNs not configured | Configure Apple Push Notification service |

### Future Enhancements

1. **Rich Notifications**
   - Product images in notifications
   - Action buttons (Accept/Reject)
   - Custom notification sounds

2. **Advanced Analytics**
   - Conversion tracking
   - A/B testing for messages
   - User engagement metrics

3. **Segmentation**
   - Location-based notifications
   - User preference targeting
   - Scheduled campaigns

4. **Additional Channels**
   - WhatsApp Business API
   - SMS fallback
   - Email digest options

---

## 📱 App Version Management System

### Overview
The app version management system allows centralized control of mobile app versions, enabling forced updates and gradual rollouts. This is critical for the customer app which receives frequent updates.

### Database Schema

**app_version** - Mobile app version control
```sql
CREATE TABLE app_version (
    id BIGSERIAL PRIMARY KEY,
    app_name VARCHAR(50) NOT NULL,      -- CUSTOMER_APP, SHOP_OWNER_APP, DELIVERY_PARTNER_APP
    platform VARCHAR(20) NOT NULL,       -- ANDROID, IOS
    current_version VARCHAR(20) NOT NULL,   -- Latest available version (e.g., '1.2.0')
    minimum_version VARCHAR(20) NOT NULL,   -- Minimum required version (e.g., '1.0.0')
    update_url TEXT NOT NULL,            -- Play Store / App Store URL
    is_mandatory BOOLEAN DEFAULT false,  -- Force update even if above minimum
    release_notes TEXT,                  -- What's new in this version
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(app_name, platform)
);

CREATE INDEX idx_app_version_lookup ON app_version(app_name, platform);
```

### System Flow

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Mobile App  │         │   Backend    │         │  Play Store  │
│ (v1.0.0)     │         │   API        │         │  (v1.2.0)    │
└──────┬───────┘         └──────┬───────┘         └──────┬───────┘
       │                        │                        │
       │  1. Check Version      │                        │
       │ ─────────────────────> │                        │
       │  GET /api/app-version  │                        │
       │  /check?appName=       │                        │
       │  CUSTOMER_APP&         │                        │
       │  platform=ANDROID&     │                        │
       │  currentVersion=1.0.0  │                        │
       │                        │                        │
       │  2. Compare Versions   │                        │
       │    <───────────────    │                        │
       │  {                     │                        │
       │    updateRequired:true │                        │
       │    currentVersion:1.2.0│                        │
       │    updateUrl:...       │                        │
       │  }                     │                        │
       │                        │                        │
       │  3. Show Update Dialog │                        │
       │    (Mandatory)         │                        │
       │                        │                        │
       │  4. User Clicks Update │                        │
       │ ──────────────────────────────────────────────> │
       │                   Open Play Store               │
       │                        │                        │
```

### API Endpoints

#### Version Check
```
GET /api/app-version/check
Query Parameters:
  - appName: CUSTOMER_APP | SHOP_OWNER_APP | DELIVERY_PARTNER_APP
  - platform: ANDROID | IOS
  - currentVersion: Semantic version (e.g., 1.0.0)

Response:
{
  "updateRequired": false,      // Below minimum version
  "updateAvailable": true,       // New version available
  "isMandatory": false,          // Force update flag
  "currentVersion": "1.2.0",    // Latest available
  "minimumVersion": "1.0.0",    // Minimum required
  "updateUrl": "https://play.google.com/store/apps/details?id=com.nammaooru.app",
  "releaseNotes": "• New features\n• Bug fixes\n• Performance improvements"
}
```

#### Update Version (Admin)
```
PUT /api/app-version/update
Authorization: Bearer <admin_token>
Body:
{
  "appName": "CUSTOMER_APP",
  "platform": "ANDROID",
  "currentVersion": "1.2.0",
  "minimumVersion": "1.1.0",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.nammaooru.app",
  "isMandatory": false,
  "releaseNotes": "What's new in this version..."
}
```

### Mobile Integration

#### Customer App
```dart
// lib/core/services/app_update_service.dart
class AppUpdateService {
  static const String APP_NAME = 'CUSTOMER_APP';
  static const String APP_VERSION = '1.0.0';

  static Future<void> showUpdateDialogIfNeeded(BuildContext context) async {
    final updateInfo = await checkForUpdate();
    // Show dialog if update available
  }
}

// lib/features/customer/dashboard/customer_dashboard.dart
@override
void initState() {
  super.initState();
  _checkForAppUpdates();  // Check on app startup
}

Future<void> _checkForAppUpdates() async {
  await Future.delayed(const Duration(seconds: 2));
  if (mounted) {
    AppUpdateService.showUpdateDialogIfNeeded(context);
  }
}
```

#### Shop Owner App
```dart
// Same integration pattern as customer app
// APP_NAME = 'SHOP_OWNER_APP'
```

### Update Scenarios

#### Scenario 1: Below Minimum Version (Force Update)
```
Current App Version: 0.9.0
Minimum Version: 1.0.0
Latest Version: 1.2.0
Result: Mandatory update - Cannot skip dialog
```

#### Scenario 2: Optional Update Available
```
Current App Version: 1.0.0
Minimum Version: 1.0.0
Latest Version: 1.2.0
is_mandatory: false
Result: Optional update - Can skip dialog
```

#### Scenario 3: Mandatory Flag Set
```
Current App Version: 1.1.0
Minimum Version: 1.0.0
Latest Version: 1.2.0
is_mandatory: true
Result: Mandatory update - Cannot skip dialog
```

#### Scenario 4: Up to Date
```
Current App Version: 1.2.0
Minimum Version: 1.0.0
Latest Version: 1.2.0
Result: No dialog shown
```

### Version Comparison Logic

```java
private boolean isUpdateRequired(String currentVersion, String requiredVersion) {
    String[] current = currentVersion.split("\\.");
    String[] required = requiredVersion.split("\\.");

    for (int i = 0; i < Math.max(current.length, required.length); i++) {
        int currentPart = i < current.length ? Integer.parseInt(current[i]) : 0;
        int requiredPart = i < required.length ? Integer.parseInt(required[i]) : 0;

        if (currentPart < requiredPart) return true;
        if (currentPart > requiredPart) return false;
    }

    return false;  // Versions are equal
}
```

### Deployment Process

1. **Update App Code**
   - Increment version in `app_update_service.dart`
   - Update `pubspec.yaml` version

2. **Build and Release**
   - Build APK/AAB: `flutter build apk --release`
   - Upload to Play Store
   - Wait for review and approval

3. **Update Database**
   ```sql
   UPDATE app_version
   SET current_version = '1.2.0',
       minimum_version = '1.0.0',  -- Only if forcing older users
       is_mandatory = false,        -- true to force all users
       release_notes = '• New features\n• Bug fixes',
       updated_at = NOW()
   WHERE app_name = 'CUSTOMER_APP' AND platform = 'ANDROID';
   ```

4. **Monitor Rollout**
   - Check user adoption rates
   - Monitor crash reports
   - Adjust minimum_version if needed

### Best Practices

1. **Semantic Versioning**: Use MAJOR.MINOR.PATCH format
2. **Minimum Version Strategy**: Keep 2-3 versions behind current
3. **Mandatory Updates**: Only for critical security/API changes
4. **Release Notes**: Write clear, user-friendly descriptions
5. **Testing**: Test update flow before releasing to production

### Current Versions

| App | Platform | Current Version | Minimum Version | Status |
|-----|----------|----------------|-----------------|--------|
| CUSTOMER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |
| SHOP_OWNER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |
| DELIVERY_PARTNER_APP | ANDROID | 1.0.0 | 1.0.0 | Active |

### Security Considerations

1. **Rate Limiting**: Prevent API abuse for version checks
2. **Token Validation**: Require admin token for version updates
3. **Version Format**: Validate semantic version format
4. **URL Validation**: Ensure update URLs point to official stores
5. **Audit Logging**: Track all version changes

### Future Enhancements

1. **Admin Dashboard**: Web UI for version management
2. **Gradual Rollout**: Release to percentage of users first
3. **Analytics**: Track version adoption rates
4. **In-App Updates**: Use Play Core API for seamless updates
5. **Regional Updates**: Different URLs per country/region
6. **A/B Testing**: Test updates with subset of users

---

This document serves as the definitive technical reference for the NammaOoru Thiru Software System architecture.
