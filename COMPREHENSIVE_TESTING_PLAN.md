# COMPREHENSIVE TESTING PLAN - NAMMAOORU SHOP MANAGEMENT SYSTEM

## Overview
This document outlines a systematic testing approach to verify all modules are working properly with valid data. The plan addresses the observation that approximately 50% of functionality may not work when tested.

## Testing Philosophy
- **Test with Real Data:** No dummy/mock data
- **End-to-End Validation:** Complete user workflows
- **Systematic Approach:** Foundation first, then integration
- **Document Everything:** Pass/Fail status with details

---

## PHASE 1: BACKEND API TESTING (Foundation)

### Prerequisites
```bash
# Start Backend Server
cd backend && ./mvnw spring-boot:run

# Start Database
# PostgreSQL should be running on localhost:5432
```

### 1.1 Authentication Module Testing

#### Test 1: User Registration
```bash
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "username": "testshop1",
  "email": "shop1@nammaooru.com",
  "password": "Test123!",
  "role": "SHOP_OWNER",
  "mobileNumber": "9876543210"
}
```
**Expected:** 201 Created with user details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 2: User Login
```bash
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "username": "testshop1",
  "password": "Test123!"
}
```
**Expected:** 200 OK with JWT token
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 3: Token Validation
```bash
GET http://localhost:8080/api/auth/validate
Authorization: Bearer {jwt_token}
```
**Expected:** 200 OK with user details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 1.2 User Management Testing

#### Test 4: Get All Users
```bash
GET http://localhost:8080/api/users
Authorization: Bearer {jwt_token}
```
**Expected:** 200 OK with user list
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 5: Create Delivery Partner
```bash
POST http://localhost:8080/api/users
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "username": "driver1",
  "email": "driver1@nammaooru.com",
  "password": "Driver123!",
  "role": "DELIVERY_PARTNER",
  "mobileNumber": "9876543211",
  "vehicleType": "BIKE",
  "licenseNumber": "DL1234567890"
}
```
**Expected:** 201 Created with delivery partner details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 1.3 Shop Management Testing

#### Test 6: Create Shop
```bash
POST http://localhost:8080/api/shops
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Nammaooru Village Shop",
  "address": "123 Main Street, Village Center",
  "latitude": 12.9716,
  "longitude": 77.5946,
  "contactNumber": "9876543212",
  "ownerUsername": "testshop1"
}
```
**Expected:** 201 Created with shop details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 7: Get All Shops
```bash
GET http://localhost:8080/api/shops
```
**Expected:** 200 OK with shop list
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 1.4 Product Management Testing

#### Test 8: Create Product
```bash
POST http://localhost:8080/api/products
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Basmati Rice 1kg",
  "description": "Premium quality basmati rice",
  "price": 85.00,
  "category": "GROCERIES",
  "shopId": "{shop_id_from_test_6}",
  "stockQuantity": 100,
  "unit": "KG"
}
```
**Expected:** 201 Created with product details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 9: Get Products by Shop
```bash
GET http://localhost:8080/api/products/shop/{shop_id}
```
**Expected:** 200 OK with product list
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 1.5 Order Workflow Testing

#### Test 10: Create Customer
```bash
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "username": "customer1",
  "email": "customer1@nammaooru.com",
  "password": "Customer123!",
  "role": "CUSTOMER",
  "mobileNumber": "9876543213"
}
```
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 11: Create Order
```bash
POST http://localhost:8080/api/orders
Authorization: Bearer {customer_jwt_token}
Content-Type: application/json

{
  "customerId": "{customer_id}",
  "shopId": "{shop_id}",
  "deliveryAddress": "456 Customer Street, Village",
  "items": [
    {
      "productId": "{product_id}",
      "quantity": 2,
      "price": 85.00
    }
  ],
  "totalAmount": 170.00
}
```
**Expected:** 201 Created with order details
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 12: Assign Delivery Partner
```bash
PUT http://localhost:8080/api/orders/{order_id}/assign
Authorization: Bearer {shop_owner_jwt_token}
Content-Type: application/json

{
  "deliveryPartnerId": "{delivery_partner_id}"
}
```
**Expected:** 200 OK with updated order
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 13: Update Order Status
```bash
PUT http://localhost:8080/api/orders/{order_id}/status
Authorization: Bearer {delivery_partner_jwt_token}
Content-Type: application/json

{
  "status": "PICKED_UP"
}
```
**Expected:** 200 OK with updated status
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

---

## PHASE 2: MOBILE APP TESTING

### Prerequisites
```bash
# Start Customer Mobile App
cd mobile/nammaooru_mobile_app && flutter run

# Start Delivery Partner App
cd mobile/nammaooru_delivery_partner && flutter run
```

### 2.1 Customer Mobile App Testing

#### Test 14: Login Flow
1. Open app
2. Enter credentials: customer1@nammaooru.com / Customer123!
3. Verify successful login and navigation to home

**Expected:** Login successful, home screen loads
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 15: Shop Browse
1. Navigate to shops list
2. Verify shops load from API (not dummy data)
3. Check shop details display correctly

**Expected:** Real shops from database displayed
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 16: Product Catalog
1. Select a shop
2. View products list
3. Verify products load from API

**Expected:** Real products with correct prices
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 17: Cart Management
1. Add products to cart
2. Update quantities
3. Remove items
4. Verify cart persistence

**Expected:** Cart functions work properly
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 18: Order Placement
1. Complete cart with items
2. Enter delivery address
3. Place order
4. Verify order created in backend

**Expected:** Order successfully placed and stored
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 19: Order Tracking
1. View order history
2. Check order status updates
3. Verify real-time tracking

**Expected:** Live order status updates
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 2.2 Delivery Partner App Testing

#### Test 20: Delivery Partner Login
1. Open delivery app
2. Login with: driver1@nammaooru.com / Driver123!
3. Verify successful authentication

**Expected:** Login successful, dashboard loads
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 21: Available Orders
1. Navigate to available orders
2. Verify orders load from API
3. Check order details accuracy

**Expected:** Real orders from database
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 22: Order Assignment
1. Accept an available order
2. Verify order status updates
3. Check notification to customer

**Expected:** Order assigned successfully
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 23: Navigation Integration
1. Start delivery for an order
2. Open navigation/maps
3. Verify route calculation

**Expected:** Maps integration works
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 24: Status Updates
1. Update order status (Picked up, In transit, Delivered)
2. Verify updates reflect in customer app
3. Check real-time synchronization

**Expected:** Status updates work end-to-end
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 25: Earnings Tracking
1. Complete a delivery
2. Check earnings calculation
3. Verify payment tracking

**Expected:** Earnings calculated correctly
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

---

## PHASE 3: FRONTEND ANGULAR TESTING

### Prerequisites
```bash
# Start Angular Frontend
cd frontend && npm start
# Access: http://localhost:4200
```

### 3.1 Admin Dashboard Testing

#### Test 26: Admin Login
1. Navigate to http://localhost:4200
2. Login with admin credentials
3. Verify dashboard loads

**Expected:** Admin dashboard accessible
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 27: User Management
1. Navigate to Users section
2. View user list (should show test users created)
3. Create new user
4. Edit existing user
5. Verify database updates

**Expected:** User CRUD operations work
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 28: Shop Management
1. Navigate to Shops section
2. View shops list
3. Create new shop
4. Edit shop details
5. Verify API integration

**Expected:** Shop management functions properly
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 29: Order Management
1. Navigate to Orders section
2. View all orders (should show test orders)
3. Update order status
4. Assign delivery partners
5. Verify real-time updates

**Expected:** Order management works end-to-end
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 30: Analytics Dashboard
1. Navigate to Analytics
2. Check order statistics
3. Verify revenue calculations
4. Test date range filters

**Expected:** Analytics display real data
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 3.2 Shop Owner Module Testing

#### Test 31: Shop Owner Login
1. Login as testshop1@nammaooru.com
2. Verify shop owner dashboard loads
3. Check shop-specific data

**Expected:** Shop owner sees only their data
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 32: Product Management
1. Navigate to Products section
2. Add new product
3. Edit existing product
4. Update inventory
5. Verify mobile app reflects changes

**Expected:** Product management works
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 33: Order Management
1. View incoming orders
2. Accept/reject orders
3. Assign delivery partners
4. Track order progress

**Expected:** Shop owner can manage orders
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

---

## PHASE 4: INTEGRATION TESTING

### 4.1 End-to-End Workflow Testing

#### Test 34: Complete Order Flow
1. **Customer:** Place order via mobile app
2. **Shop Owner:** Receive notification and accept order
3. **System:** Auto-assign or manually assign delivery partner
4. **Delivery Partner:** Receive order in mobile app
5. **Customer:** Track order progress in real-time
6. **Delivery Partner:** Update status and complete delivery
7. **System:** Process payment and update earnings

**Expected:** Complete workflow works seamlessly
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 35: Real-time Communication
1. Test WebSocket connections
2. Verify live order updates
3. Check push notifications
4. Test location tracking

**Expected:** Real-time features work
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 36: Payment Integration
1. Test payment processing
2. Verify transaction recording
3. Check refund handling
4. Test payment failures

**Expected:** Payment system works
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 4.2 Data Consistency Testing

#### Test 37: Database Relationships
1. Check foreign key constraints
2. Verify data integrity
3. Test cascade operations
4. Check orphaned records

**Expected:** Database relationships maintained
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 38: Concurrent Operations
1. Multiple users placing orders simultaneously
2. Inventory updates during active orders
3. Delivery partner availability conflicts
4. Race condition handling

**Expected:** System handles concurrency
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

---

## PHASE 5: PERFORMANCE & SECURITY TESTING

### 5.1 Performance Testing

#### Test 39: Load Testing
1. Simulate 100 concurrent users
2. Test API response times
3. Check database performance
4. Monitor memory usage

**Expected:** System performs under load
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 40: Mobile App Performance
1. Test app startup time
2. Check memory usage
3. Test network handling
4. Verify offline capabilities

**Expected:** Mobile apps perform well
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

### 5.2 Security Testing

#### Test 41: Authentication Security
1. Test JWT token expiration
2. Verify role-based access
3. Check unauthorized access prevention
4. Test password security

**Expected:** Security measures work
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

#### Test 42: Data Validation
1. Test input validation
2. Check SQL injection prevention
3. Verify XSS protection
4. Test file upload security

**Expected:** Data validation prevents attacks
**Test Status:** [ ] PASS [ ] FAIL [ ] PARTIAL

---

## EXECUTION SCHEDULE

### Week 1: Foundation Testing
- **Day 1:** Backend API Testing (Tests 1-13)
- **Day 2:** Mobile Apps Basic Functions (Tests 14-25)
- **Day 3:** Frontend Angular Testing (Tests 26-33)

### Week 2: Integration & Advanced Testing
- **Day 4:** End-to-End Workflows (Tests 34-36)
- **Day 5:** Data Consistency (Tests 37-38)
- **Day 6:** Performance Testing (Tests 39-40)
- **Day 7:** Security Testing (Tests 41-42)

## REPORTING

### Daily Reports
- Document each test result
- Record any bugs found
- Note performance issues
- List required fixes

### Weekly Summary
- Overall system health
- Critical issues found
- Recommended priorities
- Deployment readiness

### Final Assessment
- Percentage of working functionality
- Critical vs non-critical issues
- Production readiness score
- Action plan for fixes

---

## SUCCESS CRITERIA

### Minimum Viable Product (MVP)
- [ ] User authentication works end-to-end
- [ ] Order placement and tracking functional
- [ ] Basic delivery workflow operational
- [ ] Core admin functions working
- [ ] Mobile apps connect to real APIs

### Production Ready
- [ ] All critical workflows 100% functional
- [ ] Real-time features working
- [ ] Payment processing operational
- [ ] Performance meets requirements
- [ ] Security measures in place

---

## NOTES
- All tests should use **real data**, not mock/dummy data
- Each failed test should include detailed error information
- Fixes should be implemented and retested immediately
- This plan ensures we get an accurate assessment of actual working functionality

**Created:** September 17, 2025
**Last Updated:** September 17, 2025
**Version:** 1.0