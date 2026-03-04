#!/bin/bash
# ============================================
# 09 - LOAD BALANCER TEST
# ============================================
# Purpose: Test if load balancer distributes traffic evenly
#          across multiple backend instances
# Run:     bash 09-load-balancer-test.sh
#
# Prerequisites: Multiple backend containers running
#   docker-compose up -d --scale backend=3
# ============================================

BASE_URL="https://api.YOUR_DOMAIN.com"

echo "============================================"
echo "  Load Balancer Distribution Test"
echo "============================================"
echo ""

# --------- Test 1: Check which backend handles each request ---------
echo "--- Test 1: Backend Distribution ---"
echo "Sending 20 requests to check which backend handles them..."
echo "(Look at the response headers for server identification)"
echo ""

for ((i=1; i<=20; i++)); do
    # The X-Served-By header (if configured) tells which backend
    response=$(curl -s -I "$BASE_URL/actuator/health" 2>/dev/null | grep -i "x-served-by\|server\|x-upstream")
    echo "Request $i: $response"
done

echo ""

# --------- Test 2: Sticky Sessions Test ---------
echo "--- Test 2: Session Stickiness Test ---"
echo "Testing if same client goes to same backend..."
echo "(With JWT auth, this shouldn't matter - but good to know)"
echo ""

for ((i=1; i<=5; i++)); do
    result=$(curl -s -o /dev/null -w "Status: %{http_code} | IP: %{remote_ip} | Time: %{time_total}s" \
        "$BASE_URL/actuator/health")
    echo "Request $i: $result"
done

echo ""

# --------- Test 3: Failover Test ---------
echo "--- Test 3: Failover Simulation ---"
echo "This test checks what happens when one backend goes down."
echo ""
echo "MANUAL STEPS:"
echo "1. Run this script in one terminal"
echo "2. In another terminal, stop one backend:"
echo "   docker stop backend-1"
echo "3. Watch if requests still succeed (they should!)"
echo "4. Start it back: docker start backend-1"
echo ""

echo "Sending requests every 2 seconds for 30 seconds..."
echo "Stop a backend container during this time to test failover."
echo ""

for ((i=1; i<=15; i++)); do
    start_time=$(date +%s%N)
    status=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health")
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))

    timestamp=$(date +"%H:%M:%S")

    if [ "$status" = "200" ]; then
        echo "[$timestamp] Request $i: OK (${duration}ms)"
    elif [ "$status" = "502" ]; then
        echo "[$timestamp] Request $i: 502 BAD GATEWAY - Backend down! (${duration}ms)"
    elif [ "$status" = "503" ]; then
        echo "[$timestamp] Request $i: 503 SERVICE UNAVAILABLE (${duration}ms)"
    else
        echo "[$timestamp] Request $i: Status $status (${duration}ms)"
    fi

    sleep 2
done

echo ""

# --------- Test 4: Round Robin Verification ---------
echo "--- Test 4: Round Robin Verification ---"
echo ""
echo "To verify round-robin, add this to your Nginx config:"
echo ""
echo '  # Add to each backend in upstream block:'
echo '  # server localhost:8080; -> add_header X-Backend "8080";'
echo '  # server localhost:8081; -> add_header X-Backend "8081";'
echo '  # server localhost:8082; -> add_header X-Backend "8082";'
echo ""
echo "Or add this to your Spring Boot application:"
echo ""
echo '  @RestController'
echo '  public class InfoController {'
echo '      @Value("${server.port}")'
echo '      private String port;'
echo ''
echo '      @GetMapping("/api/server-info")'
echo '      public Map<String, String> serverInfo() {'
echo '          return Map.of('
echo '              "port", port,'
echo '              "hostname", InetAddress.getLocalHost().getHostName()'
echo '          );'
echo '      }'
echo '  }'
echo ""

echo "============================================"
echo "  LOAD BALANCER TEST COMPLETE"
echo "============================================"
echo ""
echo "Key Observations:"
echo "  - If all requests go to same backend: Load balancing is NOT working"
echo "  - If requests alternate between backends: Round Robin working"
echo "  - If one backend dies and requests still succeed: Failover working"
echo "  - If 502 errors appear when backend dies: Health check interval too long"
