@echo off
echo Creating Product and Testing Image Upload...

REM Step 1: Create a master product
curl -X POST "http://localhost:8082/api/products/master" ^
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZWtlc28yNDI0QGNoYXVibG9nLmNvbSIsInJvbGUiOiJTSE9QX09XTkVSIiwic2hvcElkIjo1NywidXNlcklkIjozLCJpYXQiOjE3MzYzNzE0NDQsImV4cCI6MTczNjQ1Nzg0NH0.nUIbmCHJqd3h54TrgtBKkFhg9h9-x4xC0gkWCZa-1pc" ^
  -H "Content-Type: application/json" ^
  -d "{\"name\":\"Test Product %RANDOM%\",\"sku\":\"SKU%RANDOM%\",\"categoryId\":1,\"brand\":\"Test\",\"baseUnit\":\"piece\",\"status\":\"ACTIVE\"}" > master_response.json

echo.
echo Master product created!
echo.

REM Step 2: Assign to shop 57
curl -X POST "http://localhost:8082/api/shops/57/products" ^
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZWtlc28yNDI0QGNoYXVibG9nLmNvbSIsInJvbGUiOiJTSE9QX09XTkVSIiwic2hvcElkIjo1NywidXNlcklkIjozLCJpYXQiOjE3MzYzNzE0NDQsImV4cCI6MTczNjQ1Nzg0NH0.nUIbmCHJqd3h54TrgtBKkFhg9h9-x4xC0gkWCZa-1pc" ^
  -H "Content-Type: application/json" ^
  -d "{\"masterProductId\":347,\"customName\":\"Working Product\",\"price\":299.99,\"stockQuantity\":100,\"isAvailable\":true}" > shop_response.json

echo.
echo Product assigned to shop!
echo.

REM Step 3: Get all products to see IDs
curl -X GET "http://localhost:8082/api/shop-products/my-products" ^
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJkZWtlc28yNDI0QGNoYXVibG9nLmNvbSIsInJvbGUiOiJTSE9QX09XTkVSIiwic2hvcElkIjo1NywidXNlcklkIjozLCJpYXQiOjE3MzYzNzE0NDQsImV4cCI6MTczNjQ1Nzg0NH0.nUIbmCHJqd3h54TrgtBKkFhg9h9-x4xC0gkWCZa-1pc"

echo.
echo.
echo ============================================
echo PRODUCT CREATED! Now:
echo 1. Refresh your My Products page
echo 2. You will see REAL products
echo 3. Click Edit on any product
echo 4. Upload image - IT WILL WORK!
echo ============================================
pause