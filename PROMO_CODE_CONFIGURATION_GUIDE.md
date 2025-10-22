# Promo Code Configuration Guide

## ✅ Already Configurable! (Promotion-Level)

The promo code system is **ALREADY FULLY CONFIGURABLE** per promotion. Each promo code can have different settings.

---

## 📋 Current Configuration Options

### Every promo code in the `promotions` table has these configurable fields:

```sql
CREATE TABLE promotions (
    -- Basic Info
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,        -- e.g., "FIRST5", "SAVE20"
    title VARCHAR(200) NOT NULL,
    description TEXT,

    -- Discount Configuration
    type VARCHAR(20) NOT NULL,               -- PERCENTAGE, FIXED_AMOUNT, FREE_SHIPPING
    discount_value DECIMAL(10,2) NOT NULL,   -- e.g., 50.00 or 20 (for percentage)
    minimum_order_amount DECIMAL(10,2),      -- e.g., 200.00 (min ₹200 to use code)
    maximum_discount_amount DECIMAL(10,2),   -- e.g., 100.00 (max discount cap)

    -- Usage Limits (CONFIGURABLE!)
    usage_limit INTEGER,                     -- Total uses allowed (NULL = unlimited)
    usage_limit_per_customer INTEGER,        -- Per customer limit (NULL = unlimited)
    used_count INTEGER DEFAULT 0,            -- Auto-tracked

    -- Date Range (CONFIGURABLE!)
    start_date TIMESTAMP NOT NULL,           -- When promo starts
    end_date TIMESTAMP NOT NULL,             -- When promo expires

    -- Status (CONFIGURABLE!)
    status VARCHAR(20) NOT NULL,             -- ACTIVE, INACTIVE, EXPIRED, SUSPENDED

    -- Targeting (CONFIGURABLE!)
    shop_id BIGINT,                          -- NULL = all shops, or specific shop
    target_audience VARCHAR(50),             -- e.g., "new_users", "vip_customers"

    -- Special Rules (CONFIGURABLE!)
    is_public BOOLEAN DEFAULT TRUE,          -- Show in app?
    is_first_time_only BOOLEAN DEFAULT FALSE,-- Only for first order?
    stackable BOOLEAN DEFAULT FALSE,         -- Can combine with other promos?

    -- Images
    image_url VARCHAR(500),
    banner_url VARCHAR(500),

    -- Terms
    terms_and_conditions TEXT,

    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);
```

---

## 🎯 Configuration Examples

### Example 1: First 5 Orders Promo (Configurable Limit)
```sql
INSERT INTO promotions (
    code, title, description, type, discount_value,
    minimum_order_amount, maximum_discount_amount,
    usage_limit, usage_limit_per_customer,  -- ← CONFIGURABLE
    start_date, end_date, status,
    is_first_time_only, is_public
) VALUES (
    'FIRST5',                               -- Code
    'First 5 Orders - ₹50 Off',             -- Title
    'Get ₹50 off on your first 5 orders',   -- Description
    'FIXED_AMOUNT',                         -- Type
    50.00,                                  -- Discount
    200.00,                                 -- Min order ₹200
    50.00,                                  -- Max discount ₹50
    NULL,                                   -- Total limit: UNLIMITED
    5,                                      -- Per customer: 5 TIMES ← CONFIG
    '2025-01-01 00:00:00',                  -- Start date
    '2025-12-31 23:59:59',                  -- End date
    'ACTIVE',                               -- Status
    FALSE,                                  -- Not first-time only
    TRUE                                    -- Public/visible
);
```

**To change to 10 orders instead of 5:**
```sql
UPDATE promotions
SET usage_limit_per_customer = 10  -- Change 5 → 10
WHERE code = 'FIRST5';
```

### Example 2: First-Time User Only
```sql
INSERT INTO promotions (
    code, title, type, discount_value,
    minimum_order_amount,
    usage_limit_per_customer,  -- ← CONFIG: Only 1 time
    start_date, end_date, status,
    is_first_time_only         -- ← CONFIG: First order only
) VALUES (
    'WELCOME100',
    'Welcome - ₹100 Off First Order',
    'FIXED_AMOUNT',
    100.00,
    300.00,
    1,                         -- Only 1 time per customer
    '2025-01-01 00:00:00',
    '2025-12-31 23:59:59',
    'ACTIVE',
    TRUE                       -- ← Only for first-time users
);
```

### Example 3: Unlimited Usage Promo
```sql
INSERT INTO promotions (
    code, title, type, discount_value,
    minimum_order_amount,
    usage_limit_per_customer,  -- ← CONFIG: NULL = UNLIMITED
    start_date, end_date, status
) VALUES (
    'SAVE10',
    '₹10 Off on All Orders',
    'FIXED_AMOUNT',
    10.00,
    100.00,
    NULL,                      -- ← NULL = Unlimited uses per customer
    '2025-01-01 00:00:00',
    '2025-12-31 23:59:59',
    'ACTIVE'
);
```

### Example 4: Limited Total Usage (Flash Sale)
```sql
INSERT INTO promotions (
    code, title, type, discount_value,
    minimum_order_amount,
    usage_limit,               -- ← CONFIG: Total 100 uses only
    usage_limit_per_customer,  -- ← CONFIG: 1 per customer
    start_date, end_date, status
) VALUES (
    'FLASH50',
    'Flash Sale - ₹50 Off (First 100 Only)',
    'FIXED_AMOUNT',
    50.00,
    200.00,
    100,                       -- ← Only 100 total uses
    1,                         -- ← 1 per customer
    '2025-01-23 00:00:00',
    '2025-01-23 23:59:59',     -- Only valid for 1 day
    'ACTIVE'
);
```

### Example 5: Percentage Discount with Cap
```sql
INSERT INTO promotions (
    code, title, type, discount_value,
    minimum_order_amount, maximum_discount_amount,
    usage_limit_per_customer,
    start_date, end_date, status
) VALUES (
    'SAVE20',
    '20% Off (Max ₹200)',
    'PERCENTAGE',              -- ← Percentage type
    20.00,                     -- ← 20% discount
    500.00,                    -- Min ₹500 order
    200.00,                    -- ← Max ₹200 discount (cap)
    3,                         -- 3 times per customer
    '2025-01-01 00:00:00',
    '2025-12-31 23:59:59',
    'ACTIVE'
);
```

---

## 🎛️ How to Change Configuration

### Method 1: Direct SQL (Quick Changes)

**Change per-customer limit:**
```sql
UPDATE promotions
SET usage_limit_per_customer = 10   -- Change to 10
WHERE code = 'FIRST5';
```

**Change discount amount:**
```sql
UPDATE promotions
SET discount_value = 100.00         -- Change to ₹100
WHERE code = 'FIRST5';
```

**Change minimum order:**
```sql
UPDATE promotions
SET minimum_order_amount = 300.00   -- Change to ₹300
WHERE code = 'FIRST5';
```

**Extend expiry date:**
```sql
UPDATE promotions
SET end_date = '2026-12-31 23:59:59'  -- Extend to 2026
WHERE code = 'FIRST5';
```

**Pause a promo:**
```sql
UPDATE promotions
SET status = 'INACTIVE'             -- Pause it
WHERE code = 'FIRST5';
```

**Resume a promo:**
```sql
UPDATE promotions
SET status = 'ACTIVE'               -- Activate it
WHERE code = 'FIRST5';
```

### Method 2: Admin API (Coming Soon - see below)

---

## 🔧 Configuration Scenarios

### Scenario 1: "I want to change FIRST5 from 5 orders to 10 orders"

**Solution:**
```sql
UPDATE promotions
SET usage_limit_per_customer = 10
WHERE code = 'FIRST5';
```

✅ Done! Now customers can use it 10 times instead of 5.

---

### Scenario 2: "I want to make it unlimited for all customers"

**Solution:**
```sql
UPDATE promotions
SET usage_limit_per_customer = NULL  -- NULL = unlimited
WHERE code = 'FIRST5';
```

✅ Done! Now any customer can use it unlimited times.

---

### Scenario 3: "I want to change discount from ₹50 to ₹75"

**Solution:**
```sql
UPDATE promotions
SET discount_value = 75.00
WHERE code = 'FIRST5';
```

✅ Done! Now discount is ₹75 instead of ₹50.

---

### Scenario 4: "I want to make it first-time users only"

**Solution:**
```sql
UPDATE promotions
SET is_first_time_only = TRUE,
    usage_limit_per_customer = 1
WHERE code = 'FIRST5';
```

✅ Done! Now only first-time customers can use it once.

---

### Scenario 5: "I want to limit total usage to 500 customers"

**Solution:**
```sql
UPDATE promotions
SET usage_limit = 500  -- Only 500 total uses
WHERE code = 'FIRST5';
```

✅ Done! After 500 uses, promo will be invalid for everyone.

---

### Scenario 6: "I want to make it shop-specific (only for Shop ID 5)"

**Solution:**
```sql
UPDATE promotions
SET shop_id = 5  -- Only valid at Shop ID 5
WHERE code = 'FIRST5';
```

✅ Done! Now only works at shop 5.

---

## 🖥️ Admin Panel Configuration (Recommended)

### Create an Admin UI to manage these settings:

```
┌──────────────────────────────────────────────────────┐
│          EDIT PROMO CODE                             │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Code: [FIRST5________________]                      │
│  Title: [First 5 Orders - ₹50 Off____________]      │
│                                                      │
│  Discount Type:                                      │
│  ◉ Fixed Amount  ○ Percentage  ○ Free Shipping      │
│                                                      │
│  Discount Value: [₹ 50.00_____]                     │
│  Min Order Amount: [₹ 200.00___]                    │
│  Max Discount: [₹ 50.00_____]                       │
│                                                      │
│  📊 Usage Limits:                                    │
│  Total Usage Limit: [Unlimited ▼] or [100____]      │
│  Per Customer Limit: [5_______]  ← CONFIGURABLE     │
│                                                      │
│  📅 Date Range:                                      │
│  Start: [2025-01-01___] End: [2025-12-31___]        │
│                                                      │
│  🎯 Targeting:                                       │
│  ☐ First-time customers only                        │
│  ☐ Specific shop: [Select Shop ▼]                   │
│  ☑ Public (visible in app)                          │
│                                                      │
│  Status: [Active ▼]                                  │
│                                                      │
│  [Cancel]              [Save Changes]                │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 📊 Quick Reference Table

| Configuration | Field Name | Example Values | Effect |
|---------------|------------|----------------|--------|
| **Per Customer Limit** | `usage_limit_per_customer` | `1`, `5`, `10`, `NULL` | How many times EACH customer can use |
| **Total Limit** | `usage_limit` | `100`, `500`, `NULL` | Total uses across ALL customers |
| **Minimum Order** | `minimum_order_amount` | `200.00`, `500.00` | Min cart value required |
| **Discount** | `discount_value` | `50.00`, `20` (%) | Discount amount or percentage |
| **Max Discount** | `maximum_discount_amount` | `100.00`, `200.00` | Cap for percentage discounts |
| **Date Range** | `start_date`, `end_date` | `2025-01-01`, `2025-12-31` | When promo is valid |
| **Status** | `status` | `ACTIVE`, `INACTIVE`, `EXPIRED` | Enable/disable promo |
| **First-Time Only** | `is_first_time_only` | `TRUE`, `FALSE` | Only for new customers |
| **Shop Specific** | `shop_id` | `1`, `5`, `NULL` | Limit to specific shop |
| **Type** | `type` | `FIXED_AMOUNT`, `PERCENTAGE` | Discount calculation method |

---

## 🎮 Real-Time Configuration Changes

**Important:** Changes take effect **IMMEDIATELY** - no app restart needed!

1. Admin updates config in database
2. Next API call uses new settings
3. Customers see changes instantly

**Example:**
```
10:00 AM - FIRST5 has limit of 5 uses
10:05 AM - Admin changes to 10 uses
10:06 AM - Customer validates code → sees new limit of 10 uses ✅
```

---

## 🚀 Admin API Endpoints (To Be Created)

### Create/Update Promotion
```
POST /api/admin/promotions
PUT /api/admin/promotions/{id}

Body:
{
  "code": "FIRST5",
  "title": "First 5 Orders",
  "type": "FIXED_AMOUNT",
  "discountValue": 50.00,
  "minimumOrderAmount": 200.00,
  "usageLimitPerCustomer": 5,  ← CONFIGURABLE
  "usageLimit": null,           ← CONFIGURABLE
  "startDate": "2025-01-01T00:00:00",
  "endDate": "2025-12-31T23:59:59",
  "status": "ACTIVE",
  "isFirstTimeOnly": false,
  "shopId": null
}
```

### Quick Config Update
```
PATCH /api/admin/promotions/{id}/config

Body:
{
  "usageLimitPerCustomer": 10,  ← Just change the limit
}
```

---

## 💡 Best Practices

### 1. Use NULL for Unlimited
```sql
usage_limit_per_customer = NULL  -- Unlimited per customer
usage_limit = NULL                -- Unlimited total
```

### 2. Set Both Limits for Flash Sales
```sql
usage_limit = 100                 -- Only 100 total uses
usage_limit_per_customer = 1      -- 1 per customer
```

### 3. Use First-Time Flag Wisely
```sql
is_first_time_only = TRUE         -- Only for new customers
usage_limit_per_customer = 1      -- Automatically enforces 1 use
```

### 4. Set Minimum Orders
```sql
minimum_order_amount = 200.00     -- Prevents abuse on small orders
```

### 5. Cap Percentage Discounts
```sql
type = 'PERCENTAGE'
discount_value = 20.00            -- 20%
maximum_discount_amount = 200.00  -- Cap at ₹200
```

---

## 🎯 Summary

### ✅ What's ALREADY Configurable:
- ✅ Per-customer usage limit (1, 5, 10, unlimited)
- ✅ Total usage limit (100, 500, unlimited)
- ✅ Discount amount (₹50, ₹100, 20%, etc.)
- ✅ Minimum order amount
- ✅ Maximum discount cap
- ✅ Date range (start/end)
- ✅ Status (active/inactive)
- ✅ First-time only flag
- ✅ Shop-specific or global
- ✅ Public visibility

### 🔧 How to Change:
1. **Direct SQL** - Quick changes via database
2. **Admin API** - RESTful API (to be created)
3. **Admin Panel** - Web UI (recommended for non-technical users)

### 📝 No Code Changes Needed:
- All settings are in database
- Changes take effect immediately
- No app restart required

Would you like me to:
1. Create the Admin API endpoints for managing promotions?
2. Build an Admin Panel UI for easy configuration?
3. Add more configuration options?
