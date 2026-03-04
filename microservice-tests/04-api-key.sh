#!/bin/bash
# ============================================
# Pattern 4: API Key Security
# ============================================
# What: Monolith sends X-API-Key header. User-service validates it on /internal/** endpoints.
# Why: Without this, anyone who knows the IP can call internal endpoints.
#
# Test: Call internal endpoint without key → 401. With correct key → 200.
# ============================================

MONOLITH_URL="https://api.nammaoorudelivary.in"
USER_SERVICE_URL="https://user-api.nammaoorudelivary.in"
API_KEY="nammaooru-internal-secret-2024"

echo "============================================"
echo "  Pattern 4: API Key Security"
echo "============================================"
echo ""

# Test 1: Without API Key → should get 401
echo "--- Test 1: Call /internal/users/1 WITHOUT API key ---"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$USER_SERVICE_URL/internal/users/1")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")
echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "401" ]; then
    echo "✓ PASS — Correctly rejected without API key"
else
    echo "✗ FAIL — Expected 401, got $HTTP_CODE"
fi
echo ""

# Test 2: With WRONG API Key → should get 401
echo "--- Test 2: Call /internal/users/1 WITH WRONG API key ---"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "X-API-Key: wrong-key-12345" "$USER_SERVICE_URL/internal/users/1")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")
echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "401" ]; then
    echo "✓ PASS — Correctly rejected wrong API key"
else
    echo "✗ FAIL — Expected 401, got $HTTP_CODE"
fi
echo ""

# Test 3: With CORRECT API Key → should pass (200 or 404, but NOT 401)
echo "--- Test 3: Call /internal/users/1 WITH CORRECT API key ---"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -H "X-API-Key: $API_KEY" "$USER_SERVICE_URL/internal/users/1")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")
echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" != "401" ]; then
    echo "✓ PASS — API key accepted (HTTP $HTTP_CODE)"
else
    echo "✗ FAIL — API key was rejected"
fi
echo ""

# Test 4: Non-internal endpoint should work without API key
echo "--- Test 4: Call /actuator/health WITHOUT API key (should work) ---"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$USER_SERVICE_URL/actuator/health")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")
echo "Response: $BODY"
echo "HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ PASS — Non-internal endpoints are not protected"
else
    echo "✗ FAIL — Expected 200, got $HTTP_CODE"
fi
echo ""
echo "============================================"
echo "  API Key Security Tests Complete"
echo "============================================"
