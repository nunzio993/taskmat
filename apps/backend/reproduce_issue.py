import requests
import sys

BASE_URL = "http://127.0.0.1:8000"

def test_flow():
    # 1. Login
    login_data = {
        "email": "helper@test.it",
        "password": "testtt"
    }
    print(f"Logging in as {login_data['email']}...")
    try:
        resp = requests.post(f"{BASE_URL}/auth/login", json=login_data)
        print(f"Login Status: {resp.status_code}")
        if resp.status_code != 200:
            print("Login failed:", resp.text)
            sys.exit(1)
        
        token = resp.json()["access_token"]
        print("Login successful. Token obtained.")
    except Exception as e:
        print(f"Login Exception: {e}")
        sys.exit(1)

    # 2. Call Chat Endpoint
    headers = {
        "Authorization": f"Bearer {token}"
    }
    print("Calling POST /chat/tasks/1/thread ...")
    try:
        resp = requests.post(f"{BASE_URL}/chat/tasks/1/thread", headers=headers)
        print(f"Chat Endpoint Status: {resp.status_code}")
        print("Response Headers:", resp.headers)
        print("Response Body:", resp.text)
    except Exception as e:
        print(f"Chat Endpoint Exception: {e}")

if __name__ == "__main__":
    test_flow()
