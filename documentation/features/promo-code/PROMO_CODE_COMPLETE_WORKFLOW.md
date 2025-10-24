# Promo Code System - Complete Workflow

## 🔄 End-to-End Workflow

```
╔═══════════════════════════════════════════════════════════════════╗
║           COMPLETE PROMO CODE WORKFLOW DIAGRAM                    ║
╚═══════════════════════════════════════════════════════════════════╝


PHASE 1: ADMIN CREATES PROMO CODE
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  👨‍💼 ADMIN                                                        │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Creates new promo code
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📝 INSERT INTO promotions                                      │
├─────────────────────────────────────────────────────────────────┤
│  code: "FIRST5"                                                 │
│  title: "First 5 Orders - ₹50 Off"                             │
│  type: FIXED_AMOUNT                                             │
│  discount_value: 50.00                                          │
│  minimum_order_amount: 200.00                                   │
│  usage_limit_per_customer: 5     ← CONFIG: 5 times per user    │
│  usage_limit: NULL                ← CONFIG: Unlimited total     │
│  start_date: 2025-01-01                                         │
│  end_date: 2025-12-31                                           │
│  status: ACTIVE                                                 │
│  is_first_time_only: FALSE                                      │
│  shop_id: NULL                    ← NULL = All shops            │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Saved to database ✅
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  💾 DATABASE: promotions table                                  │
│  Promo "FIRST5" is now active and ready to use                 │
└─────────────────────────────────────────────────────────────────┘


PHASE 2: CUSTOMER DISCOVERS PROMO
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  👤 CUSTOMER opens app                                          │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Option A: Sees banner/notification
         │ Option B: Manually enters code
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📱 MOBILE APP                                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 🎉 ACTIVE PROMOS (API Call)                              │ │
│  │                                                            │ │
│  │ GET /api/promotions/active                                │ │
│  │                                                            │ │
│  │ Response:                                                  │ │
│  │ • FIRST5: Get ₹50 off on orders ≥ ₹200                   │ │
│  │ • WELCOME100: First order discount                        │ │
│  │ • SAVE20: 20% off on ₹500+ orders                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  Customer taps "FIRST5" to copy code                           │
└─────────────────────────────────────────────────────────────────┘


PHASE 3: CUSTOMER ADDS ITEMS TO CART
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  📱 MOBILE APP - Shopping                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Thiruna Shop                                              │ │
│  │                                                            │ │
│  │ [+] Basmati Rice (1kg)  ₹134  [Add] → Added (Qty: 2)     │ │
│  │ [+] Toor Dal (500g)     ₹120  [Add] → Added (Qty: 1)     │ │
│  │ [+] Oil (1L)            ₹142  [Add] → Added (Qty: 1)     │ │
│  │                                                            │ │
│  │ 🛒 Cart: 4 items  Total: ₹530                             │ │
│  │ [View Cart]                                                │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Taps "View Cart"
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📱 CART SCREEN                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 🛒 Your Cart                                              │ │
│  │                                                            │ │
│  │ Basmati Rice × 2        ₹268                              │ │
│  │ Toor Dal × 1            ₹120                              │ │
│  │ Oil × 1                 ₹142                              │ │
│  │ ─────────────────────────────                             │ │
│  │ Subtotal:               ₹530                              │ │
│  │                                                            │ │
│  │ [Proceed to Checkout]                                     │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Taps "Proceed to Checkout"
         ↓


PHASE 4: CUSTOMER ENTERS PROMO CODE AT CHECKOUT
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  📱 CHECKOUT SCREEN                                             │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 💳 Checkout                                               │ │
│  │                                                            │ │
│  │ Subtotal:    ₹530                                         │ │
│  │                                                            │ │
│  │ 🎁 Have a promo code?                                     │ │
│  │ ┌────────────────────────┐                               │ │
│  │ │ FIRST5                 │  [Apply]  ← User types code   │ │
│  │ └────────────────────────┘                               │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ User taps [Apply]
         │
         │ APP COLLECTS DATA:
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📲 DATA COLLECTION                                             │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ const request = {                                         │ │
│  │   promoCode: "FIRST5",                                    │ │
│  │   customerId: 123,            ← From login session        │ │
│  │   deviceUuid: "abc-123-xyz",  ← From device_info_plus    │ │
│  │   phone: "+919876543210",     ← From user profile         │ │
│  │   orderAmount: 530.00,        ← Cart subtotal             │ │
│  │   shopId: 1                   ← Current shop              │ │
│  │ };                                                         │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ HTTP POST
         ↓


PHASE 5: BACKEND VALIDATES PROMO CODE
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  🌐 API ENDPOINT: POST /api/promotions/validate                │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Request received
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  ⚙️  PROMOTION SERVICE - validatePromoCode()                    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 1: Find Promotion                                    │ │
│  │ SELECT * FROM promotions WHERE code = 'FIRST5'            │ │
│  │ Result: Found ✅                                          │ │
│  │ {                                                          │ │
│  │   id: 1,                                                   │ │
│  │   code: "FIRST5",                                          │ │
│  │   discount_value: 50.00,                                   │ │
│  │   minimum_order_amount: 200.00,                            │ │
│  │   usage_limit_per_customer: 5,  ← CONFIG                  │ │
│  │   status: "ACTIVE"                                         │ │
│  │ }                                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 2: Check Status                                      │ │
│  │ status == "ACTIVE" ? ✅ YES                               │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 3: Check Date Range                                  │ │
│  │ NOW() between start_date AND end_date ? ✅ YES            │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 4: Check Minimum Order                               │ │
│  │ 530.00 >= 200.00 ? ✅ YES                                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 5: Check Shop                                        │ │
│  │ shop_id NULL (global) OR matches ? ✅ YES                 │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 6: Check Total Usage                                 │ │
│  │ used_count (45) < usage_limit (NULL=unlimited) ? ✅ YES   │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 7: Check First-Time Only                             │ │
│  │ is_first_time_only == FALSE ? ✅ YES (not required)       │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓ CRITICAL STEP                                        │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 8: Check Customer Usage (ANTI-ABUSE)                 │ │
│  │                                                            │ │
│  │ SELECT COUNT(*) FROM promotion_usage                      │ │
│  │ WHERE promotion_id = 1 AND (                              │ │
│  │   customer_id = 123 OR                                    │ │
│  │   device_uuid = 'abc-123-xyz' OR                          │ │
│  │   customer_phone = '+919876543210'                        │ │
│  │ )                                                          │ │
│  │                                                            │ │
│  │ Result: 2 times                                           │ │
│  │ Limit: 5 times (from config)                              │ │
│  │ Check: 2 < 5 ? ✅ YES - Still valid!                     │ │
│  │ Remaining: 3 more uses                                    │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ STEP 9: Calculate Discount                                │ │
│  │ Type: FIXED_AMOUNT                                        │ │
│  │ Discount: ₹50.00                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ✅ ALL CHECKS PASSED                                      │ │
│  │ Return: VALID + Discount ₹50                              │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Response sent back to app
         ↓


PHASE 6: APP DISPLAYS RESULT
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  📱 CHECKOUT SCREEN (Updated)                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 💳 Checkout                                               │ │
│  │                                                            │ │
│  │ ✅ Promo code "FIRST5" applied!                           │ │
│  │ You saved ₹50                                             │ │
│  │ 💡 You can use this code 3 more times                     │ │
│  │                                                            │ │
│  │ Subtotal:           ₹530                                  │ │
│  │ Promo (FIRST5):    -₹50                                   │ │
│  │ Delivery Fee:       ₹20                                   │ │
│  │ ─────────────────────────                                 │ │
│  │ Total:              ₹500                                  │ │
│  │                                                            │ │
│  │ 📍 Delivery Address                                       │ │
│  │ [Select Address]                                          │ │
│  │                                                            │ │
│  │ ┌───────────────────────────────────────────────────────┐│ │
│  │ │      PLACE ORDER - ₹500                               ││ │
│  │ └───────────────────────────────────────────────────────┘│ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Customer taps "PLACE ORDER"
         ↓


PHASE 7: ORDER PLACEMENT
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  🌐 API: POST /api/customer/orders                              │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Request Body:                                             │ │
│  │ {                                                          │ │
│  │   shopId: 1,                                               │ │
│  │   items: [...],                                            │ │
│  │   paymentMethod: "CASH_ON_DELIVERY",                       │ │
│  │   deliveryAddress: "...",                                  │ │
│  │   couponCode: "FIRST5",        ← Promo code              │ │
│  │   discountAmount: 50.00,                                   │ │
│  │   customerId: 123,                                         │ │
│  │   deviceUuid: "abc-123-xyz"                                │ │
│  │ }                                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Order Service processes
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  💾 DATABASE: INSERT INTO orders                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ id: 789                                                    │ │
│  │ order_number: "ORD1234567890"                              │ │
│  │ customer_id: 123                                           │ │
│  │ shop_id: 1                                                 │ │
│  │ subtotal: 530.00                                           │ │
│  │ discount_amount: 50.00         ← Promo discount           │ │
│  │ delivery_fee: 20.00                                        │ │
│  │ total_amount: 500.00                                       │ │
│  │ status: PENDING                                            │ │
│  │ payment_status: PENDING                                    │ │
│  │ created_at: NOW()                                          │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Order created successfully
         ↓


PHASE 8: RECORD PROMO USAGE (CRITICAL!)
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  ⚙️  PROMOTION SERVICE - recordPromotionUsage()                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 💾 INSERT INTO promotion_usage                            │ │
│  │ {                                                          │ │
│  │   promotion_id: 1,             ← Links to FIRST5         │ │
│  │   customer_id: 123,            ← Who used it             │ │
│  │   order_id: 789,               ← Which order             │ │
│  │   device_uuid: "abc-123-xyz",  ← Device tracking         │ │
│  │   customer_phone: "+919876543210",                        │ │
│  │   discount_applied: 50.00,     ← How much saved          │ │
│  │   order_amount: 530.00,                                    │ │
│  │   is_first_order: FALSE,                                   │ │
│  │   used_at: NOW(),              ← When                     │ │
│  │   shop_id: 1                                               │ │
│  │ }                                                          │ │
│  │ ✅ Usage recorded!                                        │ │
│  └───────────────────────────────────────────────────────────┘ │
│         │                                                       │
│         ↓                                                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ 💾 UPDATE promotions                                      │ │
│  │ SET used_count = used_count + 1                           │ │
│  │ WHERE id = 1                                               │ │
│  │                                                            │ │
│  │ Before: used_count = 45                                   │ │
│  │ After:  used_count = 46  ← Incremented                   │ │
│  │ ✅ Counter updated!                                       │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Usage tracking complete
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  💾 DATABASE STATE (After Order)                                │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ promotions table:                                         │ │
│  │ • code: FIRST5                                            │ │
│  │ • used_count: 46  (was 45)                                │ │
│  │                                                            │ │
│  │ promotion_usage table:                                    │ │
│  │ • Customer 123 has now used FIRST5: 3 times total        │ │
│  │   (was 2, now 3)                                          │ │
│  │ • Remaining uses for this customer: 2 more times          │ │
│  │   (5 limit - 3 used = 2 remaining)                        │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘


PHASE 9: ORDER CONFIRMATION
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  📱 ORDER CONFIRMATION SCREEN                                   │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ ✅ Order Placed Successfully!                             │ │
│  │                                                            │ │
│  │ Order #ORD1234567890                                      │ │
│  │                                                            │ │
│  │ 🎉 You saved ₹50 with promo code FIRST5!                 │ │
│  │                                                            │ │
│  │ Order Summary:                                            │ │
│  │ • Subtotal: ₹530                                          │ │
│  │ • Promo Discount: -₹50                                    │ │
│  │ • Delivery: ₹20                                           │ │
│  │ • Total Paid: ₹500                                        │ │
│  │                                                            │ │
│  │ Estimated Delivery: 30-45 minutes                         │ │
│  │                                                            │ │
│  │ [Track Order]  [View Details]                            │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘


PHASE 10: NEXT TIME CUSTOMER USES SAME CODE
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  👤 CUSTOMER (Same customer, next order)                        │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Tries to use FIRST5 again
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📱 CHECKOUT SCREEN                                             │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Enter promo: [FIRST5____]  [Apply]                       │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Validates again
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  ⚙️  BACKEND VALIDATION (2nd Order)                             │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Query promotion_usage:                                    │ │
│  │ SELECT COUNT(*) FROM promotion_usage                      │ │
│  │ WHERE promotion_id = 1 AND customer_id = 123              │ │
│  │                                                            │ │
│  │ Result: 3 times  (was 2, now 3 after last order)         │ │
│  │ Limit: 5 times                                            │ │
│  │ Check: 3 < 5 ? ✅ YES - Still valid!                     │ │
│  │ Remaining: 2 more uses                                    │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📱 RESULT                                                      │
│  ✅ Promo code applied!                                         │
│  💡 You can use this code 2 more times                          │
└─────────────────────────────────────────────────────────────────┘


PHASE 11: AFTER 5TH USE (LIMIT REACHED)
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  👤 CUSTOMER (6th order attempt)                                │
└─────────────────────────────────────────────────────────────────┘
         │
         │ Tries to use FIRST5 (6th time)
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  ⚙️  BACKEND VALIDATION (6th Attempt)                           │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ Query promotion_usage:                                    │ │
│  │ SELECT COUNT(*) FROM promotion_usage                      │ │
│  │ WHERE promotion_id = 1 AND customer_id = 123              │ │
│  │                                                            │ │
│  │ Result: 5 times  (already used all)                       │ │
│  │ Limit: 5 times                                            │ │
│  │ Check: 5 < 5 ? ❌ NO - Limit reached!                    │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────────────────────────────┐
│  📱 ERROR MESSAGE                                               │
│  ❌ Invalid promo code                                          │
│  "You have already used this promo code 5 time(s).             │
│   Maximum allowed: 5"                                           │
└─────────────────────────────────────────────────────────────────┘


SUMMARY BOX
═══════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────┐
│  📊 COMPLETE WORKFLOW SUMMARY                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1️⃣  Admin creates promo in database                            │
│      • Sets config: 5 uses per customer                         │
│                                                                 │
│  2️⃣  Customer discovers promo                                   │
│      • Views active promos or manually enters code              │
│                                                                 │
│  3️⃣  Customer adds items to cart                                │
│      • Cart total: ₹530                                         │
│                                                                 │
│  4️⃣  Customer enters promo at checkout                          │
│      • Enters "FIRST5"                                          │
│                                                                 │
│  5️⃣  Backend validates promo                                    │
│      • Checks 9 validation rules                                │
│      • Checks usage history (2/5 times used)                    │
│      • Returns: ✅ Valid, discount ₹50                          │
│                                                                 │
│  6️⃣  App displays discount                                      │
│      • Total updated: ₹500 (saved ₹50)                          │
│      • Shows: "3 more uses left"                                │
│                                                                 │
│  7️⃣  Customer places order                                      │
│      • Order created with discount                              │
│                                                                 │
│  8️⃣  System records usage                                       │
│      • Inserts into promotion_usage table                       │
│      • Tracks customer ID + device UUID + phone                 │
│      • Increments promo counter (45 → 46)                       │
│      • Customer usage: 2 → 3 times                              │
│                                                                 │
│  9️⃣  Order confirmed                                            │
│      • Customer sees success message                            │
│                                                                 │
│  🔟 Next time: System validates again                           │
│      • Checks new usage count (3/5)                             │
│      • Still valid (2 more uses)                                │
│                                                                 │
│  ⛔ After 5 uses: Blocked                                       │
│      • Usage count (5/5) - limit reached                        │
│      • Error message shown                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

