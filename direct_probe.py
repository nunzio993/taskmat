
import requests
import json

BASE_URL = "http://localhost:8000"

def direct_task_probe():
    print("--- Direct Task Probe ---")
    
    # First, we need to use an existing user and task.
    # From debug_db_state output we know:
    # - Task 1 likely exists
    # - Offers exist for task 1
    # We need to login as the CLIENT who owns task 1 to access it.
    
    # Let's try a fresh flow but print MORE details
    import random
    rand_id = random.randint(10000, 99999)
    email = f"probe_{rand_id}@test.com"
    password = "password123"
    
    # Register
    print(f"1. Registering {email}...")
    r = requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": password,
        "role": "client",
        "first_name": "Probe",
        "last_name": "User"
    })
    print(f"   Register status: {r.status_code}")
    if r.status_code != 200:
        print(f"   Body: {r.text[:500]}")
        return
        
    # Login
    print("2. Logging in...")
    r = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": password
    })
    if r.status_code != 200:
        print(f"   Login failed: {r.text}")
        return
    token = r.json()["access_token"]
    user_id = r.json()["user"]["id"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"   Logged in as user {user_id}")
    
    # Create Task
    print("3. Creating task...")
    r = requests.post(f"{BASE_URL}/tasks/", json={
        "title": "Direct Probe Task",
        "description": "Testing direct",
        "category": "General",
        "price_cents": 1000,
        "lat": 41.9,
        "lon": 12.5,
        "urgency": "low",
        "client_id": user_id
    }, headers=headers)
    print(f"   Create status: {r.status_code}")
    if r.status_code != 200:
        print(f"   Body: {r.text[:500]}")
        return
    
    task_data = r.json()
    task_id = task_data["id"]
    print(f"   Task created: ID={task_id}, Status={task_data.get('status')}")
    print(f"   Offers in creation response: {len(task_data.get('offers', []))}")
    
    # Register helper
    helper_email = f"helper_{rand_id}@test.com"
    print(f"4. Registering helper {helper_email}...")
    requests.post(f"{BASE_URL}/auth/register", json={
        "email": helper_email,
        "password": password,
        "role": "helper",
        "first_name": "Helper",
        "last_name": "Probe"
    })
    r = requests.post(f"{BASE_URL}/auth/login", json={
        "email": helper_email,
        "password": password
    })
    h_token = r.json()["access_token"]
    h_headers = {"Authorization": f"Bearer {h_token}"}
    
    # Submit offer
    print("5. Submitting offer...")
    r = requests.post(f"{BASE_URL}/tasks/{task_id}/offers", json={
        "price_cents": 800,
        "message": "Direct probe offer"
    }, headers=h_headers)
    print(f"   Offer status: {r.status_code}")
    if r.status_code == 200:
        print(f"   Offer created: {r.json()}")
    else:
        print(f"   Offer failed: {r.text[:300]}")
        
    # Direct fetch of task
    print(f"6. Directly fetching task {task_id} as client...")
    r = requests.get(f"{BASE_URL}/tasks/{task_id}", headers=headers)
    print(f"   GET status: {r.status_code}")
    
    if r.status_code == 200:
        data = r.json()
        offers = data.get("offers", [])
        print(f"   Task status: {data.get('status')}")
        print(f"   OFFERS COUNT: {len(offers)}")
        if offers:
            print("   SUCCESS! Offers found:")
            for o in offers:
                print(f"      - ID={o.get('id')}, Price={o.get('price_cents')}, Helper={o.get('helper_name')}")
        else:
            print("   FAILURE: No offers in response")
            print(f"   Full response: {json.dumps(data, indent=2, default=str)[:1000]}")
    else:
        print(f"   Failed: {r.text[:500]}")

if __name__ == "__main__":
    direct_task_probe()
