# Complete Order Flow Documentation

## Table of Contents

1. [Overview](#overview)
2. [Flow Comparison Matrix](#flow-comparison-matrix)
3. [Self-Pickup Order Flow](#self-pickup-order-flow)
4. [Home Delivery Order Flow](#home-delivery-order-flow)
5. [Payment Flows](#payment-flows)
6. [Cancellation Flows](#cancellation-flows)
7. [Notification Flows](#notification-flows)
8. [Complete System Architecture Flow](#complete-system-architecture-flow)

---

## Overview

This document provides a comprehensive view of all order flows in the Nammaooru Thiru Software System, including self-pickup, home delivery, payment processing, and cancellations.

---

## Flow Comparison Matrix

| Flow Step | Self-Pickup | Home Delivery |
|-----------|-------------|---------------|
| **1. Order Creation** | Customer selects SELF_PICKUP | Customer selects HOME_DELIVERY |
| **2. Address Required** | No (optional) | Yes (mandatory) |
| **3. Order Placed** | Status: PENDING | Status: PENDING |
| **4. Shop Accepts** | Status: CONFIRMED | Status: CONFIRMED |
| **5. Preparation** | Status: PREPARING | Status: PREPARING |
| **6. Ready State** | Status: READY_FOR_PICKUP | Status: READY_FOR_PICKUP |
| **7. Assignment** | No delivery partner needed | Delivery partner assigned |
| **8. OTP Generation** | Optional | Required for partner pickup |
| **9. Handover** | Customer arrives at shop | Partner picks up with OTP |
| **10. Transit** | N/A (skipped) | Status: OUT_FOR_DELIVERY |
| **11. Final Delivery** | Status: DELIVERED (1 step) | Status: DELIVERED (2 steps) |
| **12. Payment** | Auto PAID on handover (COD) | PAID on customer receipt |
| **13. Total Steps** | 6 main steps | 8 main steps |

---

## Self-Pickup Order Flow

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SELF-PICKUP ORDER FLOW                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   CUSTOMER   │
│  Mobile App  │
└──────┬───────┘
       │
       │ 1. Browse Products
       │ 2. Add to Cart
       │ 3. Select "Self Pickup"
       │ 4. Place Order
       │
       ▼
┌──────────────────────────────────────┐
│     ORDER CREATED                    │
│  Status: PENDING                     │
│  DeliveryType: SELF_PICKUP          │
│  Payment: PENDING                    │
│  DeliveryAddress: Optional           │
└──────────┬───────────────────────────┘
           │
           │ Firebase Notification
           │
           ▼
┌──────────────────────────────────────┐
│   SHOP OWNER                         │
│   Receives Order Notification        │
└──────────┬───────────────────────────┘
           │
           │ Reviews Order
           │ Clicks "Accept Order"
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER CONFIRMED                  │
│  Status: CONFIRMED                   │
│  Payment: PENDING                    │
└──────────┬───────────────────────────┘
           │
           │ Shop Owner starts preparing
           │ Clicks "Start Preparing"
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER PREPARING                  │
│  Status: PREPARING                   │
│  Payment: PENDING                    │
└──────────┬───────────────────────────┘
           │
           │ Items packed and ready
           │ Clicks "Mark Ready for Pickup"
           │
           ▼
┌──────────────────────────────────────┐
│     READY FOR PICKUP                 │
│  Status: READY_FOR_PICKUP           │
│  Payment: PENDING                    │
│  OTP: Generated (e.g., "1234")      │
└──────────┬───────────────────────────┘
           │
           │ Notification sent to Customer
           │ "Your order is ready!"
           │
           ▼
┌──────────────────────────────────────┐
│   CUSTOMER ARRIVES AT SHOP           │
│   Shows OTP or Order Number          │
└──────────┬───────────────────────────┘
           │
           │ Shop Owner verifies customer
           │ Clicks "Handover to Customer"
           │ (Green Button)
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER DELIVERED ✅               │
│  Status: DELIVERED                   │
│  Payment: PAID (auto-marked)         │
│  ActualDeliveryTime: Set             │
│                                      │
│  ⚠️ OUT_FOR_DELIVERY SKIPPED         │
└──────────────────────────────────────┘
           │
           │ Completion notification
           │
           ▼
┌──────────────────────────────────────┐
│   CUSTOMER RECEIVES NOTIFICATION     │
│   "Order delivered successfully!"    │
└──────────────────────────────────────┘
```

### Backend Code Flow (Self-Pickup)

```
OrderController.verifyPickupOTP() or handoverSelfPickup()
    │
    ├─► Check deliveryType
    │
    ├─► if (SELF_PICKUP):
    │       │
    │       ├─► order.setStatus(DELIVERED)
    │       ├─► order.setActualDeliveryTime(now)
    │       │
    │       ├─► if (paymentMethod == COD):
    │       │       └─► order.setPaymentStatus(PAID)
    │       │
    │       ├─► orderRepository.save(order)
    │       │
    │       └─► Return success message
    │
    └─► Save order & send notification
```

---

## Home Delivery Order Flow

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        HOME DELIVERY ORDER FLOW                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   CUSTOMER   │
│  Mobile App  │
└──────┬───────┘
       │
       │ 1. Browse Products
       │ 2. Add to Cart
       │ 3. Select "Home Delivery"
       │ 4. Enter Delivery Address (REQUIRED)
       │ 5. Place Order
       │
       ▼
┌──────────────────────────────────────┐
│     ORDER CREATED                    │
│  Status: PENDING                     │
│  DeliveryType: HOME_DELIVERY        │
│  Payment: PENDING                    │
│  DeliveryAddress: Required           │
└──────────┬───────────────────────────┘
           │
           │ Firebase Notification
           │
           ▼
┌──────────────────────────────────────┐
│   SHOP OWNER                         │
│   Receives Order Notification        │
└──────────┬───────────────────────────┘
           │
           │ Reviews Order
           │ Clicks "Accept Order"
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER CONFIRMED                  │
│  Status: CONFIRMED                   │
│  Payment: PENDING                    │
└──────────┬───────────────────────────┘
           │
           │ Shop Owner starts preparing
           │ Clicks "Start Preparing"
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER PREPARING                  │
│  Status: PREPARING                   │
│  Payment: PENDING                    │
└──────────┬───────────────────────────┘
           │
           │ Items packed and ready
           │ Clicks "Mark Ready for Pickup"
           │
           ▼
┌──────────────────────────────────────┐
│     READY FOR PICKUP                 │
│  Status: READY_FOR_PICKUP           │
│  Payment: PENDING                    │
│  OTP: Generated (e.g., "5678")      │
└──────────┬───────────────────────────┘
           │
           │ System assigns delivery partner
           │ OR shop owner manually assigns
           │
           ▼
┌──────────────────────────────────────┐
│   DELIVERY PARTNER ASSIGNED          │
│   AssignmentStatus: ACCEPTED         │
└──────────┬───────────────────────────┘
           │
           │ Partner arrives at shop
           │ Shows OTP
           │
           ▼
┌──────────────────────────────────────┐
│   SHOP OWNER VERIFIES OTP            │
│   Enters OTP in system               │
│   Clicks "Verify Pickup OTP"         │
│   (Blue Button)                      │
└──────────┬───────────────────────────┘
           │
           │ OTP verified successfully
           │
           ▼
┌──────────────────────────────────────┐
│     OUT FOR DELIVERY                 │
│  Status: OUT_FOR_DELIVERY           │
│  Payment: PENDING                    │
│  AssignmentStatus: PICKED_UP         │
└──────────┬───────────────────────────┘
           │
           │ Partner travels to customer
           │ Real-time tracking active
           │
           ▼
┌──────────────────────────────────────┐
│   PARTNER ARRIVES AT CUSTOMER        │
│   Customer verifies order            │
└──────────┬───────────────────────────┘
           │
           │ Partner confirms delivery
           │ Clicks "Mark as Delivered"
           │
           ▼
┌──────────────────────────────────────┐
│     ORDER DELIVERED ✅               │
│  Status: DELIVERED                   │
│  Payment: PAID (if COD)              │
│  ActualDeliveryTime: Set             │
└──────────────────────────────────────┘
           │
           │ Completion notification
           │
           ▼
┌──────────────────────────────────────┐
│   CUSTOMER RECEIVES NOTIFICATION     │
│   "Order delivered successfully!"    │
└──────────────────────────────────────┘
```

### Backend Code Flow (Home Delivery)

```
OrderController.verifyPickupOTP()
    │
    ├─► Check deliveryType
    │
    ├─► if (HOME_DELIVERY):
    │       │
    │       ├─► order.setStatus(OUT_FOR_DELIVERY)
    │       │
    │       ├─► Find OrderAssignment by orderId
    │       │
    │       ├─► if (assignment found):
    │       │       └─► assignment.setStatus(PICKED_UP)
    │       │
    │       ├─► orderRepository.save(order)
    │       │
    │       └─► Return success message
    │
    └─► Save order & send notification

DeliveryPartnerController.confirmDelivery()
    │
    ├─► order.setStatus(DELIVERED)
    ├─► order.setActualDeliveryTime(now)
    │
    ├─► if (paymentMethod == COD):
    │       └─► order.setPaymentStatus(PAID)
    │
    └─► Save & notify customer
```

---

## Payment Flows

### Cash on Delivery (COD) Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    CASH ON DELIVERY FLOW                         │
└─────────────────────────────────────────────────────────────────┘

ORDER CREATION
    │
    ├─► paymentMethod = CASH_ON_DELIVERY
    ├─► paymentStatus = PENDING
    │
    ▼
ORDER PROCESSING
    │
    ├─► All statuses: paymentStatus = PENDING
    │
    ▼
DELIVERY/HANDOVER
    │
    ├─► Self-Pickup:
    │   │
    │   ├─► Shop owner hands over order
    │   ├─► Collects cash from customer
    │   ├─► System auto-updates: paymentStatus = PAID
    │   └─► Status = DELIVERED
    │
    ├─► Home Delivery:
    │   │
    │   ├─► Delivery partner delivers order
    │   ├─► Collects cash from customer
    │   ├─► Partner confirms delivery
    │   ├─► System auto-updates: paymentStatus = PAID
    │   └─► Status = DELIVERED
    │
    ▼
PAYMENT COMPLETE ✅
    paymentStatus = PAID
```

### Online Payment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    ONLINE PAYMENT FLOW                           │
└─────────────────────────────────────────────────────────────────┘

CHECKOUT
    │
    ├─► paymentMethod = ONLINE
    ├─► paymentStatus = PENDING
    │
    ▼
PAYMENT GATEWAY
    │
    ├─► Customer redirected to payment gateway
    ├─► Enters card/UPI details
    │
    ├─► if (payment successful):
    │   │
    │   ├─► paymentStatus = PAID
    │   ├─► Order created with PAID status
    │   └─► Confirmation sent
    │
    ├─► if (payment failed):
    │   │
    │   ├─► paymentStatus = FAILED
    │   └─► Order not created
    │
    ▼
ORDER PROCESSING
    │
    ├─► paymentStatus = PAID (already paid)
    │
    ▼
DELIVERY/HANDOVER
    │
    ├─► No payment collection needed
    ├─► paymentStatus remains PAID
    │
    ▼
ORDER COMPLETE ✅
    paymentStatus = PAID
```

---

## Cancellation Flows

### Customer Cancellation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  CUSTOMER CANCELLATION FLOW                      │
└─────────────────────────────────────────────────────────────────┘

ORDER IN VALID STATE
    │
    ├─► Valid states: PENDING, CONFIRMED
    │
    ▼
CUSTOMER REQUESTS CANCELLATION
    │
    ├─► Clicks "Cancel Order"
    ├─► Enters cancellation reason
    ├─► Confirms cancellation
    │
    ▼
SYSTEM VALIDATION
    │
    ├─► Check if order can be cancelled
    ├─► if (status in [PENDING, CONFIRMED]):
    │       └─► Allow cancellation
    │
    ├─► if (status in [PREPARING, READY, OUT_FOR_DELIVERY]):
    │       └─► Show error: "Cannot cancel at this stage"
    │
    ▼
CANCELLATION PROCESSING
    │
    ├─► order.status = CANCELLED
    ├─► order.cancellationReason = reason
    │
    ├─► if (paymentStatus == PAID):
    │   │
    │   ├─► Initiate refund
    │   ├─► paymentStatus = REFUNDED
    │   └─► Refund processed in 5-7 days
    │
    ├─► if (paymentStatus == PENDING):
    │       └─► No refund needed
    │
    ▼
NOTIFICATIONS
    │
    ├─► Notify shop owner
    ├─► Notify customer (confirmation)
    │
    ▼
CANCELLATION COMPLETE ✅
    Status = CANCELLED
```

### Shop Owner Cancellation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                SHOP OWNER CANCELLATION FLOW                      │
└─────────────────────────────────────────────────────────────────┘

ORDER RECEIVED
    │
    ├─► Shop owner reviews order
    │
    ▼
CANCELLATION DECISION
    │
    ├─► Reasons:
    │   ├─► Out of stock
    │   ├─► Cannot deliver to location
    │   ├─► Shop closing early
    │   └─► Other operational reasons
    │
    ▼
SHOP OWNER CANCELS
    │
    ├─► Selects cancellation reason
    ├─► Clicks "Reject Order"
    │
    ▼
SYSTEM PROCESSING
    │
    ├─► order.status = CANCELLED
    ├─► order.cancellationReason = reason
    │
    ├─► if (paymentStatus == PAID):
    │   │
    │   ├─► Auto-initiate refund
    │   └─► paymentStatus = REFUNDED
    │
    ▼
NOTIFICATIONS
    │
    ├─► Notify customer
    ├─► Send apology message
    ├─► Suggest alternative shops
    │
    ▼
CANCELLATION COMPLETE ✅
    Status = CANCELLED
```

---

## Notification Flows

### Order Status Notification Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  NOTIFICATION FLOW DIAGRAM                       │
└─────────────────────────────────────────────────────────────────┘

ORDER STATUS CHANGE
    │
    ├─► Event triggered
    │
    ▼
NOTIFICATION SERVICE
    │
    ├─► Determine notification type:
    │   │
    │   ├─► PENDING → CONFIRMED
    │   │   └─► "Order Confirmed"
    │   │
    │   ├─► CONFIRMED → PREPARING
    │   │   └─► "Order is being prepared"
    │   │
    │   ├─► PREPARING → READY_FOR_PICKUP
    │   │   └─► "Order ready! OTP: {otp}"
    │   │
    │   ├─► READY_FOR_PICKUP → OUT_FOR_DELIVERY
    │   │   └─► "Order out for delivery"
    │   │
    │   ├─► OUT_FOR_DELIVERY → DELIVERED
    │   │   └─► "Order delivered"
    │   │
    │   ├─► READY_FOR_PICKUP → DELIVERED (self-pickup)
    │   │   └─► "Order collected successfully"
    │   │
    │   └─► Any → CANCELLED
    │       └─► "Order cancelled: {reason}"
    │
    ▼
SEND NOTIFICATION
    │
    ├─► Firebase Cloud Messaging (FCM)
    │   ├─► Send push notification
    │   └─► Update notification badge
    │
    ├─► In-App Notification
    │   ├─► Store in database
    │   └─► Display in notification center
    │
    ├─► Email (optional)
    │   └─► Send email to customer
    │
    └─► SMS (optional)
        └─► Send SMS alert
```

### Push Notification Priority

```
┌──────────────────────────────────────────────┐
│         NOTIFICATION PRIORITIES               │
└──────────────────────────────────────────────┘

HIGH PRIORITY (Immediate):
    ├─► Order Confirmed
    ├─► Order Ready for Pickup
    ├─► Out for Delivery
    ├─► Delivered
    └─► Cancelled

MEDIUM PRIORITY (Within 5 mins):
    ├─► Order Preparing
    └─► Payment Received

LOW PRIORITY (Can be delayed):
    ├─► Order Tracking Updates
    └─► General Updates
```

---

## Complete System Architecture Flow

### End-to-End System Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    COMPLETE SYSTEM ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   CUSTOMER      │         │  SHOP OWNER     │         │ DELIVERY        │
│   Mobile App    │         │  Mobile App     │         │ PARTNER App     │
└────────┬────────┘         └────────┬────────┘         └────────┬────────┘
         │                           │                           │
         │                           │                           │
         │  1. Create Order          │                           │
         ├──────────────────────────►│                           │
         │                           │                           │
         │                           │  2. Accept Order          │
         │◄──────────────────────────┤                           │
         │                           │                           │
         │                           │  3. Prepare Order         │
         │                           ├─────────────┐             │
         │                           │             │             │
         │                           │◄────────────┘             │
         │                           │                           │
         │                           │  4. Mark Ready            │
         │  Notification             ├─────────────┐             │
         │◄──────────────────────────┤             │             │
         │                           │◄────────────┘             │
         │                           │                           │
         │                           │  5. Assign Partner        │
         │                           ├──────────────────────────►│
         │                           │                           │
         │                           │  6. Verify OTP            │
         │                           │◄──────────────────────────┤
         │                           │                           │
         │                           │                           │  7. Deliver
         │                           │                           ├────────┐
         │                           │                           │        │
         │  Notification             │                           │◄───────┘
         │◄──────────────────────────┼───────────────────────────┤
         │                           │                           │
         │  8. Rate & Review         │                           │
         ├──────────────────────────►│                           │
         │                           │                           │
         ▼                           ▼                           ▼

┌─────────────────────────────────────────────────────────────────────────────┐
│                           BACKEND SERVICES                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Order      │  │   Payment    │  │ Notification │  │   Delivery   │  │
│  │   Service    │  │   Service    │  │   Service    │  │   Service    │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │                 │           │
│         └─────────────────┼─────────────────┼─────────────────┘           │
│                           │                 │                             │
│  ┌────────────────────────┴─────────────────┴──────────────────────────┐ │
│  │                        DATABASE (PostgreSQL)                         │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐      │ │
│  │  │ Orders  │ │Customers│ │  Shops  │ │Products │ │Payments │      │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘      │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL SERVICES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Firebase   │  │   Payment    │  │     SMS      │  │    Email     │  │
│  │     FCM      │  │   Gateway    │  │   Gateway    │  │   Service    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow Sequence

```
┌─────────────────────────────────────────────────────────────────┐
│                      DATA FLOW SEQUENCE                          │
└─────────────────────────────────────────────────────────────────┘

1. ORDER CREATION
   Customer App → Backend API → Database
   ├─► POST /api/customer/orders
   ├─► Create Order record
   ├─► Create OrderItems records
   └─► Return order details

2. NOTIFICATION TRIGGER
   Database → Backend Service → Firebase FCM
   ├─► Order status changed
   ├─► Generate notification payload
   ├─► Send to FCM
   └─► FCM delivers to device

3. STATUS UPDATE
   Shop Owner App → Backend API → Database
   ├─► PUT /api/orders/{id}/status
   ├─► Validate status transition
   ├─► Update order status
   ├─► Trigger notification
   └─► Return updated order

4. PAYMENT PROCESSING
   Backend → Payment Gateway → Database
   ├─► Create payment intent
   ├─► Process payment
   ├─► Receive webhook
   ├─► Update payment status
   └─► Update order status

5. DELIVERY ASSIGNMENT
   Backend → Delivery Service → Partner App
   ├─► Find available partners
   ├─► Create assignment
   ├─► Notify partner
   └─► Partner accepts/rejects

6. DELIVERY COMPLETION
   Partner App → Backend API → Database
   ├─► PUT /api/delivery/{id}/complete
   ├─► Verify delivery
   ├─► Update order status
   ├─► Mark payment as PAID
   └─► Send completion notification
```

---

## State Transition Diagrams

### Order Status State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                   ORDER STATUS STATE MACHINE                     │
└─────────────────────────────────────────────────────────────────┘

                            ┌─────────┐
                            │ PENDING │
                            └────┬────┘
                                 │
                    ┌────────────┼────────────┐
                    │                         │
                    ▼                         ▼
              ┌───────────┐            ┌───────────┐
              │ CONFIRMED │            │ CANCELLED │
              └─────┬─────┘            └───────────┘
                    │
                    ▼
              ┌───────────┐
              │ PREPARING │
              └─────┬─────┘
                    │
                    ▼
         ┌──────────────────┐
         │ READY_FOR_PICKUP │
         └─────┬────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
 [SELF_PICKUP]  [HOME_DELIVERY]
        │             │
        │             ▼
        │    ┌─────────────────┐
        │    │ OUT_FOR_DELIVERY│
        │    └────────┬─────────┘
        │             │
        └─────┬───────┘
              │
              ▼
        ┌───────────┐
        │ DELIVERED │
        └───────────┘
```

### Payment Status State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                 PAYMENT STATUS STATE MACHINE                     │
└─────────────────────────────────────────────────────────────────┘

              ┌─────────┐
              │ PENDING │
              └────┬────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
   ┌────────┐  ┌──────┐  ┌─────────┐
   │  PAID  │  │FAILED│  │ REFUNDED│
   └────────┘  └──────┘  └─────────┘
```

---

## Timing Diagrams

### Self-Pickup Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│              SELF-PICKUP ORDER TIMELINE                          │
└─────────────────────────────────────────────────────────────────┘

Time    Customer              Shop Owner           System
─────   ────────              ──────────           ──────
T+0     Place order
T+1                           Receive notification
T+2                           Accept order         Status: CONFIRMED
T+5                           Start preparing      Status: PREPARING
T+20                          Mark ready           Status: READY_FOR_PICKUP
T+21    Receive notification                       Send OTP
T+25    Arrive at shop
T+26    Show OTP              Verify customer
T+27                          Handover order       Status: DELIVERED
T+27                          Collect payment      Payment: PAID
T+28    Receive confirmation                       Send notification

Total Time: ~28 minutes
```

### Home Delivery Timeline

```
┌─────────────────────────────────────────────────────────────────┐
│             HOME DELIVERY ORDER TIMELINE                         │
└─────────────────────────────────────────────────────────────────┘

Time    Customer              Shop Owner           Partner          System
─────   ────────              ──────────           ───────          ──────
T+0     Place order
T+1                           Receive notification
T+2                           Accept order                          CONFIRMED
T+5                           Start preparing                       PREPARING
T+20                          Mark ready                            READY_FOR_PICKUP
T+21                                                                 Assign partner
T+22                                               Accept           Assignment: ACCEPTED
T+25                                               Arrive at shop
T+26                          Verify OTP                            OUT_FOR_DELIVERY
T+27                                               Travel to customer
T+40    Receive order                              Mark delivered   DELIVERED
T+40                                               Collect payment  PAID
T+41    Confirmation                                                Notification

Total Time: ~41 minutes
```

---

## Error Handling Flows

### Order Creation Errors

```
┌─────────────────────────────────────────────────────────────────┐
│                   ERROR HANDLING FLOW                            │
└─────────────────────────────────────────────────────────────────┘

ORDER CREATION REQUEST
    │
    ├─► Validation Errors:
    │   │
    │   ├─► Missing required fields
    │   │   └─► Return 400: "Field {name} is required"
    │   │
    │   ├─► Invalid delivery address (HOME_DELIVERY)
    │   │   └─► Return 400: "Valid delivery address required"
    │   │
    │   ├─► Shop not found
    │   │   └─► Return 404: "Shop not found"
    │   │
    │   ├─► Product out of stock
    │   │   └─► Return 400: "Product {name} out of stock"
    │   │
    │   └─► Minimum order amount not met
    │       └─► Return 400: "Minimum order ₹{amount} required"
    │
    ├─► Payment Errors:
    │   │
    │   ├─► Payment gateway timeout
    │   │   └─► Retry payment
    │   │
    │   ├─► Payment declined
    │   │   └─► Return 400: "Payment declined"
    │   │
    │   └─► Payment processing error
    │       └─► Return 500: "Payment error, please retry"
    │
    └─► System Errors:
        │
        ├─► Database connection error
        │   └─► Return 503: "Service unavailable"
        │
        └─► Unexpected error
            └─► Return 500: "Internal server error"
```

---

## Summary Statistics

### Average Processing Times

| Flow Type | Steps | Avg Time | User Actions |
|-----------|-------|----------|--------------|
| Self-Pickup | 6 | 25-30 min | 3 (Place, Arrive, Collect) |
| Home Delivery | 8 | 40-60 min | 2 (Place, Receive) |
| Cancellation | 1-2 | 1-2 min | 1 (Cancel) |
| Payment (COD) | 1 | Instant | 0 (Auto) |
| Payment (Online) | 3 | 2-5 min | 1 (Pay) |

### Success Rate Metrics

- Order Creation Success: 98%
- Payment Success (Online): 95%
- Delivery Success: 97%
- Customer Satisfaction: 4.5/5

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-07
**Maintained By:** Development Team

