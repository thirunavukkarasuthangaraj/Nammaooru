# 📱 Mobile App APIs Reference

## 🎯 **All APIs Already Exist - Ready to Use!**

---

## 🔐 **AUTHENTICATION APIs**

### **1. OTP Authentication (Both Apps)**
```
POST /api/auth/send-otp
Body: { "mobileNumber": "9876543210" }
Response: { "success": true, "message": "OTP sent" }

POST /api/auth/verify-otp  
Body: { "mobileNumber": "9876543210", "otp": "123456" }
Response: { "success": true, "token": "jwt_token", "user": {...} }

POST /api/auth/resend-otp
Body: { "mobileNumber": "9876543210" }
```

---

## 🚚 **DELIVERY PARTNER APIs**

### **2. Assignment Management**
```
GET /api/delivery/assignments/partner/{partnerId}/active
Headers: Authorization: Bearer {token}
Response: [ { "id": 1, "orderId": 123, "status": "ASSIGNED", ... } ]

PUT /api/delivery/assignments/{assignmentId}/accept
Body: { "partnerId": 123 }
Response: { "success": true, "assignment": {...} }

PUT /api/delivery/assignments/{assignmentId}/reject  
Body: { "partnerId": 123, "reason": "Vehicle issue" }
Response: { "success": true }
```

### **3. Order Workflow**
```
PUT /api/delivery/assignments/{assignmentId}/pickup
Body: { "partnerId": 123 }
Response: { "success": true, "assignment": {...} }

PUT /api/delivery/assignments/{assignmentId}/start-delivery
Body: { "partnerId": 123 }
Response: { "success": true }

PUT /api/delivery/assignments/{assignmentId}/complete
Body: { "partnerId": 123, "notes": "Delivered successfully" }
Response: { "success": true, "earning": {...} }

PUT /api/delivery/assignments/{assignmentId}/fail
Body: { "partnerId": 123, "reason": "Customer not available" }
```

### **4. Partner Profile & Earnings**
```
GET /api/delivery/partners/{partnerId}/stats
Response: { "totalDeliveries": 156, "rating": 4.8, "successRate": 96 }

GET /api/delivery/partners/{partnerId}/earnings
Query: ?page=0&size=10&startDate=2025-01-01&endDate=2025-01-31
Response: { "content": [...], "totalEarnings": 15600 }

PUT /api/delivery/partners/{partnerId}/availability  
Body: { "isAvailable": true }
Response: { "success": true }
```

---

## 🏪 **SHOP OWNER APIs**

### **5. Order Management**
```
GET /api/orders/shop/{shopId}
Query: ?page=0&size=10&status=PENDING
Response: { "content": [...orders...], "totalElements": 25 }

POST /api/orders/{orderId}/accept
Body: { "estimatedPreparationTime": "30", "notes": "Will be ready soon" }
Response: { "success": true, "order": {...} }

POST /api/orders/{orderId}/reject
Body: { "reason": "Ingredients not available" }
Response: { "success": true }
```

### **6. Order Status Updates**
```
POST /api/orders/{orderId}/prepare
Response: { "success": true, "order": {...} }

POST /api/orders/{orderId}/ready
Response: { "success": true, "order": {...} }

PUT /api/orders/{orderId}/status
Body: { "status": "PREPARING" }
Response: { "success": true }
```

### **7. Product Management**
```
GET /api/shop-owner/products
Query: ?shopId={shopId}&page=0&size=20
Response: { "content": [...products...] }

POST /api/shop-owner/products
Body: {
  "name": "Margherita Pizza",
  "price": 180,
  "category": "Pizza", 
  "isAvailable": true,
  "shopId": 123
}

PUT /api/shop-owner/products/{productId}
Body: { "name": "Updated Pizza", "price": 200, "isAvailable": false }

DELETE /api/shop-owner/products/{productId}
```

### **8. Shop Management**
```
GET /api/shop-owner/shops
Response: [ { "id": 1, "name": "Pizza Palace", "isApproved": true } ]

PUT /api/shop-owner/shops/{shopId}/hours
Body: {
  "monday": { "openTime": "09:00", "closeTime": "22:00", "isClosed": false },
  "tuesday": { "openTime": "09:00", "closeTime": "22:00", "isClosed": false }
}
```

---

## 📊 **ANALYTICS & REPORTING APIs**

### **9. Business Analytics (Shop Owner)**
```
GET /api/admin/analytics
Query: ?shopId={shopId}&period=TODAY&startDate=2025-01-01&endDate=2025-01-31
Response: {
  "totalOrders": 45,
  "totalRevenue": 12500,
  "topProducts": [...],
  "peakHours": [...]
}

GET /api/orders/shop/{shopId}/summary
Query: ?period=WEEK
Response: {
  "ordersCount": 67,
  "revenue": 15600,
  "averageOrderValue": 233
}
```

---

## 🔔 **NOTIFICATION & MESSAGING APIs**

### **10. Push Notifications (Future)**
```
POST /api/notifications/fcm-token
Body: { "userId": 123, "fcmToken": "firebase_token", "deviceType": "ANDROID" }

GET /api/notifications/user/{userId}
Response: [ { "title": "New Order", "message": "You have a new order", "timestamp": "..." } ]
```

---

## 📍 **LOCATION & TRACKING APIs**

### **11. Location Services (Delivery Partner)**
```
PUT /api/delivery/partners/{partnerId}/location
Body: { "latitude": 12.9716, "longitude": 77.5946, "timestamp": "2025-01-15T10:30:00Z" }

GET /api/delivery/tracking/{assignmentId}
Response: {
  "partnerLocation": { "lat": 12.9716, "lng": 77.5946 },
  "estimatedArrival": "10 minutes",
  "status": "IN_TRANSIT"
}
```

---

## 🎯 **MOBILE APP API USAGE BY SCREEN**

### **🚚 Delivery Partner App:**

**Login Screen:**
- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`

**Dashboard Screen:**
- `GET /api/delivery/assignments/partner/{partnerId}/active`
- `GET /api/delivery/partners/{partnerId}/stats`
- `PUT /api/delivery/partners/{partnerId}/availability`

**Order Details Screen:**
- `PUT /api/delivery/assignments/{id}/accept`
- `PUT /api/delivery/assignments/{id}/reject`

**Pickup/Delivery Screen:**
- `PUT /api/delivery/assignments/{id}/pickup`
- `PUT /api/delivery/assignments/{id}/start-delivery`
- `PUT /api/delivery/assignments/{id}/complete`

**Earnings Screen:**
- `GET /api/delivery/partners/{partnerId}/earnings`

---

### **🏪 Shop Owner App:**

**Login Screen:**
- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`

**Dashboard Screen:**
- `GET /api/orders/shop/{shopId}`
- `GET /api/shop-owner/shops`

**Order Management Screen:**
- `POST /api/orders/{orderId}/accept`
- `POST /api/orders/{orderId}/reject`
- `POST /api/orders/{orderId}/prepare`
- `POST /api/orders/{orderId}/ready`

**Product Management Screen:**
- `GET /api/shop-owner/products`
- `POST /api/shop-owner/products`
- `PUT /api/shop-owner/products/{productId}`

**Analytics Screen:**
- `GET /api/admin/analytics`
- `GET /api/orders/shop/{shopId}/summary`

---

## 🔧 **API Configuration for Mobile**

### **Base Configuration:**
```dart
class ApiConfig {
  static const String baseUrl = 'https://api.nammaoorudelivary.in/api';
  static const String devUrl = 'http://localhost:8080/api';
  
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
```

### **Error Handling:**
```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;
  
  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
}
```

---

## 📋 **Ready-to-Use API Checklist**

### ✅ **Authentication:**
- [x] Send OTP
- [x] Verify OTP  
- [x] Resend OTP
- [x] JWT Token handling

### ✅ **Delivery Partner:**
- [x] Get active assignments
- [x] Accept/reject assignments
- [x] Pickup/delivery workflow
- [x] Earnings & stats
- [x] Availability toggle

### ✅ **Shop Owner:**
- [x] Order management (accept/reject/status)
- [x] Product CRUD operations
- [x] Shop management
- [x] Business analytics

### ✅ **Additional Features:**
- [x] Location tracking
- [x] Order tracking
- [x] Notifications (structure ready)
- [x] File upload (for product images)

---

## 🚀 **Implementation Strategy**

### **Week 1-2: Core API Integration**
1. Setup API service layer
2. Implement authentication flow
3. JWT token management
4. Error handling

### **Week 3-4: Delivery Partner APIs**
1. Assignment management
2. Order workflow APIs
3. Earnings integration
4. Profile management

### **Week 5-6: Shop Owner APIs**
1. Order management APIs
2. Product management
3. Analytics integration
4. Shop settings

### **Week 7-8: Advanced Features**
1. Real-time updates (WebSocket)
2. Push notifications
3. Location tracking
4. File upload for images

**All backend APIs are ready - just need mobile implementation! 🎉**