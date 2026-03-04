// ============================================
// 04 - SPIKE TEST
// ============================================
// Purpose: Simulate sudden traffic spike
//          Example: After WhatsApp promotion goes viral
//          Tests how server handles sudden load
// Run:     k6 run 04-spike-test.js
// ============================================

import http from "k6/http";
import { check, sleep } from "k6";
import { CONFIG } from "./config.js";

export const options = {
  stages: [
    // Normal traffic
    { duration: "1m", target: 10 },

    // SPIKE! Suddenly 300 users (WhatsApp forward went viral!)
    { duration: "10s", target: 300 },

    // Hold spike
    { duration: "1m", target: 300 },

    // Spike ends
    { duration: "10s", target: 10 },

    // Normal traffic again
    { duration: "1m", target: 10 },

    // Another spike (evening orders)
    { duration: "10s", target: 200 },
    { duration: "1m", target: 200 },
    { duration: "10s", target: 0 },
  ],

  thresholds: {
    http_req_duration: ["p(95)<3000"], // During spike, allow up to 3s
    http_req_failed: ["rate<0.10"], // Allow up to 10% failure during spike
  },
};

export default function () {
  const responses = http.batch([
    ["GET", `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`],
    ["GET", CONFIG.FRONTEND_URL],
  ]);

  responses.forEach((res, i) => {
    check(res, {
      [`request ${i}: status 200`]: (r) => r.status === 200,
    });
  });

  sleep(Math.random() * 2 + 0.5);
}

/*
WHAT TO LOOK FOR:
=================
1. Does the server crash during spike? (502/503 errors)
2. How long does it take to recover after spike?
3. Does PostgreSQL connection pool run out?
4. Does Docker container get OOM killed?

REAL SCENARIO:
  You send a WhatsApp broadcast about a sale
  200 people click the link within 1 minute
  Your server must handle this spike!

MITIGATION STRATEGIES:
  1. Rate limiting in Nginx
  2. CDN for static files (Cloudflare)
  3. Connection pooling for DB
  4. Queue system for heavy operations
  5. Auto-scaling (advanced)
*/
