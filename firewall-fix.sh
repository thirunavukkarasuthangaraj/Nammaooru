#!/bin/bash
echo "=== FIREWALL FIX FOR SHOP MANAGEMENT SYSTEM ==="
echo "This script will open ports 80 and 8082 for external access"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo bash firewall-fix.sh"
    exit 1
fi

echo "1. Opening ports with UFW (if available)..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 8082/tcp
    ufw --force enable
    echo "✅ UFW rules added"
else
    echo "⚠️ UFW not available"
fi

echo ""
echo "2. Opening ports with iptables..."
# Allow HTTP (port 80)
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
# Allow Backend API (port 8082)
iptables -I INPUT -p tcp --dport 8082 -j ACCEPT

echo "✅ Iptables rules added"

echo ""
echo "3. Saving iptables rules..."
# Save rules depending on the system
if command -v iptables-save &> /dev/null; then
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
    iptables-save > /etc/sysconfig/iptables 2>/dev/null || \
    echo "⚠️ Could not save iptables rules automatically"
fi

echo ""
echo "4. Current iptables rules for ports 80 and 8082:"
iptables -L INPUT -n | grep -E '80|8082' || echo "No rules found"

echo ""
echo "5. Testing connectivity..."
sleep 2
echo "Testing localhost:80..."
curl -I http://localhost 2>&1 | head -1 || echo "localhost:80 failed"
echo "Testing external access..."
curl -I http://65.21.4.236 2>&1 | head -1 || echo "External access still failing"

echo ""
echo "=== FIREWALL FIX COMPLETED ==="
echo ""
echo "If still not working:"
echo "1. Check Hetzner Cloud Security Groups (if using Hetzner Cloud)"
echo "2. Check if containers are actually running: docker ps"
echo "3. Check container logs: docker logs shop-frontend"
echo "4. Restart Docker containers: docker-compose down && docker-compose up -d"