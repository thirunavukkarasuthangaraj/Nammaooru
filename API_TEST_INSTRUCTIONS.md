# 🎯 Complete API Testing Guide

This guide walks you through testing all APIs from admin creation to invoice delivery using real email addresses.

## 📧 Test Email Addresses

- **Admin**: `thoruncse75@gmail.com`
- **Shop Owner**: `thiruna2394@gmail.com` 
- **Customer**: `thiru.t@gmail.com`
- **Delivery Partner**: `helec60392@jobzyy.com`

## 🚀 Quick Start

### 1. Start the Server
```bash
./START_SERVER_FOR_TESTING.sh
```

### 2. Run Complete API Test
```bash
./COMPLETE_API_TEST_WORKFLOW.sh
```

### 3. Check OTPs in Database
```bash
./GET_OTP_FROM_DATABASE.sh
```

## 📋 Test Flow Overview

The complete test workflow covers:

### 🔐 **Authentication & User Management**
1. Create admin user (`thoruncse75@gmail.com`)
2. Admin login and authentication
3. User role management

### 🏪 **Shop Management**
3. Register shop with owner (`thiruna2394@gmail.com`)
4. Shop approval workflow
5. Shop owner account creation
6. Shop owner login

### 📦 **Product Management**
7. Add multiple products to shop
8. Product inventory management
9. Product pricing and SKU setup

### 👤 **Customer Management**
10. Customer registration (`thiru.t@gmail.com`)
11. **OTP email verification** ✉️
12. Customer account activation
13. Customer login

### 🛒 **Order Management**
14. Customer browses shops and products
15. Add items to cart
16. Place order with multiple items
17. **Order confirmation emails** ✉️

### 📧 **Shop Owner Workflow**
18. Shop owner receives **new order notification** ✉️
19. Shop owner reviews and accepts order
20. **Order acceptance email** sent to customer ✉️

### 🚚 **Delivery Management**
21. Register delivery partner (`helec60392@jobzyy.com`)
22. Partner approval and activation
23. Assign order to delivery partner
24. **Assignment notification** to partner ✉️

### 📍 **Delivery Tracking**
25. Partner accepts assignment
26. Order pickup confirmation
27. **Pickup notification** to customer ✉️
28. Real-time GPS location tracking
29. Delivery completion
30. **Delivery confirmation** to customer ✉️

### 💰 **Invoice & Payment**
31. **Automatic invoice generation**
32. **Invoice email** with distance & platform fees ✉️
33. Platform earnings calculation
34. Partner payment calculation

## 📧 Email Notifications Flow

| Event | Recipient | Email Type |
|-------|-----------|------------|
| Shop Registration | Shop Owner | Registration Confirmation |
| Shop Approval | Shop Owner | Welcome + Credentials |
| Customer Registration | Customer | OTP Verification |
| Order Placed | Customer | Order Confirmation |
| Order Placed | Shop Owner | New Order Alert |
| Order Accepted | Customer | Acceptance Notification |
| Delivery Assigned | Partner | Assignment Alert |
| Order Picked Up | Customer | Pickup Notification |
| Order Delivered | Customer | Delivery Confirmation |
| Order Delivered | Customer | **Invoice with Details** |

## 🔍 OTP Verification

### Getting OTP from Database:
```sql
SELECT email, otp_code, is_verified, expires_at, created_at
FROM mobile_otp 
WHERE email = 'thiru.t@gmail.com'
ORDER BY created_at DESC;
```

### Alternative OTP Methods:
1. Check email inbox for OTP
2. Use test OTP: `123456`
3. Check application logs
4. Use database query above

## 📊 Invoice Details Included

The final invoice includes:

### 💰 **Financial Breakdown**
- Item costs and quantities
- Subtotal calculation
- Tax (GST) calculation
- Delivery fees
- Discount amounts
- **Total amount**

### 🏢 **Platform Fees**
- Service Fee (2% of subtotal)
- Platform Commission (3% of subtotal)
- Payment Gateway Fee (1.5% for online)
- Delivery Partner Fee (80% of delivery fee)

### 📍 **Delivery Information**
- **Distance covered** (from GPS tracking)
- **Delivery time** (pickup to delivery)
- Delivery partner details
- Vehicle information
- Route tracking data

### 📋 **Order Details**
- Complete item breakdown
- Customer information
- Shop information
- Payment method
- Transaction details

## 🛠️ Troubleshooting

### Server Issues:
```bash
# Check if server is running
netstat -ano | findstr :8082

# View server logs
tail -f application.log

# Restart server
./START_SERVER_FOR_TESTING.sh
```

### Database Issues:
```bash
# Check PostgreSQL connection
psql -h localhost -p 5432 -U postgres -d shop_management_db

# View OTP table
SELECT * FROM mobile_otp ORDER BY created_at DESC LIMIT 10;
```

### Email Issues:
- Check spam/junk folders
- Verify email addresses are correct
- Check application logs for email sending errors
- Ensure SMTP configuration is correct

## 🎯 Expected Results

After running the complete test:

### ✅ **Successful API Calls**
- All 20+ API endpoints tested
- All HTTP responses return 200/201 status
- Data correctly stored in database

### 📧 **Email Deliveries**
- 8+ emails sent to test addresses
- OTP delivered for verification
- Order notifications sent
- Final invoice with complete breakdown

### 💾 **Database Records**
- Users, shops, products created
- Orders and assignments recorded
- GPS tracking data stored
- Payment calculations saved

### 📋 **Business Flow Completed**
- Complete e-commerce transaction
- Real-time delivery tracking
- Automatic invoice generation
- Platform fee calculations

## 🚀 Ready to Test!

Run the complete test suite:
```bash
./COMPLETE_API_TEST_WORKFLOW.sh
```

Monitor progress and check your email inboxes for notifications!