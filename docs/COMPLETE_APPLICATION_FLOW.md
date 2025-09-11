# Complete Application Flow - Multi-Shop Pricing System

## 🌐 Full Stack Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            COMPLETE APPLICATION FLOW                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                               FRONTEND LAYER                                │
│                              (Angular + TypeScript)                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │   Customer  │  │ Shop Owner  │  │   Admin     │  │   Mobile App        ││
│  │   Portal    │  │  Dashboard  │  │   Panel     │  │   (Future)          ││
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────────┘│
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │ HTTP Requests (JSON)
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               API GATEWAY                                   │
│                          (Spring Boot REST API)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────────────────┐ │
│  │ Product        │  │ Shop            │  │ Pricing                      │ │
│  │ Controller     │  │ Controller      │  │ Controller                   │ │
│  └────────────────┘  └─────────────────┘  └──────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │ Method Calls
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SERVICE LAYER                                  │
│                           (Business Logic)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────────────────┐ │
│  │ Product        │  │ Shop            │  │ Pricing                      │ │
│  │ Service        │  │ Service         │  │ Service                      │ │
│  └────────────────┘  └─────────────────┘  └──────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │ JPA Queries
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            REPOSITORY LAYER                                 │
│                              (Data Access)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────────────────┐ │
│  │ MasterProduct  │  │ Shop            │  │ ShopProduct                  │ │
│  │ Repository     │  │ Repository      │  │ Repository                   │ │
│  └────────────────┘  └─────────────────┘  └──────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────────────────┘
                           │ SQL Queries
                           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             DATABASE LAYER                                  │
│                              (PostgreSQL)                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────────────────┐ │
│  │ master_        │  │ shops           │  │ shop_products                │ │
│  │ products       │  │                 │  │ (PRICING TABLE)              │ │
│  │ (NO PRICE)     │  │                 │  │                              │ │
│  └────────────────┘  └─────────────────┘  └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Complete Data Flow - Step by Step

### 1️⃣ **Customer Search Flow**

```
CUSTOMER ACTION: "Search for Rice"
         │
         ▼
┌─────────────────────┐
│  1. FRONTEND        │
│  CustomerComponent  │
│  searchProducts()   │
└─────────┬───────────┘
          │ HTTP GET /api/products/search?q=rice&location=mumbai
          ▼
┌─────────────────────┐
│  2. CONTROLLER      │
│  ProductController  │
│  searchProducts()   │
└─────────┬───────────┘
          │ Call Service
          ▼
┌─────────────────────┐
│  3. SERVICE         │
│  ProductService     │
│  searchProducts()   │
└─────────┬───────────┘
          │ Database Query
          ▼
┌─────────────────────┐
│  4. REPOSITORY      │
│  Custom Query       │
│  JOIN 3 tables      │
└─────────┬───────────┘
          │ SQL Query
          ▼
┌─────────────────────┐
│  5. DATABASE        │
│  Complex JOIN       │
│  Return Results     │
└─────────┬───────────┘
          │ Results
          ▼
┌─────────────────────┐
│  6. RESPONSE        │
│  JSON with prices   │
│  from all shops     │
└─────────────────────┘
```

### 2️⃣ **Shop Owner Adding Product Flow**

```
SHOP OWNER ACTION: "Add Rice to my shop with price ₹280"
         │
         ▼
┌─────────────────────┐
│  1. FRONTEND        │
│  ShopOwnerDashboard │
│  addProduct()       │
└─────────┬───────────┘
          │ HTTP POST /api/shop-products
          │ Body: {masterProductId: 101, price: 280, stock: 100}
          ▼
┌─────────────────────┐
│  2. CONTROLLER      │
│  ShopController     │
│  addProductToShop() │
└─────────┬───────────┘
          │ Validate & Call Service
          ▼
┌─────────────────────┐
│  3. SERVICE         │
│  ShopService        │
│  addProduct()       │
└─────────┬───────────┘
          │ Business Logic & Save
          ▼
┌─────────────────────┐
│  4. REPOSITORY      │
│  ShopProductRepo    │
│  save()             │
└─────────┬───────────┘
          │ INSERT SQL
          ▼
┌─────────────────────┐
│  5. DATABASE        │
│  shop_products      │
│  New Record Created │
└─────────────────────┘
```

## 📱 Frontend Components Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                      ANGULAR FRONTEND                          │
├─────────────────────────────────────────────────────────────────┤

src/app/
├── core/
│   ├── services/
│   │   ├── product.service.ts          // API calls for products
│   │   ├── shop.service.ts             // API calls for shops
│   │   ├── pricing.service.ts          // Price calculations
│   │   └── auth.service.ts             // Authentication
│   ├── models/
│   │   ├── product.model.ts            // Product interfaces
│   │   ├── shop.model.ts               // Shop interfaces
│   │   └── pricing.model.ts            // Pricing interfaces
│   └── guards/
│       └── role.guard.ts               // Route protection
├── features/
│   ├── customer/
│   │   ├── product-search/
│   │   │   ├── product-search.component.ts
│   │   │   ├── product-search.component.html
│   │   │   └── product-list.component.ts
│   │   └── product-detail/
│   │       └── product-detail.component.ts
│   ├── shop-owner/
│   │   ├── dashboard/
│   │   │   ├── shop-owner-dashboard.component.ts
│   │   │   └── dashboard.component.html
│   │   ├── product-management/
│   │   │   ├── add-product.component.ts
│   │   │   ├── edit-product.component.ts
│   │   │   └── product-pricing.component.ts
│   │   └── inventory/
│   │       └── inventory.component.ts
│   └── admin/
│       ├── master-products/
│       │   ├── master-product-list.component.ts
│       │   └── master-product-form.component.ts
│       └── shops/
│           └── shop-management.component.ts
└── shared/
    ├── components/
    │   ├── price-display.component.ts  // Reusable price component
    │   └── product-card.component.ts   // Product card with pricing
    └── pipes/
        └── currency-format.pipe.ts     // Price formatting
```

## 🔧 Backend API Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPRING BOOT BACKEND                         │
├─────────────────────────────────────────────────────────────────┤

src/main/java/com/shopmanagement/
├── controller/
│   ├── ProductController.java          // Product APIs
│   ├── ShopController.java             // Shop APIs
│   ├── PricingController.java          // Pricing APIs
│   └── CustomerController.java         // Customer APIs
├── service/
│   ├── ProductService.java             // Product business logic
│   ├── ShopService.java                // Shop business logic
│   ├── PricingService.java             // Price calculations
│   └── SearchService.java              // Search logic
├── repository/
│   ├── MasterProductRepository.java    // Master products data
│   ├── ShopRepository.java             // Shops data
│   ├── ShopProductRepository.java      // Shop-specific pricing
│   └── PriceVariationRepository.java   // Promotions/discounts
├── entity/
│   ├── MasterProduct.java              // Product entity
│   ├── Shop.java                       // Shop entity
│   ├── ShopProduct.java                // Pricing entity
│   └── PriceVariation.java             // Promotion entity
└── dto/
    ├── ProductSearchResponse.java      // API responses
    ├── ShopProductRequest.java         // API requests
    └── PriceCalculationDto.java        // Price data
```

## 🔍 Key API Endpoints

### Customer APIs
```
GET  /api/products/search?q={query}&location={city}
GET  /api/products/{productId}/shops
GET  /api/shops/{shopId}/products
GET  /api/products/{productId}/price-comparison
```

### Shop Owner APIs
```
POST /api/shop-products                 // Add product to shop
PUT  /api/shop-products/{id}            // Update product price
GET  /api/shops/{shopId}/products       // Get shop's products
POST /api/shops/{shopId}/bulk-upload    // Bulk product upload
```

### Admin APIs
```
POST /api/master-products               // Create master product
PUT  /api/master-products/{id}          // Update master product
GET  /api/master-products               // List all products
GET  /api/analytics/pricing-reports     // Pricing analytics
```

## 📊 Database Query Examples

### 1. Customer Search Query
```sql
-- Get products with prices from all shops in a city
SELECT 
    mp.id as product_id,
    mp.name as product_name,
    mp.brand,
    s.id as shop_id,
    s.name as shop_name,
    s.city,
    sp.price,
    sp.original_price,
    sp.stock_quantity,
    (sp.original_price - sp.price) as discount_amount,
    ROUND(((sp.original_price - sp.price) / sp.original_price * 100), 2) as discount_percent
FROM master_products mp
JOIN shop_products sp ON mp.id = sp.master_product_id
JOIN shops s ON sp.shop_id = s.id
WHERE mp.name LIKE '%rice%'
  AND s.city = 'Mumbai'
  AND sp.is_available = true
  AND sp.status = 'ACTIVE'
ORDER BY sp.price ASC;
```

### 2. Shop Owner Dashboard Query
```sql
-- Get all products for a specific shop with profit margins
SELECT 
    sp.id,
    mp.name as product_name,
    mp.sku,
    sp.price,
    sp.cost_price,
    sp.stock_quantity,
    (sp.price - sp.cost_price) as profit_amount,
    ROUND(((sp.price - sp.cost_price) / sp.cost_price * 100), 2) as profit_margin
FROM shop_products sp
JOIN master_products mp ON sp.master_product_id = mp.id
WHERE sp.shop_id = ?
  AND sp.status = 'ACTIVE'
ORDER BY profit_margin DESC;
```

## 🎯 Complete User Journey Examples

### Journey 1: Customer Finding Best Price

```
1. Customer opens app/website
   └─> Frontend: CustomerComponent loads

2. Types "Basmati Rice" in search
   └─> Frontend: productService.searchProducts('Basmati Rice')
   └─> API Call: GET /api/products/search?q=basmati+rice

3. Backend processes search
   └─> ProductController.searchProducts()
   └─> ProductService.searchProducts()
   └─> Database: Complex JOIN query across 3 tables

4. Returns results with prices from all shops
   └─> JSON Response with pricing comparison

5. Customer sees:
   ┌─────────────────────────────────────────┐
   │ Basmati Rice 5kg                        │
   │                                         │
   │ 🏪 Super Mart      ₹320  (Save ₹30)   │
   │ 🏪 Budget Bazaar   ₹280  (Save ₹70)   │ ← Customer picks this
   │ 🏪 Wholesale Hub   ₹260  (Min 10)     │
   └─────────────────────────────────────────┘

6. Clicks "Add to Cart" for Budget Bazaar
   └─> Frontend: cartService.addItem(shopId: 2, productId: 101)
   └─> API Call: POST /api/cart/add
```

### Journey 2: Shop Owner Setting Prices

```
1. Shop Owner logs in
   └─> Frontend: ShopOwnerDashboardComponent

2. Navigates to "Add Product"
   └─> Frontend: AddProductComponent

3. Searches master catalog for "Rice"
   └─> API Call: GET /api/master-products/search?q=rice

4. Selects "Basmati Rice 5kg" (ID: 101)
   └─> Frontend: Shows pricing form

5. Sets price: ₹285, Stock: 100
   └─> Frontend: Validates inputs

6. Submits form
   └─> API Call: POST /api/shop-products
   └─> Body: {
       "masterProductId": 101,
       "price": 285.00,
       "originalPrice": 350.00,
       "stockQuantity": 100
   }

7. Backend processes
   └─> ShopController.addProductToShop()
   └─> Validates shop ownership
   └─> Checks for duplicates
   └─> ShopService.addProduct()
   └─> Database: INSERT into shop_products

8. Success response
   └─> Frontend: Shows success message
   └─> Redirects to product list
```

## 🚀 Performance Optimizations

### Frontend Optimizations
```typescript
// Lazy loading modules
const routes: Routes = [
  {
    path: 'customer',
    loadChildren: () => import('./features/customer/customer.module').then(m => m.CustomerModule)
  },
  {
    path: 'shop-owner',
    loadChildren: () => import('./features/shop-owner/shop-owner.module').then(m => m.ShopOwnerModule)
  }
];

// Caching product data
@Injectable()
export class ProductService {
  private cache = new Map<string, any>();
  
  searchProducts(query: string): Observable<Product[]> {
    if (this.cache.has(query)) {
      return of(this.cache.get(query));
    }
    
    return this.http.get<Product[]>(`/api/products/search?q=${query}`)
      .pipe(
        tap(results => this.cache.set(query, results))
      );
  }
}
```

### Backend Optimizations
```java
// Database indexes
@Entity
@Table(name = "shop_products",
       indexes = {
           @Index(name = "idx_shop_product", columnList = "shop_id, master_product_id"),
           @Index(name = "idx_available", columnList = "is_available, status"),
           @Index(name = "idx_price", columnList = "price")
       })
public class ShopProduct { }

// Query optimization with projections
@Query("""
    SELECT new com.shopmanagement.dto.ProductSearchResult(
        mp.id, mp.name, s.id, s.name, sp.price, sp.originalPrice
    )
    FROM MasterProduct mp
    JOIN mp.shopProducts sp
    JOIN sp.shop s
    WHERE mp.name LIKE %:query%
      AND s.city = :city
      AND sp.isAvailable = true
""")
List<ProductSearchResult> searchProductsOptimized(@Param("query") String query, @Param("city") String city);
```

## 📈 Real-Time Features

### WebSocket for Live Price Updates
```typescript
// Frontend WebSocket service
@Injectable()
export class PriceUpdateService {
  private socket = io('ws://localhost:8080');
  
  subscribeToShopUpdates(shopId: number): Observable<PriceUpdate> {
    return new Observable(observer => {
      this.socket.on(`shop_${shopId}_updates`, (data: PriceUpdate) => {
        observer.next(data);
      });
    });
  }
}
```

```java
// Backend WebSocket controller
@Controller
public class PriceUpdateController {
  
  @MessageMapping("/price-update")
  @SendTo("/topic/shop/{shopId}")
  public PriceUpdateMessage updatePrice(@DestinationVariable Long shopId, PriceUpdate update) {
    // Update price in database
    // Broadcast to all connected clients
    return new PriceUpdateMessage(update);
  }
}
```

This complete flow shows how the multi-shop pricing system works across the entire application stack, from user interaction to database storage!