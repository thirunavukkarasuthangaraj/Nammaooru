#!/bin/bash

# Deploy FCM + Timezone Fix to Production
# This script pulls the latest code and restarts the backend service

echo "========================================="
echo "Deploying FCM + Timezone Fix to Production"
echo "========================================="
echo "Changes being deployed:"
echo "  ✅ FCM notifications for all order statuses"
echo "  ✅ Shop owner order notifications"
echo "  ✅ Driver assignment notifications"
echo "  ✅ Asia/Kolkata timezone configuration"
echo "========================================="

# Navigate to backend directory
cd /app || { echo "Error: /app directory not found"; exit 1; }

echo ""
echo "1. Checking current git branch..."
git branch

echo ""
echo "2. Pulling latest changes from main branch..."
git pull origin main

echo ""
echo "3. Building backend (this may take a few minutes)..."
mvn clean package -DskipTests

echo ""
echo "4. Restarting shop-management service..."
systemctl restart shop-management

echo ""
echo "5. Checking service status..."
sleep 5
systemctl status shop-management --no-pager

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "Recent logs:"
journalctl -u shop-management -n 50 --no-pager

echo ""
echo "📱 To test FCM notifications:"
echo "1. Customer places order → Shop owner receives 'New Order Received! 🔔'"
echo "2. Shop marks order READY_FOR_PICKUP → Driver receives 'New Delivery Assigned! 🚚'"
echo "3. All status changes → Customer receives notifications"
echo ""
echo "🔍 Check logs in real-time:"
echo "   journalctl -u shop-management -f | grep -E 'FCM|notification|Firebase'"
echo ""
echo "🕐 Verify timezone:"
echo "   journalctl -u shop-management | grep 'Application timezone'"
echo "   Should show: 'Application timezone set to: Asia/Kolkata'"
