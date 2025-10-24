# Self-Pickup Order Feature Documentation

## Overview

The self-pickup order feature allows customers to place orders and collect them directly from the shop without requiring a delivery partner. This streamlines the order fulfillment process for customers who prefer to pick up their orders themselves.

## Table of Contents

1. [Feature Comparison](#feature-comparison)
2. [Order Flow](#order-flow)
3. [Backend Implementation](#backend-implementation)
4. [Mobile App Implementation](#mobile-app-implementation)
5. [API Endpoints](#api-endpoints)
6. [Database Schema](#database-schema)
7. [Testing Guide](#testing-guide)

---

## Feature Comparison

### Self-Pickup vs Home Delivery

| Aspect | Self-Pickup | Home Delivery |
|--------|-------------|---------------|
| **Delivery Partner** | Not required | Required |
| **Customer Action** | Goes to shop to collect | Waits at delivery address |
| **Status Flow** | PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP → **DELIVERED** | PENDING → CONFIRMED → PREPARING → READY_FOR_PICKUP → OUT_FOR_DELIVERY → DELIVERED |
| **Payment Marking** | Automatically marked PAID on handover | Marked PAID after customer receives |
| **Handover Process** | Shop owner clicks "Handover to Customer" | Delivery partner verifies OTP |
| **OTP Verification** | Optional | Required for delivery partner |
| **UI Button** | Green "Handover to Customer" | Blue "Verify Pickup OTP" |

---

## Order Flow

### Self-Pickup Order Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOMER JOURNEY                              │
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │ PENDING  │──▶│CONFIRMED │──▶│ PREPARING│──▶│  READY   │    │
│  │          │   │          │   │          │   │FOR_PICKUP│    │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘    │
│       │                                              │          │
│       │ Customer                          Customer   │          │
│       │ cancels                           arrives    │          │
│       ▼                                              ▼          │
│  ┌──────────┐                                  ┌──────────┐    │
│  │CANCELLED │                                  │DELIVERED │    │
│  │          │                                  │ + PAID   │    │
│  └──────────┘                                  └──────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Status Transitions

#### 1. PENDING (Order Created)
- **Trigger:** Customer places order via mobile app
- **Actions:**
  - Order created with `deliveryType = SELF_PICKUP`
  - Customer details saved
  - No delivery address required
  - Shop owner receives notification
- **Payment Status:** PENDING
- **Who can act:** Customer (cancel), Shop Owner (accept/reject)

#### 2. CONFIRMED (Shop Accepts)
- **Trigger:** Shop owner clicks "Accept Order"
- **Actions:**
  - Order status changes to CONFIRMED
  - Customer receives confirmation notification
  - Shop begins preparing items
- **Payment Status:** PENDING
- **Who can act:** Customer (cancel), Shop Owner (start preparing)

#### 3. PREPARING (Shop Packing)
- **Trigger:** Shop owner clicks "Start Preparing"
- **Actions:**
  - Order status changes to PREPARING
  - Customer can track order status
  - Estimated completion time shown
- **Payment Status:** PENDING
- **Who can act:** Shop Owner (mark as ready)

#### 4. READY_FOR_PICKUP (Ready to Collect)
- **Trigger:** Shop owner clicks "Mark as Ready for Pickup"
- **Actions:**
  - Order status changes to READY_FOR_PICKUP
  - Pickup OTP generated (e.g., "1234")
  - Customer receives notification with OTP
  - Customer comes to shop to collect
- **Payment Status:** PENDING
- **Who can act:** Shop Owner (handover to customer)

#### 5. DELIVERED (Handover Complete)
- **Trigger:** Shop owner clicks "Handover to Customer"
- **Actions:**
  - Order status changes to DELIVERED
  - Payment status automatically changed to PAID (for COD)
  - Actual delivery time recorded
  - Order completion notification sent
- **Payment Status:** PAID
- **Who can act:** None (order complete)

---

## Backend Implementation

### File: `OrderController.java`

**Location:** `backend/src/main/java/com/shopmanagement/controller/OrderController.java`

#### Key Method: `verifyPickupOTP` (Lines 242-320)

This method handles the handover process differently based on delivery type:

```java
@PostMapping("/{orderId}/verify-pickup-otp")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
public ResponseEntity<ApiResponse<Map<String, Object>>> verifyPickupOTP(
        @PathVariable Long orderId,
        @RequestBody Map<String, String> request) {

    // ... OTP verification code ...

    // Check delivery type - SELF_PICKUP goes directly to DELIVERED
    String finalStatus;
    String successMessage;

    if (order.getDeliveryType() == Order.DeliveryType.SELF_PICKUP) {
        // Self-pickup: customer collects from shop, mark as DELIVERED immediately
        order.setStatus(Order.OrderStatus.DELIVERED);
        order.setActualDeliveryTime(java.time.LocalDateTime.now());

        // Mark payment as PAID if it's Cash on Delivery
        if (order.getPaymentMethod() == Order.PaymentMethod.CASH_ON_DELIVERY) {
            order.setPaymentStatus(Order.PaymentStatus.PAID);
            log.info("✅ Payment marked as PAID for self-pickup order {}", orderId);
        }

        finalStatus = "DELIVERED";
        successMessage = "Order handed over to customer successfully";
        log.info("✅ Self-pickup order {} marked as DELIVERED", orderId);
    } else {
        // Home delivery: hand over to delivery partner, mark as OUT_FOR_DELIVERY
        order.setStatus(Order.OrderStatus.OUT_FOR_DELIVERY);

        // Update the OrderAssignment status to PICKED_UP
        Optional<OrderAssignment> assignmentOpt = orderAssignmentRepository.findByOrderIdAndStatus(
            orderId, OrderAssignment.AssignmentStatus.ACCEPTED);

        if (assignmentOpt.isPresent()) {
            OrderAssignment assignment = assignmentOpt.get();
            assignment.setStatus(OrderAssignment.AssignmentStatus.PICKED_UP);
            orderAssignmentRepository.save(assignment);
            log.info("✅ OrderAssignment status updated to PICKED_UP for order {}", orderId);
        }

        finalStatus = "OUT_FOR_DELIVERY";
        successMessage = "Order handed over to delivery partner successfully";
        log.info("✅ Home delivery order {} marked as OUT_FOR_DELIVERY", orderId);
    }

    orderRepository.save(order);

    Map<String, Object> responseData = Map.of(
        "orderId", orderId,
        "message", successMessage,
        "newStatus", finalStatus
    );

    return ResponseUtil.success(responseData, "Pickup verified successfully");
}
```

#### Alternative Method: `handoverSelfPickup` (Line 406)

Direct endpoint for self-pickup orders without OTP verification:

```java
@PostMapping("/{orderId}/handover-self-pickup")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN') or hasRole('SHOP_OWNER')")
public ResponseEntity<ApiResponse<Map<String, Object>>> handoverSelfPickup(
        @PathVariable Long orderId) {
    // Direct handover for self-pickup orders
    // Marks order as DELIVERED and payment as PAID
}
```

### File: `Order.java` (Entity)

**Location:** `backend/src/main/java/com/shopmanagement/entity/Order.java`

```java
@Enumerated(EnumType.STRING)
@Column(nullable = true)
private DeliveryType deliveryType = DeliveryType.HOME_DELIVERY;

public enum DeliveryType {
    HOME_DELIVERY,
    SELF_PICKUP
}

public enum OrderStatus {
    PENDING,
    CONFIRMED,
    PREPARING,
    READY_FOR_PICKUP,
    OUT_FOR_DELIVERY,
    DELIVERED,
    CANCELLED,
    REFUNDED
}

public enum PaymentStatus {
    PENDING,
    PAID,
    FAILED,
    REFUNDED
}
```

---

## Mobile App Implementation

### Shop Owner App

#### File: `order_details_screen.dart`

**Location:** `mobile/shop-owner-app/lib/screens/orders/order_details_screen.dart`

**Lines 397-421:** Differentiated buttons based on delivery type

```dart
// Show different buttons based on delivery type
if (order.deliveryType == 'SELF_PICKUP') ...[
  // Self-pickup orders: Direct handover button
  ElevatedButton.icon(
    onPressed: () => _handoverSelfPickup(context, order, orderProvider),
    icon: const Icon(Icons.how_to_reg),
    label: const Text('Handover to Customer'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
] else ...[
  // Home delivery orders: OTP verification button
  ElevatedButton.icon(
    onPressed: () => _verifyPickupOTP(context, order, orderProvider),
    icon: const Icon(Icons.verified),
    label: const Text('Verify Pickup OTP'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
]
```

#### File: `api_service.dart`

**Location:** `mobile/shop-owner-app/lib/services/api_service.dart`

**Lines 438-462:** API method for self-pickup handover

```dart
static Future<ApiResponse> handoverSelfPickup(String orderId) async {
  if (_useMockData) {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse.success({
      'orderId': orderId,
      'orderNumber': 'ORD$orderId',
      'status': 'DELIVERED',
      'paymentStatus': 'PAID',
      'message': 'Order handed over successfully'
    });
  }

  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl${ApiEndpoints.orders}/$orderId/handover-self-pickup'),
          headers: _authHeaders,
        )
        .timeout(timeout);

    return _handleResponse(response);
  } catch (e) {
    return ApiResponse.error('Network error: ${e.toString()}');
  }
}
```

### Customer Mobile App

#### File: `order_model.dart`

**Location:** `mobile/nammaooru_mobile_app/lib/core/models/order_model.dart`

Status display text mapping:

```dart
String get statusDisplayText {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'Order Placed';
    case 'CONFIRMED':
      return 'Confirmed';
    case 'PREPARING':
      return 'Being Prepared';
    case 'READY_FOR_PICKUP':
      return 'Ready for Pickup';
    case 'OUT_FOR_DELIVERY':
      return 'Out for Delivery';
    case 'DELIVERED':
      return 'Delivered';
    case 'CANCELLED':
      return 'Cancelled';
    case 'REFUNDED':
      return 'Refunded';
    default:
      return status;
  }
}
```

---

## API Endpoints

### 1. Create Order (Self-Pickup)

**Endpoint:** `POST /api/customer/orders`

**Request Body:**
```json
{
  "shopId": 4,
  "deliveryType": "SELF_PICKUP",
  "paymentMethod": "CASH_ON_DELIVERY",
  "customerInfo": {
    "firstName": "John",
    "lastName": "Doe",
    "phone": "9876543210",
    "email": "john@example.com"
  },
  "items": [
    {
      "productId": 123,
      "quantity": 2,
      "price": 100.00
    }
  ],
  "notes": "Please pack carefully"
}
```

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Order created successfully",
  "data": {
    "id": 456,
    "orderNumber": "ORD1759848520468",
    "status": "PENDING",
    "deliveryType": "SELF_PICKUP",
    "paymentStatus": "PENDING",
    "totalAmount": 200.00
  }
}
```

### 2. Handover Self-Pickup Order

**Endpoint:** `POST /api/orders/{orderId}/handover-self-pickup`

**Headers:**
```
Authorization: Bearer <shop_owner_token>
```

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Pickup verified successfully",
  "data": {
    "orderId": 456,
    "message": "Order handed over to customer successfully",
    "newStatus": "DELIVERED"
  }
}
```

### 3. Verify Pickup OTP (Alternative for Self-Pickup)

**Endpoint:** `POST /api/orders/{orderId}/verify-pickup-otp`

**Request Body:**
```json
{
  "otp": "1234"
}
```

**Response:**
```json
{
  "statusCode": "0000",
  "message": "Pickup verified successfully",
  "data": {
    "orderId": 456,
    "message": "Order handed over to customer successfully",
    "newStatus": "DELIVERED"
  }
}
```

---

## Database Schema

### Orders Table

```sql
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT NOT NULL,
    shop_id BIGINT NOT NULL,

    -- Delivery Information
    delivery_type VARCHAR(20) DEFAULT 'HOME_DELIVERY', -- 'HOME_DELIVERY' or 'SELF_PICKUP'
    delivery_address TEXT,
    delivery_city VARCHAR(100),
    delivery_state VARCHAR(100),
    delivery_postal_code VARCHAR(20),
    delivery_phone VARCHAR(20),
    delivery_contact_name VARCHAR(100),

    -- Order Status
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(30) NOT NULL,

    -- Pickup Information
    pickup_otp VARCHAR(10),
    pickup_otp_generated_at TIMESTAMP,
    pickup_otp_verified_at TIMESTAMP,

    -- Amounts
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    delivery_fee DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,

    -- Timestamps
    estimated_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Notes
    notes TEXT,
    cancellation_reason TEXT,

    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (shop_id) REFERENCES shops(id)
);
```

### Key Columns for Self-Pickup:

- `delivery_type`: Set to `'SELF_PICKUP'`
- `delivery_address`: Optional for self-pickup orders
- `pickup_otp`: Generated OTP for verification
- `pickup_otp_verified_at`: Timestamp when customer collects order
- `actual_delivery_time`: Set when order is marked as DELIVERED

---

## Testing Guide

### Test Scenario 1: Complete Self-Pickup Order Flow

1. **Create Order (Customer App)**
   - Login as customer
   - Browse products from a shop
   - Add items to cart
   - Select "Self Pickup" as delivery type
   - Place order
   - **Expected:** Order created with status PENDING, deliveryType = SELF_PICKUP

2. **Accept Order (Shop Owner App)**
   - Login as shop owner
   - View pending orders
   - Click "Accept Order"
   - **Expected:** Order status changes to CONFIRMED

3. **Start Preparing (Shop Owner App)**
   - Click "Start Preparing"
   - **Expected:** Order status changes to PREPARING

4. **Mark Ready for Pickup (Shop Owner App)**
   - Click "Mark as Ready for Pickup"
   - **Expected:**
     - Order status changes to READY_FOR_PICKUP
     - Pickup OTP generated
     - Customer receives notification

5. **Customer Arrives at Shop**
   - Customer shows OTP to shop owner

6. **Handover to Customer (Shop Owner App)**
   - Click green "Handover to Customer" button
   - **Expected:**
     - Order status changes to DELIVERED
     - Payment status changes to PAID (if COD)
     - Actual delivery time recorded
     - No OUT_FOR_DELIVERY status (skipped)

### Test Scenario 2: Verify Button Differentiation

1. **Create Self-Pickup Order**
   - Follow steps above to create SELF_PICKUP order
   - Mark as READY_FOR_PICKUP

2. **Check Shop Owner UI**
   - **Expected:** Green button labeled "Handover to Customer"

3. **Create Home Delivery Order**
   - Create order with deliveryType = HOME_DELIVERY
   - Mark as READY_FOR_PICKUP
   - Assign delivery partner

4. **Check Shop Owner UI**
   - **Expected:** Blue button labeled "Verify Pickup OTP"

### Test Scenario 3: Payment Status Verification

1. **Create COD Self-Pickup Order**
   - Create order with paymentMethod = CASH_ON_DELIVERY
   - Complete order flow to DELIVERED

2. **Verify Payment Status**
   - Check order details
   - **Expected:** Payment status automatically set to PAID

3. **Create Online Paid Self-Pickup Order**
   - Create order with paymentMethod = ONLINE
   - Mark as paid during checkout
   - Complete order flow

4. **Verify Payment Status**
   - **Expected:** Payment status remains PAID (already paid)

### API Testing with cURL

```bash
# 1. Create self-pickup order
curl -X POST http://localhost:8080/api/customer/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <customer_token>" \
  -d '{
    "shopId": 4,
    "deliveryType": "SELF_PICKUP",
    "paymentMethod": "CASH_ON_DELIVERY",
    "customerInfo": {
      "firstName": "Test",
      "lastName": "Customer",
      "phone": "9876543210"
    },
    "items": [{"productId": 123, "quantity": 1, "price": 100}]
  }'

# 2. Handover self-pickup order
curl -X POST http://localhost:8080/api/orders/456/handover-self-pickup \
  -H "Authorization: Bearer <shop_owner_token>"
```

---

## Configuration

### App Configuration

**File:** `mobile/shop-owner-app/lib/utils/app_config.dart`

```dart
class AppConfig {
  // Ensure mock data is disabled
  static const bool useMockData = false; // Use real API

  // API configuration
  static String get apiBaseUrl {
    if (kIsProduction) {
      return 'https://api.nammaooru.com';
    } else {
      return 'http://192.168.1.11:8080/api';
    }
  }
}
```

**IMPORTANT:** Always ensure `useMockData = false` in production to avoid showing dummy data to shop owners.

---

## Troubleshooting

### Issue: Order not marked as DELIVERED

**Symptoms:**
- Clicking "Handover to Customer" doesn't change status to DELIVERED
- Order remains in READY_FOR_PICKUP status

**Solution:**
1. Check backend logs for errors
2. Verify `deliveryType` is set to `SELF_PICKUP` in order
3. Ensure shop owner has proper authorization
4. Check if OTP is valid (if using OTP verification)

### Issue: Payment not marked as PAID

**Symptoms:**
- Order marked as DELIVERED but payment status still PENDING
- Payment status not updating automatically

**Solution:**
1. Verify payment method is `CASH_ON_DELIVERY`
2. Check backend logs for payment update errors
3. Ensure the `verifyPickupOTP` or `handoverSelfPickup` method is executing the payment update logic

### Issue: Wrong button showing in shop owner app

**Symptoms:**
- Blue "Verify Pickup OTP" button showing for self-pickup orders
- Green "Handover to Customer" button showing for home delivery

**Solution:**
1. Check order's `deliveryType` value in database
2. Verify frontend is reading `deliveryType` correctly
3. Clear app cache and restart

---

## Security Considerations

1. **Authorization:**
   - Only shop owners can handover orders
   - Customers cannot mark their own orders as delivered
   - All endpoints protected with JWT authentication

2. **OTP Verification:**
   - Optional for self-pickup (can use direct handover)
   - OTP expires after configured time
   - OTP only valid for specific order

3. **Payment Security:**
   - Payment status changes logged
   - Only COD orders auto-marked as PAID on delivery
   - Online payments already marked PAID during checkout

---

## Future Enhancements

1. **QR Code Scanning:**
   - Generate QR code for order
   - Shop owner scans QR code to verify customer
   - Eliminates need for OTP entry

2. **Customer Arrival Notification:**
   - Customer clicks "I'm here" button when arriving at shop
   - Shop owner receives notification
   - Helps prepare order for quick handover

3. **Pickup Time Slots:**
   - Customer selects preferred pickup time
   - Shop can manage rush hours
   - Better customer experience

4. **Pickup Instructions:**
   - Customer can add special pickup instructions
   - "Pickup from side door", "Call when ready", etc.

5. **Rating System:**
   - Customer rates pickup experience
   - Shop can track self-pickup satisfaction
   - Identify areas for improvement

---

## Support

For issues or questions:
- Backend: Check `backend/src/main/java/com/shopmanagement/controller/OrderController.java`
- Mobile: Check `mobile/shop-owner-app/lib/screens/orders/order_details_screen.dart`
- API: Review this documentation's [API Endpoints](#api-endpoints) section

---

**Last Updated:** 2025-10-07
**Version:** 1.0.0
**Authors:** Development Team
