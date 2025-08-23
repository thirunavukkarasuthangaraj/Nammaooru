#!/bin/bash
# ULTRA FAST DEPLOYMENT - For when code is already up to date
# Just restarts services - takes 10 seconds

echo "⚡ Quick restart in progress..."
cd /opt/shop-management
docker-compose restart
echo "✅ Done! Services restarted."
docker ps --format "table {{.Names}}\t{{.Status}}"