import requests
import json

# Configuration
BASE_URL = "http://localhost:8080/api"
FCM_TOKEN = "dyqp5PFWTMuHD58XosRxZI:APA91bFP7gkCbr7m0_exUTbIL7jCTG7vIxu9sNr_JRQTDTdYGb8WrL4n0r3ueeklQDuqcgfgb5zvonNUcPxmF3qulmN8GzY_NbhVt4ob9tCBl5BEViljz70"

def test_backend_connection():
    """Test if backend is running"""
    try:
        response = requests.get(f"{BASE_URL.replace('/api', '')}/actuator/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running and healthy")
            return True
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to backend: {e}")
        return False

def get_user_token():
    """Get JWT token for user thirunavukkarasu_52717"""
    # Try mobile login endpoint
    login_data = {
        "mobileNumber": "8144002155",  # Your phone number from the notification
        "password": "test123"
    }

    try:
        response = requests.post(f"{BASE_URL}/mobile/auth/login", json=login_data, timeout=10)
        print(f"Login response status: {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            token = data.get("data", {}).get("token")
            if token:
                print("✅ Successfully logged in")
                return token
            else:
                print("❌ No token in response")
                print("Response:", json.dumps(data, indent=2))
        else:
            print(f"❌ Login failed: {response.status_code}")
            print("Response:", response.text)
    except Exception as e:
        print(f"❌ Login error: {e}")

    return None

def test_push_notification(token):
    """Test the push notification endpoint"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    try:
        response = requests.get(f"{BASE_URL}/customer/notifications/test-push", headers=headers, timeout=10)
        print(f"Push test response status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("✅ Push notification test response:")
            print(json.dumps(result, indent=2))
            return True
        else:
            print(f"❌ Push test failed: {response.status_code}")
            print("Response:", response.text)
    except Exception as e:
        print(f"❌ Push test error: {e}")

    return False

def update_fcm_token(token):
    """Update FCM token for current user"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    data = {
        "fcmToken": FCM_TOKEN,
        "deviceType": "android",
        "deviceId": "test-device-123"
    }

    try:
        response = requests.post(f"{BASE_URL}/customer/notifications/fcm-token", json=data, headers=headers, timeout=10)
        print(f"FCM token update status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("✅ FCM token updated:")
            print(json.dumps(result, indent=2))
            return True
        else:
            print(f"❌ FCM token update failed: {response.status_code}")
            print("Response:", response.text)
    except Exception as e:
        print(f"❌ FCM token update error: {e}")

    return False

def main():
    print("🔍 DEBUGGING PUSH NOTIFICATIONS")
    print("=" * 50)

    # Step 1: Check backend
    if not test_backend_connection():
        return

    # Step 2: Login
    print("\n📱 Attempting login...")
    token = get_user_token()
    if not token:
        print("\n❌ Cannot proceed without login token")
        print("💡 Suggestion: Check your mobile number and password")
        return

    # Step 3: Update FCM token
    print("\n🔄 Updating FCM token...")
    if update_fcm_token(token):
        print("✅ FCM token updated successfully")
    else:
        print("❌ Failed to update FCM token")

    # Step 4: Test push notification
    print("\n🚀 Testing push notification...")
    if test_push_notification(token):
        print("\n🎉 SUCCESS! Check your phone for notification!")
    else:
        print("\n❌ Push notification test failed")

    print("\n" + "=" * 50)
    print("🔍 NEXT STEPS:")
    print("=" * 50)
    print("1. If test notification works → Create/update an order to test real notifications")
    print("2. If test fails → Check Firebase configuration and phone settings")
    print("3. If login fails → Check credentials and user account")

if __name__ == "__main__":
    main()