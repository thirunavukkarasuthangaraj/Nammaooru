// ============================================
// 03 - STRESS TEST (Find Breaking Point)
// ============================================
// Purpose: Gradually increase load until server fails
//          Helps you know your server's maximum capacity
// Run:     k6 run 03-stress-test.js
// WARNING: This WILL push your server to its limits!
//          Run during low-traffic hours
// ============================================

import http from "k6/http";
import { check, sleep } from "k6";
import { CONFIG, authHeaders } from "./config.js";

export const options = {
  stages: [
    // Step 1: Light load (10 users)
    { duration: "1m", target: 10 },

    // Step 2: Moderate load (50 users)
    { duration: "1m", target: 50 },

    // Step 3: Heavy load (100 users)
    { duration: "1m", target: 100 },

    // Step 4: Very heavy (200 users)
    { duration: "1m", target: 200 },

    // Step 5: Extreme (500 users) - will likely break!
    { duration: "1m", target: 500 },

    // Step 6: Recovery - ramp down
    { duration: "2m", target: 0 },
  ],

  thresholds: {
    // We EXPECT failures in stress test
    // These thresholds help identify when it breaks
    http_req_duration: ["p(50)<1000"], // Median under 1s
    http_req_failed: ["rate<0.50"], // Less than 50% failure
  },
};

export default function () {
  // Test the API endpoint
  const res = http.get(
    `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`
  );

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response < 1s": (r) => r.timings.duration < 1000,
    "response < 3s": (r) => r.timings.duration < 3000,
    "response < 5s": (r) => r.timings.duration < 5000,
  });

  // Log when things start breaking
  if (res.status !== 200) {
    console.log(
      `FAILURE at VU=${__VU}: status=${res.status}, time=${res.timings.duration.toFixed(0)}ms`
    );
  } else if (res.timings.duration > 3000) {
    console.log(
      `SLOW at VU=${__VU}: time=${res.timings.duration.toFixed(0)}ms`
    );
  }

  sleep(0.5);
}

/*
HOW TO READ RESULTS:
====================
Watch these numbers as load increases:

10 users:  Avg ~200ms, 0% errors      --> Healthy
50 users:  Avg ~300ms, 0% errors      --> Still good
100 users: Avg ~500ms, 0% errors      --> Getting warm
200 users: Avg ~1500ms, 2% errors     --> Under pressure
500 users: Avg ~5000ms, 30% errors    --> BREAKING POINT!

Your breaking point = the number of users where:
  - Error rate exceeds 5%
  - Response time exceeds 2 seconds
  - Server CPU hits 100%

For CX33 (4 vCPU, 8GB RAM):
  Expected breaking point: ~200-500 concurrent users
  Comfortable load: ~50-100 concurrent users
*/
