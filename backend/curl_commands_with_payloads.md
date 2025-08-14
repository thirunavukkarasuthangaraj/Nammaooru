# 🚀 Sample Data Creation - Individual Curl Commands & Payloads

## Configuration
```bash
BASE_URL="http://localhost:8082/api"
TOKEN="your-jwt-token-here"
```

---

## 📁 **1. CREATE CATEGORIES**

### Electronics Category
```bash
curl -X POST "http://localhost:8082/api/products/categories" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Electronics",
    "description": "Electronic devices, gadgets, and technology products",
    "slug": "electronics",
    "isActive": true,
    "sortOrder": 1
  }'
```

### Fashion & Clothing Category
```bash
curl -X POST "http://localhost:8082/api/products/categories" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Fashion & Clothing",
    "description": "Apparel, footwear, and fashion accessories for all",
    "slug": "fashion-clothing",
    "isActive": true,
    "sortOrder": 2
  }'
```

### Food & Beverages Category
```bash
curl -X POST "http://localhost:8082/api/products/categories" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Food & Beverages",
    "description": "Groceries, snacks, beverages, and specialty foods",
    "slug": "food-beverages",
    "isActive": true,
    "sortOrder": 3
  }'
```

### Home & Garden Category
```bash
curl -X POST "http://localhost:8082/api/products/categories" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home & Garden",
    "description": "Home improvement, furniture, and gardening supplies",
    "slug": "home-garden",
    "isActive": true,
    "sortOrder": 4
  }'
```

---

## 📱 **2. CREATE PRODUCTS**

### iPhone 15 Pro
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "iPhone 15 Pro",
    "description": "Latest Apple iPhone with advanced camera system and A17 Pro chip",
    "sku": "APPLE-IP15PRO-128",
    "barcode": "1234567890001",
    "categoryId": 1,
    "brand": "Apple",
    "baseUnit": "pcs",
    "baseWeight": 0.187,
    "specifications": "Display: 6.1-inch Super Retina XDR, Storage: 128GB, Camera: 48MP Pro camera system",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Samsung Galaxy S24 Ultra
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Samsung Galaxy S24 Ultra",
    "description": "Premium Samsung smartphone with S Pen and 200MP camera",
    "sku": "SAMSUNG-S24U-256",
    "barcode": "1234567890002",
    "categoryId": 1,
    "brand": "Samsung",
    "baseUnit": "pcs",
    "baseWeight": 0.232,
    "specifications": "Display: 6.8-inch Dynamic AMOLED 2X, Storage: 256GB, Camera: 200MP quad camera",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### MacBook Air M3
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MacBook Air M3",
    "description": "Ultra-thin laptop with Apple M3 chip and all-day battery",
    "sku": "APPLE-MBA-M3-256",
    "barcode": "1234567890004",
    "categoryId": 1,
    "brand": "Apple",
    "baseUnit": "pcs",
    "baseWeight": 1.24,
    "specifications": "Display: 13.6-inch Liquid Retina, Processor: Apple M3, Storage: 256GB SSD, RAM: 8GB",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Sony WH-1000XM5 Headphones
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sony WH-1000XM5",
    "description": "Industry-leading noise canceling wireless headphones",
    "sku": "SONY-WH1000XM5",
    "barcode": "1234567890007",
    "categoryId": 1,
    "brand": "Sony",
    "baseUnit": "pcs",
    "baseWeight": 0.25,
    "specifications": "Type: Over-ear wireless, Noise Canceling: Yes, Battery: 30 hours, Features: Touch controls",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Nike Air Max 270
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nike Air Max 270",
    "description": "Lifestyle sneakers with Max Air cushioning",
    "sku": "NIKE-AM270-BLK-10",
    "barcode": "2345678900004",
    "categoryId": 2,
    "brand": "Nike",
    "baseUnit": "pcs",
    "baseWeight": 0.5,
    "specifications": "Type: Lifestyle sneakers, Cushioning: Max Air, Sizes: 6-13 US, Colors: Black/White",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Adidas Ultraboost 22
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Adidas Ultraboost 22",
    "description": "High-performance running shoes with Boost technology",
    "sku": "ADIDAS-UB22-WHT-9",
    "barcode": "2345678900005",
    "categoryId": 2,
    "brand": "Adidas",
    "baseUnit": "pcs",
    "baseWeight": 0.48,
    "specifications": "Type: Running shoes, Technology: Boost midsole, Sizes: 6-13 US, Colors: White/Black",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Organic Green Tea
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Organic Green Tea",
    "description": "Premium organic green tea leaves with antioxidants",
    "sku": "TWININGS-GT-ORG-100",
    "barcode": "3456789000001",
    "categoryId": 3,
    "brand": "Twinings",
    "baseUnit": "box",
    "baseWeight": 0.1,
    "specifications": "Type: Green tea, Weight: 100g, Quantity: 50 tea bags, Certification: Organic",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

### Starbucks Coffee
```bash
curl -X POST "http://localhost:8082/api/products/master" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTQwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Starbucks Pike Place Coffee",
    "description": "Medium roast ground coffee beans",
    "sku": "STARBUCKS-PP-340G",
    "barcode": "3456789000004",
    "categoryId": 3,
    "brand": "Starbucks",
    "baseUnit": "bag",
    "baseWeight": 0.34,
    "specifications": "Type: Ground coffee, Weight: 340g, Roast: Medium, Origin: Latin America",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }'
```

---

## 🔍 **3. VERIFICATION COMMANDS**

### Get All Categories
```bash
curl -X GET "http://localhost:8082/api/products/categories?size=20" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ"
```

### Get All Products
```bash
curl -X GET "http://localhost:8082/api/products/master?size=20" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ"
```

### Get All Brands
```bash
curl -X GET "http://localhost:8082/api/products/master/brands" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ"
```

---

## 📋 **JSON Payload Reference**

### Category Payload Structure
```json
{
  "name": "Category Name",
  "description": "Category description",
  "slug": "category-slug",
  "parentId": null,
  "isActive": true,
  "sortOrder": 1,
  "iconUrl": "https://example.com/icon.png"
}
```

### Product Payload Structure
```json
{
  "name": "Product Name",
  "description": "Product description",
  "sku": "UNIQUE-SKU-CODE",
  "barcode": "1234567890123",
  "categoryId": 1,
  "brand": "Brand Name",
  "baseUnit": "pcs",
  "baseWeight": 0.5,
  "specifications": "Detailed specifications",
  "status": "ACTIVE",
  "isFeatured": true,
  "isGlobal": true
}
```

---

## 🚀 **Quick Start Commands**

### Option 1: Run Batch Script (Windows)
```cmd
cd backend
insert_sample_data_api.bat
```

### Option 2: Run Shell Script (Linux/Mac)
```bash
cd backend
chmod +x insert_sample_data_api.sh
./insert_sample_data_api.sh
```

### Option 3: Run Individual Commands
Copy and paste each curl command above one by one.

---

## 📊 **Expected Results**
- ✅ **4 Categories**: Electronics, Fashion & Clothing, Food & Beverages, Home & Garden
- ✅ **9 Products**: iPhone, Samsung, MacBook, Sony headphones, Nike shoes, etc.
- ✅ **6 Brands**: Apple, Samsung, Sony, Nike, Adidas, Twinings, Starbucks
- ✅ **Realistic Data** ready for testing your application