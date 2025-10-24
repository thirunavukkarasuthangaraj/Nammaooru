# ✅ Customer Promo Code API - Ready for Mobile App

## Summary

The promo code system is **100% working** for customer mobile apps! All endpoints are functional.

## For Customer Mobile App Integration

### 1. Get Active Promo Codes (Public - No Auth Required)

Shows all active promos to customers:

```bash
curl -X GET "http://localhost:8080/api/promotions/active"
```

**Response:**
```json
{
  "content": [
    {
      "id": 1,
      "code": "FIRST50",
      "title": "First Order 50% Off",
      "type": "PERCENTAGE",
      "discountValue": 50,
      "minimumOrderAmount": 100,
      "status": "ACTIVE",
      ...
    }
  ]
}
```

### 2. Validate Promo Code Before Order (Public - No Auth Required)

Customers can validate a promo code and get discount amount:

```bash
curl -X POST "http://localhost:8080/api/promotions/validate" \
  -H "Content-Type: application/json" \
  -d '{
    "promoCode": "FIRST50",
    "customerId": 1,
    "deviceUuid": "android_xyz123",
    "phone": "+919876543210",
    "orderAmount": 500,
    "shopId": 1
  }'
```

**Success Response:**
```json
{
  "valid": true,
  "message": "Promo code applied successfully!",
  "discountAmount": 250,
  "promotionId": 1,
  "promotionTitle": "First Order 50% Off",
  "discountType": "PERCENTAGE",
  "statusCode": "0000"
}
```

**Error Responses:**

*Invalid Code:*
```json
{
  "valid": false,
  "message": "Promo code not found or inactive",
  "discountAmount": 0,
  "statusCode": "1001"
}
```

*Already Used:*
```json
{
  "valid": false,
  "message": "You have already used this promo code",
  "discountAmount": 0,
  "statusCode": "1001"
}
```

*Minimum Order Not Met:*
```json
{
  "valid": false,
  "message": "Minimum order amount is ₹100",
  "discountAmount": 0,
  "statusCode": "1001"
}
```

## Mobile App Integration Flow

### Step 1: Show Available Promos
When user opens the app or cart page:
```dart
// Flutter example
final response = await http.get(
  Uri.parse('${baseUrl}/api/promotions/active')
);
// Display promos in a card/banner
```

### Step 2: Apply Promo Code
When user enters a promo code:
```dart
final response = await http.post(
  Uri.parse('${baseUrl}/api/promotions/validate'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'promoCode': promoCode,
    'customerId': customerId,
    'deviceUuid': deviceId,
    'phone': userPhone,
    'orderAmount': cartTotal,
    'shopId': selectedShopId
  })
);

final result = jsonDecode(response.body);
if (result['valid']) {
  // Show success: "₹${result['discountAmount']} discount applied!"
  // Update cart total
} else {
  // Show error: result['message']
}
```

### Step 3: Record Usage After Order
When order is placed successfully, the backend automatically records promo usage in `promotion_usage` table with:
- Customer ID
- Device UUID
- Phone number
- Order ID
- Discount amount

This prevents the same customer from using the code again (based on `usageLimitPerCustomer`).

## How Anti-Abuse Works

The system tracks usage by **3 identifiers**:
1. **Customer ID** (for logged-in users)
2. **Device UUID** (for all users, including guests)
3. **Phone Number** (from order details)

If ANY of these match a previous usage, the promo code is rejected. This prevents:
- ❌ Reinstalling the app
- ❌ Using different accounts
- ❌ Using different phone numbers
- ❌ Guest mode abuse

## Promo Code Types

### 1. PERCENTAGE
```json
{
  "type": "PERCENTAGE",
  "discountValue": 50,
  "minimumOrderAmount": 100,
  "maximumDiscountAmount": 500
}
```
**Calculation:** `discount = min(orderAmount * 0.5, 500)`

### 2. FIXED_AMOUNT
```json
{
  "type": "FIXED_AMOUNT",
  "discountValue": 100,
  "minimumOrderAmount": 200
}
```
**Calculation:** `discount = 100` (if order >= 200)

### 3. FREE_SHIPPING
```json
{
  "type": "FREE_SHIPPING",
  "minimumOrderAmount": 0
}
```
**Calculation:** `discount = deliveryFee`

## Testing

### Test 1: Valid Promo
```bash
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{"promoCode":"FIRST50","orderAmount":500}'
```
**Expected:** `"valid": true, "discountAmount": 250`

### Test 2: Invalid Code
```bash
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{"promoCode":"INVALID123","orderAmount":500}'
```
**Expected:** `"valid": false, "message": "Promo code not found..."`

### Test 3: Below Minimum
```bash
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{"promoCode":"FIRST50","orderAmount":50}'
```
**Expected:** `"valid": false, "message": "Minimum order amount is ₹100"`

## Current Promo Codes

| Code | Discount | Min Order | Max Discount | Usage Limit | Status |
|------|----------|-----------|--------------|-------------|--------|
| FIRST50 | 50% | ₹100 | ₹500 | 1 per customer | ACTIVE |

## API Base URLs

- **Development:** `http://localhost:8080`
- **Production:** `https://api.nammaooru.com`

## Status Codes

| Code | Meaning |
|------|---------|
| 0000 | Success |
| 1001 | Validation Error (invalid/expired/already used) |
| 9999 | Server Error |

---

## ✅ Ready for Production!

The promo code API is fully functional and ready to be integrated into your mobile app. All validation, usage tracking, and anti-abuse mechanisms are working perfectly! 🎉
