// ============================================
// CONFIGURATION - UPDATE THESE VALUES!
// ============================================

export const CONFIG = {
  // Your server URLs
  BASE_URL: "https://api.YOUR_DOMAIN.com",
  FRONTEND_URL: "https://YOUR_DOMAIN.com",

  // Authentication - Get a valid JWT token from your app
  // Login to your app, open browser DevTools -> Network -> copy Authorization header
  JWT_TOKEN: "YOUR_JWT_TOKEN_HERE",

  // Test user credentials (create a test user for load testing)
  TEST_USER: {
    username: "loadtest@example.com",
    password: "loadtest123",
  },

  // API Endpoints to test
  ENDPOINTS: {
    health: "/actuator/health",
    shops: "/api/shops",
    categories: "/api/categories",
    // Add your actual endpoints here:
    // orders: "/api/orders",
    // products: "/api/products",
    // profile: "/api/users/profile",
  },

  // Thresholds (what counts as "passing")
  THRESHOLDS: {
    http_req_duration_p95: 500, // 95% of requests under 500ms
    http_req_duration_p99: 1000, // 99% of requests under 1s
    http_req_failed_rate: 0.01, // Less than 1% error rate
  },
};

// Helper function for authenticated requests
export function authHeaders() {
  return {
    headers: {
      Authorization: `Bearer ${CONFIG.JWT_TOKEN}`,
      "Content-Type": "application/json",
    },
  };
}
