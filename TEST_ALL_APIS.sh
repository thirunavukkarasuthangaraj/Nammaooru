#!/bin/bash

echo "================================"
echo "TESTING ALL APIS"
echo "================================"

# Test Login
echo -e "\n1. Testing Login API..."
curl -X POST "http://localhost:8082/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}'

echo -e "\n\n2. Testing Shops API..."
curl -X GET "http://localhost:8082/api/shops"

echo -e "\n\n3. Testing Products API..."
curl -X GET "http://localhost:8082/api/products"

echo -e "\n\n4. Testing Customers API..."
curl -X GET "http://localhost:8082/api/customers"

echo -e "\n\n5. Testing Delivery Partners API..."
curl -X GET "http://localhost:8082/api/delivery/partners"

echo -e "\n\n6. Testing Orders API..."
curl -X GET "http://localhost:8082/api/orders"

echo -e "\n\nAll API tests complete!"