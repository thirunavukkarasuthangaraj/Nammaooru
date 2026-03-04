// ============================================
// 05 - SOAK TEST (Endurance Test)
// ============================================
// Purpose: Run moderate load for a LONG time
//          Finds memory leaks, connection pool leaks,
//          disk space issues that only appear over hours
// Run:     k6 run 05-soak-test.js
// Duration: ~30 minutes (increase for real soak test)
// ============================================

import http from "k6/http";
import { check, sleep } from "k6";
import { CONFIG, authHeaders } from "./config.js";

export const options = {
  stages: [
    { duration: "2m", target: 30 },  // Ramp up to 30 users
    { duration: "25m", target: 30 }, // Hold 30 users for 25 minutes
    { duration: "3m", target: 0 },   // Ramp down
  ],

  // For real soak testing, change to:
  // { duration: "5m", target: 30 },
  // { duration: "4h", target: 30 },  // Hold for 4 HOURS
  // { duration: "5m", target: 0 },

  thresholds: {
    http_req_duration: ["p(95)<500"],
    http_req_failed: ["rate<0.01"],
  },
};

export default function () {
  // Simulate realistic user behavior
  const actions = [
    () => http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`),
    () => http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.shops}`, authHeaders()),
    () => http.get(CONFIG.FRONTEND_URL),
  ];

  // Pick random action
  const action = actions[Math.floor(Math.random() * actions.length)];
  const res = action();

  check(res, {
    "status is 200": (r) => r.status === 200,
    "response < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(Math.random() * 3 + 1); // 1-4 seconds between requests
}

/*
WHAT TO LOOK FOR DURING SOAK TEST:
===================================
Monitor these over time (should stay STABLE):

1. Response Time: Should NOT gradually increase
   - If it does: Possible memory leak in Spring Boot

2. Memory Usage: Should NOT keep growing
   - Run: docker stats (watch MEM USAGE)
   - If it grows: JVM memory leak, increase -Xmx or find the leak

3. Database Connections: Should NOT keep increasing
   - Run: SELECT count(*) FROM pg_stat_activity;
   - If it grows: Connection pool leak

4. Disk Space: Should NOT fill up
   - Run: df -h
   - If it fills: Log rotation needed, temp files not cleaned

5. Error Rate: Should stay at 0%
   - If errors appear after hours: timeout issues, connection exhaustion

REAL-WORLD SCENARIO:
  Your app runs all day. Some problems only appear after hours:
  - JVM heap slowly fills -> OutOfMemoryError at 3 AM
  - Log files fill disk -> Server crashes at midnight
  - Connection pool leaks -> DB refuses connections after 6 hours
*/
