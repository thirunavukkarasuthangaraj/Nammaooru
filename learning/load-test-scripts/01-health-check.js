// ============================================
// 01 - HEALTH CHECK LOAD TEST
// ============================================
// Purpose: Verify server is responding under basic load
// Run:     k6 run 01-health-check.js
// ============================================

import http from "k6/http";
import { check, sleep } from "k6";
import { CONFIG } from "./config.js";

// Test configuration
export const options = {
  // Ramp up from 0 to 50 users over 30 seconds, hold for 1 minute
  stages: [
    { duration: "30s", target: 10 }, // Warm up: 0 -> 10 users
    { duration: "1m", target: 50 }, // Ramp up: 10 -> 50 users
    { duration: "30s", target: 50 }, // Hold: 50 users for 30 seconds
    { duration: "30s", target: 0 }, // Ramp down: 50 -> 0 users
  ],

  // Pass/fail thresholds
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests under 500ms
    http_req_failed: ["rate<0.01"], // Less than 1% error rate
  },
};

export default function () {
  // Test 1: Health endpoint
  const healthRes = http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`);

  check(healthRes, {
    "health status is 200": (r) => r.status === 200,
    "health response time < 500ms": (r) => r.timings.duration < 500,
    "health body contains UP": (r) => r.body.includes("UP"),
  });

  // Test 2: Frontend loads
  const frontendRes = http.get(CONFIG.FRONTEND_URL);

  check(frontendRes, {
    "frontend status is 200": (r) => r.status === 200,
    "frontend response time < 1000ms": (r) => r.timings.duration < 1000,
  });

  sleep(1); // Wait 1 second between iterations (simulates real user)
}

// This runs after the test ends
export function handleSummary(data) {
  console.log("\n============= RESULTS =============");
  console.log(
    `Total Requests: ${data.metrics.http_reqs.values.count}`
  );
  console.log(
    `Avg Response Time: ${data.metrics.http_req_duration.values.avg.toFixed(2)}ms`
  );
  console.log(
    `95th Percentile: ${data.metrics.http_req_duration.values["p(95)"].toFixed(2)}ms`
  );
  console.log(
    `Error Rate: ${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%`
  );
  console.log("====================================\n");
  return {};
}
