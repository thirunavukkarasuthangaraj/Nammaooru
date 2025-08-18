@echo off
echo 🚀 Building Shop Management System...

REM Create .env file if it doesn't exist
if not exist .env (
    echo 📝 Creating .env file from example...
    copy .env.example .env
    echo ⚠️  Please update .env file with your configuration
)

REM Build and start services
echo 🐳 Building Docker images...
docker-compose build --no-cache

echo 🌟 Starting services...
docker-compose up -d

REM Wait for services to be healthy
echo ⏳ Waiting for services to start...
timeout /t 30 /nobreak > nul

REM Check service health
echo 🏥 Checking service health...
docker-compose ps

REM Show logs
echo 📋 Recent logs:
docker-compose logs --tail=20

echo ✅ Build complete!
echo 📱 Frontend: http://localhost
echo 🔧 Backend: http://localhost:8082
echo 🗄️  Database: localhost:5432
echo.
echo 📖 Useful commands:
echo   docker-compose logs -f          # Follow logs
echo   docker-compose down             # Stop all services
echo   docker-compose restart backend  # Restart backend only

pause