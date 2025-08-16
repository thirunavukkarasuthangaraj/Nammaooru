# Shop Management System - Flow Structure

## 🏗️ System Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │   Database      │
│   Angular       │◄──►│  Spring Boot    │◄──►│  PostgreSQL     │
│   Port: 4201    │    │  Port: 8082     │    │  Port: 5432     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔐 Authentication Flow

```
User Registration/Login
        │
        ▼
┌─────────────────┐
│ AuthController  │ ──► JWT Token Generation
│ /api/auth/*     │     │
└─────────────────┘     ▼
        │          ┌─────────────────┐
        │          │ SecurityConfig  │ ──► Role-based Access
        │          │ JWT Filter      │
        ▼          └─────────────────┘
┌─────────────────┐
│ User Entity     │ ──► ADMIN / SHOP_OWNER / USER
│ BCrypt Password │
└─────────────────┘
```

## 🏪 Shop Management Flow

```
Shop Owner Registration
        │
        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ User Creation   │───►│ Shop Creation   │───►│ Shop Settings   │
│ Role: SHOP_OWNER│    │ Auto-linked     │    │ Business Hours  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Email Welcome   │    │ Shop Dashboard  │    │ Analytics Setup │
│ Notification    │    │ Access Control  │    │ Reporting       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📦 Product Management Flow

```
Product Catalog Structure:
        
┌─────────────────┐
│ Product Category│ ──► Electronics, Fashion, etc.
│ /api/categories │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Master Product  │ ──► Global product templates
│ /api/products/  │     (Samsung Galaxy S24, etc.)
│ master          │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Shop Product    │ ──► Shop-specific pricing & inventory
│ /api/shops/{id}/│     (Price: ₹75,000, Stock: 25)
│ products        │
└─────────────────┘
```

## 📋 Product Addition Flow

```
Admin/Manager Creates Master Product
        │
        ▼
┌─────────────────┐
│ MasterProduct   │ ──► Name, SKU, Description, Category
│ Controller      │     Brand, Specifications
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Shop Owner      │ ──► Adds to their shop with:
│ Adds Product    │     • Custom pricing
│                 │     • Inventory levels
└─────────────────┘     • Shop-specific details
        │
        ▼
┌─────────────────┐
│ ShopProduct     │ ──► Final product in shop
│ Entity Created  │     Ready for customers
└─────────────────┘
```

## 🛒 Customer Order Flow

```
Customer Browses Products
        │
        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Product Search  │───►│ Add to Cart     │───►│ Checkout Process│
│ Filter & Sort   │    │ Quantity Select │    │ Address & Pay   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Stock Check     │    │ Price Calculate │    │ Order Creation  │
│ Availability    │    │ Discount Apply  │    │ Inventory Update│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 Data Flow Structure

```
Database Relationships:

users ──────────┐
│               │
│ (1:1)         │ (1:many)
▼               ▼
shops ──────► shop_products ◄──── master_products ◄──── product_categories
│                    │                   │                      │
│ (1:many)           │ (many:1)          │ (many:1)            │
▼                    ▼                   ▼                      ▼
orders ──────► order_items        specifications        category_hierarchy
│
│ (1:many)
▼
customers ──────► customer_addresses
│
│ (1:many)
▼
notifications
```

## 🔄 API Request Flow

```
Frontend Request
        │
        ▼
┌─────────────────┐
│ CORS Filter     │ ──► Allow origin: http://localhost:4201
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ JWT Filter      │ ──► Validate token & extract user
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Security Config │ ──► Check role permissions
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Controller      │ ──► Business logic execution
│ @PreAuthorize   │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Service Layer   │ ──► Data processing & validation
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Repository      │ ──► Database operations
│ JPA/Hibernate   │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Response DTO    │ ──► Formatted JSON response
│ ApiResponse     │
└─────────────────┘
```

## 🎯 Business Logic Flow

```
Inventory Management:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Product Sale    │───►│ Stock Deduction │───►│ Low Stock Alert │
│ Order Placement │    │ Automatic       │    │ Notification    │
└─────────────────┘    └─────────────────┘    └─────────────────┘

Pricing Calculation:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Cost Price      │───►│ Selling Price   │───►│ Profit Margin   │
│ ₹65,000        │    │ ₹75,000        │    │ ₹10,000 (15.4%) │
└─────────────────┘    └─────────────────┘    └─────────────────┘

Discount Application:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Original Price  │───►│ Discount %      │───►│ Final Price     │
│ ₹80,000        │    │ 6.25%          │    │ ₹75,000        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 File Upload Flow

```
Frontend File Selection
        │
        ▼
┌─────────────────┐
│ MultipartFile   │ ──► File validation (size, type)
│ Controller      │
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ File Storage    │ ──► /uploads/products/
│ Directory       │     /uploads/shops/
└─────────────────┘     /uploads/users/
        │
        ▼
┌─────────────────┐
│ URL Generation  │ ──► http://localhost:8082/uploads/...
│ & Database Save │
└─────────────────┘
```

## 📧 Email Notification Flow

```
Trigger Event (User Registration, Order, etc.)
        │
        ▼
┌─────────────────┐
│ EmailService    │ ──► SMTP Configuration
│ Async Processing│     (Gmail SMTP)
└─────────────────┘
        │
        ▼
┌─────────────────┐
│ Template Engine │ ──► Thymeleaf templates
│ HTML Generation │     welcome-shop-owner.html
└─────────────────┘     password-reset.html
        │
        ▼
┌─────────────────┐
│ Email Delivery  │ ──► JavaMailSender
│ Status Tracking │
└─────────────────┘
```

## 🚀 Deployment Structure

```
Development Environment:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Frontend Dev    │    │ Backend Dev     │    │ Local Database  │
│ ng serve        │    │ mvn spring-boot │    │ PostgreSQL      │
│ Port: 4201      │    │ :run Port: 8082 │    │ Port: 5432      │
└─────────────────┘    └─────────────────┘    └─────────────────┘

Production Ready:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Nginx/Apache    │    │ JAR Deployment  │    │ Production DB   │
│ Static Files    │    │ java -jar app   │    │ Cloud/Dedicated │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📈 Analytics & Monitoring Flow

```
User Actions ──► Application Logs ──► Analytics Service ──► Dashboard Reports
     │                  │                     │                    │
     ▼                  ▼                     ▼                    ▼
Sales Data ──► Database Metrics ──► Business Intelligence ──► Admin Insights
```

## 🔒 Security Layers

```
1. Frontend ──► Input Validation & Sanitization
2. Network ──► HTTPS/TLS Encryption
3. API ──► JWT Authentication & Authorization
4. Business ──► Role-based Access Control
5. Database ──► SQL Injection Prevention
6. Infrastructure ──► Firewall & Security Groups
```

This flow structure shows how all components work together to create a robust, scalable shop management system! 🎯