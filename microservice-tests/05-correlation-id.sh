#!/bin/bash
# ============================================
# Pattern 5: Correlation ID / Distributed Tracing
# ============================================
# What: Generate unique trace ID (UUID) for each request. Pass it across services.
# Why: When debugging, trace one request across both servers using the same ID.
#
# Test: Send request with X-Correlation-ID → get same ID back in response header.
# ============================================

USER_SERVICE_URL="https://user-api.nammaoorudelivary.in"
API_KEY="nammaooru-internal-secret-2024"

echo "============================================"
echo "  Pattern 5: Correlation ID"
echo "============================================"
echo ""

# Test 1: Send request WITHOUT Correlation ID → should get auto-generated one in response
echo "--- Test 1: Request WITHOUT Correlation ID (auto-generate) ---"
RESPONSE_HEADERS=$(curl -s -D - -o /dev/null "$USER_SERVICE_URL/actuator/health")
CORRELATION_ID=$(echo "$RESPONSE_HEADERS" | grep -i "X-Correlation-ID" | tr -d '\r' | awk '{print $2}')
echo "Response X-Correlation-ID: $CORRELATION_ID"
if [ -n "$CORRELATION_ID" ]; then
    echo "✓ PASS — Correlation ID auto-generated: $CORRELATION_ID"
else
    echo "✗ FAIL — No Correlation ID in response"
fi
echo ""

# Test 2: Send request WITH Correlation ID → should get SAME ID back
echo "--- Test 2: Request WITH Correlation ID (pass-through) ---"
MY_CORRELATION_ID="test-trace-$(date +%s)"
RESPONSE_HEADERS=$(curl -s -D - -o /dev/null -H "X-Correlation-ID: $MY_CORRELATION_ID" "$USER_SERVICE_URL/actuator/health")
RETURNED_ID=$(echo "$RESPONSE_HEADERS" | grep -i "X-Correlation-ID" | tr -d '\r' | awk '{print $2}')
echo "Sent:     $MY_CORRELATION_ID"
echo "Received: $RETURNED_ID"
if [ "$MY_CORRELATION_ID" = "$RETURNED_ID" ]; then
    echo "✓ PASS — Same Correlation ID returned"
else
    echo "✗ FAIL — Correlation ID mismatch"
fi
echo ""

# Test 3: Two different requests get different Correlation IDs
echo "--- Test 3: Two requests get DIFFERENT Correlation IDs ---"
ID1=$(curl -s -D - -o /dev/null "$USER_SERVICE_URL/actuator/health" | grep -i "X-Correlation-ID" | tr -d '\r' | awk '{print $2}')
ID2=$(curl -s -D - -o /dev/null "$USER_SERVICE_URL/actuator/health" | grep -i "X-Correlation-ID" | tr -d '\r' | awk '{print $2}')
echo "Request 1 ID: $ID1"
echo "Request 2 ID: $ID2"
if [ "$ID1" != "$ID2" ] && [ -n "$ID1" ] && [ -n "$ID2" ]; then
    echo "✓ PASS — Each request gets a unique Correlation ID"
else
    echo "✗ FAIL — IDs are same or empty"
fi
echo ""
echo "============================================"
echo "  Correlation ID Tests Complete"
echo "============================================"
echo ""
echo "To verify in logs, SSH to user-service server and run:"
echo "  docker logs user-service --tail 20"
echo "Look for: [test-trace-xxxxx] in the log lines"
