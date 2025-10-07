# Self-Pickup Order Flow - Complete Test

## Prerequisites
- Backend running on http://localhost:8080
- Shop Owner App running on http://localhost:8081
- Customer Mobile App

## Step 1: Customer Login
```bash
curl -X POST http://localhost:8080/api/mobile/login \
  -H "Content-Type: application/json" \
  -d '{"email":"gigsumomeeting@gmail.com","password":"Test@123"}'
```

## Step 2: Create Self-Pickup Order
```bash
TOKEN="<customer_token_from_step1>"

curl -X POST http://localhost:8080/api/customer/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "shopId": 4,
    "deliveryType": "SELF_PICKUP",
    "items": [
      {
        "productId": 8,
        "productName": "Basmati Rice",
        "quantity": 2,
        "price": 134
      }
    ],
    "subtotal": 268,
    "deliveryFee": 0,
    "discount": 0,
    "total": 268,
    "paymentMethod": "CASH_ON_DELIVERY",
    "customerInfo": {
      "firstName": "Test",
      "lastName": "Customer",
      "email": "test@example.com",
      "phone": "9876543210"
    },
    "notes": "Self-pickup test order"
  }'
```

## Step 3: Shop Owner Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```

## Step 4: Shop Owner Accepts Order
```bash
SHOP_TOKEN="<shop_owner_token_from_step3>"
ORDER_ID="<order_id_from_step2>"

curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/accept" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -d '{}'
```

## Step 5: Start Preparing
```bash
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/prepare" \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

## Step 6: Mark as Ready
```bash
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/ready" \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

## Step 7: Handover to Customer (Self-Pickup)
```bash
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/handover-self-pickup" \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

## Expected Response from Step 7:
```json
{
  "statusCode": "0000",
  "message": "Order handed over successfully",
  "data": {
    "orderId": 15,
    "orderNumber": "ORD1759815295000",
    "status": "SELF_PICKUP_COLLECTED",
    "paymentStatus": "PAID",
    "message": "Order handed over successfully"
  }
}
```

## UI Flow in Shop Owner App (http://localhost:8081)

### After Step 2 (Order Created):
1. Shop Owner sees order in **Pending Orders** tab
2. Order card shows:
   - 🏪 **SELF_PICKUP** badge
   - Customer name
   - Total amount
   - Order items

### After Step 4 (Order Accepted):
3. Order moves to **Confirmed** status
4. Green "Start Preparing" button appears

### After Step 5 (Preparing):
5. Order status shows **"Preparing"**
6. Orange "Mark as Ready" button appears

### After Step 6 (Ready):
7. Order status shows **"Ready for Pickup"**
8. 🟢 **Green "Handover to Customer" button** appears
9. (NOT the orange "Verify Pickup OTP" button - that's for delivery orders)

### When Shop Owner Clicks "Handover to Customer":
10. Confirmation dialog appears:
    ```
    ┌──────────────────────────────────────┐
    │ Confirm Handover                     │
    ├──────────────────────────────────────┤
    │ Are you ready to handover this       │
    │ order to the customer?               │
    │                                      │
    │ ┌──────────────────────────────────┐ │
    │ │ Order #15                        │ │
    │ │ Customer: Test Customer          │ │
    │ │ Total: ₹268.00                   │ │
    │ │                                  │ │
    │ │ 💰 Collect payment from customer │ │
    │ └──────────────────────────────────┘ │
    │                                      │
    │ [Cancel]          [Handover]         │
    └──────────────────────────────────────┘
    ```

### After Step 7 (Handover Complete):
11. Success message: "✅ Order handed over successfully!"
12. Order status: **SELF_PICKUP_COLLECTED**
13. Payment status: **PAID**
14. Order moves to completed orders

## Comparison with Home Delivery

### Self-Pickup (🏪):
- ₹0 delivery fee
- No address required
- Customer collects from shop
- **Button**: 🟢 "Handover to Customer"
- Direct handover (no OTP)

### Home Delivery (🚚):
- ₹50 delivery fee
- Address required
- Delivery partner assigned
- **Button**: 🟠 "Verify Pickup OTP"
- OTP verification required

## Database Schema
```sql
-- Orders table includes:
delivery_type VARCHAR(255) CHECK (delivery_type IN ('HOME_DELIVERY', 'SELF_PICKUP'))
-- Defaults to 'HOME_DELIVERY'

-- Order statuses include:
-- SELF_PICKUP_COLLECTED (terminal status for self-pickup orders)
```
