#!/usr/bin/env python3
"""
Auto Assignment API Test Script
"""

import requests
import json

BASE_URL = "http://localhost:8080/api"

def print_header(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def test_debug_endpoint():
    """Test the debug endpoint to see auto-assignment status"""
    print_header("TESTING AUTO-ASSIGNMENT DEBUG ENDPOINT")

    try:
        url = f"{BASE_URL}/assignments/debug/auto-assignment/1"
        print(f"Testing URL: {url}")

        response = requests.get(url, timeout=10)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("SUCCESS! Response:")
            print(json.dumps(data, indent=2, default=str))
        else:
            print(f"Error Response: {response.text}")

    except Exception as e:
        print(f"Error: {e}")

def test_available_partners():
    """Test available partners endpoint"""
    print_header("TESTING AVAILABLE PARTNERS ENDPOINT")

    try:
        url = f"{BASE_URL}/assignments/available-partners"
        print(f"Testing URL: {url}")

        response = requests.get(url, timeout=10)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("SUCCESS! Response:")
            print(json.dumps(data, indent=2, default=str))
        else:
            print(f"Error Response: {response.text}")

    except Exception as e:
        print(f"Error: {e}")

def test_auto_assignment():
    """Test actual auto-assignment"""
    print_header("TESTING AUTO-ASSIGNMENT ENDPOINT")

    try:
        url = f"{BASE_URL}/assignments/orders/1/auto-assign?assignedBy=1"
        print(f"Testing URL: {url}")

        response = requests.post(url, timeout=10)
        print(f"Status Code: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            print("SUCCESS! Response:")
            print(json.dumps(data, indent=2, default=str))
        else:
            print(f"Error Response: {response.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    print("Starting Auto Assignment API Tests")
    print(f"Base URL: {BASE_URL}")

    # Test 1: Debug endpoint
    test_debug_endpoint()

    # Test 2: Available partners
    test_available_partners()

    # Test 3: Auto assignment
    test_auto_assignment()

    print("\nTest Complete!")