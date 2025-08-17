@echo off
echo ========================================
echo   DELIVERY PARTNER SYSTEM SETUP
echo ========================================
echo.

echo Step 1: Creating database schema...
echo.
psql -U postgres -h localhost -p 5432 -d shop_management_db -f database\delivery_schema.sql
if %errorlevel% neq 0 (
    echo ERROR: Database setup failed. Please check PostgreSQL connection.
    pause
    exit /b 1
)
echo Database schema created successfully!
echo.

echo Step 2: Setting up backend dependencies...
echo.
cd backend
call mvn clean install -DskipTests
if %errorlevel% neq 0 (
    echo ERROR: Backend build failed. Please check Maven installation.
    pause
    exit /b 1
)
echo Backend dependencies installed successfully!
echo.

echo Step 3: Setting up frontend dependencies...
echo.
cd ..\frontend
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Frontend dependencies installation failed. Please check Node.js/npm.
    pause
    exit /b 1
)
echo.

echo Installing Angular PWA packages...
call ng add @angular/pwa --skip-confirmation
call npm install ng2-charts chart.js sockjs-client stompjs
echo Frontend dependencies installed successfully!
echo.

echo ========================================
echo   SETUP COMPLETED SUCCESSFULLY!
echo ========================================
echo.
echo To start the system:
echo.
echo 1. Backend:
echo    cd backend
echo    mvn spring-boot:run
echo.
echo 2. Frontend:
echo    cd frontend  
echo    ng serve
echo.
echo 3. Access the application:
echo    - Frontend: http://localhost:4200
echo    - Backend API: http://localhost:8080
echo    - WebSocket: ws://localhost:8080/ws
echo.
echo 4. Default login credentials:
echo    - Admin: admin@example.com / admin123
echo    - Shop Owner: shop@example.com / shop123
echo.
echo ========================================
echo   DELIVERY PARTNER FEATURES AVAILABLE:
echo ========================================
echo.
echo ✅ Partner Registration & Verification
echo ✅ Smart Order Assignment Algorithm  
echo ✅ Real-time GPS Tracking
echo ✅ Mobile PWA Dashboard
echo ✅ Admin Management Interface
echo ✅ Customer Tracking Portal
echo ✅ WebSocket Real-time Updates
echo ✅ Comprehensive Analytics
echo ✅ Document Verification System
echo ✅ Earnings & Performance Tracking
echo ✅ Emergency Alert System
echo ✅ Route Optimization
echo.
echo Happy delivering! 🚚📱
pause