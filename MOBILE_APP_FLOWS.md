# 📱 NammaOoru Mobile Apps - Complete Flow Design

## 📋 Document Overview

**Purpose**: Complete mobile app design for Delivery Partners and Shop Owners  
**Platform**: Flutter (iOS + Android)  
**Target Users**: Delivery Partners, Shop Owners  
**Last Updated**: January 2025  

---

## 🚚 DELIVERY PARTNER MOBILE APP

### 📱 App Overview
```
┌─────────────────────────────────────────────────────────────────────┐
│                    NammaOoru Delivery Partner                      │
│                           Mobile App                               │
└─────────────────────────────────────────────────────────────────────┘

Core Features:
├─ Authentication (OTP-based)
├─ Assignment Management
├─ Real-time Order Tracking
├─ Navigation Integration
├─ Earnings Dashboard
├─ Profile Management
└─ Support System
```

### 🔐 Authentication Flow

#### **1. Onboarding & Registration**
```
Welcome Screen
    ↓
Mobile Number Entry
    ↓ 
OTP Verification (MSG91)
    ↓
[New User] → Registration Form:
    - Full Name
    - Vehicle Type (Bike/Car/Auto)
    - License Number
    - Driving License Photo
    - Vehicle RC Photo
    - Bank Account Details
    - Emergency Contact
    ↓
Document Verification (Admin Approval)
    ↓
Profile Approved → Dashboard Access

[Existing User] → Direct to Dashboard
```

#### **2. Login Flow**
```
Splash Screen → Check Auth Status
    ↓
[Not Logged In] → Mobile Login
    ↓
Enter Mobile Number → Send OTP → Verify → Dashboard

[Already Logged In] → Dashboard
```

### 🏠 Dashboard & Main Navigation

#### **Dashboard Screen**
```
┌─────────────────────────────────────────────────────────────────────┐
│  🔴 OFFLINE    [Toggle Online/Offline]    📍 Location: ON         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  👋 Hello, Rajesh!                        📊 Today's Stats         │
│  📍 Current Location: Koramangala         ├─ Deliveries: 8          │
│  🚚 Vehicle: Bike (KA01AB1234)           ├─ Earnings: ₹640         │
│                                           └─ Rating: 4.7⭐         │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      📋 PENDING ASSIGNMENTS                        │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🛍️ Order #ORD001                    [ACCEPT] [REJECT]         │ │
│  │ 📍 From: Pizza Palace, BTM Layout                               │ │
│  │ 🏠 To: HSR Layout (2.5 km)                                     │ │
│  │ 💰 Earn: ₹80    ⏰ Ready in: 15 mins                          │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                     🚚 ACTIVE DELIVERIES                           │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🛍️ Order #ORD002            📍 Navigate    📞 Call Customer   │ │
│  │ Status: Picked Up → Delivering                                  │ │
│  │ 🏠 Delivering to: Jayanagar (1.2 km)                          │ │
│  │ ⏰ ETA: 10 minutes           [DELIVERED] [ISSUE]               │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

Bottom Navigation:
[🏠 Home] [📋 Orders] [💰 Earnings] [👤 Profile]
```

### 📋 Order Management Flow

#### **1. Assignment Notification**
```
Push Notification Received
    ↓ 
"New Delivery Assignment! Order from Pizza Palace"
    ↓
App Opens → Assignment Details Screen:
    
┌─────────────────────────────────────────────────────────────────────┐
│                    🛍️ NEW ASSIGNMENT                               │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          💰 You'll Earn: ₹85     │
│                                                                     │
│  📍 PICKUP FROM:                           ⏰ TIMING:               │
│  🏪 Domino's Pizza                         📋 Ready in: 20 mins     │
│  📍 123 MG Road, Bangalore                 🚚 Distance: 3.2 km     │
│  📞 +91 80 1234 5678                       ⏱️ Est. Time: 25 mins   │
│                                                                     │
│  🏠 DELIVER TO:                            🛍️ ORDER DETAILS:       │
│  👤 Suresh Kumar                           🍕 1x Margherita Pizza   │
│  📍 45 HSR Layout, Bangalore               🥤 1x Coca Cola          │
│  📞 +91 98765 43210                        💰 Order Value: ₹450     │
│                                                                     │
│  💳 PAYMENT: Paid Online                   🗒️ NOTES:               │
│                                            "Ring doorbell twice"    │
├─────────────────────────────────────────────────────────────────────┤
│           [🚫 REJECT]           [✅ ACCEPT DELIVERY]                │
│                                                                     │
│  ⏰ Auto-reject in: 02:45                                          │
└─────────────────────────────────────────────────────────────────────┘
```

#### **2. After Accepting Assignment**
```
Assignment Accepted
    ↓
Status: "Accepted" → Navigate to Pickup
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    🚚 PICKUP PENDING                               │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                                                  │
│                                                                     │
│  📍 GO TO RESTAURANT:                      ⏰ STATUS:               │
│  🏪 Domino's Pizza                         ✅ Order Accepted        │
│  📍 123 MG Road, Bangalore                 🍕 Being Prepared        │
│  📞 +91 80 1234 5678                       ⏱️ Ready in: 18 mins    │
│                                                                     │
│  🗺️ [NAVIGATE TO RESTAURANT]  📞 [CALL RESTAURANT]               │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  🏠 CUSTOMER DETAILS:                      💰 DELIVERY INFO:       │
│  👤 Suresh Kumar                           🚚 Distance: 3.2 km     │
│  📍 45 HSR Layout                          💰 You'll Earn: ₹85     │
│  📞 +91 98765 43210                        💳 Payment: Online      │
│                                                                     │
│  🔄 [REFRESH STATUS]                                               │
└─────────────────────────────────────────────────────────────────────┘
```

#### **3. At Restaurant - Pickup Process**
```
Arrived at Restaurant
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     📍 AT RESTAURANT                               │
├─────────────────────────────────────────────────────────────────────┤
│  🏪 Domino's Pizza                         📱 Order: #ORD12345     │
│  📍 123 MG Road, Bangalore                                         │
│                                                                     │
│  ⏰ ORDER STATUS:                          🛍️ ORDER ITEMS:         │
│  ✅ Ready for Pickup!                      🍕 1x Margherita Pizza   │
│                                            🥤 1x Coca Cola          │
│                                                                     │
│  📞 [CALL RESTAURANT]                      📷 [SCAN QR/BARCODE]    │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  ✅ Order Received? Confirm pickup:                                │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ 📦 Items received and verified                                  ││
│  │ ✅ Order looks correct                                          ││
│  │ ✅ All items included                                           ││
│  │                                                                 ││
│  │              [📷 TAKE PHOTO] [✅ CONFIRM PICKUP]               ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

#### **4. Delivery In Progress**
```
Order Picked Up
    ↓
Status: "Out for Delivery" → Navigate to Customer
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    🚚 OUT FOR DELIVERY                             │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          ⏰ ETA: 15 minutes      │
│                                                                     │
│  🏠 DELIVERING TO:                         🛍️ ORDER DETAILS:       │
│  👤 Suresh Kumar                           🍕 1x Margherita Pizza   │
│  📍 45 HSR Layout, Bangalore               🥤 1x Coca Cola          │
│  📞 +91 98765 43210                        💰 Value: ₹450          │
│                                            💳 Payment: Online       │
│                                                                     │
│  🗺️ [NAVIGATE TO CUSTOMER]    📞 [CALL CUSTOMER]                  │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  📍 LIVE TRACKING:                         🚨 QUICK ACTIONS:       │
│  Current Location: Koramangala              📞 Call Customer        │
│  Distance to Customer: 1.8 km               📍 Share Live Location  │
│  📍 [UPDATE LOCATION]                       ⚠️ Report Issue        │
│                                                                     │
│  🔄 Auto-updating every 30 seconds                                 │
└─────────────────────────────────────────────────────────────────────┘
```

#### **5. Delivery Completion**
```
Reached Customer Location
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                   📍 REACHED DESTINATION                           │
├─────────────────────────────────────────────────────────────────────┤
│  🏠 Delivering to: Suresh Kumar            📱 Order: #ORD12345     │
│  📍 45 HSR Layout, Bangalore                                       │
│                                                                     │
│  💳 PAYMENT STATUS: ✅ Paid Online          📞 [CALL CUSTOMER]      │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  🛍️ DELIVERY CONFIRMATION:                                        │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ 📦 Hand over order to customer                                  ││
│  │ ✅ Customer received the order                                  ││
│  │ ✅ Order delivered successfully                                 ││
│  │                                                                 ││
│  │ 📷 [TAKE DELIVERY PHOTO]                                       ││
│  │                                                                 ││
│  │ 📝 Delivery Notes (Optional):                                   ││
│  │ ┌─────────────────────────────────────────────────────────────┐ ││
│  │ │ Customer was very friendly                                  │ ││
│  │ └─────────────────────────────────────────────────────────────┘ ││
│  │                                                                 ││
│  │               [✅ MARK AS DELIVERED]                           ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  ⚠️ Having issues? [🚨 REPORT PROBLEM]                            │
└─────────────────────────────────────────────────────────────────────┘
```

#### **6. Delivery Completed**
```
Order Delivered Successfully
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    ✅ DELIVERY COMPLETED                           │
├─────────────────────────────────────────────────────────────────────┤
│  🎉 Great Job! Order delivered successfully                        │
│                                                                     │
│  📱 Order: #ORD12345                       ⏰ Delivered at:        │
│  👤 Customer: Suresh Kumar                  🕐 2:45 PM             │
│                                                                     │
│  💰 EARNINGS SUMMARY:                       📊 PERFORMANCE:        │
│  💵 Base Delivery Fee: ₹65                 ⭐ Your Rating: 4.7     │
│  🎯 Distance Bonus: ₹15                     🚚 Total Deliveries: 9 │
│  🎁 Tip from Customer: ₹5                   📈 Success Rate: 98%   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  💰 Total Earned: ₹85                       💳 Payment: Instant   │
│                                                                     │
│  🌟 Customer might rate & tip you!          📱 [VIEW EARNINGS]     │
│                                                                     │
│              [🏠 BACK TO DASHBOARD]                                │
└─────────────────────────────────────────────────────────────────────┘
```

### 💰 Earnings & Analytics

#### **Earnings Dashboard**
```
┌─────────────────────────────────────────────────────────────────────┐
│                    💰 EARNINGS DASHBOARD                           │
├─────────────────────────────────────────────────────────────────────┤
│  📊 TODAY'S SUMMARY                         📅 [Today] [Week] [Month] │
│                                                                     │
│  🚚 Deliveries: 8                          💰 Total Earned: ₹640   │
│  ⏰ Online Hours: 6h 30m                    💵 Average per delivery: ₹80 │
│  📈 Efficiency: 92%                         🎁 Tips Received: ₹45   │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                     💳 PAYMENT BREAKDOWN                           │
│                                                                     │
│  💵 Base Earnings:         ₹520                                    │
│  🎯 Distance Bonus:        ₹75                                     │
│  🎁 Customer Tips:         ₹45                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  💰 Total Today:           ₹640                                    │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                    📋 RECENT DELIVERIES                            │
│                                                                     │
│  🛍️ #ORD12345  Pizza Palace → HSR Layout    ₹85   2:45 PM  ⭐4.8 │
│  🛍️ #ORD12344  KFC → Jayanagar             ₹75   1:30 PM  ⭐4.9 │
│  🛍️ #ORD12343  McDonald's → BTM            ₹90   12:15 PM ⭐4.6 │
│                                                                     │
│              [📊 VIEW DETAILED REPORT]                             │
├─────────────────────────────────────────────────────────────────────┤
│  💳 PAYMENT STATUS:                         🏦 BANK DETAILS:       │
│  ✅ All payments processed                   💳 HDFC Bank           │
│  💰 Available for withdrawal: ₹640           🔢 ****1234            │
│                                                                     │
│              [💸 WITHDRAW EARNINGS]                                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🏪 SHOP OWNER MOBILE APP

### 📱 App Overview
```
┌─────────────────────────────────────────────────────────────────────┐
│                      NammaOoru Shop Owner                          │
│                         Mobile App                                 │
└─────────────────────────────────────────────────────────────────────┘

Core Features:
├─ Shop Management
├─ Order Management
├─ Product Catalog
├─ Inventory Management
├─ Sales Analytics
├─ Customer Management
└─ Business Settings
```

### 🔐 Authentication Flow

#### **1. Shop Owner Registration**
```
Welcome Screen
    ↓
Mobile Number Entry
    ↓
OTP Verification (MSG91)
    ↓
[New Shop Owner] → Business Registration:
    - Business Name
    - Owner Name & Details
    - Business Type/Category
    - Business Address
    - Business License (Photo)
    - GSTIN (Optional)
    - Bank Account Details
    - Operating Hours
    ↓
Document Verification → Admin Approval
    ↓
Shop Approved → Dashboard Access

[Existing Owner] → Direct to Dashboard
```

### 🏠 Dashboard & Main Navigation

#### **Dashboard Screen**
```
┌─────────────────────────────────────────────────────────────────────┐
│  🟢 OPEN     [Toggle Open/Closed]       📍 Location Services: ON   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  👋 Hello, Ramesh!                       📊 Today's Stats          │
│  🏪 Pizza Palace                         ├─ Orders: 12             │
│  📍 MG Road, Bangalore                   ├─ Revenue: ₹2,400        │
│  ⭐ 4.5 Rating (234 reviews)            └─ New Customers: 3       │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      🔔 NEW ORDERS (3)                             │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🛍️ Order #ORD001                      [ACCEPT] [REJECT]       │ │
│  │ 👤 Suresh Kumar | 📞 +91 98765 43210                          │ │
│  │ 🍕 2x Margherita, 1x Coke             💰 ₹450                  │ │
│  │ ⏰ 5 minutes ago                       🏠 HSR Layout            │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                    🍳 PREPARING ORDERS (2)                         │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🛍️ Order #ORD002                      ⏰ Prep Time: 15 mins    │ │
│  │ 🍔 1x Burger, 1x Fries                [PREPARING] [READY]      │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                   🚚 OUT FOR DELIVERY (1)                          │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ 🛍️ Order #ORD003                      📍 Track Delivery        │ │
│  │ 🚚 Partner: Rajesh | ETA: 10 mins     💰 ₹320                  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

Bottom Navigation:
[🏠 Home] [📋 Orders] [🛍️ Products] [📊 Analytics] [👤 Profile]
```

### 📋 Order Management Flow

#### **1. New Order Notification**
```
Push Notification: "New Order Received!"
    ↓
App Opens → Order Details Screen:

┌─────────────────────────────────────────────────────────────────────┐
│                      🛍️ NEW ORDER                                  │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          💰 Order Value: ₹450    │
│  ⏰ Received: Just now                                              │
│                                                                     │
│  👤 CUSTOMER DETAILS:                      🛍️ ORDER ITEMS:         │
│  👤 Suresh Kumar                           🍕 2x Margherita Pizza (L) │
│  📞 +91 98765 43210                        🥤 1x Coca Cola (500ml)  │
│  📧 suresh@email.com                       ━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                            💰 Subtotal: ₹400       │
│  🏠 DELIVERY ADDRESS:                       🚚 Delivery: ₹50       │
│  📍 45, HSR Layout                         ━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  📍 Bangalore - 560102                     💰 Total: ₹450          │
│  📞 Alt: +91 80 1234 5678                 💳 Payment: Online ✅    │
│                                                                     │
│  🗒️ SPECIAL INSTRUCTIONS:                                          │
│  "Extra cheese on both pizzas, less spicy"                         │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  ⏰ ESTIMATED PREP TIME:                                           │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ How long will it take to prepare?                               ││
│  │ [15 mins] [20 mins] [30 mins] [45 mins] [Custom: ___]          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│           [🚫 REJECT ORDER]        [✅ ACCEPT ORDER]               │
│                                                                     │
│  ⏰ Auto-reject in: 04:30 minutes                                  │
└─────────────────────────────────────────────────────────────────────┘
```

#### **2. Order Preparation Management**
```
Order Accepted → Preparation Phase
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     🍳 ORDER PREPARATION                           │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          ⏰ ETA: 20 minutes      │
│  👤 Customer: Suresh Kumar                  📞 +91 98765 43210     │
│                                                                     │
│  📋 PREPARATION CHECKLIST:                                         │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ ☑️ Order confirmed & payment verified                           ││
│  │ ☑️ Ingredients checked & available                              ││
│  │ 🔳 Start preparing Margherita Pizza #1                        ││
│  │ 🔳 Start preparing Margherita Pizza #2                        ││
│  │ 🔳 Add extra cheese (as requested)                            ││
│  │ 🔳 Prepare Coca Cola                                          ││
│  │ 🔳 Quality check & packaging                                   ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  📝 PREPARATION NOTES:                                             │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Customer requested extra cheese - added                         ││
│  │ Made less spicy as requested                                   ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  🔄 ORDER STATUS UPDATE:                                           │
│  [🍳 PREPARING] [✅ READY FOR PICKUP] [📞 CALL CUSTOMER]          │
│                                                                     │
│  ⏰ Preparation Timer: [START] [PAUSE] [RESET]                     │
│  Current Time: 12 minutes elapsed                                  │
└─────────────────────────────────────────────────────────────────────┘
```

#### **3. Ready for Pickup/Delivery**
```
Order Ready → Notify Delivery Partner
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    📦 ORDER READY                                  │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          ✅ Status: Ready        │
│  👤 Customer: Suresh Kumar                  ⏰ Ready at: 2:30 PM   │
│                                                                     │
│  🚚 DELIVERY ASSIGNMENT:                    📦 ORDER SUMMARY:      │
│  👤 Partner: Rajesh Kumar                   🍕 2x Margherita Pizza  │
│  📞 +91 90123 45678                        🥤 1x Coca Cola         │
│  🚚 Vehicle: Bike (KA01AB1234)             💰 Value: ₹450          │
│  ⭐ Rating: 4.7 (123 deliveries)                                   │
│                                                                     │
│  📍 DELIVERY TRACKING:                      ⏰ ESTIMATED DELIVERY:  │
│  Current Status: Partner Notified           🕐 3:00 PM (30 mins)   │
│  📍 Partner Location: En route              🏠 Distance: 2.5 km    │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  🚨 ACTIONS:                                                       │
│  [📞 CALL PARTNER] [📞 CALL CUSTOMER] [📊 TRACK DELIVERY]         │
│                                                                     │
│  ⚠️ Issues? [🚨 REPORT PROBLEM]                                   │
└─────────────────────────────────────────────────────────────────────┘
```

#### **4. Live Order Tracking**
```
┌─────────────────────────────────────────────────────────────────────┐
│                    📍 LIVE ORDER TRACKING                          │
├─────────────────────────────────────────────────────────────────────┤
│  Order: #ORD12345                          🚚 Delivery Partner:    │
│  👤 Suresh Kumar                            👤 Rajesh Kumar        │
│  📞 +91 98765 43210                        📞 +91 90123 45678     │
│                                                                     │
│  📊 DELIVERY PROGRESS:                                             │
│  ✅ Order Prepared        ⏰ 2:30 PM                              │
│  ✅ Partner Assigned      ⏰ 2:32 PM                              │
│  ✅ Picked Up from Shop   ⏰ 2:45 PM                              │
│  🚚 Out for Delivery      ⏰ 2:50 PM                              │
│  🔳 Delivered             ⏰ ETA: 3:10 PM                         │
│                                                                     │
│  🗺️ LIVE MAP:                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │           📍 Your Shop                                          ││
│  │              │                                                 ││
│  │              │ ▼ ▼ ▼ Route                                    ││
│  │              │                                                 ││
│  │         🚚 Partner Location                                    ││
│  │              │ (1.2 km to customer)                           ││
│  │              │ ▼ ▼ ▼                                          ││
│  │              │                                                 ││
│  │           🏠 Customer                                          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  📊 ESTIMATED DELIVERY: 3:10 PM (20 minutes)                      │
│  📍 Current Distance: 1.2 km from customer                        │
│                                                                     │
│  [📞 CALL PARTNER] [📞 CALL CUSTOMER] [🔄 REFRESH]                │
└─────────────────────────────────────────────────────────────────────┘
```

### 🛍️ Product Management

#### **Product Catalog**
```
┌─────────────────────────────────────────────────────────────────────┐
│                    🛍️ PRODUCT MANAGEMENT                          │
├─────────────────────────────────────────────────────────────────────┤
│  📊 INVENTORY OVERVIEW:                     🔍 [Search Products]    │
│  📦 Total Products: 47                      📋 [Categories ▼]      │
│  ✅ Available: 42                           [+ ADD PRODUCT]        │
│  ❌ Out of Stock: 5                                                │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                        🍕 PIZZAS (12)                              │
│                                                                     │
│  🍕 Margherita Pizza                        💰 ₹180     ✅ Available│
│     Medium/Large available                   📦 Stock: 50         │
│     [📝 EDIT] [📊 STATS] [❌ DISABLE]                             │
│                                                                     │
│  🍕 Pepperoni Pizza                         💰 ₹220     ❌ Out of Stock│
│     Large only                              📦 Stock: 0          │
│     [📝 EDIT] [📦 RESTOCK] [✅ ENABLE]                            │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                        🥤 BEVERAGES (8)                            │
│                                                                     │
│  🥤 Coca Cola                               💰 ₹60      ✅ Available│
│     500ml/1L available                       📦 Stock: 30         │
│     [📝 EDIT] [📊 STATS] [❌ DISABLE]                             │
│                                                                     │
│  🧃 Fresh Juice                             💰 ₹80      ✅ Available│
│     Orange/Apple/Mixed                       📦 Stock: 15         │
│     [📝 EDIT] [📊 STATS] [❌ DISABLE]                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

#### **Add/Edit Product**
```
┌─────────────────────────────────────────────────────────────────────┐
│                     📝 ADD NEW PRODUCT                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  📷 PRODUCT PHOTOS:                                                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                 │
│  │  📸     │ │  📸     │ │  📸     │ │    +    │                 │
│  │ Main    │ │ Angle 2 │ │ Angle 3 │ │   Add   │                 │
│  │ Photo   │ │         │ │         │ │  Photo  │                 │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘                 │
│                                                                     │
│  📋 BASIC DETAILS:                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Product Name: [Chicken Biryani                    ]            ││
│  │ Category: [Indian Food        ▼]                               ││
│  │ Description: [Authentic Hyderabadi Biryani with               ]││
│  │              [tender chicken pieces and basmati rice          ]││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  💰 PRICING & VARIANTS:                                            │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Size Options:                                                   ││
│  │ ☑️ Half Plate - ₹[180] - Stock: [25]                          ││
│  │ ☑️ Full Plate - ₹[320] - Stock: [15]                          ││
│  │ ☑️ Family Pack - ₹[550] - Stock: [8]                          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  📦 INVENTORY SETTINGS:                                            │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ Track Inventory: ☑️ Yes                                        ││
│  │ Low Stock Alert: [5] units                                     ││
│  │ Available: ☑️ Yes  Vegetarian: 🔳 No  Spicy: ☑️ Yes          ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│            [💾 SAVE PRODUCT]           [❌ CANCEL]                 │
└─────────────────────────────────────────────────────────────────────┘
```

### 📊 Business Analytics

#### **Sales Dashboard**
```
┌─────────────────────────────────────────────────────────────────────┐
│                    📊 BUSINESS ANALYTICS                           │
├─────────────────────────────────────────────────────────────────────┤
│  📅 TIME PERIOD: [Today] [Week] [Month] [Custom Range]            │
│                                                                     │
│  💰 REVENUE OVERVIEW:                       📈 PERFORMANCE:        │
│  Today: ₹2,400 (↑12% vs yesterday)         Orders: 18 (↑8%)       │
│  This Week: ₹16,800 (↑8% vs last week)     Avg Order: ₹133        │
│  This Month: ₹67,200 (↑15% vs last month)  Success Rate: 96%      │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      📊 SALES CHART                                │
│  ₹                                                                 │
│  3000 ┌─┐                                                         │
│       │ │                   ┌─┐                                   │
│  2000 │ │         ┌─┐      │ │                                   │
│       │ │         │ │      │ │     ┌─┐                           │
│  1000 │ │   ┌─┐   │ │      │ │     │ │                           │
│       │ │   │ │   │ │      │ │     │ │                           │
│     0 └─┘───┘─┘───┘─┘──────┘─┘─────┘─┘───────────────────────────── │
│       Mon Tue Wed Thu  Fri  Sat  Sun                              │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                    🏆 TOP PERFORMING ITEMS                         │
│                                                                     │
│  🥇 1. Margherita Pizza      - 47 orders  - ₹8,460 revenue        │
│  🥈 2. Chicken Biryani       - 32 orders  - ₹9,600 revenue        │
│  🥉 3. Pepperoni Pizza       - 28 orders  - ₹6,160 revenue        │
│  4. Coca Cola                - 45 orders  - ₹2,700 revenue        │
│  5. Garlic Bread             - 23 orders  - ₹1,610 revenue        │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│                      🕐 PEAK HOURS ANALYSIS                        │
│                                                                     │
│  Lunch Rush: 12:00 PM - 2:00 PM (28% of orders)                   │
│  Dinner Rush: 7:00 PM - 9:30 PM (42% of orders)                   │
│  Weekend Peak: Saturday 8:00 PM - 10:00 PM                        │
│                                                                     │
│  💡 Suggestion: Consider special offers during slow hours          │
│                                                                     │
│              [📊 DETAILED REPORT] [📧 EMAIL REPORT]                │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📱 Technical Architecture

### 🏗️ Mobile App Architecture

#### **Technology Stack**
```
Frontend Framework: Flutter 3.x
├─ UI Components: Material Design 3
├─ State Management: Provider/Riverpod
├─ Navigation: GoRouter
├─ Local Storage: Hive/SharedPreferences
├─ HTTP Client: Dio
├─ Maps Integration: Google Maps Flutter
├─ Notifications: Firebase Cloud Messaging
├─ Image Handling: cached_network_image
├─ Camera: camera/image_picker
└─ Authentication: JWT + OTP (MSG91)

Backend Integration:
├─ API Base URL: https://api.nammaoorudelivary.in
├─ Authentication: Bearer Token (JWT)
├─ Real-time Updates: WebSocket/Server-Sent Events
├─ Push Notifications: Firebase FCM
├─ Location Services: GPS + Google Maps API
└─ File Upload: Multipart form data
```

#### **Project Structure**
```
lib/
├─ main.dart                          # App entry point
├─ app/                              # App-level configuration
│  ├─ app.dart                       # Main app widget
│  ├─ routes.dart                    # App routing
│  └─ themes.dart                    # App theming
├─ core/                             # Core utilities
│  ├─ constants/                     # App constants
│  │  ├─ api_endpoints.dart
│  │  ├─ app_strings.dart
│  │  └─ app_colors.dart
│  ├─ services/                      # Core services
│  │  ├─ api_service.dart           # HTTP client
│  │  ├─ auth_service.dart          # Authentication
│  │  ├─ location_service.dart      # GPS & location
│  │  ├─ notification_service.dart   # Push notifications
│  │  └─ storage_service.dart       # Local storage
│  ├─ utils/                         # Utility functions
│  │  ├─ date_utils.dart
│  │  ├─ validation_utils.dart
│  │  └─ permission_utils.dart
│  └─ widgets/                       # Reusable widgets
│     ├─ custom_button.dart
│     ├─ loading_widget.dart
│     └─ error_widget.dart
├─ features/                         # Feature modules
│  ├─ auth/                         # Authentication
│  │  ├─ data/
│  │  │  ├─ models/
│  │  │  └─ repositories/
│  │  ├─ presentation/
│  │  │  ├─ screens/
│  │  │  ├─ widgets/
│  │  │  └─ providers/
│  │  └─ domain/
│  ├─ orders/                       # Order management
│  ├─ delivery/                     # Delivery features
│  ├─ products/                     # Product management
│  ├─ analytics/                    # Analytics & reporting
│  └─ profile/                      # User profile
└─ shared/                          # Shared components
   ├─ models/                       # Shared data models
   ├─ widgets/                      # Shared UI components
   └─ extensions/                   # Dart extensions
```

### 📡 API Integration

#### **Authentication Flow**
```dart
// API Service Example
class ApiService {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  
  // Send OTP for login
  Future<ApiResponse> sendOTP(String mobileNumber) async {
    return await post('/auth/send-otp', {
      'mobileNumber': mobileNumber
    });
  }
  
  // Verify OTP and get JWT token
  Future<AuthResponse> verifyOTP(String mobile, String otp) async {
    final response = await post('/auth/verify-otp', {
      'mobileNumber': mobile,
      'otp': otp
    });
    
    if (response.success) {
      await StorageService.saveAuthToken(response.data['token']);
    }
    
    return AuthResponse.fromJson(response.data);
  }
}
```

#### **Real-time Order Updates**
```dart
// WebSocket Service for real-time updates
class WebSocketService {
  IOWebSocketChannel? _channel;
  
  void connectToOrderUpdates(String token) {
    _channel = IOWebSocketChannel.connect(
      'wss://api.nammaoorudelivary.in/ws/orders',
      headers: {'Authorization': 'Bearer $token'}
    );
    
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      _handleOrderUpdate(data);
    });
  }
  
  void _handleOrderUpdate(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'new_order':
        _showNewOrderNotification(data);
        break;
      case 'order_status_changed':
        _updateOrderStatus(data);
        break;
      case 'assignment_update':
        _updateAssignmentStatus(data);
        break;
    }
  }
}
```

### 📱 Key Features Implementation

#### **Location Tracking for Delivery Partners**
```dart
class LocationTrackingService {
  Timer? _locationTimer;
  Position? _lastKnownPosition;
  
  void startLocationTracking() {
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateCurrentLocation();
    });
  }
  
  Future<void> _updateCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (_shouldSendUpdate(position)) {
        await ApiService.updatePartnerLocation(
          position.latitude, 
          position.longitude
        );
        _lastKnownPosition = position;
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }
  
  bool _shouldSendUpdate(Position newPosition) {
    if (_lastKnownPosition == null) return true;
    
    double distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude
    );
    
    return distance > 50; // Send update if moved more than 50 meters
  }
}
```

#### **Push Notifications**
```dart
class NotificationService {
  static FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission();
    
    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await ApiService.updateFCMToken(token);
    }
    
    // Handle background notifications
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen(_foregroundHandler);
  }
  
  static void _foregroundHandler(RemoteMessage message) {
    if (message.data['type'] == 'new_assignment') {
      _showAssignmentDialog(message.data);
    } else if (message.data['type'] == 'order_ready') {
      _showOrderReadyNotification(message.data);
    }
  }
  
  static void _showAssignmentDialog(Map<String, dynamic> data) {
    Get.dialog(
      AssignmentDialog(
        orderId: data['orderId'],
        shopName: data['shopName'],
        customerName: data['customerName'],
        deliveryFee: data['deliveryFee'],
        distance: data['distance'],
      ),
      barrierDismissible: false,
    );
  }
}
```

---

## 🎯 Next Steps for Implementation

### 📋 Phase 1: Core Development
1. **Setup Flutter Project Structure**
2. **Implement Authentication (OTP)**
3. **Create Basic UI Components**
4. **API Integration Layer**
5. **Local Storage Setup**

### 📋 Phase 2: Delivery Partner App
1. **Dashboard & Navigation**
2. **Assignment Management**
3. **Location Tracking**
4. **Order Workflow (Accept → Pickup → Deliver)**
5. **Earnings Dashboard**

### 📋 Phase 3: Shop Owner App
1. **Dashboard & Orders**
2. **Product Management**
3. **Order Status Updates**
4. **Analytics Dashboard**
5. **Business Settings**

### 📋 Phase 4: Advanced Features
1. **Real-time Notifications**
2. **Maps Integration**
3. **Camera Features**
4. **Offline Capabilities**
5. **Performance Optimization**

### 📋 Phase 5: Testing & Deployment
1. **Unit Testing**
2. **Integration Testing**
3. **User Acceptance Testing**
4. **Play Store/App Store Deployment**
5. **Performance Monitoring**

---

**🔄 Document Status**  
- **Created**: January 2025
- **Version**: 1.0  
- **Next Phase**: Begin Flutter project setup
- **Estimated Development Time**: 8-12 weeks

This comprehensive flow design provides the complete roadmap for building both mobile applications with detailed user experiences, technical architecture, and implementation phases.