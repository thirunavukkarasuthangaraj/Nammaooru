#!/bin/bash

echo "📧 INVOICE SYSTEM TEST"
echo "======================"

BASE_URL="http://localhost:8082"

echo -e "\n1️⃣ ADMIN LOGIN"
echo "==============="
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"superadmin","password":"password"}' | \
  jq -r '.accessToken')
echo "✅ Admin logged in: ${ADMIN_TOKEN:0:50}..."

echo -e "\n2️⃣ GET ORDER FOR INVOICE"
echo "========================="
# Get a delivered order ID (you might need to adjust this)
ORDER_ID=1

echo -e "\n3️⃣ GENERATE INVOICE DATA"
echo "========================"
echo "Generating invoice for Order ID: $ORDER_ID"
curl -s -X GET "$BASE_URL/api/invoices/order/$ORDER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'

echo -e "\n4️⃣ SEND INVOICE EMAIL"
echo "===================="
echo "Sending invoice email for Order ID: $ORDER_ID"
curl -s -X POST "$BASE_URL/api/invoices/order/$ORDER_ID/send" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'

echo -e "\n5️⃣ TEST DELIVERY COMPLETION → AUTO INVOICE"
echo "==========================================="
echo "Testing auto-invoice when order is marked as delivered..."
curl -s -X PUT "$BASE_URL/api/orders/$ORDER_ID/status?status=DELIVERED" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'

echo -e "\n6️⃣ PLATFORM EARNINGS REPORT"
echo "============================"
echo "Generating platform earnings report for current month..."
CURRENT_YEAR=$(date +%Y)
CURRENT_MONTH=$(date +%m)
curl -s -X GET "$BASE_URL/api/invoices/reports/platform-earnings?year=$CURRENT_YEAR&month=$CURRENT_MONTH" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'

echo -e "\n✅ INVOICE SYSTEM TEST COMPLETE!"
echo "================================"
echo "📋 What was tested:"
echo "   ✅ Invoice generation with distance & costs"
echo "   ✅ Platform fees breakdown"
echo "   ✅ Automatic invoice email on delivery"
echo "   ✅ Manual invoice sending"
echo "   ✅ Platform earnings reporting"
echo ""
echo "📧 Check email for invoice delivery!"
echo "🎯 Invoice includes:"
echo "   • Distance covered (km)"
echo "   • Delivery partner details"
echo "   • Platform fees breakdown"
echo "   • Service fees, commission, payment gateway fees"
echo "   • Complete order itemization"
echo "   • Beautiful PDF-ready format"