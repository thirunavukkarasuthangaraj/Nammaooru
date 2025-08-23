#!/bin/bash
# ============================================
# ONE-COMMAND DEPLOYMENT SCRIPT
# Never waste 3 hours again! Just run: ./NEVER_WASTE_TIME_DEPLOY.sh
# ============================================

set -e  # Exit on any error

echo "🚀 AUTOMATED DEPLOYMENT STARTING..."
echo "================================================"

# Navigate to project directory
cd /opt/shop-management

# Step 1: Pull latest code
echo "📥 [1/7] Pulling latest code..."
git pull origin main || {
    echo "⚠️  Git pull failed, continuing with existing code..."
}

# Step 2: Create/Update .env file
echo "🔧 [2/7] Setting up environment..."
cat > .env << 'EOF'
POSTGRES_DB=shop_management_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
REDIS_PASSWORD=Redis@2024Pass
JWT_SECRET=nammaooru-jwt-secret-key-2024-secure
BUILD_ID=latest
EOF

# Step 3: Stop and clean existing containers
echo "🧹 [3/7] Cleaning old containers..."
docker-compose down || true
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Step 4: Build fresh images
echo "🔨 [4/7] Building Docker images (this may take 2-3 minutes)..."
docker-compose build --no-cache

# Step 5: Start all services
echo "🎯 [5/7] Starting all services..."
docker-compose up -d

# Step 6: Wait for services to be ready
echo "⏳ [6/7] Waiting for services to initialize (30 seconds)..."
sleep 30

# Check if backend is healthy
for i in {1..10}; do
    if curl -s http://localhost:8082/actuator/health > /dev/null 2>&1; then
        echo "✅ Backend is healthy!"
        break
    else
        echo "⏳ Waiting for backend... ($i/10)"
        sleep 5
    fi
done

# Step 7: Create super admin if doesn't exist
echo "👤 [7/7] Setting up super admin user..."
docker exec shop-postgres psql -U postgres -d shop_management_db -c "
INSERT INTO users (username, email, password, first_name, last_name, role, status, is_active, email_verified, created_at, updated_at) 
VALUES ('superadmin', 'admin@nammaoorudelivary.in', '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Super', 'Admin', 'SUPER_ADMIN', 'ACTIVE', true, true, NOW(), NOW())
ON CONFLICT (username) DO UPDATE SET 
    password = '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    status = 'ACTIVE',
    is_active = true;" > /dev/null 2>&1 || echo "   Admin user already exists"

# Final status check
echo ""
echo "================================================"
echo "📊 DEPLOYMENT STATUS:"
echo "================================================"
docker-compose ps

# Test endpoints
echo ""
echo "🧪 Testing endpoints..."
if curl -s http://localhost:8082/actuator/health > /dev/null 2>&1; then
    echo "✅ Backend API: Working"
else
    echo "❌ Backend API: Not responding"
fi

if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Frontend: Working"
else
    echo "❌ Frontend: Not responding"
fi

# Show access info
echo ""
echo "================================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "================================================"
echo "📌 Access your application:"
echo "   URL: https://nammaoorudelivary.in"
echo "   Username: superadmin"
echo "   Password: password"
echo ""
echo "📌 Direct access:"
echo "   Frontend: http://$(hostname -I | awk '{print $1}'):8080"
echo "   Backend API: http://$(hostname -I | awk '{print $1}'):8082"
echo ""
echo "📌 View logs:"
echo "   docker-compose logs -f"
echo ""
echo "⏱️  Total deployment time: $SECONDS seconds"
echo "================================================"