# 🏗️ NammaOoru Shop Management System - Technical Architecture

## 📋 Document Overview

**Purpose**: Comprehensive technical architecture documentation with detailed system diagrams and database schema  
**Audience**: Developers, System Architects, DevOps Engineers, Technical Stakeholders  
**Last Updated**: January 2025  

---

## 🌐 System Architecture Diagram

### High-Level System Overview
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           NammaOoru Shop Management System                          │
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

#### 2. Shop Management Tables

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

### Delivery Partner Mobile App - Complete System Architecture & Flow

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

**📋 Document Status**  
- **Created**: January 2025
- **Version**: 1.0  
- **Next Review**: When system architecture changes
- **Maintainer**: Development Team

**🔄 Change Log**  
- v1.0: Initial comprehensive architecture documentation
- Added detailed database schema with all tables
- Included complete system diagrams
- Added deployment and scalability considerations

This document serves as the definitive technical reference for the NammaOoru Shop Management System architecture.