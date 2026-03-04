// ============================================
// 02 - MULTIPLE API ENDPOINT LOAD TEST
// ============================================
// Purpose: Test multiple API endpoints simultaneously
//          Simulates real traffic patterns
// Run:     k6 run 02-api-load-test.js
// ============================================

import http from "k6/http";
import { check, sleep, group } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";
import { CONFIG, authHeaders } from "./config.js";

// Custom metrics to track per endpoint
const apiErrors = new Counter("api_errors");
const shopsTrend = new Trend("shops_response_time");
const healthTrend = new Trend("health_response_time");

export const options = {
  stages: [
    { duration: "30s", target: 20 }, // Warm up
    { duration: "1m", target: 50 }, // Normal load
    { duration: "2m", target: 100 }, // Peak load
    { duration: "1m", target: 50 }, // Scale down
    { duration: "30s", target: 0 }, // Cool down
  ],

  thresholds: {
    http_req_duration: ["p(95)<1000", "p(99)<2000"],
    http_req_failed: ["rate<0.05"],
    shops_response_time: ["p(95)<800"],
    health_response_time: ["p(95)<200"],
  },
};

export default function () {
  // Randomly choose what this virtual user does
  // Simulates real traffic: 40% browse shops, 30% check categories, 20% health, 10% other
  const random = Math.random();

  if (random < 0.4) {
    // 40% - Browse shops (most common action)
    group("Browse Shops", function () {
      const res = http.get(
        `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.shops}`,
        authHeaders()
      );

      check(res, {
        "shops: status 200": (r) => r.status === 200,
        "shops: response < 1s": (r) => r.timings.duration < 1000,
        "shops: has data": (r) => r.body.length > 10,
      });

      shopsTrend.add(res.timings.duration);

      if (res.status !== 200) {
        apiErrors.add(1);
        console.log(`SHOPS ERROR: ${res.status} - ${res.body.substring(0, 200)}`);
      }
    });
  } else if (random < 0.7) {
    // 30% - Browse categories
    group("Browse Categories", function () {
      const res = http.get(
        `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.categories}`,
        authHeaders()
      );

      check(res, {
        "categories: status 200": (r) => r.status === 200,
        "categories: response < 800ms": (r) => r.timings.duration < 800,
      });

      if (res.status !== 200) {
        apiErrors.add(1);
      }
    });
  } else if (random < 0.9) {
    // 20% - Health check
    group("Health Check", function () {
      const res = http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`);

      check(res, {
        "health: status 200": (r) => r.status === 200,
        "health: response < 200ms": (r) => r.timings.duration < 200,
      });

      healthTrend.add(res.timings.duration);
    });
  } else {
    // 10% - Frontend page load
    group("Frontend Load", function () {
      const res = http.get(CONFIG.FRONTEND_URL);

      check(res, {
        "frontend: status 200": (r) => r.status === 200,
      });
    });
  }

  // Simulate user think time (1-3 seconds between actions)
  sleep(Math.random() * 2 + 1);
}
