# 14 - Load Testing (Hands-On Practical)

## What You'll Learn
- How to load test your YourApp server
- Tools: curl, ab (Apache Bench), wrk, k6
- Test multiple API endpoints simultaneously
- Interpret results and find bottlenecks
- Real-time monitoring during tests

---

## 1. Quick Load Test with curl

### Test Single API Response Time:
```bash
# Basic response time
curl -w "\nDNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nTotal: %{time_total}s\n" \
  -o /dev/null -s https://api.YOUR_DOMAIN.com/actuator/health

# Output:
# DNS: 0.023s
# Connect: 0.156s
# TLS: 0.312s
# Total: 0.489s
```

### Test Multiple Endpoints:
```bash
# Create test script: test-endpoints.sh
#!/bin/bash
ENDPOINTS=(
  "https://api.YOUR_DOMAIN.com/actuator/health"
  "https://api.YOUR_DOMAIN.com/api/shops"
  "https://YOUR_DOMAIN.com"
)

for url in "${ENDPOINTS[@]}"; do
  echo "Testing: $url"
  curl -w "  Status: %{http_code} | Time: %{time_total}s | Size: %{size_download} bytes\n" \
    -o /dev/null -s "$url"
done
```

---

## 2. Apache Bench (ab) - Simple Load Testing

### Install:
```bash
# On your server
apt install apache2-utils

# On Windows (use WSL or download from Apache)
```

### Basic Load Tests:

```bash
# Test 1: 100 requests, 10 concurrent
ab -n 100 -c 10 https://api.YOUR_DOMAIN.com/actuator/health

# Test 2: 1000 requests, 50 concurrent (moderate load)
ab -n 1000 -c 50 https://YOUR_DOMAIN.com/

# Test 3: API with authentication header
ab -n 100 -c 10 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://api.YOUR_DOMAIN.com/api/shops

# Test 4: POST request (simulate login)
ab -n 100 -c 10 \
  -p login.json \
  -T "application/json" \
  https://api.YOUR_DOMAIN.com/api/auth/login
```

### Reading ab Results:
```
Server Software:        nginx
Server Hostname:        api.YOUR_DOMAIN.com
Server Port:            443

Document Path:          /actuator/health
Document Length:        50 bytes

Concurrency Level:      10              <-- 10 simultaneous users
Time taken for tests:   12.345 seconds  <-- Total test time
Complete requests:      1000            <-- All completed
Failed requests:        0               <-- None failed (good!)
Total transferred:      180000 bytes

Requests per second:    81.01 [#/sec]   <-- THROUGHPUT (higher = better)
Time per request:       123.4 [ms]      <-- User-perceived time
Time per request:       12.34 [ms]      <-- Server processing time per request

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       45   89  23.4     85     234
Processing:    23   34  12.1     30     189
Waiting:       22   33  11.8     29     188
Total:         68  123  28.9    115     423

Percentage of the requests served within a certain time (ms)
  50%    115    <-- 50% of requests under 115ms
  66%    128
  75%    140
  90%    165
  95%    189
  99%    312
 100%    423    <-- Slowest request: 423ms
```

---

## 3. wrk - Advanced Load Testing

### Install:
```bash
# On Ubuntu
apt install wrk

# Or build from source
git clone https://github.com/wg/wrk.git
cd wrk && make
```

### Load Tests:

```bash
# Test 1: 30 seconds, 12 threads, 100 connections
wrk -t12 -c100 -d30s https://YOUR_DOMAIN.com/

# Test 2: API endpoint with headers
wrk -t4 -c50 -d30s \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://api.YOUR_DOMAIN.com/api/shops

# Test 3: Scripted POST request
wrk -t4 -c20 -d15s -s post.lua https://api.YOUR_DOMAIN.com/api/auth/login
```

### wrk Lua Scripts for Complex Tests:

```lua
-- post.lua (Login load test)
wrk.method = "POST"
wrk.body   = '{"username":"test@example.com","password":"test123"}'
wrk.headers["Content-Type"] = "application/json"
```

```lua
-- multi-endpoint.lua (Test multiple APIs randomly)
local endpoints = {
  "/api/shops",
  "/api/categories",
  "/actuator/health"
}

request = function()
  local path = endpoints[math.random(#endpoints)]
  return wrk.format("GET", path, {
    ["Authorization"] = "Bearer YOUR_JWT_TOKEN"
  })
end

done = function(summary, latency, requests)
  io.write("-----Results-----\n")
  io.write(string.format("Requests/sec: %.2f\n", summary.requests / summary.duration * 1000000))
  io.write(string.format("Avg Latency:  %.2f ms\n", latency.mean / 1000))
  io.write(string.format("Max Latency:  %.2f ms\n", latency.max / 1000))
  io.write(string.format("Errors:       %d\n", summary.errors.status))
end
```

### Reading wrk Results:
```
Running 30s test @ https://api.YOUR_DOMAIN.com/api/shops
  12 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   234.56ms   89.12ms   1.23s    78.90%    <-- Response time
    Req/Sec    35.67     12.34    89.00     65.43%     <-- Requests per second per thread
  12345 requests in 30.00s, 45.67MB read                <-- Total
  Socket errors: connect 0, read 0, write 0, timeout 3  <-- Errors
Requests/sec:    411.50                                  <-- TOTAL throughput
Transfer/sec:      1.52MB                                <-- Bandwidth used
```

---

## 4. k6 - Modern Load Testing (Recommended)

### Install:
```bash
# On Ubuntu
snap install k6

# On Windows
choco install k6
# Or download from https://k6.io/
```

### k6 is the best tool because:
- Write tests in JavaScript
- Beautiful output
- Supports complex scenarios
- Can simulate real user behavior

---

## 5. Monitoring During Load Tests

### Run these in SEPARATE terminals while load testing:

```bash
# Terminal 1: Watch server CPU/RAM
ssh root@YOUR_SERVER_IP "htop"

# Terminal 2: Watch Docker container resources
ssh root@YOUR_SERVER_IP "docker stats"

# Terminal 3: Watch Nginx connections
ssh root@YOUR_SERVER_IP "watch -n1 'curl -s http://localhost/nginx_status'"

# Terminal 4: Watch PostgreSQL connections
ssh root@YOUR_SERVER_IP "watch -n1 \"psql -U postgres -c 'SELECT count(*) FROM pg_stat_activity;'\""

# Terminal 5: Watch error logs
ssh root@YOUR_SERVER_IP "tail -f /var/log/nginx/error.log"
```

---

## 6. Test Scenarios for YourApp

### Scenario 1: Normal Day (50 concurrent users)
```bash
ab -n 5000 -c 50 https://api.YOUR_DOMAIN.com/actuator/health
# Expected: <200ms response, 0 errors
```

### Scenario 2: Peak Hours (200 concurrent users)
```bash
ab -n 10000 -c 200 https://api.YOUR_DOMAIN.com/actuator/health
# Watch for: response time increase, errors
```

### Scenario 3: Find Breaking Point
```bash
# Gradually increase load
for c in 10 50 100 200 500 1000; do
  echo "=== Testing with $c concurrent connections ==="
  ab -n 2000 -c $c -q https://api.YOUR_DOMAIN.com/actuator/health 2>&1 | \
    grep -E "Requests per second|Failed requests|Time per request.*\(mean\)"
  sleep 5
done
```

### Scenario 4: WebSocket Load Test
```bash
# Install wscat
npm install -g wscat

# Connect to WebSocket
wscat -c wss://api.YOUR_DOMAIN.com/ws

# For load testing WebSocket, use k6:
# (see load-test-scripts/ folder)
```

---

## 7. Interpreting Results

### Good Performance:
```
Response time:  < 200ms (95th percentile)
Error rate:     0%
Throughput:     > 100 req/sec
CPU usage:      < 70%
RAM usage:      < 80%
DB connections: < 80% of pool size
```

### Warning Signs:
```
Response time:  200-500ms   --> Optimize queries, add caching
Error rate:     < 1%        --> Check logs, fix edge cases
CPU:            70-90%      --> Consider scaling up
RAM:            80-90%      --> Check for memory leaks
```

### Critical Issues:
```
Response time:  > 1 second  --> Something is very wrong
Error rate:     > 5%        --> Server is failing
CPU:            > 95%       --> Server overwhelmed
RAM:            > 95%       --> OOM kill imminent
5xx errors:     Any         --> Backend crashing
```

---

## Key Takeaways

1. **Start with `ab`** for quick tests, graduate to `k6` for complex scenarios
2. **Always monitor server** while load testing (htop, docker stats)
3. **Test gradually** - start low, increase until you find the breaking point
4. **Focus on 95th percentile** response time, not average
5. **0% error rate** is the goal under expected load
6. **Your CX33 should handle** ~200-500 concurrent API requests comfortably

---

## See also:
- `load-test-scripts/` folder for ready-to-run scripts
- [15 - Architecture Diagram](./15-architecture-diagram.md)
