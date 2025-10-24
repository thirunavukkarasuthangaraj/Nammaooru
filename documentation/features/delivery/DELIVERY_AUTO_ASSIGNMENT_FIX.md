# 🚨 Delivery Auto-Assignment Not Working - Diagnostic & Fix Guide

## Problem
Delivery partners are not being auto-assigned to orders when orders reach `READY_FOR_PICKUP` status.

---

## 🔍 Root Cause Analysis

### Auto-Assignment Trigger Location
**File**: `backend/src/main/java/com/shopmanagement/service/OrderService.java`
**Line**: 316

```java
// This is called when order status changes to READY_FOR_PICKUP
orderAssignmentService.autoAssignOrder(orderId, assignedBy);
```

### Auto-Assignment Logic
**File**: `backend/src/main/java/com/shopmanagement/service/OrderAssignmentService.java`
**Lines**: 52-164

```java
public OrderAssignment autoAssignOrder(Long orderId, String assignedBy) {
    // Lines 69-74: Find available delivery partners
    List<User> availablePartners = userRepository.findByRoleAndIsActiveAndIsAvailableAndIsOnline(
        User.UserRole.DELIVERY_PARTNER, true, true, true);

    if (availablePartners.isEmpty()) {
        throw new RuntimeException("No available delivery partners found");
    }

    // Lines 77-79: Select best partner using fair distribution
    User selectedPartner = selectBestAvailablePartner(availablePartners);
}
```

---

## 🐛 Possible Issues

### Issue 1: No Delivery Partners Meet All Criteria ⚠️
**Problem**: Auto-assignment requires delivery partners to have ALL of these:
- `isActive = true`
- `isAvailable = true`
- `isOnline = true`
- `role = DELIVERY_PARTNER`

**Solution**: Check database and update delivery partners

### Issue 2: Delivery Partners Not Logging In 📱
**Problem**: Partners need to open the app and login to be marked as online

**Solution**: Ensure delivery partners:
1. Install delivery partner app
2. Login successfully
3. App marks them as online automatically

### Issue 3: FCM Tokens Not Registered 🔔
**Problem**: Even if assigned, partners won't get notifications without FCM tokens

**Solution**: Verify FCM token registration in delivery partner app

### Issue 4: Partners Not Marking Themselves as Available
**Problem**: Partners may be online but have availability toggle OFF

**Solution**: Add UI toggle in delivery partner app for availability

---

## 🔧 Diagnostic Steps

### Step 1: Check Backend Logs
Look for this error when marking order as READY:
```
ERROR: No available delivery partners found
```

### Step 2: Check Delivery Partners via API

#### Login as Admin
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```

#### Get All Delivery Partners
```bash
ADMIN_TOKEN="<token_from_step1>"

curl -X GET http://localhost:8080/api/admin/delivery-partners \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Look for**:
```json
{
  "id": 123,
  "email": "partner@example.com",
  "role": "DELIVERY_PARTNER",
  "isActive": true,    // ✅ Must be true
  "isAvailable": false, // ❌ This causes the issue!
  "isOnline": false,   // ❌ This causes the issue!
  "fcmToken": null     // ❌ Won't receive notifications!
}
```

### Step 3: Check Database Directly (If psql available)
```sql
SELECT
    id,
    email,
    role,
    is_active,
    is_available,
    is_online,
    fcm_token
FROM users
WHERE role = 'DELIVERY_PARTNER';
```

---

## ✅ Solutions

### Solution 1: Manually Update Delivery Partner Status (Quick Fix)

Create this API endpoint in backend:

**File**: `backend/src/main/java/com/shopmanagement/controller/DeliveryPartnerController.java`

Add new endpoint:
```java
@PostMapping("/partners/{partnerId}/set-available")
@PreAuthorize("hasRole('SUPER_ADMIN') or hasRole('ADMIN')")
public ResponseEntity<ApiResponse<User>> setPartnerAvailable(
    @PathVariable Long partnerId,
    @RequestParam boolean available,
    @RequestParam boolean online
) {
    User partner = userRepository.findById(partnerId)
        .orElseThrow(() -> new RuntimeException("Partner not found"));

    if (partner.getRole() != User.UserRole.DELIVERY_PARTNER) {
        return ResponseUtil.error("User is not a delivery partner");
    }

    partner.setIsAvailable(available);
    partner.setIsOnline(online);
    partner.setIsActive(true);

    User updated = userRepository.save(partner);

    return ResponseUtil.success(updated, "Partner status updated");
}
```

**Usage**:
```bash
curl -X POST "http://localhost:8080/api/delivery-partners/partners/123/set-available?available=true&online=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Solution 2: Update Delivery Partner App to Auto-Set Online Status

**File**: `mobile/nammaooru_delivery_partner/lib/features/auth/providers/auth_provider.dart`

Add after successful login:
```dart
// After login success
await _apiService.updateStatus(
  isOnline: true,
  isAvailable: true,
);
```

### Solution 3: Add Availability Toggle in Delivery Partner App

**File**: `mobile/nammaooru_delivery_partner/lib/features/dashboard/screens/dashboard_screen.dart`

Add toggle switch:
```dart
SwitchListTile(
  title: const Text('Available for Orders'),
  subtitle: const Text('Turn on to receive new order assignments'),
  value: _isAvailable,
  onChanged: (bool value) async {
    setState(() => _isAvailable = value);
    await ApiService.updateAvailability(value);
  },
  activeColor: Colors.green,
)
```

### Solution 4: Create Data Fix Script

**File**: `fix_delivery_partners_availability.sql`

```sql
-- Fix all existing delivery partners to be available
UPDATE users
SET
    is_active = true,
    is_available = true,
    is_online = true
WHERE role = 'DELIVERY_PARTNER'
  AND is_active = true;

-- Verify the update
SELECT
    id,
    email,
    is_active,
    is_available,
    is_online
FROM users
WHERE role = 'DELIVERY_PARTNER';
```

### Solution 5: Create Test Delivery Partner

**Create via API**:
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testdelivery@example.com",
    "password": "Test@123",
    "firstName": "Test",
    "lastName": "Driver",
    "phone": "9999999999",
    "role": "DELIVERY_PARTNER"
  }'
```

**Then set as available**:
```bash
curl -X POST "http://localhost:8080/api/delivery-partners/partners/<partner_id>/set-available?available=true&online=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## 🧪 Testing Auto-Assignment

### Complete Test Flow

#### 1. Ensure Delivery Partner is Available
```bash
# Get partner ID
curl -X GET http://localhost:8080/api/admin/delivery-partners \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Set partner as available and online
curl -X POST "http://localhost:8080/api/delivery-partners/partners/5/set-available?available=true&online=true" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

#### 2. Create Order
```bash
CUSTOMER_TOKEN="<customer_token>"

curl -X POST http://localhost:8080/api/customer/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN" \
  -d '{
    "shopId": 4,
    "deliveryType": "HOME_DELIVERY",
    "items": [{"shopProductId": 8, "quantity": 2, "price": 134}],
    "deliveryAddress": "Test Address",
    "deliveryCity": "Chennai",
    "deliveryState": "Tamil Nadu",
    "deliveryPostalCode": "635601",
    "deliveryPhone": "9876543210",
    "deliveryContactName": "Test Customer",
    "subtotal": 268,
    "deliveryFee": 50,
    "total": 318,
    "paymentMethod": "CASH_ON_DELIVERY"
  }'
```

#### 3. Shop Owner Accepts and Prepares
```bash
SHOP_TOKEN="<shop_owner_token>"
ORDER_ID="<order_id_from_step2>"

# Accept
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/accept" \
  -H "Authorization: Bearer $SHOP_TOKEN" \
  -d '{}'

# Start preparing
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/prepare" \
  -H "Authorization: Bearer $SHOP_TOKEN"

# Mark as ready - THIS TRIGGERS AUTO-ASSIGNMENT
curl -X POST "http://localhost:8080/api/orders/$ORDER_ID/ready" \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

#### 4. Check if Partner was Assigned
```bash
curl -X GET "http://localhost:8080/api/orders/$ORDER_ID" \
  -H "Authorization: Bearer $SHOP_TOKEN"
```

**Expected Response**:
```json
{
  "orderId": 16,
  "status": "READY_FOR_PICKUP",
  "assignedToDeliveryPartner": true,    // ✅ Should be true
  "deliveryPartnerId": 5,               // ✅ Should have partner ID
  "deliveryPartnerName": "Test Driver"  // ✅ Should have partner name
}
```

---

## 📊 Auto-Assignment Status Indicators

### ✅ Working Correctly
- Backend logs: `Selected delivery partner: testdelivery@example.com (ID: 5) from 1 available partners`
- Order has `assignedToDeliveryPartner: true`
- Delivery partner receives FCM notification
- Partner sees order in their "Available Orders" screen

### ❌ Not Working - No Partners Available
- Backend logs: `ERROR: No available delivery partners found`
- Order remains unassigned
- Shop owner sees no "Verify Pickup OTP" button

### ❌ Not Working - Assignment Fails
- Backend logs: Error during assignment process
- Check for database connection issues
- Check for FCM token issues

---

## 🎯 Recommended Immediate Action

**For testing RIGHT NOW**:

1. **Run this curl command to check current partners**:
```bash
curl -X GET http://localhost:8080/api/admin/delivery-partners \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0aGlydW5hY3NlNzVAZ21haWwuY29tIiwiZXhwIjoxNzU5NTkxNzI3LCJpYXQiOjE3NTk1MDUzMjd9.zF9bQ3nY7J5K4L3mN2pO1qR8sT6uV7wX9yA0bC1dE2f"
```

2. **If no partners found, create one**:
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "quickdriver@test.com",
    "password": "Test@123",
    "firstName": "Quick",
    "lastName": "Driver",
    "phone": "9999988888",
    "role": "DELIVERY_PARTNER"
  }'
```

3. **Create the endpoint to manually set availability** (add to DeliveryPartnerController.java)

4. **Test complete order flow** with home delivery type

---

## 📝 Long-Term Fixes

1. **Add auto-online on login** in delivery partner app
2. **Add availability toggle** in delivery partner app dashboard
3. **Add fallback to manual assignment** if auto-assignment fails
4. **Add admin UI** to view/manage delivery partner status
5. **Add notification** to shop owner when no partners available
6. **Add retry logic** for auto-assignment after 5 minutes

---

## 🔗 Related Files

- `backend/src/main/java/com/shopmanagement/service/OrderAssignmentService.java` (lines 52-164)
- `backend/src/main/java/com/shopmanagement/service/OrderService.java` (line 316)
- `backend/src/main/java/com/shopmanagement/controller/DeliveryPartnerController.java`
- `mobile/nammaooru_delivery_partner/lib/features/auth/providers/auth_provider.dart`
- `mobile/nammaooru_delivery_partner/lib/features/dashboard/screens/dashboard_screen.dart`
