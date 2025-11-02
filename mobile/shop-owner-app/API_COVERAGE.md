# API Coverage - Flutter Shop Owner App vs Angular Frontend

## Legend
- ✅ Implemented in Flutter
- ❌ Not Implemented
- ⚠️ Partially Implemented

---

## Product Service (`product.service.ts`)

### Master Products
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/products/master` | GET | ✅ | ✅ | Get master products with filters |
| `/products/master/{id}` | GET | ✅ | ❌ | Get single master product |
| `/products/master/sku/{sku}` | GET | ✅ | ❌ | Get product by SKU |
| `/products/master` | POST | ✅ | ✅ | Create master product |
| `/products/master/{id}` | PUT | ✅ | ❌ | Update master product |
| `/products/master/{id}` | DELETE | ✅ | ❌ | Delete master product |
| `/products/master/search` | GET | ✅ | ❌ | Search master products |
| `/products/master/featured` | GET | ✅ | ❌ | Get featured products |
| `/products/master/category/{id}` | GET | ✅ | ❌ | Get products by category |
| `/products/master/brands` | GET | ✅ | ❌ | Get all brands |

### Product Images
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/products/images/master/{id}` | POST | ✅ | ❌ | Upload master product images |
| `/products/images/master/{id}` | GET | ✅ | ❌ | Get master product images |
| `/products/images/{imageId}` | DELETE | ✅ | ❌ | Delete product image |
| `/products/images/shop/{shopId}/{productId}` | GET | ✅ | ❌ | Get shop product images |
| `/products/images/shop/{shopId}/{productId}` | POST | ✅ | ❌ | Upload shop product images |

---

## Shop Product Service (`shop-product.service.ts`)

### Shop Products
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/shops/{shopId}/products` | GET | ✅ | ✅ | Get shop products (paginated) |
| `/shops/{shopId}/products/{productId}` | GET | ✅ | ❌ | Get single shop product |
| `/shops/{shopId}/products` | POST | ✅ | ⚠️ | Add product to shop (via `/shop-products/create`) |
| `/shops/{shopId}/products/{productId}` | PUT | ✅ | ❌ | Update shop product |
| `/shops/{shopId}/products/{productId}` | DELETE | ✅ | ❌ | Remove product from shop |
| `/shops/{shopId}/products/search` | GET | ✅ | ❌ | Search shop products |
| `/shops/{shopId}/products/featured` | GET | ✅ | ❌ | Get featured shop products |
| `/shops/{shopId}/products/low-stock` | GET | ✅ | ❌ | Get low stock products |
| `/shops/{shopId}/products/{productId}/inventory` | PATCH | ✅ | ❌ | Update inventory |
| `/shops/{shopId}/products/stats` | GET | ✅ | ❌ | Get product stats |
| `/shops/bulk-upload` | POST | ✅ | ❌ | Bulk upload products |

### Alternative Endpoint (Shop Owner Context)
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/shop-products/my-products` | GET | ❌ | ✅ | Get current shop owner's products |
| `/shop-products/create` | POST | ❌ | ✅ | Create shop product (shop owner context) |

---

## Order Service (`order.service.ts`)

### Orders
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/orders` | GET | ✅ | ❌ | Get all orders (admin) |
| `/orders/{id}` | GET | ✅ | ❌ | Get order by ID |
| `/orders/number/{orderNumber}` | GET | ✅ | ❌ | Get order by number |
| `/orders/{id}/status` | PUT | ✅ | ✅ | Update order status |
| `/orders/{id}/cancel` | PUT | ✅ | ❌ | Cancel order |
| `/orders/shop/{shopId}` | GET | ✅ | ✅ | Get orders by shop |
| `/orders/customer/{customerId}` | GET | ✅ | ❌ | Get orders by customer |
| `/orders/status/{status}` | GET | ✅ | ❌ | Get orders by status |
| `/orders/search` | GET | ✅ | ❌ | Search orders |
| `/orders/statuses` | GET | ✅ | ❌ | Get order statuses |
| `/orders/{id}/delivery-info` | GET | ✅ | ❌ | Get delivery info |
| `/orders/{id}/accept` | POST | ✅ | ❌ | Accept order |

### Alternative Endpoint (Shop Owner Context)
| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/shops/{shopId}/orders` | GET | ❌ | ✅ | Get shop orders with shop context |

---

## Category Service

| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/products/categories` | GET | ✅ | ✅ | Get categories (paginated) |
| `/products/categories/tree` | GET | ✅ | ❌ | Get category tree |
| `/products/categories/{id}` | GET | ✅ | ❌ | Get category by ID |
| `/products/categories` | POST | ✅ | ❌ | Create category |
| `/products/categories/{id}` | PUT | ✅ | ❌ | Update category |
| `/products/categories/{id}` | DELETE | ✅ | ❌ | Delete category |

---

## Shop Service

| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/shops/my-shop` | GET | ❌ | ✅ | Get current shop owner's shop |
| `/shops/{shopId}` | GET | ✅ | ❌ | Get shop by ID |
| `/shops` | POST | ✅ | ❌ | Create shop |
| `/shops/{shopId}` | PUT | ✅ | ❌ | Update shop |

---

## Dashboard Service

| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/dashboard/stats` | GET | ✅ | ✅ | Get dashboard statistics |

---

## Authentication Service

| Endpoint | Method | Angular | Flutter | Notes |
|----------|--------|---------|---------|-------|
| `/auth/login` | POST | ✅ | ✅ | Login |
| `/auth/logout` | POST | ✅ | ❌ | Logout |
| `/auth/refresh` | POST | ✅ | ❌ | Refresh token |
| `/auth/register` | POST | ✅ | ❌ | Register |

---

## Summary

### Total API Endpoints by Category:

**Product APIs:**
- Angular: 15 endpoints
- Flutter: 3 endpoints (✅ 3, ❌ 12)
- Coverage: 20%

**Shop Product APIs:**
- Angular: 11 endpoints
- Flutter: 2 endpoints (✅ 2, ❌ 9)
- Coverage: 18%

**Order APIs:**
- Angular: 12 endpoints
- Flutter: 3 endpoints (✅ 3, ❌ 9)
- Coverage: 25%

**Category APIs:**
- Angular: 6 endpoints
- Flutter: 1 endpoint (✅ 1, ❌ 5)
- Coverage: 17%

**Overall Coverage:**
- Total Angular Endpoints: ~44
- Total Flutter Endpoints: ~9
- Overall Coverage: ~20%

---

## Critical Missing APIs for Shop Owner App:

### High Priority (Core Functionality):
1. ✅ `/products/master` - GET (Browse catalog) - **IMPLEMENTED**
2. ✅ `/shop-products/create` - POST (Add to shop) - **IMPLEMENTED**
3. ✅ `/shop-products/my-products` - GET (View shop products) - **IMPLEMENTED**
4. ❌ `/shops/{shopId}/products/{productId}` - PUT (Update product)
5. ❌ `/shops/{shopId}/products/{productId}` - DELETE (Remove product)
6. ❌ `/shops/{shopId}/products/low-stock` - GET (Low stock alerts)
7. ❌ `/shops/{shopId}/products/{productId}/inventory` - PATCH (Update stock)

### Medium Priority (Enhanced Features):
8. ❌ `/products/master/search` - GET (Better search)
9. ❌ `/products/master/category/{id}` - GET (Category filtering)
10. ❌ `/orders/{id}` - GET (Order details)
11. ❌ `/orders/{id}/accept` - POST (Accept order)
12. ❌ `/orders/{id}/cancel` - PUT (Cancel order)

### Low Priority (Nice to Have):
13. ❌ `/products/images/*` - Image management
14. ❌ `/products/master/{id}` - Single product view
15. ❌ `/shops/{shopId}/products/stats` - Product statistics

---

## Recommendations:

1. **Immediate Actions:**
   - ✅ Implement core product management (browse, add, create)
   - ❌ Add product update/delete functionality
   - ❌ Add inventory management (stock updates)

2. **Next Phase:**
   - Add order management (accept, cancel, details)
   - Add low stock alerts
   - Add product search and filtering

3. **Future Enhancements:**
   - Image upload/management
   - Bulk operations
   - Advanced analytics
