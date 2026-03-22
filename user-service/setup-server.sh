#!/bin/bash
# ============================================
# User Service - Server Setup Script
# Run this on your new server (46.225.224.191)
# ============================================

echo "========================================="
echo "  User Service - Server Setup"
echo "========================================="

# Step 1: Update system
echo ""
echo "[1/6] Updating system..."
apt update && apt upgrade -y

# Step 2: Install Java 17
echo ""
echo "[2/6] Installing Java 17..."
apt install -y openjdk-17-jdk maven git curl

echo "Java version:"
java -version

# Step 3: Install PostgreSQL
echo ""
echo "[3/6] Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Start PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Step 4: Create database
echo ""
echo "[4/6] Creating user_db database..."
sudo -u postgres psql -c "CREATE DATABASE user_db;" 2>/dev/null || echo "Database may already exist"
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

# Allow local connections with password
PG_HBA=$(sudo -u postgres psql -t -c "SHOW hba_file;" | xargs)
if [ -f "$PG_HBA" ]; then
    # Change peer to md5 for local connections
    sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$PG_HBA"
    systemctl restart postgresql
fi

echo "Database created successfully!"

# Step 5: Create app directory
echo ""
echo "[5/6] Setting up application directory..."
mkdir -p /opt/user-service
cd /opt/user-service

# Step 6: Create run script
echo ""
echo "[6/6] Creating run scripts..."

cat > /opt/user-service/start.sh << 'STARTEOF'
#!/bin/bash
cd /opt/user-service

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo "Starting User Service on port 8081..."
echo "Database: user_db"
echo "Press Ctrl+C to stop"
echo ""

mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xms128m -Xmx256m"
STARTEOF

cat > /opt/user-service/start-background.sh << 'BGEOF'
#!/bin/bash
cd /opt/user-service

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

echo "Starting User Service in background..."

nohup mvn spring-boot:run \
    -Dspring-boot.run.jvmArguments="-Xms128m -Xmx256m" \
    > /opt/user-service/app.log 2>&1 &

echo $! > /opt/user-service/app.pid
echo "Started! PID: $(cat app.pid)"
echo "Logs: tail -f /opt/user-service/app.log"
BGEOF

cat > /opt/user-service/stop.sh << 'STOPEOF'
#!/bin/bash
if [ -f /opt/user-service/app.pid ]; then
    PID=$(cat /opt/user-service/app.pid)
    echo "Stopping User Service (PID: $PID)..."
    kill $PID 2>/dev/null
    rm /opt/user-service/app.pid
    echo "Stopped!"
else
    echo "No PID file found. Trying to find process..."
    pkill -f "user-service" 2>/dev/null
    echo "Done"
fi
STOPEOF

cat > /opt/user-service/status.sh << 'STATUSEOF'
#!/bin/bash
echo "=== User Service Status ==="
if [ -f /opt/user-service/app.pid ]; then
    PID=$(cat /opt/user-service/app.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Status: RUNNING (PID: $PID)"
        curl -s http://localhost:8081/api/version 2>/dev/null && echo "" || echo "Service not responding yet..."
    else
        echo "Status: STOPPED (stale PID file)"
    fi
else
    echo "Status: STOPPED"
fi
STATUSEOF

chmod +x /opt/user-service/*.sh

# Create .env template
cat > /opt/user-service/.env << 'ENVEOF'
# Database
DB_URL=jdbc:postgresql://localhost:5432/user_db
DB_USERNAME=postgres
DB_PASSWORD=postgres

# JWT Secret (MUST match your old server!)
JWT_SECRET=CHANGE_THIS_TO_MATCH_OLD_SERVER

# Email
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=noreplay@nammaoorudelivary.in
MAIL_PASSWORD=CHANGE_THIS

# SMS (MSG91)
MSG91_AUTH_KEY=CHANGE_THIS
MSG91_SENDER_ID=NAMMAO
MSG91_OTP_TEMPLATE_ID=CHANGE_THIS
MSG91_FORGOT_PASSWORD_TEMPLATE_ID=CHANGE_THIS
SMS_ENABLED=false
ENVEOF

# Open firewall port 8081
echo ""
echo "Opening port 8081..."
ufw allow 8081/tcp 2>/dev/null || true

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Copy your code to this server:"
echo "     scp -r user-service/* root@46.225.224.191:/opt/user-service/"
echo ""
echo "  2. Edit .env file:"
echo "     nano /opt/user-service/.env"
echo "     - Set JWT_SECRET (same as old server)"
echo "     - Set MAIL_PASSWORD"
echo "     - Set MSG91_AUTH_KEY"
echo ""
echo "  3. Start the service:"
echo "     cd /opt/user-service"
echo "     ./start.sh              # foreground (see logs)"
echo "     ./start-background.sh   # background (daemon)"
echo ""
echo "  4. Test:"
echo "     curl http://localhost:8081/api/version"
echo ""
echo "  Helper commands:"
echo "     ./stop.sh       # stop service"
echo "     ./status.sh     # check status"
echo "     tail -f app.log # view logs"
echo "========================================="
