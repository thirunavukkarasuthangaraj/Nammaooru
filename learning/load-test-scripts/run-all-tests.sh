#!/bin/bash
# ============================================
# RUN ALL LOAD TESTS (Quick Version)
# ============================================
# Runs a subset of each test to get a quick overview
# For full tests, run each script individually
# ============================================

echo "============================================"
echo "  YourApp - Complete Load Test Suite"
echo "============================================"
echo "  Server: https://api.YOUR_DOMAIN.com"
echo "  Date: $(date)"
echo "============================================"
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo "ERROR: k6 is not installed!"
    echo "Install: https://k6.io/docs/get-started/installation/"
    echo ""
    echo "Quick install:"
    echo "  Ubuntu:  snap install k6"
    echo "  Windows: choco install k6"
    echo "  Mac:     brew install k6"
    exit 1
fi

echo "Step 1/5: Health Check Test (30 seconds)"
echo "---"
k6 run --duration 30s --vus 10 01-health-check.js 2>&1 | tail -20
echo ""
echo "Press Enter to continue to next test..."
read

echo "Step 2/5: Multi-API Load Test (1 minute)"
echo "---"
k6 run --duration 1m --vus 20 02-api-load-test.js 2>&1 | tail -20
echo ""
echo "Press Enter to continue..."
read

echo "Step 3/5: Quick Stress Test (2 minutes)"
echo "---"
k6 run 03-stress-test.js 2>&1 | tail -30
echo ""
echo "Press Enter to continue..."
read

echo "Step 4/5: Concurrent curl Test"
echo "---"
bash 08-concurrent-api-test.sh
echo ""
echo "Press Enter to continue..."
read

echo "Step 5/5: Full Scenario Test (9 minutes)"
echo "---"
k6 run 10-full-scenario-test.js 2>&1 | tail -40
echo ""

echo "============================================"
echo "  ALL TESTS COMPLETE"
echo "============================================"
echo ""
echo "Review the results above. Key metrics to check:"
echo "  1. p(95) response time should be < 500ms"
echo "  2. Error rate should be < 1%"
echo "  3. Requests/sec should be > 50"
echo ""
echo "If any tests failed, check:"
echo "  - Server logs: ssh root@YOUR_SERVER_IP 'docker logs backend'"
echo "  - Nginx logs:  ssh root@YOUR_SERVER_IP 'tail /var/log/nginx/error.log'"
echo "  - Resources:   ssh root@YOUR_SERVER_IP 'docker stats --no-stream'"
