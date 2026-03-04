// ============================================
// 07 - REAL USER JOURNEY SIMULATION
// ============================================
// Purpose: Simulate complete user journey through the app
//          Customer: Browse -> Select Shop -> View Products -> Order
//          This is the most realistic test!
// Run:     k6 run 07-real-user-simulation.js
// ============================================

import http from "k6/http";
import { check, sleep, group } from "k6";
import { Trend, Counter } from "k6/metrics";
import { CONFIG, authHeaders } from "./config.js";

// Custom metrics per step
const loginTime = new Trend("login_duration");
const browseTime = new Trend("browse_duration");
const orderTime = new Trend("order_duration");
const journeyErrors = new Counter("journey_errors");

export const options = {
  // Simulate 20 users browsing the app simultaneously
  stages: [
    { duration: "30s", target: 5 },
    { duration: "2m", target: 20 },
    { duration: "1m", target: 20 },
    { duration: "30s", target: 0 },
  ],

  thresholds: {
    login_duration: ["p(95)<1000"],
    browse_duration: ["p(95)<800"],
    http_req_failed: ["rate<0.05"],
  },
};

export default function () {
  // ==========================================
  // STEP 1: User opens the app (Frontend load)
  // ==========================================
  group("Step 1: Open App", function () {
    const res = http.get(CONFIG.FRONTEND_URL);
    check(res, {
      "app loaded": (r) => r.status === 200,
    });
    sleep(2); // User looks at the landing page
  });

  // ==========================================
  // STEP 2: User logs in
  // ==========================================
  group("Step 2: Login", function () {
    const loginPayload = JSON.stringify({
      username: CONFIG.TEST_USER.username,
      password: CONFIG.TEST_USER.password,
    });

    const res = http.post(
      `${CONFIG.BASE_URL}/api/auth/login`,
      loginPayload,
      {
        headers: { "Content-Type": "application/json" },
      }
    );

    loginTime.add(res.timings.duration);

    const success = check(res, {
      "login successful": (r) => r.status === 200,
      "login has token": (r) => {
        try {
          return JSON.parse(r.body).token !== undefined;
        } catch {
          return false;
        }
      },
    });

    if (!success) {
      journeyErrors.add(1);
      console.log(`Login failed: ${res.status} - ${res.body.substring(0, 100)}`);
      return; // Can't continue without login
    }

    sleep(1); // User sees dashboard
  });

  // ==========================================
  // STEP 3: Browse shops
  // ==========================================
  group("Step 3: Browse Shops", function () {
    const res = http.get(
      `${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.shops}`,
      authHeaders()
    );

    browseTime.add(res.timings.duration);

    check(res, {
      "shops loaded": (r) => r.status === 200,
      "shops response fast": (r) => r.timings.duration < 800,
    });

    sleep(3); // User scrolls through shops
  });

  // ==========================================
  // STEP 4: View a specific shop
  // ==========================================
  group("Step 4: View Shop Details", function () {
    // Replace with a real shop ID from your database
    const shopId = 1;
    const res = http.get(
      `${CONFIG.BASE_URL}/api/shops/${shopId}`,
      authHeaders()
    );

    check(res, {
      "shop details loaded": (r) => r.status === 200 || r.status === 404,
    });

    sleep(2); // User reads shop details
  });

  // ==========================================
  // STEP 5: Browse products
  // ==========================================
  group("Step 5: Browse Products", function () {
    const shopId = 1;
    const res = http.get(
      `${CONFIG.BASE_URL}/api/shops/${shopId}/products`,
      authHeaders()
    );

    check(res, {
      "products loaded": (r) => r.status === 200 || r.status === 404,
    });

    sleep(5); // User browses products (takes time)
  });

  // ==========================================
  // STEP 6: Check health (background monitoring)
  // ==========================================
  group("Step 6: Health Check", function () {
    const res = http.get(`${CONFIG.BASE_URL}${CONFIG.ENDPOINTS.health}`);
    check(res, {
      "server healthy": (r) => r.status === 200,
    });
  });

  // User leaves or starts another journey
  sleep(Math.random() * 5 + 2);
}

/*
WHAT THIS SIMULATES:
====================
A real customer journey:
1. Opens the app (downloads JS/CSS)
2. Logs in (API auth)
3. Browses nearby shops (API call)
4. Clicks on a shop (API call)
5. Browses products (API call)

Each step has realistic "think time" (sleep)
20 users doing this simultaneously = realistic peak traffic

IMPORTANT:
- Update the shop IDs and endpoints to match YOUR actual API
- Create a test user specifically for load testing
- Don't use real user credentials in scripts!
*/
