# Product Pricing System Design

## 🎯 Design Goals
1. **Multi-Shop Independence**: Each shop sets its own prices
2. **Price Flexibility**: Support multiple pricing strategies
3. **Performance**: Fast price lookups for thousands of products
4. **Maintainability**: Clear separation of concerns

## 📊 Database Design Pattern

### Core Design Principles
```
┌─────────────────────────────────────────────────────────┐
│                    SEPARATION OF CONCERNS                │
├─────────────────────────────────────────────────────────┤
│  MASTER CATALOG (What)  │  SHOP SPECIFICS (How Much)    │
├─────────────────────────────────────────────────────────┤
│  • Product Definition    │  • Pricing                    │
│  • SKU/Barcode          │  • Inventory                  │
│  • Category             │  • Discounts                  │
│  • Specifications       │  • Custom Names               │
└─────────────────────────────────────────────────────────┘
```

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                         │
│                    (Web/Mobile Applications)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                          API LAYER                           │
│                    ProductController                         │
│                    PricingController                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                       SERVICE LAYER                          │
│  ┌─────────────────────────┐  ┌──────────────────────────┐ │
│  │   ProductService        │  │   PricingService         │ │
│  │   - getMasterProducts() │  │   - calculatePrice()     │ │
│  │   - getShopProducts()   │  │   - applyDiscounts()     │ │
│  └─────────────────────────┘  └──────────────────────────┘ │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                      REPOSITORY LAYER                        │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │MasterProduct │  │ShopProduct   │  │PriceVariation  │   │
│  │Repository    │  │Repository    │  │Repository       │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                       DATABASE LAYER                         │
│                         PostgreSQL                           │
└──────────────────────────────────────────────────────────────┘
```

## 🗄️ Database Schema Design

### Entity Relationship Diagram
```
┌─────────────────────┐
│   MASTER_PRODUCTS   │
├─────────────────────┤
│ PK: id              │
│ name                │
│ sku (unique)        │
│ category_id ────────┼────┐
│ brand               │    │
│ specifications      │    │
└──────────┬──────────┘    │
           │                │
           │ 1:N            │
           │                │
           ▼                ▼
┌─────────────────────┐  ┌──────────────────┐
│   SHOP_PRODUCTS     │  │ PRODUCT_CATEGORY │
├─────────────────────┤  ├──────────────────┤
│ PK: id              │  │ PK: id           │
│ FK: shop_id         │  │ name             │
│ FK: master_product  │  │ parent_id        │
│ price ◄─────────────┼─┐│ slug             │
│ original_price      │ ││ icon             │
│ cost_price          │ │└──────────────────┘
│ stock_quantity      │ │
│ custom_name         │ │ PRICING LOGIC
└──────────┬──────────┘ │
           │             │
           │ 1:N         │
           │             │
           ▼             │
┌─────────────────────┐ │
│  PRICE_VARIATIONS   │ │
├─────────────────────┤ │
│ PK: id              │ │
│ FK: shop_product_id │─┘
│ special_price       │
│ start_date          │
│ end_date            │
│ variation_type      │
└─────────────────────┘
```

## 💰 Pricing Logic Flow

### Price Calculation Algorithm
```
START
  │
  ▼
┌─────────────────────┐
│ Get Base Price from │
│   shop_products     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Check Active        │
│ Promotions?         │
└──────────┬──────────┘
           │
      ┌────┴────┐
      │   YES   │ NO
      ▼         │
┌──────────┐    │
│ Apply    │    │
│ Promo    │    │
│ Price    │    │
└────┬─────┘    │
     │          │
     └────┬─────┘
          │
          ▼
┌─────────────────────┐
│ Check Bulk          │
│ Quantity?           │
└──────────┬──────────┘
           │
      ┌────┴────┐
      │   YES   │ NO
      ▼         │
┌──────────┐    │
│ Apply    │    │
│ Bulk     │    │
│ Price    │    │
└────┬─────┘    │
     │          │
     └────┬─────┘
          │
          ▼
┌─────────────────────┐
│ Check Customer      │
│ Group?              │
└──────────┬──────────┘
           │
      ┌────┴────┐
      │   YES   │ NO
      ▼         │
┌──────────┐    │
│ Apply    │    │
│ Group    │    │
│ Price    │    │
└────┬─────┘    │
     │          │
     └────┬─────┘
          │
          ▼
    RETURN FINAL PRICE
```

## 🔧 Implementation Details

### 1. Master Product Entity
```java
@Entity
@Table(name = "master_products")
public class MasterProduct {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private String sku;  // Unique identifier
    
    @ManyToOne
    private ProductCategory category;
    
    // No price field - intentional design
}
```

### 2. Shop Product Entity (With Pricing)
```java
@Entity
@Table(name = "shop_products")
public class ShopProduct {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne
    @JoinColumn(name = "shop_id")
    private Shop shop;
    
    @ManyToOne
    @JoinColumn(name = "master_product_id")
    private MasterProduct masterProduct;
    
    // PRICING FIELDS
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;           // Current selling price
    
    @Column(precision = 10, scale = 2)
    private BigDecimal originalPrice;   // For showing discounts
    
    @Column(precision = 10, scale = 2)
    private BigDecimal costPrice;        // Shop's purchase cost
    
    // Shop can override product details
    private String customName;
    private String customDescription;
}
```

### 3. Price Calculation Service
```java
@Service
public class PricingService {
    
    public BigDecimal calculateFinalPrice(Long shopProductId, 
                                         Integer quantity, 
                                         String customerGroup) {
        // 1. Get base price
        ShopProduct product = shopProductRepository.findById(shopProductId);
        BigDecimal finalPrice = product.getPrice();
        
        // 2. Check for active promotions
        Optional<PriceVariation> activePromo = priceVariationRepository
            .findActivePromotion(shopProductId, LocalDateTime.now());
        
        if (activePromo.isPresent()) {
            finalPrice = activePromo.get().getSpecialPrice();
        }
        
        // 3. Apply bulk pricing if applicable
        if (quantity > 1) {
            Optional<BulkPricing> bulkPrice = bulkPricingRepository
                .findByQuantity(shopProductId, quantity);
            
            if (bulkPrice.isPresent()) {
                finalPrice = bulkPrice.get().getPricePerUnit();
            }
        }
        
        // 4. Apply customer group discount
        if (customerGroup != null) {
            Optional<CustomerGroupPricing> groupPrice = 
                customerGroupPricingRepository
                    .findByGroup(shopProductId, customerGroup);
            
            if (groupPrice.isPresent()) {
                finalPrice = groupPrice.get().getSpecialPrice();
            }
        }
        
        return finalPrice;
    }
}
```

## 📈 Use Cases & Examples

### Use Case 1: Different Shops, Different Prices
```sql
-- Master Product: "Basmati Rice 5kg" (ID: 101)

-- Shop A (Premium Store) - Higher price, better location
INSERT INTO shop_products (shop_id, master_product_id, price, original_price)
VALUES (1, 101, 280.00, 300.00);

-- Shop B (Discount Store) - Lower price, bulk buyer
INSERT INTO shop_products (shop_id, master_product_id, price, original_price)
VALUES (2, 101, 250.00, 300.00);

-- Shop C (Wholesale) - Lowest price, minimum margin
INSERT INTO shop_products (shop_id, master_product_id, price, cost_price)
VALUES (3, 101, 240.00, 200.00);
```

### Use Case 2: Seasonal Pricing
```sql
-- Diwali Sale: 20% off on all products in Shop A
INSERT INTO price_variations 
(shop_product_id, variation_type, special_price, start_datetime, end_datetime)
SELECT 
    id, 
    'SEASONAL', 
    price * 0.8,  -- 20% discount
    '2024-11-10 00:00:00',
    '2024-11-15 23:59:59'
FROM shop_products 
WHERE shop_id = 1;
```

### Use Case 3: Bulk Purchase Discounts
```sql
-- Bulk pricing for Rice in Shop A
INSERT INTO bulk_pricing_tiers 
(shop_product_id, min_quantity, max_quantity, price_per_unit)
VALUES 
(1, 1, 4, 280.00),     -- 1-4 bags: ₹280 each
(1, 5, 9, 270.00),     -- 5-9 bags: ₹270 each
(1, 10, NULL, 260.00); -- 10+ bags: ₹260 each
```

## 🎯 Design Benefits

1. **Separation of Concerns**
   - Master catalog manages product information
   - Shop products manage pricing and inventory

2. **Flexibility**
   - Each shop has complete control over pricing
   - Supports multiple pricing strategies simultaneously

3. **Scalability**
   - Efficient indexes for fast lookups
   - Minimal joins required for price calculation

4. **Maintainability**
   - Clear entity relationships
   - Easy to add new pricing rules

5. **Business Value**
   - Supports competitive pricing
   - Enables targeted promotions
   - Facilitates profit margin tracking

## 🚀 API Examples

### Get Product with Shop-Specific Price
```http
GET /api/products/shop/1/product/101
```

Response:
```json
{
    "productId": 101,
    "name": "Basmati Rice 5kg",
    "shopPrice": 280.00,
    "originalPrice": 300.00,
    "discount": 20.00,
    "discountPercentage": 6.67,
    "inStock": true,
    "stockQuantity": 150
}
```

### Calculate Price with Quantity
```http
POST /api/pricing/calculate
{
    "shopProductId": 1,
    "quantity": 10,
    "customerGroup": "WHOLESALE"
}
```

Response:
```json
{
    "basePrice": 280.00,
    "bulkPrice": 260.00,
    "finalPrice": 260.00,
    "totalAmount": 2600.00,
    "savings": 200.00
}
```

## 📊 Performance Considerations

### Indexes for Optimization
```sql
-- Fast price lookups
CREATE INDEX idx_shop_product ON shop_products(shop_id, master_product_id);

-- Active promotions
CREATE INDEX idx_active_promos ON price_variations(shop_product_id, start_datetime, end_datetime)
WHERE is_active = TRUE;

-- Bulk pricing tiers
CREATE INDEX idx_bulk_pricing ON bulk_pricing_tiers(shop_product_id, min_quantity);
```

## 🔄 Migration Strategy

### From Single Price to Multi-Shop Pricing
```sql
-- Step 1: Create shop_products table
CREATE TABLE shop_products AS 
SELECT 
    p.id as master_product_id,
    1 as shop_id,  -- Default shop
    p.price,
    p.original_price
FROM products p;

-- Step 2: Remove price from master products
ALTER TABLE products DROP COLUMN price, DROP COLUMN original_price;

-- Step 3: Add foreign key constraints
ALTER TABLE shop_products 
ADD CONSTRAINT fk_master_product 
FOREIGN KEY (master_product_id) REFERENCES products(id);
```

## 📝 Summary

This design provides a robust, scalable solution for handling product pricing across multiple shops with support for:
- Independent shop pricing
- Time-based promotions
- Quantity-based discounts
- Customer group pricing
- Performance optimization
- Easy maintenance and extension