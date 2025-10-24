# Promo Code System - User-Based Implementation

## Overview
Complete promo code system with user-based validation, device tracking, and usage limits. Prevents abuse by tracking customer ID, mobile device UUID, and phone number.

---

## How It Works (User-Based)

### Multi-Layer Validation

The system validates promo codes using **3 identifiers**:

1. **Customer ID** - For registered/logged-in users
2. **Device UUID** - For guest users or additional device tracking
3. **Phone Number** - Fallback identifier

### Usage Tracking Logic

```
For EACH promo code:
├── If customer is logged in → Track by Customer ID
├── If guest user → Track by Device UUID
├── Fallback → Track by Phone Number
└── Cross-check ALL identifiers to prevent abuse
```

### Example Scenarios

#### Scenario 1: New Customer
```
User: "FIRST5" promo code
System checks:
✓ Customer ID: 123 (never used before)
✓ Device UUID: abc-123 (never used before)
✓ Phone: +919876543210 (never used before)
Result: ✅ VALID - Discount applied
```

#### Scenario 2: Customer Already Used Code
```
User: "FIRST5" promo code again
System checks:
✗ Customer ID: 123 (used 1 time, limit is 1)
Result: ❌ INVALID - "You have already used this promo code"
```

#### Scenario 3: Different Login, Same Device
```
User: Creates new account on same phone
System checks:
✓ Customer ID: 456 (new account)
✗ Device UUID: abc-123 (ALREADY USED)
Result: ❌ INVALID - "This device has already used this promo code"
```

#### Scenario 4: Guest User
```
User: Not logged in, using app
System checks:
✓ Customer ID: null
✓ Device UUID: xyz-789 (never used)
Result: ✅ VALID - Discount applied
```

---

## API Endpoints

### 1. Validate Promo Code (PUBLIC)

**Endpoint:** `POST /api/promotions/validate`

**Request:**
```json
{
  "promoCode": "FIRST5",
  "customerId": 123,              // Optional - for logged-in users
  "deviceUuid": "abc-123-xyz",    // Required for guests
  "phone": "+919876543210",       // Fallback identifier
  "orderAmount": 500.00,
  "shopId": 1                     // Optional - for shop-specific promos
}
```

**Response (Valid):**
```json
{
  "statusCode": "0000",
  "valid": true,
  "message": "Promo code applied successfully!",
  "discountAmount": 50.00,
  "promotionId": 1,
  "promotionTitle": "First 5 Orders - ₹50 Off",
  "discountType": "FIXED_AMOUNT"
}
```

**Response (Invalid):**
```json
{
  "statusCode": "1001",
  "valid": false,
  "message": "You have already used this promo code 1 time(s). Maximum allowed: 1"
}
```

### 2. Get Active Promotions (PUBLIC)

**Endpoint:** `GET /api/promotions/active?shopId=1`

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Active promotions retrieved successfully",
  "data": [
    {
      "id": 1,
      "code": "FIRST5",
      "title": "First 5 Orders - ₹50 Off",
      "description": "Get ₹50 off on your first 5 orders",
      "type": "FIXED_AMOUNT",
      "discountValue": 50.00,
      "minimumOrderAmount": 200.00,
      "usageLimitPerCustomer": 5,
      "isFirstTimeOnly": false,
      "startDate": "2025-01-01T00:00:00",
      "endDate": "2025-12-31T23:59:59"
    }
  ],
  "count": 1
}
```

### 3. Get Usage History (CUSTOMER)

**Endpoint:** `GET /api/promotions/my-usage?customerId=123`

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Usage history retrieved successfully",
  "data": [
    {
      "id": 1,
      "promotionCode": "FIRST5",
      "discountApplied": 50.00,
      "orderAmount": 500.00,
      "usedAt": "2025-01-15T10:30:00",
      "orderNumber": "ORD123456"
    }
  ],
  "count": 1
}
```

### 4. Get Promotion Stats (ADMIN)

**Endpoint:** `GET /api/promotions/1/stats`

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Promotion statistics retrieved successfully",
  "data": {
    "totalUsageCount": 150,
    "uniqueCustomers": 45,
    "uniqueDevices": 48,
    "totalDiscountGiven": 7500.00,
    "recentUsages": [...]
  }
}
```

---

## Database Schema

### `promotions` Table
```sql
CREATE TABLE promotions (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL,          -- PERCENTAGE, FIXED_AMOUNT, etc.
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_order_amount DECIMAL(10,2),
    maximum_discount_amount DECIMAL(10,2),
    usage_limit INTEGER,                -- Total usage limit
    usage_limit_per_customer INTEGER,   -- Per customer limit
    used_count INTEGER DEFAULT 0,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    status VARCHAR(20) NOT NULL,
    shop_id BIGINT,                     -- NULL = global promo
    is_public BOOLEAN DEFAULT TRUE,
    is_first_time_only BOOLEAN DEFAULT FALSE,
    stackable BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### `promotion_usage` Table (NEW)
```sql
CREATE TABLE promotion_usage (
    id BIGSERIAL PRIMARY KEY,
    promotion_id BIGINT NOT NULL,
    customer_id BIGINT,                 -- NULL for guest users
    order_id BIGINT,
    device_uuid VARCHAR(100),           -- Mobile device UUID
    customer_phone VARCHAR(15),
    customer_email VARCHAR(100),
    discount_applied DECIMAL(10,2) NOT NULL,
    order_amount DECIMAL(10,2) NOT NULL,
    is_first_order BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    used_at TIMESTAMP NOT NULL,
    shop_id BIGINT,

    UNIQUE(promotion_id, customer_id, order_id),
    UNIQUE(promotion_id, device_uuid, order_id)
);
```

---

## Promo Code Validation Rules

### 1. ✅ Basic Validation
- ✓ Code exists in database
- ✓ Status is ACTIVE
- ✓ Current date is between start_date and end_date

### 2. ✅ Amount Validation
- ✓ Order amount >= minimum_order_amount
- ✓ Calculated discount <= maximum_discount_amount

### 3. ✅ Usage Limits
- ✓ Total usage < usage_limit (if set)
- ✓ Customer usage < usage_limit_per_customer (if set)

### 4. ✅ Shop-Specific
- ✓ If shop_id is set, promo only works for that shop
- ✓ If shop_id is NULL, promo works for all shops

### 5. ✅ First-Time Only
- ✓ If is_first_time_only = true, only for customers with 0 previous orders

### 6. ✅ User/Device Tracking
- ✓ Check by Customer ID (registered users)
- ✓ Check by Device UUID (guest users)
- ✓ Check by Phone Number (fallback)
- ✓ Cross-check ALL identifiers to prevent abuse

---

## Example Promo Code Configurations

### 1. First 5 Orders Promo
```json
{
  "code": "FIRST5",
  "title": "₹50 Off - First 5 Orders",
  "type": "FIXED_AMOUNT",
  "discountValue": 50.00,
  "minimumOrderAmount": 200.00,
  "usageLimitPerCustomer": 5,
  "isFirstTimeOnly": false
}
```

### 2. First-Time User Only
```json
{
  "code": "WELCOME100",
  "title": "₹100 Off - First Order",
  "type": "FIXED_AMOUNT",
  "discountValue": 100.00,
  "minimumOrderAmount": 300.00,
  "usageLimitPerCustomer": 1,
  "isFirstTimeOnly": true
}
```

### 3. Percentage Discount
```json
{
  "code": "SAVE20",
  "title": "20% Off - Limited Time",
  "type": "PERCENTAGE",
  "discountValue": 20.00,
  "minimumOrderAmount": 500.00,
  "maximumDiscountAmount": 200.00,
  "usageLimitPerCustomer": 3
}
```

### 4. Shop-Specific Promo
```json
{
  "code": "SHOP10OFF",
  "title": "₹10 Off at Thiruna Shop",
  "type": "FIXED_AMOUNT",
  "discountValue": 10.00,
  "shopId": 1,
  "usageLimitPerCustomer": 10
}
```

---

## Mobile App Integration

### Step 1: Get Device UUID
```dart
// Flutter example
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<String> getDeviceUuid() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Android ID
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? '';
  }
  return '';
}
```

### Step 2: Validate Promo Code
```dart
Future<Map<String, dynamic>> validatePromoCode(String code, double amount) async {
  final deviceUuid = await getDeviceUuid();
  final customerId = await getCustomerId(); // From auth
  final phone = await getPhone();

  final response = await http.post(
    Uri.parse('$baseUrl/api/promotions/validate'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'promoCode': code,
      'customerId': customerId,
      'deviceUuid': deviceUuid,
      'phone': phone,
      'orderAmount': amount,
      'shopId': selectedShopId,
    }),
  );

  return jsonDecode(response.body);
}
```

### Step 3: Apply Discount
```dart
if (validationResult['valid']) {
  final discount = validationResult['discountAmount'];
  final newTotal = orderTotal - discount;

  // Update UI
  setState(() {
    appliedPromoCode = promoCode;
    discountAmount = discount;
    finalTotal = newTotal;
  });
}
```

---

## Security Features

### 1. Multi-Identifier Tracking
- Tracks Customer ID + Device UUID + Phone
- Prevents users from creating multiple accounts to reuse promos

### 2. Device Fingerprinting
- Stores IP address and User-Agent
- Helps detect fraudulent activity

### 3. Rate Limiting
- Backend should implement rate limiting on validation endpoint
- Prevents brute-force promo code guessing

### 4. Case-Insensitive Codes
- "FIRST5", "first5", "First5" all work the same
- Improves user experience

---

## Admin Features

### Create Promotion
```sql
INSERT INTO promotions (
    code, title, description, type, discount_value,
    minimum_order_amount, usage_limit_per_customer,
    start_date, end_date, status
) VALUES (
    'FIRST5',
    'First 5 Orders - ₹50 Off',
    'Get ₹50 off on your first 5 orders with minimum order of ₹200',
    'FIXED_AMOUNT',
    50.00,
    200.00,
    5,
    '2025-01-01 00:00:00',
    '2025-12-31 23:59:59',
    'ACTIVE'
);
```

### Check Usage Statistics
```sql
SELECT
    p.code,
    p.title,
    p.used_count AS total_uses,
    COUNT(DISTINCT pu.customer_id) AS unique_customers,
    COUNT(DISTINCT pu.device_uuid) AS unique_devices,
    SUM(pu.discount_applied) AS total_discount_given
FROM promotions p
LEFT JOIN promotion_usage pu ON p.id = pu.promotion_id
WHERE p.id = 1
GROUP BY p.id, p.code, p.title;
```

---

## Next Steps

1. **Run Migration:** Execute `V23__Create_Promotion_Usage_Table.sql`
2. **Restart Backend:** Reload Spring Boot application
3. **Test APIs:** Use Postman to test promo code validation
4. **Integrate Mobile:** Add device UUID tracking and promo code UI
5. **Create Promotions:** Add initial promo codes via database or admin panel

---

## Files Modified/Created

### New Files:
1. `PromotionUsage.java` - Entity for tracking usage
2. `PromotionUsageRepository.java` - Database queries
3. `PromotionService.java` - Business logic and validation
4. `V23__Create_Promotion_Usage_Table.sql` - Database migration

### Modified Files:
1. `PromotionRepository.java` - Added findByCode() and other queries
2. `PromotionController.java` - Added validation and usage APIs

---

## Testing

### Test Case 1: Valid Promo Code
```bash
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{
    "promoCode": "FIRST5",
    "customerId": 1,
    "deviceUuid": "test-device-123",
    "phone": "+919876543210",
    "orderAmount": 500.00,
    "shopId": 1
  }'
```

### Test Case 2: Already Used
```bash
# Use same customer ID again - should fail
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{
    "promoCode": "FIRST5",
    "customerId": 1,
    "deviceUuid": "test-device-123",
    "phone": "+919876543210",
    "orderAmount": 500.00,
    "shopId": 1
  }'
```

---

## Support

For questions or issues, contact the development team.
