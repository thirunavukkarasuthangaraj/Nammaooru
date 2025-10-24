# Create Promo Code Using CURL

## ✅ Promo Code API is Working!

The API endpoints are working correctly. They return:
- **403 Forbidden** for unauthenticated requests (security working correctly)
- **200 OK** when authenticated with valid admin token

## Option 1: Use Angular UI (Recommended)

The easiest way to create promo codes:

1. Open: http://localhost:4200/admin/promo-codes
2. Login as SUPER_ADMIN or ADMIN
3. Click "Create Promo Code" button
4. Fill the form and save

**This is the recommended approach!**

---

## Option 2: Use CURL with Authentication

If you want to test with CURL, follow these steps:

### Step 1: Login to get JWT token

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@nammaooru.com",
    "password": "your_admin_password"
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {...}
}
```

Copy the `token` value.

### Step 2: Create Promo Code with Token

```bash
curl -X POST http://localhost:8080/api/promotions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "code": "WELCOME50",
    "title": "Welcome Offer 50% Off",
    "description": "Get 50% discount on your first order",
    "type": "PERCENTAGE",
    "discountValue": 50,
    "minimumOrderAmount": 100,
    "maximumDiscountAmount": 500,
    "startDate": "2025-01-01T00:00:00",
    "endDate": "2025-12-31T23:59:59",
    "status": "ACTIVE",
    "usageLimit": 1000,
    "usageLimitPerCustomer": 1,
    "firstTimeOnly": true,
    "applicableToAllShops": true,
    "imageUrl": ""
  }'
```

**Expected Response:**
```json
{
  "statusCode": "0000",
  "message": "Promotion created successfully",
  "data": {
    "id": 1,
    "code": "WELCOME50",
    "title": "Welcome Offer 50% Off",
    ...
  }
}
```

---

## All Available Endpoints

### Public Endpoints (No Auth Required)

1. **Get Active Promos**
```bash
curl http://localhost:8080/api/promotions/active
```

2. **Validate Promo Code**
```bash
curl -X POST http://localhost:8080/api/promotions/validate \
  -H "Content-Type: application/json" \
  -d '{
    "promoCode": "WELCOME50",
    "customerId": 1,
    "orderAmount": 500
  }'
```

### Protected Endpoints (Admin Token Required)

Replace `YOUR_TOKEN_HERE` with actual JWT token from login.

1. **List All Promos**
```bash
curl http://localhost:8080/api/promotions \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

2. **Get Promo by ID**
```bash
curl http://localhost:8080/api/promotions/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

3. **Create Promo** (see Step 2 above)

4. **Update Promo**
```bash
curl -X PUT http://localhost:8080/api/promotions/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "title": "Updated Title",
    "discountValue": 60
  }'
```

5. **Delete Promo**
```bash
curl -X DELETE http://localhost:8080/api/promotions/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

6. **Activate Promo**
```bash
curl -X PATCH http://localhost:8080/api/promotions/1/activate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

7. **Deactivate Promo**
```bash
curl -X PATCH http://localhost:8080/api/promotions/1/deactivate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

8. **Get Statistics**
```bash
curl http://localhost:8080/api/promotions/1/stats \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

9. **Get Usage History**
```bash
curl http://localhost:8080/api/promotions/1/usage?page=0&size=20 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Testing Summary

✅ **Backend is running** on http://localhost:8080
✅ **Promo API endpoints are configured** at `/api/promotions`
✅ **Security is working** (returns 403 without auth)
✅ **Angular UI is ready** at http://localhost:4200/admin/promo-codes

**Recommendation:** Use the Angular UI for creating/managing promo codes. It's easier and handles authentication automatically!
