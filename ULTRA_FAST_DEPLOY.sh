#!/bin/bash
# ============================================
# ULTRA FAST DEPLOYMENT - Choose your option
# ============================================

echo "🚀 NAMMAOORU DEPLOYMENT SYSTEM"
echo "=============================="
echo "Choose deployment type:"
echo "1) Full deployment (30 seconds) - Pull code + rebuild"
echo "2) Quick restart (10 seconds) - Just restart services"
echo "3) Backend only update"
echo "4) Frontend only update"
echo "5) Emergency fix - Full reset"
echo "6) Check status"
echo "7) View logs"
echo ""
read -p "Enter option (1-7): " option

cd /opt/shop-management

case $option in
    1)
        echo "⚡ Full deployment starting..."
        ./NEVER_WASTE_TIME_DEPLOY.sh
        ;;
    2)
        echo "⚡ Quick restart..."
        docker-compose restart
        echo "✅ Services restarted!"
        docker ps --format "table {{.Names}}\t{{.Status}}"
        ;;
    3)
        echo "🔧 Updating backend only..."
        git pull origin main
        docker-compose stop backend
        docker-compose build backend
        docker-compose up -d backend
        sleep 20
        curl -s http://localhost:8082/actuator/health && echo "✅ Backend healthy!" || echo "❌ Backend not responding"
        ;;
    4)
        echo "🎨 Updating frontend only..."
        git pull origin main
        docker-compose stop frontend
        docker-compose build frontend
        docker-compose up -d frontend
        echo "✅ Frontend updated!"
        ;;
    5)
        echo "🚨 Emergency reset..."
        docker-compose down -v
        docker rm -f $(docker ps -aq) 2>/dev/null || true
        ./NEVER_WASTE_TIME_DEPLOY.sh
        ;;
    6)
        echo "📊 Status check..."
        docker ps --format "table {{.Names}}\t{{.Status}}"
        echo ""
        echo "Health checks:"
        curl -s http://localhost:8082/actuator/health > /dev/null 2>&1 && echo "✅ Backend: OK" || echo "❌ Backend: DOWN"
        curl -s http://localhost:8080 > /dev/null 2>&1 && echo "✅ Frontend: OK" || echo "❌ Frontend: DOWN"
        docker exec shop-postgres pg_isready > /dev/null 2>&1 && echo "✅ Database: OK" || echo "❌ Database: DOWN"
        docker exec shop-redis redis-cli ping > /dev/null 2>&1 && echo "✅ Redis: OK" || echo "❌ Redis: DOWN"
        ;;
    7)
        echo "📜 View logs (Ctrl+C to exit)..."
        echo "1) All logs"
        echo "2) Backend logs"
        echo "3) Frontend logs"
        echo "4) Database logs"
        read -p "Enter option: " log_option
        case $log_option in
            1) docker-compose logs -f ;;
            2) docker-compose logs -f backend ;;
            3) docker-compose logs -f frontend ;;
            4) docker-compose logs -f postgres ;;
            *) docker-compose logs -f ;;
        esac
        ;;
    *)
        echo "Invalid option!"
        ;;
esac