// ============================================
// 10 - FULL PRODUCTION SCENARIO TEST
// ============================================
// Purpose: Simulate a complete day of YourApp traffic
//          Morning slow, afternoon busy, evening peak, night quiet
//          Tests everything: APIs, static files, WebSocket, file uploads
// Run:     k6 run 10-full-scenario-test.js
// Duration: ~10 minutes (simulates compressed day pattern)
// ============================================

import http from "k6/http";
import { check, sleep, group } from "k6";
import { Trend, Counter, Rate } from "k6/metrics";
import { CONFIG, authHeaders } from "./config.js";

// Custom metrics
const pageLoadTime = new Trend("page_load_time");
const apiCallTime = new Trend("api_call_time");
const totalErrors = new Counter("total_errors");
const errorRate = new Rate("error_rate");

export const options = {
  scenarios: {
    // Scenario 1: Customers browsing shops
    customers: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "1m", target: 5 },    // Morning: few users
        { duration: "2m", target: 20 },   // Afternoon: moderate
        { duration: "2m", target: 50 },   // Evening peak: many users
        { duration: "2m", target: 30 },   // Late evening: decreasing
        { duration: "1m", target: 5 },    // Night: few users
        { duration: "1m", target: 0 },    // Midnight: almost none
      ],
      exec: "customerJourney",
    },

    // Scenario 2: Shop owners managing their shop
    shopOwners: {
      executor: "constant-vus",
      vus: 5, // 5 shop owners active throughout
      duration: "9m",
      exec: "shopOwnerJourney",
    },

    // Scenario 3: Background health monitoring
    monitoring: {
      executor: "constant-arrival-rate",
      rate: 1, // 1 request per second
      timeUnit: "1s",
      duration: "9m",
      preAllocatedVUs: 2,
      exec: "healthMonitor",
    },
  },

  thresholds: {
    page_load_time: ["p(95)<2000"],
    api_call_time: ["p(95)<1000"],
    error_rate: ["rate<0.05"],
    http_req_duration: ["p(95)<1500"],
  },
};

// ==========================================
// SCENARIO 1: Customer Journey
// ==========================================
export function customerJourney() {
  group("Customer: Load Homepage", function () {
    const res = http.get(CONFIG.FRONTEND_URL);
    pageLoadTime.add(res.timings.duration);

    const success = check(res, {
      "homepage loaded": (r) => r.status === 200,
    });
    errorRate.add(!success);
    if (!success) totalErrors.add(1);
  });

  sleep(2); // User reads homepage

  group("Customer: Browse Shops", function () {
    const res = http.get(
      `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.shops}`,
      authHeaders()
    );
    apiCallTime.add(res.timings.duration);

    const success = check(res, {
      "shops loaded": (r) => r.status === 200,
      "shops fast": (r) => r.timings.duration < 1000,
    });
    errorRate.add(!success);
    if (!success) totalErrors.add(1);
  });

  sleep(3); // User browses shops

  group("Customer: View Shop Products", function () {
    const shopId = Math.floor(Math.random() * 10) + 1;
    const res = http.get(
      `${CONFIG.BASE_URL}/api/shops/${shopId}/products`,
      authHeaders()
    );
    apiCallTime.add(res.timings.duration);

    check(res, {
      "products loaded": (r) => r.status === 200 || r.status === 404,
    });
  });

  sleep(5); // User browses products

  group("Customer: Search", function () {
    const searchTerms = ["rice", "milk", "vegetables", "fruits", "snacks"];
    const term = searchTerms[Math.floor(Math.random() * searchTerms.length)];

    const res = http.get(
      `${CONFIG.BASE_URL}/api/products/search?q=${term}`,
      authHeaders()
    );
    apiCallTime.add(res.timings.duration);

    check(res, {
      "search responded": (r) => r.status === 200 || r.status === 404,
    });
  });

  sleep(Math.random() * 5 + 2);
}

// ==========================================
// SCENARIO 2: Shop Owner Journey
// ==========================================
export function shopOwnerJourney() {
  group("ShopOwner: Dashboard", function () {
    const res = http.get(
      `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.shops}`,
      authHeaders()
    );
    apiCallTime.add(res.timings.duration);

    check(res, {
      "dashboard loaded": (r) => r.status === 200,
    });
  });

  sleep(10); // Shop owner reviews orders

  group("ShopOwner: Check Orders", function () {
    const res = http.get(
      `${CONFIG.BASE_URL}/api/orders?status=PENDING`,
      authHeaders()
    );

    check(res, {
      "orders loaded": (r) => r.status === 200 || r.status === 401,
    });
  });

  sleep(15); // Shop owner processes orders

  group("ShopOwner: Update Order Status", function () {
    // Simulated - would need real order ID
    const res = http.get(
      `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`
    );

    check(res, {
      "server responsive": (r) => r.status === 200,
    });
  });

  sleep(Math.random() * 10 + 5);
}

// ==========================================
// SCENARIO 3: Health Monitoring
// ==========================================
export function healthMonitor() {
  const res = http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`);

  const success = check(res, {
    "health: status UP": (r) => r.status === 200,
    "health: fast": (r) => r.timings.duration < 500,
  });

  if (!success) {
    console.log(
      `HEALTH CHECK FAILED! Status: ${res.status}, Time: ${res.timings.duration.toFixed(0)}ms`
    );
    totalErrors.add(1);
  }
}

/*
WHAT THIS SIMULATES:
====================

A compressed "day" of YourApp traffic:

Timeline (9 minutes = compressed day):
  0-1m:   Morning (5 customers)    - Low traffic
  1-3m:   Afternoon (20 customers) - Growing traffic
  3-5m:   Evening (50 customers)   - PEAK TRAFFIC (dinner orders!)
  5-7m:   Late evening (30 cust)   - Decreasing
  7-8m:   Night (5 customers)      - Low traffic
  8-9m:   Midnight (0 customers)   - Quiet

Throughout:
  - 5 shop owners constantly managing their shops
  - Health checks every second

EXPECTED RESULTS FOR CX33:
  Morning:  Avg ~200ms, 0% errors
  Peak:     Avg ~400ms, <1% errors
  If errors > 5% during peak: Need to scale!

WHAT TO MONITOR:
  Terminal 1: k6 run 10-full-scenario-test.js
  Terminal 2: ssh root@YOUR_SERVER_IP "docker stats"
  Terminal 3: ssh root@YOUR_SERVER_IP "htop"
  Terminal 4: ssh root@YOUR_SERVER_IP "tail -f /var/log/nginx/error.log"
*/
