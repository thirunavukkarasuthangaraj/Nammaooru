#!/bin/bash

# =============================================
# SAMPLE DATA INSERTION VIA REST API
# Shop Management System
# =============================================

# Configuration
BASE_URL="http://localhost:8082/api"
TOKEN="eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Sample Data Creation via API...${NC}"
echo -e "${YELLOW}Base URL: $BASE_URL${NC}"
echo ""

# =============================================
# 1. CREATE ROOT CATEGORIES
# =============================================
echo -e "${BLUE}📁 Creating Root Categories...${NC}"

# Electronics
echo -e "Creating Electronics category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Electronics",
    "description": "Electronic devices, gadgets, and technology products",
    "slug": "electronics",
    "isActive": true,
    "sortOrder": 1
  }' -w "\nStatus: %{http_code}\n\n"

# Fashion & Clothing  
echo -e "Creating Fashion & Clothing category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Fashion & Clothing",
    "description": "Apparel, footwear, and fashion accessories for all",
    "slug": "fashion-clothing", 
    "isActive": true,
    "sortOrder": 2
  }' -w "\nStatus: %{http_code}\n\n"

# Home & Garden
echo -e "Creating Home & Garden category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home & Garden",
    "description": "Home improvement, furniture, and gardening supplies",
    "slug": "home-garden",
    "isActive": true,
    "sortOrder": 3
  }' -w "\nStatus: %{http_code}\n\n"

# Food & Beverages
echo -e "Creating Food & Beverages category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Food & Beverages", 
    "description": "Groceries, snacks, beverages, and specialty foods",
    "slug": "food-beverages",
    "isActive": true,
    "sortOrder": 4
  }' -w "\nStatus: %{http_code}\n\n"

# Sports & Outdoors
echo -e "Creating Sports & Outdoors category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sports & Outdoors",
    "description": "Athletic gear, outdoor equipment, and fitness products", 
    "slug": "sports-outdoors",
    "isActive": true,
    "sortOrder": 5
  }' -w "\nStatus: %{http_code}\n\n"

# Books & Media
echo -e "Creating Books & Media category..."
curl -X POST "$BASE_URL/products/categories" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Books & Media",
    "description": "Books, movies, music, and educational materials",
    "slug": "books-media", 
    "isActive": true,
    "sortOrder": 6
  }' -w "\nStatus: %{http_code}\n\n"

echo -e "${GREEN}✅ Root categories created!${NC}"
echo ""

# Wait a moment for categories to be created
sleep 2

# Get Electronics category ID for subcategories
echo -e "${BLUE}🔍 Fetching Electronics category ID...${NC}"
ELECTRONICS_RESPONSE=$(curl -s -X GET "$BASE_URL/products/categories?search=Electronics" \
  -H "Authorization: Bearer $TOKEN")
echo "Electronics API Response: $ELECTRONICS_RESPONSE"

# Get Fashion category ID  
echo -e "${BLUE}🔍 Fetching Fashion category ID...${NC}"
FASHION_RESPONSE=$(curl -s -X GET "$BASE_URL/products/categories?search=Fashion" \
  -H "Authorization: Bearer $TOKEN") 
echo "Fashion API Response: $FASHION_RESPONSE"

echo ""

# =============================================
# 2. CREATE MASTER PRODUCTS
# =============================================
echo -e "${BLUE}📱 Creating Sample Products...${NC}"

# iPhone 15 Pro
echo -e "Creating iPhone 15 Pro..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# Samsung Galaxy S24 Ultra
echo -e "Creating Samsung Galaxy S24 Ultra..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# MacBook Air M3
echo -e "Creating MacBook Air M3..."  
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# Sony WH-1000XM5
echo -e "Creating Sony WH-1000XM5..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# Nike Air Max 270
echo -e "Creating Nike Air Max 270..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# Adidas Ultraboost 22
echo -e "Creating Adidas Ultraboost 22..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
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
  }' -w "\nStatus: %{http_code}\n\n"

# Organic Green Tea
echo -e "Creating Organic Green Tea..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Organic Green Tea",
    "description": "Premium organic green tea leaves with antioxidants",
    "sku": "TWININGS-GT-ORG-100", 
    "barcode": "3456789000001",
    "categoryId": 4,
    "brand": "Twinings", 
    "baseUnit": "box",
    "baseWeight": 0.1,
    "specifications": "Type: Green tea, Weight: 100g, Quantity: 50 tea bags, Certification: Organic",
    "status": "ACTIVE",
    "isFeatured": true, 
    "isGlobal": true
  }' -w "\nStatus: %{http_code}\n\n"

# Starbucks Coffee
echo -e "Creating Starbucks Pike Place Coffee..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Starbucks Pike Place Coffee",
    "description": "Medium roast ground coffee beans",
    "sku": "STARBUCKS-PP-340G",
    "barcode": "3456789000004", 
    "categoryId": 4,
    "brand": "Starbucks",
    "baseUnit": "bag",
    "baseWeight": 0.34,
    "specifications": "Type: Ground coffee, Weight: 340g, Roast: Medium, Origin: Latin America",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }' -w "\nStatus: %{http_code}\n\n"

# Levi's 501 Jeans  
echo -e "Creating Levi's 501 Original Jeans..."
curl -X POST "$BASE_URL/products/master" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Levis 501 Original Jeans",
    "description": "Classic straight-fit jeans in original blue denim",
    "sku": "LEVIS-501-ORIG-32",
    "barcode": "2345678900001",
    "categoryId": 2,
    "brand": "Levis",
    "baseUnit": "pcs",
    "baseWeight": 0.8, 
    "specifications": "Material: 100% Cotton, Fit: Straight, Sizes: 28-40 waist, Color: Original Blue",
    "status": "ACTIVE",
    "isFeatured": true,
    "isGlobal": true
  }' -w "\nStatus: %{http_code}\n\n"

echo -e "${GREEN}✅ Sample products created!${NC}"
echo ""

# =============================================
# 3. VERIFICATION
# =============================================
echo -e "${BLUE}🔍 Verification - Checking created data...${NC}"

echo -e "📊 Categories:"
curl -s -X GET "$BASE_URL/products/categories?size=20" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data.content[] | "- \(.name) (ID: \(.id), Active: \(.isActive))"' 2>/dev/null || echo "Categories created (JSON parsing requires jq)"

echo ""
echo -e "📦 Products:" 
curl -s -X GET "$BASE_URL/products/master?size=20" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data.content[] | "- \(.name) by \(.brand // "Unknown") (SKU: \(.sku))"' 2>/dev/null || echo "Products created (JSON parsing requires jq)"

echo ""
echo -e "🎯 Brands available:"
curl -s -X GET "$BASE_URL/products/master/brands" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[] | "- \(.)"' 2>/dev/null || echo "Brands created (JSON parsing requires jq)"

echo ""
echo -e "${GREEN}🎉 Sample data creation completed!${NC}"
echo -e "${YELLOW}📝 Note: If you see 'jq' errors, install jq for better output formatting${NC}"
echo -e "${BLUE}🌐 Your application now has realistic sample data ready for testing!${NC}"