@echo off
REM =============================================
REM SAMPLE DATA INSERTION VIA REST API (Windows)
REM Shop Management System  
REM =============================================

set BASE_URL=http://localhost:8082/api
set TOKEN=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIsImV4cCI6MTc1NTI1NzMzNiwiaWF0IjoxNzU1MTcwOTM2fQ.B3bo3RoAmtY7XSj8zUi-U1fxClWuhtjdmBOFeKxwItQ

echo 🚀 Starting Sample Data Creation via API...
echo Base URL: %BASE_URL%
echo.

REM =============================================
REM 1. CREATE ROOT CATEGORIES
REM =============================================
echo 📁 Creating Root Categories...

echo Creating Electronics category...
curl -X POST "%BASE_URL%/products/categories" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Electronics\", \"description\": \"Electronic devices, gadgets, and technology products\", \"slug\": \"electronics\", \"isActive\": true, \"sortOrder\": 1}"

echo.
echo Creating Fashion ^& Clothing category...
curl -X POST "%BASE_URL%/products/categories" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Fashion & Clothing\", \"description\": \"Apparel, footwear, and fashion accessories for all\", \"slug\": \"fashion-clothing\", \"isActive\": true, \"sortOrder\": 2}"

echo.
echo Creating Food ^& Beverages category...
curl -X POST "%BASE_URL%/products/categories" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Food & Beverages\", \"description\": \"Groceries, snacks, beverages, and specialty foods\", \"slug\": \"food-beverages\", \"isActive\": true, \"sortOrder\": 3}"

echo.
echo Creating Home ^& Garden category...
curl -X POST "%BASE_URL%/products/categories" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Home & Garden\", \"description\": \"Home improvement, furniture, and gardening supplies\", \"slug\": \"home-garden\", \"isActive\": true, \"sortOrder\": 4}"

echo.
echo ✅ Root categories created!
echo.

timeout /t 3 /nobreak > nul

REM =============================================  
REM 2. CREATE MASTER PRODUCTS
REM =============================================
echo 📱 Creating Sample Products...

echo Creating iPhone 15 Pro...
curl -X POST "%BASE_URL%/products/master" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"iPhone 15 Pro\", \"description\": \"Latest Apple iPhone with advanced camera system and A17 Pro chip\", \"sku\": \"APPLE-IP15PRO-128\", \"barcode\": \"1234567890001\", \"categoryId\": 1, \"brand\": \"Apple\", \"baseUnit\": \"pcs\", \"baseWeight\": 0.187, \"specifications\": \"Display: 6.1-inch Super Retina XDR, Storage: 128GB, Camera: 48MP Pro camera system\", \"status\": \"ACTIVE\", \"isFeatured\": true, \"isGlobal\": true}"

echo.
echo Creating Samsung Galaxy S24 Ultra...
curl -X POST "%BASE_URL%/products/master" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Samsung Galaxy S24 Ultra\", \"description\": \"Premium Samsung smartphone with S Pen and 200MP camera\", \"sku\": \"SAMSUNG-S24U-256\", \"barcode\": \"1234567890002\", \"categoryId\": 1, \"brand\": \"Samsung\", \"baseUnit\": \"pcs\", \"baseWeight\": 0.232, \"specifications\": \"Display: 6.8-inch Dynamic AMOLED 2X, Storage: 256GB, Camera: 200MP quad camera\", \"status\": \"ACTIVE\", \"isFeatured\": true, \"isGlobal\": true}"

echo.
echo Creating MacBook Air M3...
curl -X POST "%BASE_URL%/products/master" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"MacBook Air M3\", \"description\": \"Ultra-thin laptop with Apple M3 chip and all-day battery\", \"sku\": \"APPLE-MBA-M3-256\", \"barcode\": \"1234567890004\", \"categoryId\": 1, \"brand\": \"Apple\", \"baseUnit\": \"pcs\", \"baseWeight\": 1.24, \"specifications\": \"Display: 13.6-inch Liquid Retina, Processor: Apple M3, Storage: 256GB SSD, RAM: 8GB\", \"status\": \"ACTIVE\", \"isFeatured\": true, \"isGlobal\": true}"

echo.
echo Creating Nike Air Max 270...
curl -X POST "%BASE_URL%/products/master" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Nike Air Max 270\", \"description\": \"Lifestyle sneakers with Max Air cushioning\", \"sku\": \"NIKE-AM270-BLK-10\", \"barcode\": \"2345678900004\", \"categoryId\": 2, \"brand\": \"Nike\", \"baseUnit\": \"pcs\", \"baseWeight\": 0.5, \"specifications\": \"Type: Lifestyle sneakers, Cushioning: Max Air, Sizes: 6-13 US, Colors: Black/White\", \"status\": \"ACTIVE\", \"isFeatured\": true, \"isGlobal\": true}"

echo.
echo Creating Organic Green Tea...
curl -X POST "%BASE_URL%/products/master" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\": \"Organic Green Tea\", \"description\": \"Premium organic green tea leaves with antioxidants\", \"sku\": \"TWININGS-GT-ORG-100\", \"barcode\": \"3456789000001\", \"categoryId\": 3, \"brand\": \"Twinings\", \"baseUnit\": \"box\", \"baseWeight\": 0.1, \"specifications\": \"Type: Green tea, Weight: 100g, Quantity: 50 tea bags, Certification: Organic\", \"status\": \"ACTIVE\", \"isFeatured\": true, \"isGlobal\": true}"

echo.
echo ✅ Sample products created!
echo.

REM =============================================
REM 3. VERIFICATION
REM =============================================
echo 🔍 Verification - Checking created data...
echo.

echo 📊 Fetching Categories:
curl -s -X GET "%BASE_URL%/products/categories?size=10" -H "Authorization: Bearer %TOKEN%"

echo.
echo.
echo 📦 Fetching Products:
curl -s -X GET "%BASE_URL%/products/master?size=10" -H "Authorization: Bearer %TOKEN%"

echo.
echo.
echo 🎯 Fetching Available Brands:
curl -s -X GET "%BASE_URL%/products/master/brands" -H "Authorization: Bearer %TOKEN%"

echo.
echo.
echo 🎉 Sample data creation completed!
echo 🌐 Your application now has realistic sample data ready for testing!

pause