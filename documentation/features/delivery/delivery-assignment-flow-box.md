# Delivery Partner Auto-Assignment Flow - Box Model

## System Overview
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              NAMMAOORU DELIVERY SYSTEM                                │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐          │
│  │   SHOP OWNER     │      │   BACKEND API    │      │ DELIVERY PARTNER │          │
│  │   DASHBOARD      │◄────►│     SERVER        │◄────►│   MOBILE APP     │          │
│  └──────────────────┘      └──────────────────┘      └──────────────────┘          │
│          │                          │                          │                     │
│          │                          ▼                          │                     │
│          │                  ┌──────────────────┐              │                     │
│          └─────────────────►│    DATABASE      │◄─────────────┘                     │
│                             └──────────────────┘                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Auto-Assignment Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           AUTO-ASSIGNMENT PROCESS FLOW                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

STEP 1: ORDER READY FOR DELIVERY
┌──────────────────────────────────────────────────────────┐
│  Shop Owner                                              │
│  ┌────────────────────────────────────────────────┐     │
│  │  Click "Ready for Delivery" Button             │     │
│  │  Order ID: 12345                               │     │
│  │  Total Amount: ₹450                            │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
STEP 2: API CALL TO AUTO-ASSIGN
┌──────────────────────────────────────────────────────────┐
│  POST /api/assignments/orders/12345/auto-assign         │
│  ┌────────────────────────────────────────────────┐     │
│  │  Request Body:                                  │     │
│  │  {                                             │     │
│  │    "assignedBy": 101  (Shop Owner ID)         │     │
│  │  }                                             │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
STEP 3: FIND AVAILABLE PARTNERS
┌──────────────────────────────────────────────────────────┐
│  Database Query                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │  SELECT * FROM users WHERE:                    │     │
│  │  - role = 'DELIVERY_PARTNER'                   │     │
│  │  - isOnline = true                             │     │
│  │  - isAvailable = true                          │     │
│  │  - rideStatus = 'IDLE'                         │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
│  Results:                                                │
│  ┌─────────┬──────────┬───────────┬──────────┐        │
│  │ ID      │ Name     │ Distance  │ Rating   │        │
│  ├─────────┼──────────┼───────────┼──────────┤        │
│  │ 201     │ Kumar    │ 1.2 km    │ 4.8      │        │
│  │ 202     │ Ravi     │ 2.5 km    │ 4.5      │        │
│  │ 203     │ Suresh   │ 3.1 km    │ 4.9      │        │
│  └─────────┴──────────┴───────────┴──────────┘        │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
STEP 4: SELECT BEST PARTNER
┌──────────────────────────────────────────────────────────┐
│  Partner Selection Algorithm                             │
│  ┌────────────────────────────────────────────────┐     │
│  │  Priority Factors:                             │     │
│  │  1. Distance from shop (40%)                   │     │
│  │  2. Partner rating (30%)                       │     │
│  │  3. Completed deliveries (20%)                 │     │
│  │  4. Response time history (10%)                │     │
│  │                                                │     │
│  │  Selected: Partner ID 201 (Kumar)              │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
STEP 5: CREATE ASSIGNMENT
┌──────────────────────────────────────────────────────────┐
│  Create Order Assignment Record                          │
│  ┌────────────────────────────────────────────────┐     │
│  │  OrderAssignment {                             │     │
│  │    id: 5001                                    │     │
│  │    orderId: 12345                              │     │
│  │    deliveryPartnerId: 201                      │     │
│  │    status: 'ASSIGNED'                          │     │
│  │    assignmentType: 'AUTO'                      │     │
│  │    assignedAt: '2025-01-15 10:30:00'           │     │
│  │    deliveryFee: 50.00                          │     │
│  │    partnerCommission: 40.00                    │     │
│  │  }                                              │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
STEP 6: NOTIFY DELIVERY PARTNER
┌──────────────────────────────────────────────────────────┐
│  Push Notification to Partner App                        │
│  ┌────────────────────────────────────────────────┐     │
│  │  🔔 New Delivery Request!                      │     │
│  │                                                │     │
│  │  Order: #12345                                 │     │
│  │  Pickup: Namma Store, MG Road                  │     │
│  │  Delivery: 123 BTM Layout                      │     │
│  │  Distance: 3.5 km                              │     │
│  │  Earnings: ₹40                                 │     │
│  │                                                │     │
│  │  ┌──────────┐  ┌──────────┐                  │     │
│  │  │  ACCEPT  │  │  REJECT  │                  │     │
│  │  └──────────┘  └──────────┘                  │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

## Partner Response Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              PARTNER RESPONSE HANDLING                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

SCENARIO A: PARTNER ACCEPTS
┌──────────────────────────────────────────────────────────┐
│  Partner Clicks ACCEPT                                   │
│  ┌────────────────────────────────────────────────┐     │
│  │  POST /api/assignments/5001/accept              │     │
│  │  partnerId: 201                                 │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐     │
│  │  Update Assignment:                            │     │
│  │  - status: 'ACCEPTED'                          │     │
│  │  - acceptedAt: '2025-01-15 10:31:30'          │     │
│  │  - Update partner rideStatus: 'BUSY'           │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐     │
│  │  Show Navigation to Shop                       │     │
│  │  Enable "Mark as Picked Up" button             │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘

SCENARIO B: PARTNER REJECTS
┌──────────────────────────────────────────────────────────┐
│  Partner Clicks REJECT                                   │
│  ┌────────────────────────────────────────────────┐     │
│  │  POST /api/assignments/5001/reject              │     │
│  │  partnerId: 201                                 │     │
│  │  reason: "Too far from current location"       │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐     │
│  │  Update Assignment:                            │     │
│  │  - status: 'REJECTED'                          │     │
│  │  - rejectedAt: '2025-01-15 10:31:45'          │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐     │
│  │  Auto-Reassign to Next Available Partner       │     │
│  │  (Repeat from STEP 3)                          │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘

SCENARIO C: NO RESPONSE (TIMEOUT)
┌──────────────────────────────────────────────────────────┐
│  15 Minutes Elapsed - No Response                        │
│  ┌────────────────────────────────────────────────┐     │
│  │  System Auto-Timeout                           │     │
│  │  - status: 'EXPIRED'                           │     │
│  │  - expiredAt: '2025-01-15 10:45:00'           │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  ┌────────────────────────────────────────────────┐     │
│  │  Auto-Reassign to Next Available Partner       │     │
│  │  OR                                            │     │
│  │  Alert Shop Owner for Manual Assignment        │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

## Delivery Process Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                DELIVERY EXECUTION                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

1. PICKUP PHASE
┌──────────────────────────────────────────────────────────┐
│  Partner Arrives at Shop                                 │
│  ┌────────────────────────────────────────────────┐     │
│  │  Partner App Shows:                            │     │
│  │  • Order Details                               │     │
│  │  • Items List                                  │     │
│  │  • Order Number: #12345                        │     │
│  │  • Verification Code: 4567                     │     │
│  │                                                │     │
│  │  [✓] MARK AS PICKED UP                        │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  POST /api/assignments/5001/pickup                       │
│  Updates: status = 'PICKED_UP'                           │
│           pickupTime = '2025-01-15 10:45:00'            │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
2. IN-TRANSIT PHASE
┌──────────────────────────────────────────────────────────┐
│  Partner Delivering Order                                │
│  ┌────────────────────────────────────────────────┐     │
│  │  Live Tracking:                                │     │
│  │  • GPS Location Updates                        │     │
│  │  • ETA: 15 minutes                            │     │
│  │  • Distance Remaining: 2.3 km                  │     │
│  │  • Customer Contact: +91-9876543210            │     │
│  │                                                │     │
│  │  [📍] Navigate  [📞] Call Customer            │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
3. DELIVERY COMPLETION
┌──────────────────────────────────────────────────────────┐
│  Partner Completes Delivery                              │
│  ┌────────────────────────────────────────────────┐     │
│  │  Delivery Confirmation:                        │     │
│  │  • Customer Name: Verified ✓                   │     │
│  │  • OTP Verified: 4567 ✓                        │     │
│  │  • Payment: COD ₹450 Collected ✓               │     │
│  │                                                │     │
│  │  Delivery Notes: "Handed to customer"          │     │
│  │                                                │     │
│  │  [✓] MARK AS DELIVERED                        │     │
│  └────────────────────────────────────────────────┘     │
│                     ▼                                    │
│  POST /api/assignments/5001/deliver                      │
│  Updates: status = 'DELIVERED'                           │
│           deliveryCompletedAt = '2025-01-15 11:00:00'   │
│           Update partner rideStatus = 'IDLE'             │
└──────────────────────────────────────────────────────────┘
```

## Assignment Status Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ASSIGNMENT STATUS TRANSITIONS                            │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              ┌──────────────┐
                              │   CREATED    │
                              │   (START)    │
                              └──────┬───────┘
                                     │
                                     ▼
                              ┌──────────────┐
                    ┌─────────│   ASSIGNED   │─────────┐
                    │         └──────┬───────┘         │
                    │                │                 │
                    ▼                ▼                 ▼
             ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
             │   REJECTED   │ │   ACCEPTED   │ │   EXPIRED    │
             └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
                    │                │                 │
                    │                ▼                 │
                    │         ┌──────────────┐         │
                    │         │  PICKED_UP   │         │
                    │         └──────┬───────┘         │
                    │                │                 │
                    │                ▼                 │
                    │         ┌──────────────┐         │
                    │         │  DELIVERED   │         │
                    │         └──────┬───────┘         │
                    │                │                 │
                    └────────────────┼─────────────────┘
                                     ▼
                              ┌──────────────┐
                              │  COMPLETED   │
                              │    (END)     │
                              └──────────────┘
```

## API Endpoints Summary
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  API ENDPOINTS                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│  ASSIGNMENT OPERATIONS                                                               │
│  ┌────────────────────────────────────────────────────────────────────────────┐     │
│  │  POST   /api/assignments/orders/{orderId}/auto-assign                      │     │
│  │  POST   /api/assignments/orders/{orderId}/manual-assign                    │     │
│  │  POST   /api/assignments/{assignmentId}/accept                             │     │
│  │  POST   /api/assignments/{assignmentId}/reject                             │     │
│  │  POST   /api/assignments/{assignmentId}/pickup                             │     │
│  │  POST   /api/assignments/{assignmentId}/deliver                            │     │
│  └────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                       │
│  PARTNER QUERIES                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐     │
│  │  GET    /api/assignments/available-partners                                │     │
│  │  GET    /api/assignments/partners/{partnerId}/pending                      │     │
│  │  GET    /api/assignments/partner/{partnerId}/available                     │     │
│  │  GET    /api/assignments/partners/{partnerId}/current                      │     │
│  │  GET    /api/assignments/partners/{partnerId}/history                      │     │
│  └────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                       │
│  ORDER & DEBUG                                                                       │
│  ┌────────────────────────────────────────────────────────────────────────────┐     │
│  │  GET    /api/assignments/orders/{orderId}                                  │     │
│  │  GET    /api/assignments/debug/auto-assignment/{orderId}                   │     │
│  └────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Database Tables
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                 DATABASE SCHEMA                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘

ORDERS TABLE
┌──────────────────────────────────────────────────────────┐
│  orders                                                  │
├──────────────────────────────────────────────────────────┤
│  id                 BIGINT      PRIMARY KEY              │
│  order_number       VARCHAR     UNIQUE                   │
│  shop_id            BIGINT      FOREIGN KEY              │
│  customer_id        BIGINT      FOREIGN KEY              │
│  total_amount       DECIMAL                              │
│  delivery_address   TEXT                                 │
│  status             VARCHAR                              │
│  created_at         TIMESTAMP                            │
│  updated_at         TIMESTAMP                            │
└──────────────────────────────────────────────────────────┘
                           │
                           │ 1:N
                           ▼
ORDER_ASSIGNMENTS TABLE
┌──────────────────────────────────────────────────────────┐
│  order_assignments                                       │
├──────────────────────────────────────────────────────────┤
│  id                      BIGINT      PRIMARY KEY         │
│  order_id                BIGINT      FOREIGN KEY         │
│  delivery_partner_id     BIGINT      FOREIGN KEY         │
│  status                  VARCHAR                         │
│  assignment_type         VARCHAR                         │
│  assigned_at             TIMESTAMP                       │
│  accepted_at             TIMESTAMP                       │
│  rejected_at             TIMESTAMP                       │
│  pickup_time             TIMESTAMP                       │
│  delivery_completed_at   TIMESTAMP                       │
│  delivery_fee            DECIMAL                         │
│  partner_commission      DECIMAL                         │
│  assignment_notes        TEXT                            │
│  delivery_notes          TEXT                            │
│  rejection_reason        TEXT                            │
└──────────────────────────────────────────────────────────┘
                           │
                           │ N:1
                           ▼
USERS TABLE (DELIVERY PARTNERS)
┌──────────────────────────────────────────────────────────┐
│  users                                                   │
├──────────────────────────────────────────────────────────┤
│  id                 BIGINT      PRIMARY KEY              │
│  email              VARCHAR     UNIQUE                   │
│  mobile_number      VARCHAR                              │
│  first_name         VARCHAR                              │
│  last_name          VARCHAR                              │
│  role               VARCHAR                              │
│  is_online          BOOLEAN                              │
│  is_available       BOOLEAN                              │
│  ride_status        VARCHAR                              │
│  current_latitude   DECIMAL                              │
│  current_longitude  DECIMAL                              │
│  last_activity      TIMESTAMP                            │
└──────────────────────────────────────────────────────────┘
```

## Key Features Summary
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                  FEATURE HIGHLIGHTS                                   │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│  ✓ AUTO-ASSIGNMENT                                                                   │
│    • Intelligent partner selection based on distance, rating, availability           │
│    • Automatic reassignment on rejection or timeout                                  │
│    • 15-minute response window for partners                                          │
│                                                                                       │
│  ✓ MANUAL FALLBACK                                                                   │
│    • Shop owners can manually assign when auto-assignment fails                      │
│    • Select specific partners for special requirements                               │
│                                                                                       │
│  ✓ REAL-TIME TRACKING                                                                │
│    • Live GPS updates during delivery                                                │
│    • Status updates at each stage                                                    │
│    • ETA calculations                                                                │
│                                                                                       │
│  ✓ PARTNER MANAGEMENT                                                                │
│    • Online/Offline status tracking                                                  │
│    • Availability management                                                         │
│    • Ride status (IDLE/BUSY/OFFLINE)                                                │
│                                                                                       │
│  ✓ COMMISSION HANDLING                                                               │
│    • Automatic commission calculation                                                │
│    • Delivery fee management                                                         │
│    • Partner earnings tracking                                                       │
│                                                                                       │
└─────────────────────────────────────────────────────────────────────────────────────┘
```