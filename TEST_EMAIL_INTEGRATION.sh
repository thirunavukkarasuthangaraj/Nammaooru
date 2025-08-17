#!/bin/bash

echo "🎯 EMAIL INTEGRATION TEST"
echo "========================="

BASE_URL="http://localhost:8082"

echo -e "\n1️⃣ ADMIN LOGIN"
echo "==============="
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}')

echo "Admin login response: $ADMIN_TOKEN"

echo -e "\n2️⃣ CUSTOMER LOGIN"  
echo "=================="
CUSTOMER_TOKEN=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"customer1","password":"password"}')

echo "Customer login response: $CUSTOMER_TOKEN"

echo -e "\n3️⃣ CREATE ORDER TO TEST EMAILS"
echo "==============================="
ORDER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/orders" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(echo "$CUSTOMER_TOKEN" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)" \
  -d '{
    "customerId": 15,
    "shopId": 11,
    "orderItems": [
      {"shopProductId": 12, "quantity": 1, "unitPrice": 85000}
    ],
    "paymentMethod": "CASH_ON_DELIVERY",
    "deliveryAddress": "123 Email Test Street",
    "deliveryContactName": "Email Test Customer",
    "deliveryPhone": "9876543210",
    "deliveryCity": "Bangalore",
    "deliveryState": "Karnataka",
    "deliveryPostalCode": "560003",
    "notes": "Test order for email integration"
  }')

echo "Order creation response:"
echo "$ORDER_RESPONSE"

echo -e "\n✅ EMAIL INTEGRATION TEST COMPLETE"
echo "Check application logs for email sending attempts"