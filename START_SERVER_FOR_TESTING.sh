#!/bin/bash

echo "🚀 STARTING SERVER FOR API TESTING"
echo "=================================="

cd "$(dirname "$0")"

# Check if server is already running
if netstat -ano | grep ":8082" > /dev/null 2>&1; then
    echo "✅ Server is already running on port 8082"
    echo ""
    echo "🔍 Testing server connection..."
    curl -s "$BASE_URL/api/health" > /dev/null && echo "✅ Server responding" || echo "⚠️ Server not responding properly"
    echo ""
    echo "🎯 Ready to run API tests!"
    echo "Run: ./COMPLETE_API_TEST_WORKFLOW.sh"
    exit 0
fi

echo "📦 Building and starting Spring Boot application..."
echo ""

# Navigate to backend directory
if [ -d "backend" ]; then
    cd backend
else
    echo "❌ Backend directory not found!"
    exit 1
fi

# Check if Maven is available
if ! command -v mvn >/dev/null 2>&1; then
    echo "❌ Maven not found! Please install Maven first."
    exit 1
fi

# Clean and build the project
echo "🔨 Building project with Maven..."
mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Please check Maven build errors."
    exit 1
fi

# Check if JAR file exists
JAR_FILE="target/shop-management-backend-1.0.0.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ JAR file not found: $JAR_FILE"
    echo "Build may have failed."
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "🚀 Starting Spring Boot application..."
echo "   Port: 8082"
echo "   Profile: development"
echo "   Database: PostgreSQL (localhost:5432)"
echo ""

# Start the application in background
nohup java -jar "$JAR_FILE" > ../application.log 2>&1 &
SERVER_PID=$!

echo "📋 Server started with PID: $SERVER_PID"
echo "📝 Logs available in: application.log"
echo ""

# Wait for server to start
echo "⏳ Waiting for server to start..."
for i in {1..30}; do
    if curl -s "http://localhost:8082/actuator/health" > /dev/null 2>&1; then
        echo "✅ Server started successfully!"
        echo ""
        echo "🌐 Server URLs:"
        echo "   Health Check: http://localhost:8082/actuator/health"
        echo "   API Base: http://localhost:8082/api"
        echo "   Swagger UI: http://localhost:8082/swagger-ui.html"
        echo ""
        echo "🎯 Ready to run API tests!"
        echo "Commands:"
        echo "   ./COMPLETE_API_TEST_WORKFLOW.sh    # Complete end-to-end test"
        echo "   ./GET_OTP_FROM_DATABASE.sh         # Check OTPs in database"
        echo "   tail -f application.log             # Monitor server logs"
        echo ""
        echo "📧 Make sure to check email inboxes for:"
        echo "   - OTP codes"
        echo "   - Registration confirmations"
        echo "   - Order notifications"
        echo "   - Invoices"
        exit 0
    fi
    echo "   Attempt $i/30: Server not ready yet..."
    sleep 2
done

echo "❌ Server failed to start within 60 seconds!"
echo "📝 Check logs for errors:"
echo "   tail application.log"
echo ""
echo "🔍 Troubleshooting:"
echo "   1. Check if PostgreSQL is running"
echo "   2. Verify database connection settings"
echo "   3. Check if port 8082 is available"
echo "   4. Review application.log for detailed errors"

exit 1