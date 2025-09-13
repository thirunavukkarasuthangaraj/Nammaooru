# 📱 Basic Mobile App Function Flow

## 🚚 DELIVERY PARTNER APP - Basic Flow

### 🔐 **1. Login**
```
Open App → Enter Mobile → Get OTP → Verify → Dashboard
```

### 🏠 **2. Dashboard (Simple)**
```
┌─────────────────────────────┐
│ 🔴 OFFLINE [Toggle Online] │
├─────────────────────────────┤
│ 👋 Hi Rajesh!              │
│ Today: 5 orders, ₹400      │
├─────────────────────────────┤
│ 📋 NEW ORDER               │
│ Pizza Palace → HSR Layout  │
│ ₹80 | 2.5km               │
│ [ACCEPT] [REJECT]          │
└─────────────────────────────┘
```

### 📋 **3. Order Flow**
```
New Order → Accept → Go to Shop → Pickup → Deliver → Complete
```

**Accept Order:**
- Show order details
- Tap ACCEPT

**Pickup:**
- Navigate to shop
- Tap "PICKED UP" when got order

**Deliver:**  
- Navigate to customer
- Tap "DELIVERED" when done

### 💰 **4. Earnings**
```
Today: ₹400
This Week: ₹2800
[View Details]
```

---

## 🏪 SHOP OWNER APP - Basic Flow

### 🔐 **1. Login**
```
Open App → Enter Mobile → Get OTP → Verify → Dashboard
```

### 🏠 **2. Dashboard (Simple)**
```
┌─────────────────────────────┐
│ 🟢 OPEN [Toggle Closed]    │
├─────────────────────────────┤
│ 🏪 Pizza Palace           │
│ Today: 8 orders, ₹1200    │
├─────────────────────────────┤
│ 🔔 NEW ORDER (2)          │
│ Margherita Pizza x2        │
│ Customer: Suresh           │
│ ₹360                       │
│ [ACCEPT] [REJECT]          │
└─────────────────────────────┘
```

### 📋 **3. Order Management**
```
New Order → Accept → Prepare → Ready → Track Delivery
```

**Accept Order:**
- See order details
- Set prep time (15/30/45 mins)
- Tap ACCEPT

**Prepare:**
- Tap "PREPARING" when start cooking
- Tap "READY" when done

**Ready:**
- Order auto-assigned to delivery partner
- Track delivery progress

### 🛍️ **4. Products (Basic)**
```
┌─────────────────────────────┐
│ 📋 MY PRODUCTS             │
├─────────────────────────────┤
│ 🍕 Margherita - ₹180  ✅   │
│ 🍕 Pepperoni - ₹220   ❌   │
│ 🥤 Coke - ₹60         ✅   │
│                            │
│ [+ ADD PRODUCT]            │
└─────────────────────────────┘
```

**Add Product:**
- Product name
- Price  
- Available/Not available
- Save

---

## 🔧 Basic API Calls

### **Delivery Partner APIs:**
```
POST /api/auth/send-otp
POST /api/auth/verify-otp
GET /api/delivery/assignments/partner/{id}/active
PUT /api/delivery/assignments/{id}/accept
PUT /api/delivery/assignments/{id}/pickup  
PUT /api/delivery/assignments/{id}/complete
GET /api/delivery/partners/{id}/earnings
```

### **Shop Owner APIs:**
```
POST /api/auth/send-otp
POST /api/auth/verify-otp
GET /api/orders/shop/{shopId}
POST /api/orders/{orderId}/accept
POST /api/orders/{orderId}/prepare
POST /api/orders/{orderId}/ready
GET /api/shop-owner/products
POST /api/shop-owner/products
```

---

## 📱 Basic Screens List

### **Delivery Partner (6 Screens):**
1. Login Screen
2. Dashboard Screen  
3. Order Details Screen
4. Navigation Screen (Google Maps)
5. Delivery Confirmation Screen
6. Earnings Screen

### **Shop Owner (6 Screens):**
1. Login Screen
2. Dashboard Screen
3. Order Management Screen
4. Order Preparation Screen  
5. Product List Screen
6. Add Product Screen

---

## 🚀 Implementation Priority

### **Week 1-2: Authentication**
- Login with OTP
- JWT token storage
- API service setup

### **Week 3-4: Delivery Partner Core**
- Dashboard with orders
- Accept/reject orders
- Basic pickup/delivery flow

### **Week 5-6: Shop Owner Core** 
- Dashboard with orders
- Accept orders + prep time
- Basic product list

### **Week 7-8: Integration & Polish**
- Real-time notifications
- Maps integration
- Bug fixes

---

## 🎯 MVP Features Only

### **Delivery Partner MVP:**
✅ Login with mobile OTP  
✅ See assigned orders  
✅ Accept/reject assignments  
✅ Mark pickup/delivered  
✅ View earnings  

### **Shop Owner MVP:**
✅ Login with mobile OTP  
✅ See incoming orders  
✅ Accept/reject orders  
✅ Set order as ready  
✅ Basic product management  

**No complex features:**
❌ No real-time tracking  
❌ No camera features  
❌ No detailed analytics  
❌ No maps initially  
❌ No chat/messaging  

This gets both apps working with core business functionality in 8 weeks!