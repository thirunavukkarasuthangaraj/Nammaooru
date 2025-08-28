# SKU-Based Product System Explained

## 📊 System Architecture Overview

This system uses a **Two-Tier Product Model** similar to large e-commerce platforms:

```
┌─────────────────────┐         ┌──────────────────┐
│  MASTER PRODUCTS    │ 1 ----→ │  SHOP PRODUCTS   │
│  (Central Catalog)  │    *    │  (Shop-specific) │
└─────────────────────┘         └──────────────────┘
```

## 🔑 What is SKU?

**SKU (Stock Keeping Unit)**: A unique identifier for each product in the system.

Example SKUs:
- `RICE-BAS-001` - Basmati Rice 1kg
- `MILK-AMU-500` - Amul Milk 500ml
- `PHN-SAM-S24U` - Samsung S24 Ultra
- `VEG-TOM-1KG` - Tomatoes per kg

## 🎯 How It Works

### 1. **Master Products (Central Catalog)**
```java
MasterProduct {
    id: 1,
    sku: "RICE-BAS-001",        // Unique identifier
    name: "Basmati Rice",
    barcode: "8901030865278",
    category: "Grocery/Rice",
    brand: "India Gate",
    baseUnit: "kg",
    specifications: {...}
}
```

**Purpose:**
- Central product database
- Maintained by ADMIN/SUPER_ADMIN
- One SKU = One unique product
- Shared across all shops

### 2. **Shop Products (Shop-specific)**
```java
ShopProduct {
    id: 101,
    shop: "Test Grocery Store",
    masterProduct: "RICE-BAS-001",  // Links via SKU
    price: 150.00,                  // Shop's selling price
    stockQuantity: 50,               // Shop's current stock
    customName: "Premium Basmati",  // Optional custom name
    isAvailable: true
}
```

**Purpose:**
- Shop-specific pricing
- Individual stock management
- Custom descriptions
- Availability control

## 📝 Product Creation Workflow

### Method 1: Select from Master Catalog (Recommended)
```
1. Shop owner clicks "Add Product"
2. Search master catalog by:
   - SKU (RICE-BAS-001)
   - Name (Basmati)
   - Barcode scan
   - Category browse
3. Select product
4. Set shop-specific details:
   - Selling price
   - Stock quantity
   - Custom name (optional)
5. Save
```

### Method 2: Request New Master Product
```
1. Product not in catalog
2. Shop owner requests new SKU
3. Admin creates master product:
   - Assigns SKU
   - Sets base details
4. Shop owner can now add it
```

## 💻 Implementation Example

### Frontend - Add Product Component
```typescript
// Step 1: Search master products
searchMasterProducts(query: string) {
  return this.http.get(`/api/master-products/search?q=${query}`);
}

// Step 2: Create shop product
addProductToShop(shopId: number, data: any) {
  const payload = {
    masterProductId: data.selectedProduct.id,  // Links via master product
    price: data.price,
    stockQuantity: data.stock,
    customName: data.customName || null,
    isAvailable: true
  };
  
  return this.http.post(`/api/shop-products`, payload);
}
```

### Backend - API Flow
```java
// 1. Search master products by SKU
@GetMapping("/api/master-products/search")
public List<MasterProduct> searchBySku(@RequestParam String sku) {
    return masterProductRepository.findBySkuContaining(sku);
}

// 2. Create shop product
@PostMapping("/api/shop-products")
public ShopProduct createShopProduct(@RequestBody ShopProductRequest request) {
    // Verify master product exists
    MasterProduct master = masterProductRepository.findById(request.getMasterProductId())
        .orElseThrow(() -> new NotFoundException("Product SKU not found"));
    
    // Create shop-specific product
    ShopProduct shopProduct = ShopProduct.builder()
        .shop(getCurrentShop())
        .masterProduct(master)
        .price(request.getPrice())
        .stockQuantity(request.getStockQuantity())
        .customName(request.getCustomName())
        .isAvailable(true)
        .build();
    
    return shopProductRepository.save(shopProduct);
}
```

## 🎨 UI Flow for Shop Owner

### 1. Product Search Screen
```
┌────────────────────────────────────┐
│  Add Product to Your Shop          │
│                                     │
│  🔍 Search by SKU or Name          │
│  ┌─────────────────────────┐       │
│  │ RICE-BAS                 │ 🔍   │
│  └─────────────────────────┘       │
│                                     │
│  Results:                           │
│  ┌─────────────────────────────┐   │
│  │ SKU: RICE-BAS-001          │   │
│  │ Basmati Rice 1kg           │   │
│  │ Brand: India Gate          │   │
│  │ [Select]                   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ SKU: RICE-BAS-005          │   │
│  │ Basmati Rice 5kg           │   │
│  │ Brand: India Gate          │   │
│  │ [Select]                   │   │
│  └─────────────────────────────┘   │
└────────────────────────────────────┘
```

### 2. Set Shop-Specific Details
```
┌────────────────────────────────────┐
│  Configure Product for Your Shop   │
│                                     │
│  Selected: Basmati Rice 1kg        │
│  SKU: RICE-BAS-001                 │
│                                     │
│  ┌─────────────────────────┐       │
│  │ Your Price: ₹ 150        │      │
│  └─────────────────────────┘       │
│                                     │
│  ┌─────────────────────────┐       │
│  │ Stock Quantity: 50       │      │
│  └─────────────────────────┘       │
│                                     │
│  ┌─────────────────────────┐       │
│  │ Custom Name (Optional):  │      │
│  │ Premium Basmati Rice     │      │
│  └─────────────────────────┘       │
│                                     │
│  [Cancel]  [Add to Shop]           │
└────────────────────────────────────┘
```

## ✅ Benefits of SKU System

### For Shop Owners:
1. **No Duplicate Entry** - Product details already exist
2. **Quick Addition** - Just set price and stock
3. **Consistent Data** - Same product info across platform
4. **Barcode Support** - Scan to add products

### For Customers:
1. **Product Comparison** - Same SKU across shops
2. **Price Comparison** - Compare prices for same product
3. **Reliable Information** - Verified product details

### For Platform:
1. **Data Integrity** - Single source of truth
2. **Analytics** - Track product popularity
3. **Inventory Management** - Platform-wide insights
4. **Quality Control** - Standardized catalog

## 📊 Database Schema

```sql
-- Master Products Table (Central Catalog)
CREATE TABLE master_products (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,  -- Unique identifier
    name VARCHAR(255) NOT NULL,
    barcode VARCHAR(100),
    category_id BIGINT,
    brand VARCHAR(100),
    base_unit VARCHAR(50),
    status VARCHAR(20),
    created_at TIMESTAMP
);

-- Shop Products Table (Shop-specific)
CREATE TABLE shop_products (
    id BIGSERIAL PRIMARY KEY,
    shop_id BIGINT NOT NULL,
    master_product_id BIGINT NOT NULL,  -- Links to SKU
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER,
    custom_name VARCHAR(255),
    is_available BOOLEAN,
    UNIQUE(shop_id, master_product_id)  -- One SKU per shop
);
```

## 🚀 Live Example

**Scenario:** Shop owner wants to add "Amul Milk 500ml"

1. **Search:** Types "Amul Milk" or SKU "MILK-AMU-500"
2. **Select:** Chooses from master catalog
3. **Configure:**
   - Sets price: ₹25
   - Sets stock: 100 units
   - Custom name: "Fresh Amul Milk" (optional)
4. **Save:** Product added to shop

**Result in Database:**
```sql
-- Master Product (shared)
id: 42, sku: 'MILK-AMU-500', name: 'Amul Milk', unit: '500ml'

-- Shop Product (shop-specific)
id: 1001, shop_id: 11, master_product_id: 42, price: 25.00, stock: 100
```

## 🔧 API Endpoints

```bash
# Search master products
GET /api/master-products/search?q=milk
GET /api/master-products/search?sku=MILK-AMU-500
GET /api/master-products/search?barcode=8901030865278

# Get master product details
GET /api/master-products/{id}

# Add product to shop
POST /api/shop-products
{
  "masterProductId": 42,
  "price": 25.00,
  "stockQuantity": 100,
  "customName": "Fresh Amul Milk"
}

# Update shop product
PUT /api/shop-products/{id}
{
  "price": 26.00,
  "stockQuantity": 150
}

# Remove from shop
DELETE /api/shop-products/{id}
```

## 📱 Mobile App Flow

1. **Barcode Scanner** → Scan product → Auto-fill SKU
2. **Voice Search** → "Add Amul Milk" → Show matches
3. **Quick Add** → Recent/Frequent products list

## 🎯 Summary

The SKU system works like a **library catalog**:
- **Master Products** = Library's book catalog (ISBN)
- **Shop Products** = Individual library branches having copies
- **SKU** = ISBN number identifying the book
- Each shop decides their own price and stock for the same SKU

This ensures:
- ✅ No duplicate data entry
- ✅ Consistent product information
- ✅ Easy price comparison
- ✅ Efficient inventory management
- ✅ Scalable system architecture

---
**Note:** This is the same model used by:
- Amazon (ASIN)
- Flipkart (FSN)
- Zomato/Swiggy (Central menu items)
- Walmart (Item Number)