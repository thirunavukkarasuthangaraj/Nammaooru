# Multi-Shop Pricing Example - Same Product, Different Prices

## 🏪 The Scenario: 3 Shops, 1 Master Product, 3 Different Prices

### 📦 MASTER PRODUCT (Shared Catalog)
```
┌──────────────────────────────────────────┐
│         MASTER_PRODUCTS TABLE            │
├──────────────────────────────────────────┤
│ id: 101                                  │
│ name: "Basmati Rice Premium 5kg"        │
│ sku: "RICE-BAS-5KG"                     │
│ brand: "India Gate"                     │
│ category: "Groceries > Rice"            │
│ ❌ NO PRICE HERE - ONLY PRODUCT INFO    │
└──────────────────────────────────────────┘
```

### 💰 EACH SHOP SETS THEIR OWN PRICE

```
     MASTER PRODUCT (ID: 101)
              │
              ├─────────────────┬─────────────────┐
              ▼                 ▼                 ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │     SHOP 1      │ │     SHOP 2      │ │     SHOP 3      │
    │  Premium Store  │ │  Discount Mart  │ │   Wholesale     │
    ├─────────────────┤ ├─────────────────┤ ├─────────────────┤
    │ Price: ₹320     │ │ Price: ₹280     │ │ Price: ₹260     │
    │ MRP: ₹350       │ │ MRP: ₹350       │ │ MRP: ₹350       │
    │ Margin: 25%     │ │ Margin: 15%     │ │ Margin: 10%     │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## 📊 Database Tables Structure

### 1️⃣ MASTER_PRODUCTS Table (Common Catalog)
```sql
┌────────────────────────────────────────────────────┐
│                 MASTER_PRODUCTS                    │
├────┬───────────────────────┬──────────────────────┤
│ ID │ NAME                  │ SKU                  │
├────┼───────────────────────┼──────────────────────┤
│ 101│ Basmati Rice 5kg      │ RICE-BAS-5KG        │
│ 102│ Wheat Flour 10kg      │ FLOUR-WHEAT-10KG    │
│ 103│ Sugar 1kg             │ SUGAR-WHITE-1KG     │
│ 104│ Cooking Oil 1L        │ OIL-SUNFLOWER-1L    │
└────┴───────────────────────┴──────────────────────┘
         ⚠️ NO PRICE COLUMN IN THIS TABLE!
```

### 2️⃣ SHOPS Table
```sql
┌──────────────────────────────────────────────────────┐
│                      SHOPS                           │
├────┬──────────────────┬──────────────┬──────────────┤
│ ID │ NAME             │ TYPE         │ LOCATION     │
├────┼──────────────────┼──────────────┼──────────────┤
│ 1  │ Super Mart       │ Premium      │ City Center  │
│ 2  │ Budget Bazaar    │ Discount     │ Suburb       │
│ 3  │ Wholesale Hub    │ Wholesale    │ Industrial   │
└────┴──────────────────┴──────────────┴──────────────┘
```

### 3️⃣ SHOP_PRODUCTS Table (Where Pricing Happens!)
```sql
┌────────────────────────────────────────────────────────────────────┐
│                          SHOP_PRODUCTS                             │
├────┬─────────┬──────────────┬────────┬──────────┬───────────────┤
│ ID │ SHOP_ID │ MASTER_PROD  │ PRICE  │ ORIGINAL │ COST_PRICE    │
├────┼─────────┼──────────────┼────────┼──────────┼───────────────┤
│ 1  │    1    │     101      │ 320.00 │  350.00  │   240.00      │
│ 2  │    2    │     101      │ 280.00 │  350.00  │   240.00      │
│ 3  │    3    │     101      │ 260.00 │  350.00  │   240.00      │
│ 4  │    1    │     102      │ 450.00 │  500.00  │   350.00      │
│ 5  │    2    │     102      │ 420.00 │  500.00  │   350.00      │
│ 6  │    3    │     102      │ 400.00 │  500.00  │   350.00      │
└────┴─────────┴──────────────┴────────┴──────────┴───────────────┘
```

## 🔄 How It Works - Step by Step

### Step 1: Create Master Product (Admin)
```sql
INSERT INTO master_products (id, name, sku, brand, category_id)
VALUES (101, 'Basmati Rice Premium 5kg', 'RICE-BAS-5KG', 'India Gate', 1);
-- ✅ No price added here!
```

### Step 2: Each Shop Sets Their Own Price
```sql
-- Shop 1 (Premium Store) - Higher price, better service
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price)
VALUES (1, 101, 320.00, 350.00, 240.00);

-- Shop 2 (Discount Store) - Competitive pricing
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price)
VALUES (2, 101, 280.00, 350.00, 240.00);

-- Shop 3 (Wholesale) - Bulk sales, lowest margin
INSERT INTO shop_products (shop_id, master_product_id, price, original_price, cost_price)
VALUES (3, 101, 260.00, 350.00, 240.00);
```

## 🛒 Customer Experience

### When Customer Searches for "Basmati Rice":

```
┌──────────────────────────────────────────────────────┐
│           SEARCH RESULTS: "Basmati Rice"             │
├──────────────────────────────────────────────────────┤
│                                                      │
│ 📦 Basmati Rice Premium 5kg                         │
│                                                      │
│ 🏪 Available at:                                    │
│                                                      │
│ ┌────────────────────────────────────┐              │
│ │ Super Mart (City Center)           │              │
│ │ ₹320  ̶₹̶3̶5̶0̶  (Save ₹30)           │              │
│ │ ⭐⭐⭐⭐⭐ Premium Quality            │              │
│ │ [Add to Cart]                       │              │
│ └────────────────────────────────────┘              │
│                                                      │
│ ┌────────────────────────────────────┐              │
│ │ Budget Bazaar (Suburb)             │              │
│ │ ₹280  ̶₹̶3̶5̶0̶  (Save ₹70)           │              │
│ │ ⭐⭐⭐⭐ Best Value                  │              │
│ │ [Add to Cart]                       │              │
│ └────────────────────────────────────┘              │
│                                                      │
│ ┌────────────────────────────────────┐              │
│ │ Wholesale Hub (Industrial)         │              │
│ │ ₹260  ̶₹̶3̶5̶0̶  (Save ₹90)           │              │
│ │ ⭐⭐⭐ Bulk Orders Only              │              │
│ │ [Add to Cart]                       │              │
│ └────────────────────────────────────┘              │
└──────────────────────────────────────────────────────┘
```

## 💡 Real-World Example Code

### Java Entity Implementation

```java
// MasterProduct.java - NO PRICE FIELD
@Entity
@Table(name = "master_products")
public class MasterProduct {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String name;
    private String sku;
    private String brand;
    
    // ❌ NO price field here!
    // Prices are handled in ShopProduct
}

// ShopProduct.java - HAS PRICE FIELDS
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
    
    // ✅ PRICING FIELDS HERE!
    @Column(nullable = false)
    private BigDecimal price;          // Shop's selling price
    
    private BigDecimal originalPrice;  // MRP for discount display
    private BigDecimal costPrice;      // Shop's purchase cost
    
    // Calculate profit margin
    public BigDecimal getProfitMargin() {
        if (costPrice == null || price == null) return BigDecimal.ZERO;
        return price.subtract(costPrice)
                    .divide(costPrice, 2, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal(100));
    }
}
```

### API Response Example

```json
// GET /api/products/search?q=basmati+rice

{
  "product": {
    "id": 101,
    "name": "Basmati Rice Premium 5kg",
    "sku": "RICE-BAS-5KG",
    "brand": "India Gate",
    "availableAt": [
      {
        "shopId": 1,
        "shopName": "Super Mart",
        "price": 320.00,
        "originalPrice": 350.00,
        "discount": 30.00,
        "discountPercent": 8.57,
        "inStock": true,
        "location": "City Center"
      },
      {
        "shopId": 2,
        "shopName": "Budget Bazaar",
        "price": 280.00,
        "originalPrice": 350.00,
        "discount": 70.00,
        "discountPercent": 20.00,
        "inStock": true,
        "location": "Suburb"
      },
      {
        "shopId": 3,
        "shopName": "Wholesale Hub",
        "price": 260.00,
        "originalPrice": 350.00,
        "discount": 90.00,
        "discountPercent": 25.71,
        "inStock": true,
        "location": "Industrial",
        "minOrderQty": 10
      }
    ]
  }
}
```

## 🎯 Benefits of This Design

### 1. Independence
Each shop controls their own:
- Selling price
- Discount amount
- Stock levels
- Profit margins

### 2. Flexibility
- Shop 1 can run a sale without affecting Shop 2
- Shop 3 can offer bulk discounts
- Each shop can have different costs

### 3. Centralized Product Management
- Product info updated once in master
- All shops get the update automatically
- No duplicate product data

### 4. Competition & Choice
- Customers can compare prices
- Shops can compete on price
- Market-driven pricing

## 📈 Advanced Scenarios

### Scenario 1: Festival Sale (Shop 1 Only)
```sql
-- Only Shop 1 has Diwali sale
UPDATE shop_products 
SET price = 290.00 
WHERE shop_id = 1 AND master_product_id = 101;

-- Result:
-- Shop 1: ₹290 (was ₹320)
-- Shop 2: ₹280 (unchanged)
-- Shop 3: ₹260 (unchanged)
```

### Scenario 2: Bulk Discount (Shop 3)
```sql
-- Shop 3 offers bulk pricing
INSERT INTO bulk_pricing (shop_product_id, min_qty, price_per_unit)
VALUES 
(3, 1, 260.00),   -- 1-9 units: ₹260
(3, 10, 250.00),  -- 10-49 units: ₹250
(3, 50, 240.00);  -- 50+ units: ₹240
```

### Scenario 3: Out of Stock (Shop 2)
```sql
-- Shop 2 runs out of stock
UPDATE shop_products 
SET stock_quantity = 0, is_available = false 
WHERE shop_id = 2 AND master_product_id = 101;

-- Now only Shop 1 and Shop 3 show in search results
```

## 🔑 Key Takeaway

```
┌─────────────────────────────────────────────────────┐
│                  REMEMBER THIS:                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  MASTER PRODUCT = WHAT IT IS (Name, Brand, SKU)    │
│                                                     │
│  SHOP PRODUCT = HOW MUCH IT COSTS IN EACH SHOP     │
│                                                     │
│  One Product → Many Shops → Many Prices            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

This design lets each shop operate independently while sharing a common product catalog!