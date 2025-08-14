@echo off
echo ===== Shop Management System API Testing =====
echo.

set BASE_URL=http://localhost:8082
set TOKEN=

echo 1. Testing User Registration...
curl -X POST %BASE_URL%/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"username\": \"testuser2\", \"email\": \"testuser2@example.com\", \"password\": \"password123\", \"role\": \"USER\"}"
echo.
echo.

echo 2. Testing User Login...
for /f "tokens=*" %%a in ('curl -s -X POST %BASE_URL%/api/auth/login -H "Content-Type: application/json" -d "{\"username\": \"newuser\", \"password\": \"password123\"}" ^| jq -r .accessToken') do set TOKEN=%%a
echo Token obtained: %TOKEN:~0,50%...
echo.

echo 3. Testing Shop Owner Registration...
curl -X POST %BASE_URL%/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "{\"username\": \"shopowner1\", \"email\": \"owner@shop.com\", \"password\": \"password123\", \"role\": \"SHOP_OWNER\"}"
echo.
echo.

echo 4. Testing Shop Creation...
curl -X POST %BASE_URL%/api/shops ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -d "{\"name\": \"Test Shop\", \"description\": \"A test shop\", \"shopId\": \"TS001\", \"slug\": \"test-shop\", \"ownerName\": \"Test Owner\", \"ownerEmail\": \"test@owner.com\", \"ownerPhone\": \"+91 1234567890\", \"businessName\": \"Test Business\", \"businessType\": \"GROCERY\", \"addressLine1\": \"123 Test Street\", \"city\": \"Test City\", \"state\": \"Test State\", \"postalCode\": \"123456\", \"country\": \"India\"}"
echo.
echo.

echo 5. Testing Get All Shops...
curl -X GET %BASE_URL%/api/shops ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 6. Testing Shop Search...
curl -X GET "%BASE_URL%/api/shops/search?name=Fresh" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 7. Testing Get Shops by City...
curl -X GET "%BASE_URL%/api/shops?city=Chennai" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 8. Testing Get Shop by ID (assuming ID 1 exists)...
curl -X GET %BASE_URL%/api/shops/1 ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo ===== API Testing Complete =====
pause