# Promo Code System - Box Model & Flow Diagram

## 📱 User Interface Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CUSTOMER MOBILE APP                       │
└─────────────────────────────────────────────────────────────┘

Step 1: Browse & Add Items to Cart
┌──────────────────────────────────────┐
│   🛒 Shopping Cart                   │
├──────────────────────────────────────┤
│  Item 1: Rice - ₹200                 │
│  Item 2: Dal - ₹150                  │
│  Item 3: Oil - ₹180                  │
│                                       │
│  Subtotal:        ₹530               │
│  ─────────────────────────────       │
│  [Have a promo code?]                │
│  ┌────────────────────┐ [Apply]      │
│  │  FIRST5            │              │
│  └────────────────────┘              │
│                                       │
│  → User enters "FIRST5" and taps     │
│     Apply button                     │
└──────────────────────────────────────┘
           ↓
```

---

## 🔄 System Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                         FLOW DIAGRAM                                │
└────────────────────────────────────────────────────────────────────┘

USER ACTION                    SYSTEM PROCESSING              DATABASE
─────────────                 ──────────────────             ─────────

1. USER ENTERS PROMO CODE
┌─────────────┐
│ Enter Code: │
│  FIRST5     │  ──────────────────────────→
└─────────────┘
                              2. COLLECT DATA
                              ┌──────────────────┐
                              │ • Promo Code     │
                              │ • Customer ID    │
                              │ • Device UUID    │
                              │ • Phone Number   │
                              │ • Order Amount   │
                              │ • Shop ID        │
                              └──────────────────┘
                                      ↓
                              3. SEND TO BACKEND
                              ┌──────────────────┐
                              │ POST /api/       │
                              │ promotions/      │
                              │ validate         │
                              └──────────────────┘
                                      ↓
                              4. VALIDATE PROMO CODE
                              ┌──────────────────┐              ┌──────────┐
                              │ Find Code in DB  │──────────→   │promotions│
                              └──────────────────┘              └──────────┘
                                      ↓                                ↓
                                      ├──────────────────────────────┘
                                      │ Found: "FIRST5"
                                      │ • Status: ACTIVE ✓
                                      │ • Valid dates ✓
                                      │ • Min order: ₹200 ✓
                                      ↓
                              5. CHECK USAGE HISTORY
                              ┌──────────────────┐              ┌────────────────┐
                              │ Has customer     │──────────→   │promotion_usage │
                              │ used this code?  │              └────────────────┘
                              └──────────────────┘                      ↓
                                      ↓                                 │
                                      ├─────────────────────────────────┘
                                      │ Query Results:
                                      │ • Customer ID: 0 times ✓
                                      │ • Device UUID: 0 times ✓
                                      │ • Phone: 0 times ✓
                                      ↓
                              6. CALCULATE DISCOUNT
                              ┌──────────────────┐
                              │ Type: FIXED      │
                              │ Amount: ₹50      │
                              │ Max: ₹50         │
                              │                  │
                              │ Discount = ₹50   │
                              └──────────────────┘
                                      ↓
                              7. RETURN RESULT
                              ┌──────────────────┐
                              │ ✅ Valid: true   │
                              │ Discount: ₹50    │
                              │ Message: Success │
                              └──────────────────┘
                                      ↓
8. UPDATE UI                          │
┌─────────────────┐          ←────────┘
│ ✅ Applied!     │
│                 │
│ Subtotal: ₹530  │
│ Promo: -₹50     │
│ ─────────────   │
│ Total: ₹480     │
└─────────────────┘
      ↓
9. PLACE ORDER
┌─────────────────┐
│ [Place Order]   │──────→
└─────────────────┘
                              10. RECORD USAGE
                              ┌──────────────────┐              ┌────────────────┐
                              │ Save to DB:      │──────────→   │promotion_usage │
                              │ • Promo ID: 1    │              │                │
                              │ • Customer: 123  │              │ INSERT         │
                              │ • Device: abc-   │              │ new record     │
                              │ • Discount: ₹50  │              │                │
                              └──────────────────┘              └────────────────┘
                                      ↓
                              11. INCREMENT COUNTER
                              ┌──────────────────┐              ┌──────────┐
                              │ Update:          │──────────→   │promotions│
                              │ used_count = 1   │              │          │
                              └──────────────────┘              │ UPDATE   │
                                                                 └──────────┘

12. ORDER CONFIRMED
┌─────────────────┐
│ ✅ Order placed │
│ Order #ORD123   │
│ Saved ₹50!      │
└─────────────────┘
```

---

## 🎯 Detailed Component Boxes

### Box 1: Mobile App Input
```
┌─────────────────────────────────────────────┐
│          CHECKOUT SCREEN                    │
├─────────────────────────────────────────────┤
│                                             │
│  Cart Items:                    ₹530        │
│  ─────────────────────────────────          │
│                                             │
│  📋 Have a Promo Code?                      │
│  ┌────────────────────────────┐            │
│  │ FIRST5                     │  [Apply]   │
│  └────────────────────────────┘            │
│                                             │
│  ✅ Promo code applied!                     │
│  You saved ₹50                              │
│                                             │
│  Subtotal:                     ₹530         │
│  Promo Discount (FIRST5):     -₹50          │
│  Delivery Fee:                 ₹20          │
│  ─────────────────────────────────          │
│  Total:                        ₹500         │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │      PLACE ORDER                      │ │
│  └───────────────────────────────────────┘ │
│                                             │
└─────────────────────────────────────────────┘
```

### Box 2: Data Collection (App)
```
┌─────────────────────────────────────────────┐
│       DATA COLLECTED BY APP                 │
├─────────────────────────────────────────────┤
│                                             │
│  1. promoCode: "FIRST5"                     │
│     ↳ From user input                       │
│                                             │
│  2. customerId: 123                         │
│     ↳ From login session (if logged in)    │
│     ↳ null if guest user                   │
│                                             │
│  3. deviceUuid: "abc-123-xyz-456"           │
│     ↳ From device_info_plus package        │
│     ↳ Android: android.id                  │
│     ↳ iOS: identifierForVendor             │
│                                             │
│  4. phone: "+919876543210"                  │
│     ↳ From user profile or input           │
│                                             │
│  5. orderAmount: 530.00                     │
│     ↳ Calculated cart subtotal             │
│                                             │
│  6. shopId: 1                               │
│     ↳ Current shop being ordered from      │
│                                             │
└─────────────────────────────────────────────┘
```

### Box 3: API Request
```
┌─────────────────────────────────────────────┐
│         HTTP POST REQUEST                   │
├─────────────────────────────────────────────┤
│                                             │
│  URL:                                       │
│  POST /api/promotions/validate              │
│                                             │
│  Headers:                                   │
│  Content-Type: application/json             │
│                                             │
│  Body:                                      │
│  {                                          │
│    "promoCode": "FIRST5",                   │
│    "customerId": 123,                       │
│    "deviceUuid": "abc-123-xyz-456",         │
│    "phone": "+919876543210",                │
│    "orderAmount": 530.00,                   │
│    "shopId": 1                              │
│  }                                          │
│                                             │
└─────────────────────────────────────────────┘
```

### Box 4: Backend Validation Logic
```
┌─────────────────────────────────────────────────────────────┐
│              PROMOTION SERVICE                              │
│            validatePromoCode()                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✓ STEP 1: Find Promotion by Code                          │
│    └─→ SELECT * FROM promotions WHERE code = 'FIRST5'      │
│        Result: Found ✅                                     │
│                                                             │
│  ✓ STEP 2: Check if Active                                 │
│    └─→ status = 'ACTIVE' ✅                                │
│                                                             │
│  ✓ STEP 3: Check Date Range                                │
│    └─→ NOW() between start_date AND end_date ✅            │
│                                                             │
│  ✓ STEP 4: Check Minimum Order Amount                      │
│    └─→ 530.00 >= 200.00 (minimum) ✅                       │
│                                                             │
│  ✓ STEP 5: Check Shop                                      │
│    └─→ shop_id matches OR is NULL (global) ✅             │
│                                                             │
│  ✓ STEP 6: Check Total Usage Limit                         │
│    └─→ used_count (45) < usage_limit (100) ✅             │
│                                                             │
│  ✓ STEP 7: Check First-Time Only                           │
│    └─→ is_first_time_only = false ✅                       │
│                                                             │
│  ✓ STEP 8: Check Per-Customer Usage                        │
│    Query: How many times has THIS user used this promo?    │
│    SELECT COUNT(*) FROM promotion_usage                    │
│    WHERE promotion_id = 1 AND (                            │
│      customer_id = 123 OR                                  │
│      device_uuid = 'abc-123-xyz-456' OR                    │
│      customer_phone = '+919876543210'                      │
│    )                                                        │
│    Result: 0 times ✅                                      │
│    Limit: 5 times allowed                                  │
│    └─→ 0 < 5 ✅ VALID                                     │
│                                                             │
│  ✓ STEP 9: Calculate Discount                              │
│    Type: FIXED_AMOUNT                                      │
│    Discount: ₹50.00                                        │
│    Maximum: ₹50.00                                         │
│    └─→ Final Discount: ₹50.00 ✅                          │
│                                                             │
│  ✅ ALL CHECKS PASSED                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Box 5: API Response (Success)
```
┌─────────────────────────────────────────────┐
│         HTTP 200 OK RESPONSE                │
├─────────────────────────────────────────────┤
│                                             │
│  {                                          │
│    "statusCode": "0000",                    │
│    "valid": true,                           │
│    "message": "Promo code applied!",        │
│    "discountAmount": 50.00,                 │
│    "promotionId": 1,                        │
│    "promotionTitle": "First 5 Orders",      │
│    "discountType": "FIXED_AMOUNT"           │
│  }                                          │
│                                             │
└─────────────────────────────────────────────┘
```

### Box 6: API Response (Already Used)
```
┌─────────────────────────────────────────────┐
│       HTTP 400 BAD REQUEST                  │
├─────────────────────────────────────────────┤
│                                             │
│  {                                          │
│    "statusCode": "1001",                    │
│    "valid": false,                          │
│    "message": "You have already used this   │
│               promo code 5 time(s).         │
│               Maximum allowed: 5"           │
│  }                                          │
│                                             │
└─────────────────────────────────────────────┘
```

### Box 7: Record Usage After Order
```
┌─────────────────────────────────────────────────────────────┐
│          AFTER ORDER IS PLACED                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  INSERT INTO promotion_usage:                               │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ id: 456                                               │ │
│  │ promotion_id: 1  ──→ Links to "FIRST5" promo         │ │
│  │ customer_id: 123  ──→ Customer who used it           │ │
│  │ order_id: 789  ──→ Order where it was used           │ │
│  │ device_uuid: "abc-123-xyz-456"  ──→ Device tracking  │ │
│  │ customer_phone: "+919876543210"                      │ │
│  │ discount_applied: 50.00  ──→ Actual discount given   │ │
│  │ order_amount: 530.00                                 │ │
│  │ is_first_order: false                                │ │
│  │ used_at: 2025-01-23 14:30:00                         │ │
│  │ shop_id: 1                                           │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  UPDATE promotions:                                         │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ SET used_count = used_count + 1                      │ │
│  │ WHERE id = 1                                         │ │
│  │ (Now: 46 total uses)                                 │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 What Happens on 2nd Use (Same Customer)

```
USER TRIES AGAIN (2nd Order)
┌─────────────┐
│ Enter Code: │
│  FIRST5     │  ──────────────────────────→
└─────────────┘
                              SYSTEM CHECKS:
                              ┌──────────────────────────────┐
                              │ promotion_usage table:       │
                              │                              │
                              │ Customer 123 used FIRST5:    │
                              │ • 1 time already ✓           │
                              │                              │
                              │ Limit: 5 times               │
                              │ Used: 1 time                 │
                              │ Remaining: 4 times           │
                              │                              │
                              │ ✅ STILL VALID               │
                              │ Can use 4 more times         │
                              └──────────────────────────────┘

RESULT:
┌─────────────────┐
│ ✅ Applied!     │
│ Discount: ₹50   │
│ (4 uses left)   │
└─────────────────┘
```

---

## 🔍 What Happens on 6th Use (Limit Reached)

```
USER TRIES 6TH TIME
┌─────────────┐
│ Enter Code: │
│  FIRST5     │  ──────────────────────────→
└─────────────┘
                              SYSTEM CHECKS:
                              ┌──────────────────────────────┐
                              │ promotion_usage table:       │
                              │                              │
                              │ Customer 123 used FIRST5:    │
                              │ • 5 times already ✓          │
                              │                              │
                              │ Limit: 5 times               │
                              │ Used: 5 times                │
                              │ Remaining: 0 times           │
                              │                              │
                              │ ❌ LIMIT REACHED             │
                              └──────────────────────────────┘

RESULT:
┌──────────────────┐
│ ❌ Invalid       │
│ "You have        │
│  already used    │
│  this promo code │
│  5 time(s)."     │
└──────────────────┘
```

---

## 🔍 What Happens with Different Device (Same Customer)

```
SAME CUSTOMER, NEW DEVICE
┌─────────────┐
│ Customer 123│
│ New Phone   │
│ Device: xyz │──────────────────────────→
│ Code: FIRST5│
└─────────────┘
                              SYSTEM CHECKS:
                              ┌──────────────────────────────┐
                              │ promotion_usage table:       │
                              │                              │
                              │ WHERE promotion_id = 1 AND ( │
                              │   customer_id = 123 OR       │
                              │   device_uuid = 'xyz-new'    │
                              │ )                            │
                              │                              │
                              │ Found:                       │
                              │ • Customer 123: 5 times ✗    │
                              │ • Device xyz: 0 times        │
                              │                              │
                              │ ❌ CUSTOMER LIMIT REACHED    │
                              │ (even though device is new)  │
                              └──────────────────────────────┘

RESULT:
┌──────────────────┐
│ ❌ Blocked       │
│ Customer already │
│ used 5 times     │
└──────────────────┘
```

---

## 🔍 What Happens with Guest User (No Login)

```
GUEST USER
┌─────────────┐
│ No Login    │
│ Device: pqr │──────────────────────────→
│ Phone: +91  │
│ Code: FIRST5│
└─────────────┘
                              SYSTEM CHECKS:
                              ┌──────────────────────────────┐
                              │ promotion_usage table:       │
                              │                              │
                              │ WHERE promotion_id = 1 AND ( │
                              │   device_uuid = 'pqr-123' OR │
                              │   customer_phone = '+91...'  │
                              │ )                            │
                              │                              │
                              │ Found: 0 matches             │
                              │                              │
                              │ ✅ VALID - First time use    │
                              └──────────────────────────────┘

RESULT:
┌─────────────────┐
│ ✅ Applied!     │
│ Discount: ₹50   │
└─────────────────┘
```

---

## 📊 Database Table Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                    DATABASE SCHEMA                           │
└──────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│   promotions        │
├─────────────────────┤
│ id (PK)             │──────┐
│ code                │      │
│ title               │      │
│ type                │      │
│ discount_value      │      │
│ usage_limit         │      │
│ usage_limit_per_    │      │
│   customer          │      │
│ used_count          │      │
│ start_date          │      │
│ end_date            │      │
│ status              │      │
└─────────────────────┘      │
                             │ (1:Many)
                             ↓
                   ┌─────────────────────┐
                   │  promotion_usage    │
                   ├─────────────────────┤
                   │ id (PK)             │
                   │ promotion_id (FK)   │───→ Links back
                   │ customer_id (FK)    │───→ to customer
                   │ order_id (FK)       │───→ to order
                   │ device_uuid         │ ← Device tracking
                   │ customer_phone      │ ← Phone tracking
                   │ discount_applied    │
                   │ order_amount        │
                   │ used_at             │
                   └─────────────────────┘
                             ↓
              ┌──────────────┴──────────────┐
              ↓                             ↓
   ┌──────────────────┐         ┌──────────────────┐
   │   customers      │         │     orders       │
   ├──────────────────┤         ├──────────────────┤
   │ id (PK)          │         │ id (PK)          │
   │ name             │         │ order_number     │
   │ phone            │         │ customer_id      │
   │ email            │         │ total_amount     │
   └──────────────────┘         └──────────────────┘
```

---

## 🎨 Mobile App UI Mockup

```
╔═══════════════════════════════════════════════╗
║  ← Checkout                               🛒  ║
╠═══════════════════════════════════════════════╣
║                                               ║
║  📦 Order Summary                             ║
║  ─────────────────────────────────────────    ║
║  Basmati Rice (1kg) × 2          ₹268        ║
║  Toor Dal (500g) × 1             ₹120        ║
║  Sunflower Oil (1L) × 1          ₹142        ║
║                                               ║
║  ─────────────────────────────────────────    ║
║                                               ║
║  🎁 Promo Code                                ║
║  ┌─────────────────────────────┐             ║
║  │ FIRST5                      │  [Apply]    ║
║  └─────────────────────────────┘             ║
║                                               ║
║  ✅ Promo code "FIRST5" applied!              ║
║  You saved ₹50 on this order                  ║
║  💡 You can use this code 4 more times        ║
║                                               ║
║  ─────────────────────────────────────────    ║
║                                               ║
║  💰 Payment Summary                           ║
║                                               ║
║  Subtotal                         ₹530       ║
║  Promo Discount (FIRST5)         -₹50        ║
║  Delivery Fee                     ₹20        ║
║  ─────────────────────────────────────────    ║
║  Total Amount                     ₹500       ║
║                                               ║
║  ┌───────────────────────────────────────┐   ║
║  │         PLACE ORDER - ₹500            │   ║
║  └───────────────────────────────────────┘   ║
║                                               ║
╚═══════════════════════════════════════════════╝
```

---

## Summary

**Key Points:**

1. **User enters promo code** in cart/checkout
2. **App collects** customer ID + device UUID + phone
3. **API validates** the promo code with multi-layer checks
4. **Database tracks** usage by all identifiers
5. **Discount applied** to order total
6. **Usage recorded** when order is placed
7. **Future validation** checks previous usage

**Anti-Abuse Measures:**

✅ Tracks Customer ID
✅ Tracks Device UUID
✅ Tracks Phone Number
✅ Cross-validates all identifiers
✅ Prevents multiple accounts on same device
✅ Prevents device switching to bypass limits

