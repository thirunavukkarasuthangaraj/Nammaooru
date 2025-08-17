#!/bin/bash

echo "🔍 OTP VERIFICATION HELPER"
echo "=========================="

# Database connection details
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="shop_management_db"
DB_USER="postgres"
DB_PASSWORD="password"

echo "📧 Email addresses used in test:"
echo "   - thiruna2394@gmail.com"
echo "   - thiru.t@gmail.com"
echo "   - helec60392@jobzyy.com"
echo "   - thoruncse75@gmail.com"
echo ""

echo "🔍 Getting latest OTPs from database..."
echo ""

# Try to connect to PostgreSQL and get OTPs
if command -v psql >/dev/null 2>&1; then
    echo "📊 Recent OTPs from mobile_otp table:"
    echo "====================================="
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        email,
        otp_code,
        is_verified,
        expires_at,
        created_at
    FROM mobile_otp 
    WHERE email IN ('thiruna2394@gmail.com', 'thiru.t@gmail.com', 'helec60392@jobzyy.com', 'thoruncse75@gmail.com')
    ORDER BY created_at DESC
    LIMIT 10;
    " 2>/dev/null || echo "❌ Could not connect to database directly"
    
    echo ""
    echo "📊 All recent OTPs (last 20):"
    echo "============================="
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SELECT 
        email,
        otp_code,
        is_verified,
        CASE 
            WHEN expires_at > NOW() THEN 'Valid'
            ELSE 'Expired'
        END as status,
        created_at
    FROM mobile_otp 
    ORDER BY created_at DESC
    LIMIT 20;
    " 2>/dev/null || echo "❌ Could not connect to database directly"
    
else
    echo "❌ psql command not found. Please install PostgreSQL client."
    echo ""
    echo "💡 Alternative ways to get OTP:"
    echo "   1. Check your email inbox for OTP"
    echo "   2. Use pgAdmin to query mobile_otp table"
    echo "   3. Check application logs for OTP generation"
    echo "   4. Use default test OTP: 123456"
fi

echo ""
echo "🔧 SQL Query to run manually:"
echo "=============================="
echo "SELECT email, otp_code, is_verified, expires_at, created_at"
echo "FROM mobile_otp"
echo "WHERE email IN ('thiruna2394@gmail.com', 'thiru.t@gmail.com', 'helec60392@jobzyy.com', 'thoruncse75@gmail.com')"
echo "ORDER BY created_at DESC;"
echo ""
echo "💡 If OTP verification fails, check:"
echo "   - Email sent successfully (check application logs)"
echo "   - OTP not expired (valid for 10 minutes)"
echo "   - Correct email address used"
echo "   - Database connection working"