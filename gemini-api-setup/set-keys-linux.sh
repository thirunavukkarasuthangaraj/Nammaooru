#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#  Gemini API Keys Setup Script for Linux/Mac
#  Sets environment variables and starts Spring Boot application
# ═══════════════════════════════════════════════════════════════════════

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║          🚀 Gemini API Keys Configuration for Linux/Mac               ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  STEP 1: REPLACE THESE WITH YOUR ACTUAL API KEYS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Get your keys from: https://aistudio.google.com/api-keys
#  Click "Show API key" button for each key and paste below

export GEMINI_API_KEY_1="AIzaSyA-SdjVz-rnQbPk17e9k2FSq6LY_svGB3Q"
export GEMINI_API_KEY_2="AIzaSyDvKELg3zFky3G2Pg0uN2_NV5BoIl9JiQE"
export GEMINI_API_KEY_3="AIzaSyAYqI-DsGx4QWBjyS9K8P9uSqMEcD7CmQo"
export GEMINI_API_KEY_4="AIzaSyCGt_F5WfqMZwr5UDkvOKWSuMQkkNRxoTc"

# Enable/disable Gemini AI
export GEMINI_ENABLED=true

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "✅ Environment variables exported for current session!"
echo ""
echo "API Key 1 (GB3Q): ${GEMINI_API_KEY_1:0:20}..."
echo "API Key 2 (JlQE): ${GEMINI_API_KEY_2:0:20}..."
echo "API Key 3 (CmQo): ${GEMINI_API_KEY_3:0:20}..."
echo "API Key 4 (XoTc): ${GEMINI_API_KEY_4:0:20}..."
echo ""
echo "Gemini Enabled: $GEMINI_ENABLED"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NOTE: These are session variables only (temporary)"
echo "For permanent setup, add to your ~/.bashrc or ~/.zshrc:"
echo "  export GEMINI_API_KEY_1=\"your-key-1\""
echo "  export GEMINI_API_KEY_2=\"your-key-2\""
echo "  export GEMINI_API_KEY_3=\"your-key-3\""
echo "  export GEMINI_API_KEY_4=\"your-key-4\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask user if they want to start the backend
read -p "Do you want to start the Spring Boot backend now? (Y/N): " START_BACKEND

if [[ "$START_BACKEND" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting Spring Boot application..."
    echo ""
    cd "$(dirname "$0")/../backend"
    ./mvnw spring-boot:run
else
    echo ""
    echo "Environment variables are set. Start your backend manually with:"
    echo "  cd backend"
    echo "  ./mvnw spring-boot:run"
    echo ""
fi
