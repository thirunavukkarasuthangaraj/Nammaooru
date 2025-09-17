#!/usr/bin/env python3
"""
Auto Assignment API Test Script
This script demonstrates the auto-assignment functionality of the Order Assignment API
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://localhost:8080/api"

def print_header(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def print_response(response, title="Response"):
    print(f"\n--- {title} ---")
    print(f"Status Code: {response.status_code}")
    try:
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2, default=str)}")
    except:
        print(f"Raw Response: {response.text}")

def test_auto_assignment_flow():
    """Test the complete auto-assignment flow"""

    print_header("AUTO ASSIGNMENT API DEMONSTRATION")
    print(f"Testing at: {datetime.now()}")

    # Test 1: Check available partners
    print_header("1. CHECK AVAILABLE DELIVERY PARTNERS")
    try:
        response = requests.get(f"{BASE_URL}/assignments/available-partners")
        print_response(response, "Available Partners")

        if response.status_code == 200:
            data = response.json()
            partner_count = data.get('totalAvailable', 0)
            print(f"\n✅ Found {partner_count} available delivery partners")
        else:
            print("⚠️  Unable to fetch partners (likely authentication required)")
    except Exception as e:
        print(f"❌ Error: {e}")

    # Test 2: Debug auto-assignment for order ID 1
    print_header("2. DEBUG AUTO-ASSIGNMENT READINESS")
    try:
        response = requests.get(f"{BASE_URL}/assignments/debug/auto-assignment/1")
        print_response(response, "Auto-Assignment Debug")

        if response.status_code == 200:
            data = response.json()
            status = data.get('autoAssignmentStatus', 'unknown')
            message = data.get('autoAssignmentMessage', 'No message')
            available_count = data.get('availablePartnersCount', 0)

            print(f"\n📊 Auto-Assignment Status: {status}")
            print(f"📝 Message: {message}")
            print(f"👥 Available Partners: {available_count}")

            if status == 'ready':
                print("✅ System is ready for auto-assignment")
            else:
                print(f"⚠️  System not ready: {message}")
        else:
            print("⚠️  Unable to get debug info (likely authentication required)")
    except Exception as e:
        print(f"❌ Error: {e}")

    # Test 3: Attempt auto-assignment
    print_header("3. ATTEMPT AUTO-ASSIGNMENT")
    try:
        # Try to auto-assign order 1
        response = requests.post(f"{BASE_URL}/assignments/orders/1/auto-assign?assignedBy=1")
        print_response(response, "Auto-Assignment Result")

        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                assignment = data.get('assignment', {})
                partner_name = assignment.get('deliveryPartner', {}).get('name', 'Unknown')
                order_number = assignment.get('order', {}).get('orderNumber', 'Unknown')
                delivery_fee = assignment.get('deliveryFee', 0)
                commission = assignment.get('partnerCommission', 0)

                print(f"\n🎉 SUCCESS! Order auto-assigned")
                print(f"📦 Order: {order_number}")
                print(f"🚚 Assigned to: {partner_name}")
                print(f"💰 Delivery Fee: ₹{delivery_fee}")
                print(f"💵 Partner Commission: ₹{commission}")
                print(f"🕐 Assigned at: {assignment.get('assignedAt', 'Unknown')}")
            else:
                print(f"❌ Assignment failed: {data.get('message', 'Unknown error')}")
        else:
            print("⚠️  Auto-assignment request failed (likely authentication or data issues)")
    except Exception as e:
        print(f"❌ Error: {e}")

    # Test 4: Check assignment history
    print_header("4. CHECK ORDER ASSIGNMENTS")
    try:
        response = requests.get(f"{BASE_URL}/assignments/orders/1")
        print_response(response, "Order Assignments")

        if response.status_code == 200:
            data = response.json()
            assignments = data.get('assignments', [])
            print(f"\n📋 Total assignments for order 1: {len(assignments)}")

            for i, assignment in enumerate(assignments, 1):
                status = assignment.get('status', 'Unknown')
                assignment_type = assignment.get('assignmentType', 'Unknown')
                partner = assignment.get('deliveryPartner', {}).get('name', 'Unknown')
                print(f"  {i}. Status: {status}, Type: {assignment_type}, Partner: {partner}")
        else:
            print("⚠️  Unable to get assignment history")
    except Exception as e:
        print(f"❌ Error: {e}")

def test_api_endpoints():
    """Test various API endpoints to show functionality"""

    print_header("API ENDPOINTS DEMONSTRATION")

    endpoints = [
        ("GET", "/assignments/available-partners", "Get Available Partners"),
        ("GET", "/assignments/debug/auto-assignment/1", "Debug Auto-Assignment"),
        ("POST", "/assignments/orders/1/auto-assign?assignedBy=1", "Auto-Assign Order"),
        ("POST", "/assignments/orders/1/manual-assign?deliveryPartnerId=1&assignedBy=1", "Manual Assign Order"),
        ("GET", "/assignments/orders/1", "Get Order Assignments"),
        ("GET", "/assignments/partners/1/pending", "Get Partner Pending Assignments"),
        ("GET", "/assignments/partners/1/current", "Get Partner Current Assignment"),
        ("GET", "/assignments/partners/1/history", "Get Partner Assignment History"),
    ]

    for method, endpoint, description in endpoints:
        print(f"\n🔗 {method} {BASE_URL}{endpoint}")
        print(f"   📄 {description}")

        try:
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}")
            else:
                response = requests.post(f"{BASE_URL}{endpoint}")

            print(f"   📊 Status: {response.status_code}")

            if response.status_code == 200:
                data = response.json()
                if 'success' in data:
                    print(f"   ✅ Success: {data.get('success')}")
                    if 'message' in data:
                        print(f"   📝 Message: {data.get('message')}")

        except Exception as e:
            print(f"   ❌ Error: {str(e)[:50]}...")

if __name__ == "__main__":
    print("🚀 Starting Auto Assignment API Test")
    print(f"🌐 Base URL: {BASE_URL}")

    # Test the auto-assignment flow
    test_auto_assignment_flow()

    # Show available endpoints
    test_api_endpoints()

    print_header("TEST COMPLETE")
    print("📝 Note: Some endpoints require authentication")
    print("🔧 To test with authentication, add JWT token headers")
    print("📊 Check backend logs for detailed assignment logic")