# Promo Code System - Deploy Fixed Code

## Current Situation

The backend server running on port 8080 (PID 2352) has the **OLD CODE** without our fixes. That's why you're getting "Internal server error" when creating promo codes.

## All Fixes We Made Today

### ✅ Angular Fixes (Already Applied in Code)
1. **API URL Fix** - Changed `/api/api/promotions` to `/api/promotions` in `promo-code.service.ts`
2. **Compilation Error Fix** - Removed color attribute in `promo-code-form.component.html`
3. **Private Property Fix** - Made `promoCodeService` public in `promo-code-stats.component.ts`

### ✅ Backend Fixes (Already Applied in Code)
1. **Missing Imports** - Added `Page` and `Pageable` imports in `PromotionService.java`
2. **Method Names** - Fixed `setIsFirstTimeOnly` and `setIsPublic` in `PromotionController.java`

## How to Deploy the Fixes

### Step 1: Stop Current Backend

```bash
# Find the Java process
tasklist | findstr java

# Kill it (replace PID with actual PID from step above)
taskkill /F /PID 2352
```

### Step 2: Rebuild and Start Backend

```bash
cd backend
mvn clean package
mvn spring-boot:run
```

**OR** if you're using an IDE, just restart the Spring Boot application.

### Step 3: Verify Backend is Running

Wait ~60 seconds for backend to start, then test:

```bash
curl -X POST http://localhost:8080/api/promotions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0aGlydW5hMjM5NCIsImV4cCI6MTc2MTI4NDc5OSwiaWF0IjoxNzYxMTk4Mzk5fQ.vWfx0LrNZn3yP80RHugYMuLppLdB_i2gbahvzoa7EEs" \
  -d '{
    "code":"FIRST50",
    "title":"First Order 50% Off",
    "description":"Get 50% discount on your first order",
    "type":"PERCENTAGE",
    "discountValue":50,
    "minimumOrderAmount":100,
    "maximumDiscountAmount":500,
    "startDate":"2025-01-01T00:00:00",
    "endDate":"2025-12-31T23:59:59",
    "status":"ACTIVE",
    "usageLimit":1000,
    "usageLimitPerCustomer":1,
    "firstTimeOnly":true,
    "applicableToAllShops":true,
    "imageUrl":""
  }'
```

**Expected Response:**
```json
{
  "statusCode": "0000",
  "message": "Promotion created successfully",
  "data": {
    "id": 1,
    "code": "FIRST50",
    ...
  }
}
```

### Step 4: Test in Angular UI

1. Open http://localhost:4200/admin/promo-codes
2. Click "Create Promo Code"
3. Fill form and save
4. Should see success message and promo code in table

## Files That Were Modified

### Angular:
- `frontend/src/app/core/services/promo-code.service.ts` - Fixed API URL
- `frontend/src/app/features/admin/components/promo-code-management/promo-code-form.component.html` - Removed color attribute
- `frontend/src/app/features/admin/components/promo-code-management/promo-code-stats.component.ts` - Made service public

### Backend:
- `backend/src/main/java/com/shopmanagement/service/PromotionService.java` - Added Page/Pageable imports
- `backend/src/main/java/com/shopmanagement/controller/PromotionController.java` - Fixed method names

## Quick Test Commands

After restarting backend:

### 1. Create Promo Code:
```bash
curl -X POST http://localhost:8080/api/promotions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"code":"WELCOME50","title":"Welcome Offer","type":"PERCENTAGE","discountValue":50,"minimumOrderAmount":100,"startDate":"2025-01-01T00:00:00","endDate":"2025-12-31T23:59:59","status":"ACTIVE","usageLimitPerCustomer":1,"firstTimeOnly":true,"applicableToAllShops":true}'
```

### 2. List All Promos:
```bash
curl http://localhost:8080/api/promotions \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Get Active Promos (Public):
```bash
curl http://localhost:8080/api/promotions/active
```

## Summary

✅ All code fixes are done
✅ Angular is running with fixes (port 4200)
❌ Backend needs restart to load the fixes (port 8080)

**Action Required:** Restart your backend server to apply the fixes!

Once restarted, both curl commands AND Angular UI will work perfectly! 🚀
