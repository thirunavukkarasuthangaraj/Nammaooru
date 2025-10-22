# Promo Code Configuration - Box Model

## 🎛️ Configuration Control Panel (Admin View)

```
╔═══════════════════════════════════════════════════════════════════╗
║                   ADMIN CONFIGURATION PANEL                       ║
╚═══════════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────────────┐
│                     PROMOTIONS TABLE                              │
│                   (Database Configuration)                        │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│  Promo Code: FIRST5                                    [Edit] 📝  │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  📋 BASIC INFO                                              │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │  Code:         FIRST5                                       │ │
│  │  Title:        First 5 Orders - ₹50 Off                    │ │
│  │  Description:  Get ₹50 off on your first 5 orders          │ │
│  │  Status:       [ACTIVE ▼]                                  │ │
│  │                 ↑ CONFIGURABLE                              │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  💰 DISCOUNT SETTINGS                                       │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │  Type:            [FIXED_AMOUNT ▼]                          │ │
│  │                    ↑ CONFIGURABLE                           │ │
│  │                    Options: FIXED_AMOUNT, PERCENTAGE,       │ │
│  │                            FREE_SHIPPING, BUY_ONE_GET_ONE   │ │
│  │                                                              │ │
│  │  Discount Value:  [₹ 50.00 ]                               │ │
│  │                    ↑ CONFIGURABLE (change to ₹75, ₹100)    │ │
│  │                                                              │ │
│  │  Min Order Amt:   [₹ 200.00]                               │ │
│  │                    ↑ CONFIGURABLE (change to ₹300, ₹500)   │ │
│  │                                                              │ │
│  │  Max Discount:    [₹ 50.00 ]                               │ │
│  │                    ↑ CONFIGURABLE (for percentage caps)    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  📊 USAGE LIMITS (MAIN CONFIGURATION)                       │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │                                                              │ │
│  │  Total Usage Limit:                                         │ │
│  │  ○ Unlimited                                                │ │
│  │  ◉ Limited to: [_______] uses                              │ │
│  │                 ↑ CONFIGURABLE                              │ │
│  │                 Example: 100, 500, 1000                     │ │
│  │                                                              │ │
│  │  Per Customer Limit:                                        │ │
│  │  ○ Unlimited                                                │ │
│  │  ◉ Limited to: [   5    ] uses per customer                │ │
│  │                 ↑↑↑↑↑↑↑↑                                    │ │
│  │                 MAIN CONFIG - Change to 1, 10, 20, etc.     │ │
│  │                                                              │ │
│  │  💡 Examples:                                                │ │
│  │  • 1 = One-time use per customer                           │ │
│  │  • 5 = Customer can use 5 times (default)                  │ │
│  │  • 10 = Customer can use 10 times                          │ │
│  │  • NULL = Unlimited uses per customer                      │ │
│  │                                                              │ │
│  │  Current Status:                                            │ │
│  │  📈 Total Used: 45 times                                    │ │
│  │  👥 Unique Customers: 12                                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  📅 DATE RANGE                                              │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │  Start Date:  [2025-01-01 00:00:00] 📅                     │ │
│  │                ↑ CONFIGURABLE                               │ │
│  │                                                              │ │
│  │  End Date:    [2025-12-31 23:59:59] 📅                     │ │
│  │                ↑ CONFIGURABLE (extend or shorten)          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  🎯 TARGETING & RULES                                       │ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │  ☐ First-time customers only                               │ │
│  │     ↑ CONFIGURABLE (toggle on/off)                         │ │
│  │                                                              │ │
│  │  ☑ Public (visible in app)                                 │ │
│  │     ↑ CONFIGURABLE (show/hide from customers)              │ │
│  │                                                              │ │
│  │  ☐ Stackable with other promos                             │ │
│  │     ↑ CONFIGURABLE (allow multiple promos)                 │ │
│  │                                                              │ │
│  │  Shop Specific:                                             │ │
│  │  ○ All Shops (Global)                                       │ │
│  │  ◉ Specific Shop: [Shop 1 - Thiruna Shop ▼]               │ │
│  │                    ↑ CONFIGURABLE                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────┐                  │
│  │  [Cancel]            [Save Changes]        │                  │
│  └────────────────────────────────────────────┘                  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📊 Configuration Flow - How Changes Work

```
┌─────────────────────────────────────────────────────────────────┐
│                    CONFIGURATION WORKFLOW                       │
└─────────────────────────────────────────────────────────────────┘


STEP 1: CURRENT CONFIGURATION
┌──────────────────────────────┐
│  promotions table            │
├──────────────────────────────┤
│  code: "FIRST5"              │
│  usage_limit_per_customer: 5 │ ← Currently 5 uses
│  discount_value: 50.00       │
│  status: ACTIVE              │
└──────────────────────────────┘
           │
           │ Customer Validates
           ↓
┌──────────────────────────────┐
│  Validation Result:          │
│  ✅ Valid (3 uses remaining) │
└──────────────────────────────┘


STEP 2: ADMIN CHANGES CONFIG
┌──────────────────────────────┐
│  Admin Updates:              │
│  usage_limit_per_customer    │
│  FROM: 5                     │
│  TO:   10                    │ ← Change to 10 uses
└──────────────────────────────┘
           │
           │ SQL UPDATE or API call
           ↓
┌──────────────────────────────┐
│  UPDATE promotions           │
│  SET usage_limit_per_        │
│      customer = 10           │
│  WHERE code = 'FIRST5';      │
└──────────────────────────────┘
           │
           │ Instant Effect
           ↓
┌──────────────────────────────┐
│  promotions table            │
├──────────────────────────────┤
│  code: "FIRST5"              │
│  usage_limit_per_customer: 10│ ← NOW 10 uses
│  discount_value: 50.00       │
│  status: ACTIVE              │
└──────────────────────────────┘


STEP 3: NEXT CUSTOMER USES NEW CONFIG
┌──────────────────────────────┐
│  Customer Validates Again    │
└──────────────────────────────┘
           │
           │ Reads from database
           ↓
┌──────────────────────────────┐
│  System checks:              │
│  - Used: 5 times             │
│  - Limit: 10 times (NEW!)    │
│  - Remaining: 5 uses         │
└──────────────────────────────┘
           │
           ↓
┌──────────────────────────────┐
│  Validation Result:          │
│  ✅ Valid (5 uses remaining) │ ← More uses now!
└──────────────────────────────┘
```

---

## 🎯 Configuration Scenarios (Box Models)

### Scenario 1: Change Per-Customer Limit

```
BEFORE                           AFTER
┌─────────────────────┐         ┌─────────────────────┐
│ usage_limit_per_    │         │ usage_limit_per_    │
│ customer = 5        │ ──────→ │ customer = 10       │
│                     │  UPDATE │                     │
│ Customer can use    │         │ Customer can use    │
│ 5 times             │         │ 10 times            │
└─────────────────────┘         └─────────────────────┘

SQL: UPDATE promotions SET usage_limit_per_customer = 10 WHERE code = 'FIRST5';
```

### Scenario 2: Change Discount Amount

```
BEFORE                           AFTER
┌─────────────────────┐         ┌─────────────────────┐
│ discount_value =    │         │ discount_value =    │
│ 50.00               │ ──────→ │ 100.00              │
│                     │  UPDATE │                     │
│ Discount: ₹50       │         │ Discount: ₹100      │
└─────────────────────┘         └─────────────────────┘

SQL: UPDATE promotions SET discount_value = 100.00 WHERE code = 'FIRST5';
```

### Scenario 3: Make Unlimited

```
BEFORE                           AFTER
┌─────────────────────┐         ┌─────────────────────┐
│ usage_limit_per_    │         │ usage_limit_per_    │
│ customer = 5        │ ──────→ │ customer = NULL     │
│                     │  UPDATE │                     │
│ Limited to 5 uses   │         │ UNLIMITED uses      │
└─────────────────────┘         └─────────────────────┘

SQL: UPDATE promotions SET usage_limit_per_customer = NULL WHERE code = 'FIRST5';
```

### Scenario 4: Change Discount Type

```
BEFORE                           AFTER
┌─────────────────────┐         ┌─────────────────────┐
│ type = FIXED_AMOUNT │         │ type = PERCENTAGE   │
│ discount_value = 50 │ ──────→ │ discount_value = 20 │
│                     │  UPDATE │ max_discount = 200  │
│ ₹50 off             │         │ 20% off (max ₹200)  │
└─────────────────────┘         └─────────────────────┘

SQL:
UPDATE promotions
SET type = 'PERCENTAGE',
    discount_value = 20.00,
    maximum_discount_amount = 200.00
WHERE code = 'FIRST5';
```

---

## 🔄 Real-Time Configuration Impact

```
┌─────────────────────────────────────────────────────────────────┐
│                   TIMELINE VIEW                                 │
└─────────────────────────────────────────────────────────────────┘

10:00 AM
┌──────────────────────────────┐
│ Config: limit = 5            │
│ Status: Customer has used    │
│         4 times              │
│ Result: ✅ 1 use remaining   │
└──────────────────────────────┘

10:05 AM - ADMIN CHANGES CONFIG
┌──────────────────────────────┐
│ UPDATE: limit = 10           │ ← Admin changes to 10
└──────────────────────────────┘
         ↓
┌──────────────────────────────┐
│ Database Updated ✅          │
└──────────────────────────────┘

10:06 AM - CUSTOMER VALIDATES AGAIN
┌──────────────────────────────┐
│ Config: limit = 10 (NEW!)    │
│ Status: Customer has used    │
│         4 times              │
│ Result: ✅ 6 uses remaining  │ ← More uses now!
└──────────────────────────────┘

10:15 AM - CUSTOMER USES 5TH TIME
┌──────────────────────────────┐
│ Config: limit = 10           │
│ Status: Customer has used    │
│         5 times              │
│ Result: ✅ 5 uses remaining  │
└──────────────────────────────┘
```

---

## 🎮 Admin Control Panel (Detailed)

```
╔═══════════════════════════════════════════════════════════════════╗
║                  PROMO CODE MANAGEMENT                            ║
╚═══════════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────────────┐
│  All Promo Codes                              [+ Create New]      │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 📋 FIRST5                                        [Edit] [❌]│ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │ First 5 Orders - ₹50 Off                                   │ │
│  │ ───────────────────────────────────────────────────────────│ │
│  │ Type: Fixed Amount          Discount: ₹50.00              │ │
│  │ Min Order: ₹200             Per Customer: 5 uses          │ │
│  │ Status: 🟢 ACTIVE           Used: 45/∞ times              │ │
│  │ Valid: Jan 1, 2025 - Dec 31, 2025                         │ │
│  │                                                             │ │
│  │ [Quick Edit Limit: ___] [Save]                            │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 📋 WELCOME100                                    [Edit] [❌]│ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │ Welcome - ₹100 Off First Order                             │ │
│  │ ───────────────────────────────────────────────────────────│ │
│  │ Type: Fixed Amount          Discount: ₹100.00             │ │
│  │ Min Order: ₹300             Per Customer: 1 use           │ │
│  │ Status: 🟢 ACTIVE           Used: 127/∞ times             │ │
│  │ 🎯 First-time customers only                               │ │
│  │                                                             │ │
│  │ [Deactivate] [View Stats]                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 📋 SAVE20                                        [Edit] [❌]│ │
│  ├─────────────────────────────────────────────────────────────┤ │
│  │ 20% Off - Limited Time                                     │ │
│  │ ───────────────────────────────────────────────────────────│ │
│  │ Type: Percentage (20%)      Max Discount: ₹200            │ │
│  │ Min Order: ₹500             Per Customer: 3 uses          │ │
│  │ Status: 🔴 INACTIVE         Used: 89/500 times            │ │
│  │                                                             │ │
│  │ [Activate] [Delete]                                        │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📱 Customer View (How Config Affects Them)

```
╔═══════════════════════════════════════════════════════════════════╗
║                    CUSTOMER APP                                   ║
╚═══════════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────────────┐
│  🛒 Checkout                                                      │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Cart Total: ₹530                                                 │
│                                                                   │
│  🎁 Have a promo code?                                            │
│  ┌────────────────────────────┐                                  │
│  │ FIRST5                     │  [Apply]                         │
│  └────────────────────────────┘                                  │
│         ↓                                                         │
│         │ Sends to backend with:                                 │
│         │ • code: "FIRST5"                                       │
│         │ • customerId: 123                                      │
│         │ • deviceUuid: "abc-123"                                │
│         │ • amount: 530                                          │
│         ↓                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  BACKEND CHECKS CONFIG:                                     │ │
│  │  ┌───────────────────────────────────────────────────────┐ │ │
│  │  │ SELECT * FROM promotions WHERE code = 'FIRST5'       │ │ │
│  │  │ Result:                                               │ │ │
│  │  │  • discount_value: 50.00                             │ │ │
│  │  │  • usage_limit_per_customer: 5  ← READS THIS CONFIG  │ │ │
│  │  │  • minimum_order_amount: 200.00                      │ │ │
│  │  │  • status: ACTIVE                                    │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                                                              │ │
│  │  ┌───────────────────────────────────────────────────────┐ │ │
│  │  │ SELECT COUNT(*) FROM promotion_usage                 │ │ │
│  │  │ WHERE promotion_id = 1 AND customer_id = 123         │ │ │
│  │  │ Result: 2 times used                                 │ │ │
│  │  └───────────────────────────────────────────────────────┘ │ │
│  │                                                              │ │
│  │  Validation: 2 < 5 ✅ VALID                                 │ │
│  └─────────────────────────────────────────────────────────────┘ │
│         ↓                                                         │
│  ✅ Promo code applied!                                           │
│  You saved ₹50                                                    │
│  💡 You can use this code 3 more times                            │
│     ↑                          ↑                                  │
│     │                          Calculated from config (5 - 2)     │
│     Discount from config                                          │
│                                                                   │
│  Subtotal:           ₹530                                         │
│  Promo (FIRST5):    -₹50   ← From discount_value config          │
│  Delivery:           ₹20                                          │
│  ─────────────────────────                                        │
│  Total:              ₹500                                         │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Quick Configuration Reference

```
┌───────────────────────────────────────────────────────────────────┐
│              CONFIGURATION QUICK REFERENCE                        │
├───────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Field: usage_limit_per_customer                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Value    │ Effect                                            │ │
│  ├──────────┼───────────────────────────────────────────────────┤ │
│  │ 1        │ One-time use per customer                        │ │
│  │ 5        │ Customer can use 5 times (default example)       │ │
│  │ 10       │ Customer can use 10 times                        │ │
│  │ 100      │ Customer can use 100 times                       │ │
│  │ NULL     │ UNLIMITED - customer can use forever             │ │
│  └──────────┴───────────────────────────────────────────────────┘ │
│                                                                   │
│  Field: usage_limit                                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Value    │ Effect                                            │ │
│  ├──────────┼───────────────────────────────────────────────────┤ │
│  │ 100      │ Only 100 total uses across ALL customers        │ │
│  │ 500      │ Only 500 total uses                              │ │
│  │ NULL     │ UNLIMITED total uses                             │ │
│  └──────────┴───────────────────────────────────────────────────┘ │
│                                                                   │
│  Field: type                                                      │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Value         │ Effect                                       │ │
│  ├───────────────┼──────────────────────────────────────────────┤ │
│  │ FIXED_AMOUNT  │ Fixed discount (e.g., ₹50 off)              │ │
│  │ PERCENTAGE    │ Percentage discount (e.g., 20% off)         │ │
│  │ FREE_SHIPPING │ Free delivery                                │ │
│  │ BUY_ONE_GET_ONE│ BOGO offer                                  │ │
│  └───────────────┴──────────────────────────────────────────────┘ │
│                                                                   │
│  Field: status                                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ Value      │ Effect                                          │ │
│  ├────────────┼─────────────────────────────────────────────────┤ │
│  │ ACTIVE     │ Promo is live and usable                       │ │
│  │ INACTIVE   │ Promo is paused (not usable)                   │ │
│  │ EXPIRED    │ Promo has expired (auto-set)                   │ │
│  │ SUSPENDED  │ Promo is temporarily disabled                  │ │
│  └────────────┴─────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## 💡 Common Configuration Tasks

### Task 1: "Change from 5 orders to 10 orders"

```
┌────────────────────────────────┐
│ SQL Command:                   │
├────────────────────────────────┤
│ UPDATE promotions              │
│ SET usage_limit_per_customer   │
│     = 10                       │ ← Change this value
│ WHERE code = 'FIRST5';         │
└────────────────────────────────┘
```

### Task 2: "Make it unlimited"

```
┌────────────────────────────────┐
│ SQL Command:                   │
├────────────────────────────────┤
│ UPDATE promotions              │
│ SET usage_limit_per_customer   │
│     = NULL                     │ ← NULL = unlimited
│ WHERE code = 'FIRST5';         │
└────────────────────────────────┘
```

### Task 3: "Pause the promo"

```
┌────────────────────────────────┐
│ SQL Command:                   │
├────────────────────────────────┤
│ UPDATE promotions              │
│ SET status = 'INACTIVE'        │ ← Pause it
│ WHERE code = 'FIRST5';         │
└────────────────────────────────┘
```

### Task 4: "Change discount to ₹100"

```
┌────────────────────────────────┐
│ SQL Command:                   │
├────────────────────────────────┤
│ UPDATE promotions              │
│ SET discount_value = 100.00    │ ← New discount
│ WHERE code = 'FIRST5';         │
└────────────────────────────────┘
```

---

## 📊 Summary Box

```
╔═══════════════════════════════════════════════════════════════════╗
║                    CONFIGURATION SUMMARY                          ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  ✅ ALREADY CONFIGURABLE (No Code Changes Needed!)                ║
║                                                                   ║
║  🎛️  Main Configs:                                                ║
║   • Per-customer limit (1, 5, 10, unlimited)                     ║
║   • Total usage limit                                            ║
║   • Discount amount                                              ║
║   • Minimum order amount                                         ║
║   • Date range                                                   ║
║   • Active/Inactive status                                       ║
║   • First-time only flag                                         ║
║   • Shop-specific or global                                      ║
║                                                                   ║
║  🔧 How to Change:                                                ║
║   • Direct SQL UPDATE commands                                   ║
║   • Admin API (can be created)                                   ║
║   • Admin Panel UI (can be built)                                ║
║                                                                   ║
║  ⚡ Effect:                                                        ║
║   • Changes take effect IMMEDIATELY                              ║
║   • No app restart needed                                        ║
║   • Next validation uses new config                              ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

