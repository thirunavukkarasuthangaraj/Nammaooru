#!/bin/bash
# ============================================
# 08 - CONCURRENT API TEST (Using curl)
# ============================================
# Purpose: Quick load test using only curl (no extra tools needed)
#          Tests multiple API endpoints simultaneously
# Run:     bash 08-concurrent-api-test.sh
# ============================================

# Configuration
BASE_URL="https://api.YOUR_DOMAIN.com"
FRONTEND_URL="https://YOUR_DOMAIN.com"
JWT_TOKEN="YOUR_JWT_TOKEN_HERE"
CONCURRENT=10    # Number of simultaneous requests
TOTAL=100        # Total requests to send

echo "============================================"
echo "  YourApp Concurrent API Load Test"
echo "============================================"
echo "Server: $BASE_URL"
echo "Concurrent: $CONCURRENT requests at a time"
echo "Total: $TOTAL requests per endpoint"
echo ""

# --------- Test 1: Health Check ---------
echo "--- Test 1: Health Check Endpoint ---"
echo "Running $TOTAL requests, $CONCURRENT concurrent..."

start_time=$(date +%s%N)
success=0
fail=0

for ((i=1; i<=TOTAL; i++)); do
    (
        status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health")
        if [ "$status" = "200" ]; then
            echo "OK" >> /tmp/health_results.txt
        else
            echo "FAIL:$status" >> /tmp/health_results.txt
        fi
    ) &

    # Control concurrency
    if (( i % CONCURRENT == 0 )); then
        wait
    fi
done
wait

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

success=$(grep -c "OK" /tmp/health_results.txt 2>/dev/null || echo 0)
fail=$(grep -c "FAIL" /tmp/health_results.txt 2>/dev/null || echo 0)
rm -f /tmp/health_results.txt

echo "  Duration: ${duration}ms"
echo "  Success: $success / $TOTAL"
echo "  Failed: $fail"
echo "  Requests/sec: $(echo "scale=1; $TOTAL * 1000 / $duration" | bc 2>/dev/null || echo "N/A")"
echo ""

# --------- Test 2: Frontend Load ---------
echo "--- Test 2: Frontend (Static Files) ---"
echo "Running $TOTAL requests, $CONCURRENT concurrent..."

start_time=$(date +%s%N)

for ((i=1; i<=TOTAL; i++)); do
    (
        status=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL")
        if [ "$status" = "200" ]; then
            echo "OK" >> /tmp/frontend_results.txt
        else
            echo "FAIL:$status" >> /tmp/frontend_results.txt
        fi
    ) &

    if (( i % CONCURRENT == 0 )); then
        wait
    fi
done
wait

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

success=$(grep -c "OK" /tmp/frontend_results.txt 2>/dev/null || echo 0)
fail=$(grep -c "FAIL" /tmp/frontend_results.txt 2>/dev/null || echo 0)
rm -f /tmp/frontend_results.txt

echo "  Duration: ${duration}ms"
echo "  Success: $success / $TOTAL"
echo "  Failed: $fail"
echo ""

# --------- Test 3: API with Auth ---------
echo "--- Test 3: Authenticated API Call ---"
echo "Running $TOTAL requests, $CONCURRENT concurrent..."

start_time=$(date +%s%N)

for ((i=1; i<=TOTAL; i++)); do
    (
        result=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            "$BASE_URL/api/shops")
        echo "$result" >> /tmp/api_results.txt
    ) &

    if (( i % CONCURRENT == 0 )); then
        wait
    fi
done
wait

end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

# Calculate stats
total_time=0
count=0
while IFS='|' read -r status time; do
    if [ "$status" = "200" ]; then
        ((count++))
    fi
done < /tmp/api_results.txt 2>/dev/null

echo "  Duration: ${duration}ms"
echo "  Success: $count / $TOTAL"
echo "  Failed: $((TOTAL - count))"
rm -f /tmp/api_results.txt
echo ""

# --------- Test 4: Response Time Measurement ---------
echo "--- Test 4: Response Time Analysis ---"
echo "Measuring response times for 10 sequential requests..."
echo ""

declare -a times=()
for ((i=1; i<=10; i++)); do
    time=$(curl -s -o /dev/null -w "%{time_total}" "$BASE_URL/actuator/health")
    time_ms=$(echo "$time * 1000" | bc 2>/dev/null || echo "N/A")
    echo "  Request $i: ${time_ms}ms"
    times+=($time_ms)
done

echo ""
echo "============================================"
echo "  TEST COMPLETE"
echo "============================================"
echo ""
echo "Interpretation Guide:"
echo "  < 200ms  = Excellent"
echo "  200-500ms = Good (expected for India->Helsinki)"
echo "  500ms-1s  = Acceptable under load"
echo "  > 1s      = Needs optimization"
echo "  Any fails = Investigate server logs"
