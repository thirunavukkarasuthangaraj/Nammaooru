#!/usr/bin/env python3
"""
Show existing data for auto-assignment demonstration
"""

import requests
import json

def test_backend_health():
    """Test if backend is running and show basic info"""
    try:
        response = requests.get("http://localhost:8080/actuator/health", timeout=5)
        print(f"Backend Health Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Backend is running successfully")
            return True
        else:
            print("❌ Backend health check failed")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to backend: {e}")
        return False

def show_auto_assignment_summary():
    """Show what we know about the auto-assignment system"""
    print("\n" + "="*60)
    print("AUTO-ASSIGNMENT API SYSTEM OVERVIEW")
    print("="*60)

    print("\n📋 AVAILABLE API ENDPOINTS:")
    endpoints = [
        "POST /api/assignments/orders/{orderId}/auto-assign",
        "POST /api/assignments/orders/{orderId}/manual-assign",
        "GET  /api/assignments/available-partners",
        "GET  /api/assignments/debug/auto-assignment/{orderId}",
        "POST /api/assignments/{assignmentId}/accept",
        "POST /api/assignments/{assignmentId}/reject",
        "POST /api/assignments/{assignmentId}/pickup",
        "POST /api/assignments/{assignmentId}/deliver",
        "GET  /api/assignments/partners/{partnerId}/pending",
        "GET  /api/assignments/partners/{partnerId}/current",
        "GET  /api/assignments/orders/{orderId}"
    ]

    for endpoint in endpoints:
        print(f"  🔗 {endpoint}")

    print("\n🧠 AUTO-ASSIGNMENT LOGIC:")
    print("  1. Checks if order status is 'READY_FOR_PICKUP'")
    print("  2. Finds available delivery partners (online, available, not on ride)")
    print("  3. Selects best partner using smart algorithm:")
    print("     - First available partner (basic)")
    print("     - Falls back to busy partners finishing soon (>20 min)")
    print("  4. Calculates delivery fee and partner commission")
    print("  5. Creates assignment and updates order status to 'OUT_FOR_DELIVERY'")
    print("  6. Updates partner status to 'ON_RIDE' and unavailable")

    print("\n💡 SMART FEATURES:")
    print("  ✨ Automatic distance-based fee calculation")
    print("  ✨ Partner commission calculation")
    print("  ✨ Prevents double assignment")
    print("  ✨ Time-based partner selection")
    print("  ✨ Email notifications")
    print("  ✨ Real-time status updates")

    print("\n🔒 SECURITY:")
    print("  🛡️  JWT Authentication required")
    print("  🛡️  Role-based access control")
    print("  🛡️  ADMIN/SHOP_OWNER can assign orders")
    print("  🛡️  DELIVERY_PARTNER can accept/reject/update")

def show_database_queries():
    """Show the SQL queries to check existing data"""
    print("\n" + "="*60)
    print("DATABASE QUERIES TO CHECK EXISTING DATA")
    print("="*60)

    queries = [
        ("Check Delivery Partners", """
SELECT id, email, first_name, last_name, is_online, is_available, ride_status
FROM users
WHERE role = 'DELIVERY_PARTNER'
ORDER BY created_at DESC;"""),

        ("Check Orders Ready for Assignment", """
SELECT o.id, o.order_number, o.status, o.total_amount, o.delivery_address,
       c.first_name || ' ' || c.last_name as customer_name
FROM orders o
JOIN users c ON o.customer_id = c.id
WHERE o.status = 'READY_FOR_PICKUP'
ORDER BY o.created_at DESC;"""),

        ("Check Existing Assignments", """
SELECT oa.id, oa.status, o.order_number,
       dp.first_name || ' ' || dp.last_name as partner_name
FROM order_assignments oa
JOIN orders o ON oa.order_id = o.id
JOIN users dp ON oa.delivery_partner_id = dp.id
ORDER BY oa.assigned_at DESC;"""),

        ("Auto-Assignment Readiness Check", """
SELECT 'Available Partners' as metric, COUNT(*) as count
FROM users
WHERE role = 'DELIVERY_PARTNER' AND is_online = true AND is_available = true
UNION ALL
SELECT 'Orders Ready', COUNT(*) FROM orders WHERE status = 'READY_FOR_PICKUP'
UNION ALL
SELECT 'Active Assignments', COUNT(*) FROM order_assignments WHERE status IN ('ASSIGNED', 'ACCEPTED', 'PICKED_UP');""")
    ]

    for title, query in queries:
        print(f"\n📊 {title}:")
        print(f"```sql{query}```")

def show_test_commands():
    """Show test commands to demonstrate auto-assignment"""
    print("\n" + "="*60)
    print("TEST COMMANDS FOR AUTO-ASSIGNMENT")
    print("="*60)

    print("\n🔧 USING CURL (with JWT token):")
    print("""
# 1. Get JWT token first (login)
curl -X POST "http://localhost:8080/api/auth/login" \\
  -H "Content-Type: application/json" \\
  -d '{"identifier": "admin@example.com", "password": "password"}'

# 2. Check available partners
curl -X GET "http://localhost:8080/api/assignments/available-partners" \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 3. Debug auto-assignment for order 1
curl -X GET "http://localhost:8080/api/assignments/debug/auto-assignment/1" \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# 4. Auto-assign order 1
curl -X POST "http://localhost:8080/api/assignments/orders/1/auto-assign?assignedBy=1" \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
""")

    print("\n🔧 USING POSTMAN:")
    print("""
1. POST /api/auth/login - Get JWT token
2. Add "Authorization: Bearer {token}" to all requests
3. GET /api/assignments/available-partners
4. POST /api/assignments/orders/{orderId}/auto-assign?assignedBy={userId}
""")

if __name__ == "__main__":
    print("🚀 AUTO-ASSIGNMENT API DEMONSTRATION")

    # Test backend health
    if test_backend_health():
        show_auto_assignment_summary()
        show_database_queries()
        show_test_commands()

        print("\n" + "="*60)
        print("✅ AUTO-ASSIGNMENT SYSTEM IS READY!")
        print("="*60)
        print("\n💡 Next Steps:")
        print("  1. Use the SQL queries to check your existing data")
        print("  2. Create test delivery partners if needed")
        print("  3. Create test orders with READY_FOR_PICKUP status")
        print("  4. Use authentication to test the API endpoints")
        print("  5. Monitor backend logs to see assignment logic in action")
    else:
        print("\n❌ Backend is not accessible")
        print("💡 Make sure the Spring Boot application is running on port 8080")