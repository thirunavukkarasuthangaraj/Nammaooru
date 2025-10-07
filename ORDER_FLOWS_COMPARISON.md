# Order Flows Comparison - Self-Pickup vs Home Delivery

## 🎯 Two Complete Order Flows

---

## 🏪 FLOW 1: SELF-PICKUP ORDER (NO Driver Involved)

### Participants: Customer ↔ Shop Owner Only

```
┌─────────────┐              ┌─────────────┐
│  CUSTOMER   │              │ SHOP OWNER  │
│   Mobile    │              │   Mobile    │
└─────────────┘              └─────────────┘
       │                            │
       │                            │
```

### Step-by-Step Flow:

#### Step 1: Customer Places Order
```
CUSTOMER MOBILE APP
┌──────────────────────────────────────┐
│  Checkout Screen                     │
├──────────────────────────────────────┤
│  Select Delivery Type:               │
│  ┌──────────┐  ┌──────────┐        │
│  │   🚚     │  │   🏪     │        │
│  │  Home    │  │  Self    │        │
│  │ Delivery │  │  Pickup  │        │
│  │          │  │  ✓       │ ← Selected
│  │  ₹50     │  │  ₹0      │        │
│  └──────────┘  └──────────┘        │
│                                      │
│  Order Summary:                      │
│  Subtotal:        ₹268.00           │
│  Delivery Fee:    ₹0.00  ← FREE!   │
│  Total:           ₹268.00           │
│                                      │
│  [  PLACE ORDER  ]                  │
└──────────────────────────────────────┘

API Call:
POST /api/customer/orders
{
  "deliveryType": "SELF_PICKUP",
  "deliveryFee": 0,
  "shopId": 4
}

ORDER CREATED: Status = PENDING
```

#### Step 2: Shop Owner Receives Notification
```
SHOP OWNER APP - Dashboard
┌──────────────────────────────────────┐
│  🔔 New Order!                       │
├──────────────────────────────────────┤
│  Order #ORD1759815295                │
│  🏪 SELF_PICKUP                      │
│  Customer: Test Customer             │
│  Total: ₹268.00                      │
│  Status: [PENDING]                   │
│                                      │
│  [View Order Details]                │
└──────────────────────────────────────┘
```

#### Step 3: Shop Owner Accepts Order
```
SHOP OWNER APP - Order Details
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  🏪 SELF_PICKUP    [PENDING]         │
├──────────────────────────────────────┤
│  Customer: Test Customer             │
│  Phone: 9876543210                   │
│  Items: 2x Basmati Rice              │
│  Total: ₹268.00 (₹0 delivery)       │
│                                      │
│  Actions:                            │
│  ┌────────────┐  ┌────────────┐    │
│  │ ✓ ACCEPT   │  │ ✗ REJECT   │    │
│  └────────────┘  └────────────┘    │
└──────────────────────────────────────┘

Shop Owner Clicks: ACCEPT

API Call:
POST /api/orders/15/accept

ORDER STATUS: PENDING → CONFIRMED
```

#### Step 4: Shop Owner Starts Preparing
```
SHOP OWNER APP
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  🏪 SELF_PICKUP    [CONFIRMED]       │
├──────────────────────────────────────┤
│  Actions:                            │
│  ┌────────────────────────────────┐ │
│  │  👨‍🍳 START PREPARING           │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘

Shop Owner Clicks: START PREPARING

API Call:
POST /api/orders/15/prepare

ORDER STATUS: CONFIRMED → PREPARING
```

#### Step 5: Shop Owner Marks Order Ready
```
SHOP OWNER APP
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  🏪 SELF_PICKUP    [PREPARING]       │
├──────────────────────────────────────┤
│  Actions:                            │
│  ┌────────────────────────────────┐ │
│  │  ✅ MARK AS READY              │ │
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘

Shop Owner Clicks: MARK AS READY

API Call:
POST /api/orders/15/ready

ORDER STATUS: PREPARING → READY_FOR_PICKUP

CUSTOMER NOTIFICATION: "Your order is ready for pickup!"
```

#### Step 6: Customer Arrives at Shop
```
CUSTOMER MOBILE APP
┌──────────────────────────────────────┐
│  Your Order                          │
├──────────────────────────────────────┤
│  Order #ORD1759815295                │
│  Status: Ready for Pickup ✅         │
│                                      │
│  📍 Shop Location:                   │
│  Thiruna Shop                        │
│  Test Address, Chennai               │
│                                      │
│  [Get Directions]                    │
└──────────────────────────────────────┘

Customer physically goes to the shop
```

#### Step 7: Shop Owner Hands Over Order
```
SHOP OWNER APP
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  🏪 SELF_PICKUP [READY_FOR_PICKUP]   │
├──────────────────────────────────────┤
│  Actions:                            │
│  ┌────────────────────────────────┐ │
│  │  🟢 HANDOVER TO CUSTOMER       │ │ ← GREEN BUTTON
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘

Shop Owner Clicks: HANDOVER TO CUSTOMER

Confirmation Dialog Appears:
┌──────────────────────────────────────┐
│  Confirm Handover                    │
├──────────────────────────────────────┤
│  Are you ready to handover this      │
│  order to the customer?              │
│                                      │
│  ┌────────────────────────────────┐ │
│  │ Order #ORD1759815295           │ │
│  │ Customer: Test Customer        │ │
│  │ Total: ₹268.00                 │ │
│  │                                │ │
│  │ 💰 Collect payment from        │ │
│  │    customer                    │ │
│  └────────────────────────────────┘ │
│                                      │
│  [Cancel]        [HANDOVER]          │
└──────────────────────────────────────┘

Shop Owner Clicks: HANDOVER

API Call:
POST /api/orders/15/handover-self-pickup

Backend Logic:
- order.status = SELF_PICKUP_COLLECTED
- order.paymentStatus = PAID (if COD)
- order.actualDeliveryTime = NOW

ORDER STATUS: READY_FOR_PICKUP → SELF_PICKUP_COLLECTED
PAYMENT STATUS: PENDING → PAID ✅
```

#### Step 8: Order Complete
```
SHOP OWNER APP
┌──────────────────────────────────────┐
│  ✅ Order handed over successfully!  │
├──────────────────────────────────────┤
│  Order #ORD1759815295                │
│  Status: SELF_PICKUP_COLLECTED ✅    │
│  Payment: PAID ✅                    │
└──────────────────────────────────────┘

CUSTOMER APP
┌──────────────────────────────────────┐
│  Order Collected! ✅                 │
├──────────────────────────────────────┤
│  Thank you for your order!           │
│  Order #ORD1759815295                │
│  Status: Collected                   │
└──────────────────────────────────────┘
```

### Timeline Visualization:

```
CUSTOMER                SHOP OWNER              SYSTEM
   │                        │                      │
   │ 1. Select Self-Pickup  │                      │
   │───────────────────────────────────────────────>│
   │    deliveryType=SELF_PICKUP                   │
   │    deliveryFee=₹0                             │
   │                        │                      │
   │                        │ 2. Notification      │
   │                        │<─────────────────────│
   │                        │   New Order (PENDING)│
   │                        │                      │
   │                        │ 3. Accept Order      │
   │                        │─────────────────────>│
   │                        │   Status→CONFIRMED   │
   │                        │                      │
   │                        │ 4. Start Preparing   │
   │                        │─────────────────────>│
   │                        │   Status→PREPARING   │
   │                        │                      │
   │                        │ 5. Mark Ready        │
   │                        │─────────────────────>│
   │                        │   Status→READY_FOR_  │
   │                        │          PICKUP      │
   │ 6. Notification        │                      │
   │<──────────────────────────────────────────────│
   │   Order Ready!         │                      │
   │                        │                      │
   │ 7. Go to Shop          │                      │
   │───────────────────────>│                      │
   │                        │                      │
   │                        │ 8. Handover          │
   │                        │    💰 Collect Payment│
   │                        │─────────────────────>│
   │                        │   Status→SELF_PICKUP_│
   │                        │          COLLECTED   │
   │                        │   Payment→PAID       │
   │                        │                      │
   │ 9. Receive Order ✅    │                      │
   │<───────────────────────│                      │
   │                        │                      │
```

---

## 🚚 FLOW 2: HOME DELIVERY ORDER (Driver IS Involved)

### Participants: Customer ↔ Shop Owner ↔ Delivery Partner

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│  CUSTOMER   │     │ SHOP OWNER  │     │   DELIVERY   │
│   Mobile    │     │   Mobile    │     │   PARTNER    │
└─────────────┘     └─────────────┘     └──────────────┘
       │                   │                     │
       │                   │                     │
```

### Step-by-Step Flow:

#### Step 1: Customer Places Order
```
CUSTOMER MOBILE APP
┌──────────────────────────────────────┐
│  Checkout Screen                     │
├──────────────────────────────────────┤
│  Select Delivery Type:               │
│  ┌──────────┐  ┌──────────┐        │
│  │   🚚     │  │   🏪     │        │
│  │  Home    │  │  Self    │        │
│  │ Delivery │  │  Pickup  │        │
│  │  ✓       │  │          │ ← Selected
│  │  ₹50     │  │  ₹0      │        │
│  └──────────┘  └──────────┘        │
│                                      │
│  Delivery Address:                   │
│  Street: 271/1 Marimanikuppam       │
│  City: Chennai                       │
│  Pincode: 600001                     │
│  Phone: 9876543210                   │
│                                      │
│  Order Summary:                      │
│  Subtotal:        ₹268.00           │
│  Delivery Fee:    ₹50.00            │
│  Total:           ₹318.00           │
│                                      │
│  [  PLACE ORDER  ]                  │
└──────────────────────────────────────┘

API Call:
POST /api/customer/orders
{
  "deliveryType": "HOME_DELIVERY",
  "deliveryFee": 50,
  "deliveryAddress": {...}
}

ORDER CREATED: Status = PENDING
```

#### Step 2-5: Same as Self-Pickup
```
Shop Owner:
- Receives notification
- Accepts order (PENDING → CONFIRMED)
- Starts preparing (CONFIRMED → PREPARING)
- Marks ready (PREPARING → READY_FOR_PICKUP)
```

#### Step 6: System Auto-Assigns Delivery Partner
```
SYSTEM (Automatic)
┌──────────────────────────────────────┐
│  🤖 Auto-Assignment Logic            │
├──────────────────────────────────────┤
│  Finding available delivery partners │
│  within 5km of shop...               │
│                                      │
│  Found: 3 available partners         │
│  Assigning to: Ramesh Kumar          │
│  Distance: 2.3km                     │
│                                      │
│  Assignment Status: SUCCESS ✅       │
└──────────────────────────────────────┘

ORDER UPDATED:
- assignedToDeliveryPartner = true
- deliveryPartnerId = 5
- pickupOTP generated
```

#### Step 7: Delivery Partner Receives Notification
```
DELIVERY PARTNER APP
┌──────────────────────────────────────┐
│  🔔 New Delivery Available!          │
├──────────────────────────────────────┤
│  Order #ORD1759815295                │
│  Pickup: Thiruna Shop                │
│  Delivery: 271/1 Marimanikuppam      │
│  Distance: 2.3km                     │
│  Amount: ₹318.00                     │
│                                      │
│  [ACCEPT]  [REJECT]                  │
└──────────────────────────────────────┘

Delivery Partner Clicks: ACCEPT

ORDER STATUS: Still READY_FOR_PICKUP
(waiting for partner to arrive at shop)
```

#### Step 8: Delivery Partner Goes to Shop
```
DELIVERY PARTNER APP
┌──────────────────────────────────────┐
│  Navigate to Pickup Location         │
├──────────────────────────────────────┤
│  📍 Thiruna Shop                     │
│  Test Address, Chennai               │
│  Distance: 2.3km                     │
│                                      │
│  [Start Navigation]                  │
│  [I've Arrived at Shop]              │
└──────────────────────────────────────┘

Delivery Partner arrives and clicks: I'VE ARRIVED
```

#### Step 9: Shop Owner Verifies Pickup OTP
```
SHOP OWNER APP
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  🚚 HOME_DELIVERY [READY_FOR_PICKUP] │
│  Assigned: Ramesh Kumar              │
├──────────────────────────────────────┤
│  Actions:                            │
│  ┌────────────────────────────────┐ │
│  │  🟠 VERIFY PICKUP OTP          │ │ ← ORANGE BUTTON
│  └────────────────────────────────┘ │
└──────────────────────────────────────┘

Shop Owner Clicks: VERIFY PICKUP OTP

OTP Dialog:
┌──────────────────────────────────────┐
│  Verify Pickup OTP                   │
├──────────────────────────────────────┤
│  Enter OTP from delivery partner:    │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ 1  │ │ 2  │ │ 3  │ │ 4  │       │
│  └────┘ └────┘ └────┘ └────┘       │
│                                      │
│  Delivery Partner: Ramesh Kumar      │
│  Phone: 9876543210                   │
│                                      │
│  [Cancel]        [VERIFY]            │
└──────────────────────────────────────┘

Shop Owner Enters: 1234 (from delivery partner)
Clicks: VERIFY

API Call:
POST /api/orders/15/verify-pickup-otp
{"otp": "1234"}

ORDER STATUS: READY_FOR_PICKUP → OUT_FOR_DELIVERY
```

#### Step 10: Delivery Partner Delivers to Customer
```
DELIVERY PARTNER APP
┌──────────────────────────────────────┐
│  Order Picked Up ✅                  │
│  Navigate to Customer                │
├──────────────────────────────────────┤
│  📍 Delivery Address                 │
│  271/1 Marimanikuppam                │
│  Chennai - 600001                    │
│  Distance: 5.2km                     │
│                                      │
│  Customer: Test Customer             │
│  Phone: 9876543210                   │
│                                      │
│  [Start Navigation]                  │
│  [I've Arrived at Customer]          │
└──────────────────────────────────────┘

Delivery Partner arrives and clicks: I'VE ARRIVED
```

#### Step 11: Customer Verifies Delivery OTP
```
DELIVERY PARTNER APP
┌──────────────────────────────────────┐
│  Verify Delivery OTP                 │
├──────────────────────────────────────┤
│  Get OTP from customer:              │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│  │ 5  │ │ 6  │ │ 7  │ │ 8  │       │
│  └────┘ └────┘ └────┘ └────┘       │
│                                      │
│  💰 COD Amount: ₹318.00              │
│  [ ] Payment Collected               │
│                                      │
│  [Cancel]        [COMPLETE DELIVERY] │
└──────────────────────────────────────┘

Customer provides OTP: 5678
Delivery Partner Enters: 5678
Clicks: COMPLETE DELIVERY

API Call:
POST /api/orders/15/complete-delivery
{"otp": "5678", "paymentCollected": true}

ORDER STATUS: OUT_FOR_DELIVERY → DELIVERED
PAYMENT STATUS: PENDING → PAID ✅
```

#### Step 12: Order Complete
```
DELIVERY PARTNER APP
┌──────────────────────────────────────┐
│  ✅ Delivery Complete!               │
│  Earnings: ₹50                       │
└──────────────────────────────────────┘

CUSTOMER APP
┌──────────────────────────────────────┐
│  Order Delivered! ✅                 │
│  Thank you for your order!           │
│  Order #ORD1759815295                │
└──────────────────────────────────────┘

SHOP OWNER APP
┌──────────────────────────────────────┐
│  Order #ORD1759815295                │
│  Status: DELIVERED ✅                │
│  Payment: PAID ✅                    │
└──────────────────────────────────────┘
```

### Timeline Visualization:

```
CUSTOMER        SHOP OWNER      DELIVERY PARTNER       SYSTEM
   │                │                  │                  │
   │ 1. Home Delivery│                 │                  │
   │────────────────────────────────────────────────────>│
   │   deliveryFee=₹50                 │                  │
   │                │                  │                  │
   │                │ 2. Accept        │                  │
   │                │─────────────────────────────────────>│
   │                │                  │                  │
   │                │ 3. Prepare       │                  │
   │                │─────────────────────────────────────>│
   │                │                  │                  │
   │                │ 4. Mark Ready    │                  │
   │                │─────────────────────────────────────>│
   │                │                  │   5. Auto-assign │
   │                │                  │<─────────────────│
   │                │                  │   Notification   │
   │                │                  │                  │
   │                │                  │ 6. Accept        │
   │                │                  │─────────────────>│
   │                │                  │                  │
   │                │                  │ 7. Go to Shop    │
   │                │                  │─────────────────>│
   │                │                  │                  │
   │                │ 8. Verify Pickup OTP                │
   │                │<─────────────────│                  │
   │                │   (OTP: 1234)    │                  │
   │                │─────────────────────────────────────>│
   │                │                  │   Status→OUT_FOR_│
   │                │                  │          DELIVERY│
   │                │                  │                  │
   │                │                  │ 9. Deliver       │
   │<───────────────────────────────────│                  │
   │                │                  │                  │
   │ 10. Verify Delivery OTP           │                  │
   │   (OTP: 5678)  │                  │                  │
   │───────────────────────────────────>│─────────────────>│
   │                │                  │   Status→DELIVERED│
   │                │                  │   Payment→PAID   │
   │                │                  │                  │
```

---

## 📊 Side-by-Side Comparison

| Step | Self-Pickup 🏪 | Home Delivery 🚚 |
|------|----------------|-------------------|
| **1. Order** | Customer selects Self-Pickup | Customer selects Home Delivery |
| **2. Fee** | ₹0 | ₹50 |
| **3. Address** | Not required | Required |
| **4. Accept** | Shop owner accepts | Shop owner accepts |
| **5. Prepare** | Shop owner prepares | Shop owner prepares |
| **6. Ready** | Shop owner marks ready | Shop owner marks ready |
| **7. Assignment** | ❌ NO driver assigned | ✅ Driver auto-assigned |
| **8. Pickup** | ❌ NO pickup OTP | ✅ Shop verifies pickup OTP |
| **9. Delivery** | Customer collects | Driver delivers |
| **10. Handover** | Shop owner clicks GREEN button | Driver verifies delivery OTP |
| **11. Payment** | Shop owner collects | Driver collects |
| **12. Final Status** | SELF_PICKUP_COLLECTED | DELIVERED |

---

## 🎯 Key Takeaways

### Self-Pickup Benefits:
- ✅ Faster (no waiting for driver)
- ✅ Cheaper (₹0 delivery fee)
- ✅ Simpler (3 participants → 2 participants)
- ✅ No OTP needed
- ✅ Direct shop-to-customer

### Home Delivery Benefits:
- ✅ Convenient for customer (no travel)
- ✅ Better for heavy/bulk orders
- ✅ Door-step delivery
- ✅ Secure (double OTP verification)

---

## 🔐 Security Comparison

| Security Feature | Self-Pickup | Home Delivery |
|-----------------|-------------|---------------|
| **Pickup OTP** | ❌ Not needed | ✅ Required |
| **Delivery OTP** | ❌ Not needed | ✅ Required |
| **Driver Verification** | ❌ No driver | ✅ Verified driver |
| **Payment Collection** | Shop owner | Delivery partner |
| **Customer Verification** | In-person at shop | OTP at doorstep |

---

## 💡 Business Logic

```java
// Backend: OrderService.java

public Order createOrder(OrderRequest request) {
    // Check delivery type
    DeliveryType deliveryType = request.getDeliveryType();

    if (deliveryType == DeliveryType.SELF_PICKUP) {
        // Self-pickup logic
        order.setDeliveryFee(BigDecimal.ZERO);
        order.setRequiresDriver(false);
        // Address is optional
    } else {
        // Home delivery logic
        order.setDeliveryFee(BigDecimal.valueOf(50));
        order.setRequiresDriver(true);
        // Address is mandatory
        validateAddress(request.getDeliveryAddress());
    }

    return orderRepository.save(order);
}

// When order is READY_FOR_PICKUP
public void markReady(Long orderId) {
    Order order = findOrder(orderId);
    order.setStatus(OrderStatus.READY_FOR_PICKUP);

    if (order.getDeliveryType() == DeliveryType.HOME_DELIVERY) {
        // Auto-assign driver
        autoAssignDeliveryPartner(order);
        generatePickupOTP(order);
    } else {
        // Just notify customer
        notifyCustomer(order, "Your order is ready for pickup!");
    }
}
```

---

## 📱 UI Button Colors

| Order Type | Button Text | Color | When Shown |
|-----------|-------------|-------|------------|
| Self-Pickup | "Handover to Customer" | 🟢 GREEN | READY_FOR_PICKUP |
| Home Delivery | "Verify Pickup OTP" | 🟠 ORANGE | READY_FOR_PICKUP + Driver Assigned |

---

This document shows **BOTH complete flows** for your Nammaooru shop management system!
