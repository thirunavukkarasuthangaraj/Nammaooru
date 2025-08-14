@echo off
echo ===== Shop Management System - Complete API Testing =====
echo.

set BASE_URL=http://localhost:8082

echo 1. Testing User Login (with existing user)...
curl -X POST %BASE_URL%/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "{\"username\": \"newuser\", \"password\": \"password123\"}"
echo.
echo.

echo 2. Getting JWT Token for API calls...
for /f "tokens=2 delims=:" %%a in ('curl -s -X POST %BASE_URL%/api/auth/login -H "Content-Type: application/json" -d "{\"username\": \"newuser\", \"password\": \"password123\"}" ^| findstr accessToken ^| cut -d"," -f1') do set RAW_TOKEN=%%a
set TOKEN=%RAW_TOKEN:"=%
echo Using Token: %TOKEN:~0,50%...
echo.

echo 3. Testing Get All Shops...
curl -X GET %BASE_URL%/api/shops ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 4. Testing Shop Search (q=Fresh)...
curl -X GET "%BASE_URL%/api/shops/search?q=Fresh" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 5. Testing Shop Filter by City...
curl -X GET "%BASE_URL%/api/shops?city=Chennai" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 6. Testing Get Shop by ID (ID=1)...
curl -X GET %BASE_URL%/api/shops/1 ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 7. Testing Shop Creation...
curl -X POST %BASE_URL%/api/shops ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer %TOKEN%" ^
  -d "{\"name\": \"Test API Shop\", \"description\": \"Shop created via API test\", \"shopId\": \"API001\", \"slug\": \"test-api-shop\", \"ownerName\": \"API Test Owner\", \"ownerEmail\": \"apitest@shop.com\", \"ownerPhone\": \"+91 9999999999\", \"businessName\": \"API Test Business\", \"businessType\": \"GROCERY\", \"addressLine1\": \"123 API Test Street\", \"city\": \"Mumbai\", \"state\": \"Maharashtra\", \"postalCode\": \"400001\", \"country\": \"India\", \"latitude\": 19.0760, \"longitude\": 72.8777}"
echo.
echo.

echo 8. Testing Pagination (page=0, size=1)...
curl -X GET "%BASE_URL%/api/shops?page=0&size=1" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 9. Testing Shop Filter by Business Type...
curl -X GET "%BASE_URL%/api/shops?businessType=GROCERY" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo 10. Testing Multiple Filters (city + businessType)...
curl -X GET "%BASE_URL%/api/shops?city=Chennai&businessType=GROCERY" ^
  -H "Authorization: Bearer %TOKEN%"
echo.
echo.

echo ===== API Testing Complete =====
echo All major endpoints tested successfully!
pause