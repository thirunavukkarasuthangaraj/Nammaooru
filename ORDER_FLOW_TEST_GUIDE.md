# Complete Order Flow Testing Guide

## 🎯 Test Accounts Created

| Role | Username | Password | Purpose |
|------|----------|----------|---------|
| **Customer** | customer1 | password | Place orders |
| **Shop Owner** | shopowner1 | password | Manage shop & orders |
| **Delivery Partner** | delivery1 | password | Deliver orders |
| **Admin** | admin | password | System administration |
| **Super Admin** | superadmin | password | Full system access |

## 📋 Setup Test Data

1. **Run SQL in pgAdmin4**:
   - Open pgAdmin4
   - Connect to `shop_management_db`
   - Run: `database/test-order-flow-data.sql`

## 🛒 Test Flow 1: Customer Order Process

### Step 1: Customer Login
1. Go to http://localhost:8080
2. Login as: `customer1` / `password`
3. You'll see customer dashboard

### Step 2: Browse & Add to Cart
1. Click **"Browse Shops"** or **"All Shops"**
2. Find **"Test Grocery Store"**
3. Click to view products
4. Add items to cart:
   - Tomatoes (₹40/kg)
   - Milk (₹25/liter)
   - Orange Juice (₹80/liter)

### Step 3: Checkout
1. Click **Cart** icon
2. Review items
3. Click **"Proceed to Checkout"**
4. Enter delivery address (or use saved)
5. Select payment method (Cash on Delivery)
6. Click **"Place Order"**
7. Note the **Order Number** (e.g., ORD-2024-0001)

## 👨‍💼 Test Flow 2: Shop Owner Management

### Step 1: Shop Owner Login
1. Open new incognito window
2. Go to http://localhost:8080
3. Login as: `shopowner1` / `password`
4. You'll see shop owner dashboard

### Step 2: View New Order
1. Click **"Orders"** or **"Pending Orders"**
2. You should see the order from customer1
3. Click order to view details

### Step 3: Process Order
1. Click **"Accept Order"**
2. Order status changes to **"CONFIRMED"**
3. Click **"Mark as Ready"** when prepared
4. Order status changes to **"READY_FOR_PICKUP"**

### Step 4: Request Delivery Assignment
1. Click **"Request Delivery"**
2. System will auto-assign or you can manually assign
3. Wait for delivery partner assignment

## 🚴 Test Flow 3: Delivery Assignment

### Step 1: Admin/Shop Owner Assigns Delivery
As shop owner or admin:
1. Go to **"Delivery Management"**
2. Find the ready order
3. Click **"Assign Delivery Partner"**
4. Select **"Delivery Partner"** from list
5. Click **"Assign"**

### Step 2: Delivery Partner Login
1. Open another incognito window
2. Login as: `delivery1` / `password`
3. You'll see delivery dashboard

### Step 3: Accept & Deliver
1. Click **"New Assignments"** or **"Pending Deliveries"**
2. Find the assigned order
3. Click **"Accept Delivery"**
4. Click **"Pick Up Order"** (at shop)
5. Click **"Start Delivery"**
6. Click **"Complete Delivery"** (at customer location)

## 📊 Test Flow 4: Order Tracking

### As Customer:
1. Login as customer1
2. Go to **"My Orders"**
3. Click on your order
4. See real-time status:
   - PENDING → CONFIRMED → READY → OUT_FOR_DELIVERY → DELIVERED

### As Shop Owner:
1. Login as shopowner1
2. Go to **"Orders"** → **"All Orders"**
3. Filter by status
4. View order history and earnings

## 🔄 Complete Order Lifecycle

```
Customer Places Order
    ↓
Shop Owner Receives Notification
    ↓
Shop Owner Accepts Order
    ↓
Shop Prepares Order
    ↓
Shop Marks as Ready
    ↓
Delivery Partner Assigned
    ↓
Delivery Partner Accepts
    ↓
Pickup from Shop
    ↓
Out for Delivery
    ↓
Delivered to Customer
    ↓
Customer Rates Experience
```

## 💰 Payment Flow

1. **Cash on Delivery (COD)**:
   - Customer pays delivery partner
   - Partner collects cash
   - System tracks payment

2. **Online Payment** (if configured):
   - Customer pays during checkout
   - Shop receives payment minus commission
   - Delivery partner gets delivery fee

## 📱 Additional Features to Test

### Shop Owner Features:
- **Inventory Management**: Update stock levels
- **Product Management**: Add/edit products
- **Reports**: View sales reports
- **Settings**: Update shop details

### Customer Features:
- **Order History**: View past orders
- **Reorder**: Quick reorder previous items
- **Ratings**: Rate shop and delivery
- **Address Book**: Save multiple addresses

### Delivery Features:
- **Earnings**: View delivery earnings
- **History**: See completed deliveries
- **Availability**: Toggle online/offline status
- **Route**: View delivery route on map

## 🎭 Role-Based Access

| Feature | Customer | Shop Owner | Delivery | Admin |
|---------|----------|------------|----------|-------|
| Browse Products | ✅ | ✅ | ❌ | ✅ |
| Place Orders | ✅ | ❌ | ❌ | ✅ |
| Manage Shop | ❌ | ✅ | ❌ | ✅ |
| Deliver Orders | ❌ | ❌ | ✅ | ✅ |
| System Settings | ❌ | ❌ | ❌ | ✅ |

## 🧪 Testing Tips

1. **Use Incognito Windows**: Test different roles simultaneously
2. **Check Notifications**: Each role gets relevant notifications
3. **Test Edge Cases**:
   - Cancel order
   - Out of stock items
   - Delivery partner unavailable
   - Shop closed
4. **Mobile Testing**: Resize browser to test mobile view

## 📝 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Can't login | Check username/password, ensure user is active |
| No products showing | Run test data SQL, check shop is approved |
| Can't assign delivery | Ensure delivery partner is online/available |
| Order stuck | Check all users completed their steps |

## 🎯 Success Criteria

✅ Customer can browse, add to cart, and place order
✅ Shop owner receives and can process order
✅ Delivery partner can be assigned and complete delivery
✅ Order status updates throughout the flow
✅ All users see appropriate dashboards and features
✅ Notifications work at each step