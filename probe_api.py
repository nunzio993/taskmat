
import requests
import json

BASE_URL = "http://localhost:8000"

def probe_offers():
    print("--- Probing API for Offers ---")
    
    # 1. Login (using a hardcoded test user or one we create on fly if needed)
    # We'll assume the user ID 1 exists or similar, or try to register one to be safe?
    # Actually, let's try to query nearby tasks first, maybe that's easier if public? No, authenticated.
    
    # Let's try to login as a known user. In dev_start, we might not have a fixed seed.
    # But usually 'user@example.com' / 'password' is a common seed.
    # Or I can register a new client.
    
    import random
    rand_id = random.randint(1000, 9999)
    email = f"debug_client_{rand_id}@example.com"
    password = "password123"
    
    print(f"1. Registering/Logging in as {email}...")
    try:
        # Register
        resp = requests.post(f"{BASE_URL}/auth/register", json={
            "email": email,
            "password": password,
            "role": "client",
            "first_name": "Debug",
            "last_name": "Client"
        })
        if resp.status_code != 200:
             print(f"Register failed: {resp.text}")
             return
    except Exception as e:
        print(f"Error connecting to API: {e}")
        return

    # Login
    auth_resp = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": password
    })
    
    if auth_resp.status_code != 200:
        print(f"Login failed: {auth_resp.text}")
        return
        
    token = auth_resp.json()["access_token"]
    global client_id_from_login
    client_id_from_login = auth_resp.json()["user"]["id"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"   Login successful. Token obtained. ID: {client_id_from_login}")
    
    # 2. Create a Task (so we have something to check)
    print("2. Creating a test task...")
    task_resp = requests.post(f"{BASE_URL}/tasks/", json={
        "title": "Probe Task",
        "description": "Debugging offers",
        "category": "General",
        "price_cents": 5000,
        "lat": 41.9028,
        "lon": 12.4964,
        "urgency": "medium",
         "client_id": 1 # ignored by backend override usually
    }, headers=headers)
    
    if task_resp.status_code != 200:
        print(f"Failed to create task: {task_resp.text}")
        return

    task_id = task_resp.json()["id"]
    print(f"   Task created! ID: {task_id}")
    
    # 3. Create an Offer (simulate a helper, but we might need a helper account)
    # Register Helper
    helper_email = f"debug_helper_{rand_id}@example.com"
    print(f"3. Registering Helper {helper_email}...")
    requests.post(f"{BASE_URL}/auth/register", json={
        "email": helper_email,
        "password": password,
        "role": "helper",
        "first_name": "Debug",
        "last_name": "Helper"
    })
    # We should assume it works or check it, but let's just proceed
    pass
    
    # Login Helper
    h_auth = requests.post(f"{BASE_URL}/auth/login", json={
        "email": helper_email,
        "password": password
    })
    h_token = h_auth.json()["access_token"]
    h_headers = {"Authorization": f"Bearer {h_token}"}
    
    # Make Offer
    print("   Submitting offer...")
    offer_resp = requests.post(f"{BASE_URL}/tasks/{task_id}/offers", json={
        "price_cents": 4000,
        "message": "I can do this!"
    }, headers=h_headers)
    
    if offer_resp.status_code != 200:
        print(f"Failed to submit offer: {offer_resp.text}")
    else:
        print("   Offer submitted successfully.")

    # 4. Check Client View (Get Created Tasks)
    print("4. Verifying Client View (get_created_tasks)...")
    
    # extracted from login response
    client_id_real = client_id_from_login
    
    list_resp = requests.get(f"{BASE_URL}/tasks/created", params={"client_id": client_id_real}, headers=headers)
    
    if list_resp.status_code != 200:
        print(f"Failed to list tasks: {list_resp.text}")
        return
        
    tasks = list_resp.json()
    target_task = next((t for t in tasks if t["id"] == task_id), None)
    
    if not target_task:
        print("   Target task not found in list!")
    else:
        offers = target_task.get("offers", [])
        print(f"   Task Found. Offers count: {len(offers)}")
        print(json.dumps(offers, indent=2))
        if len(offers) > 0:
            print("   SUCCESS: Offers are present in the List API response.")
            # Check helper details
            first_offer = offers[0]
            if "helper_name" in first_offer and first_offer["helper_name"] is not None:
                 print(f"   SUCCESS: Helper details present: {first_offer['helper_name']}")
            else:
                 print("   FAILURE: Helper details MISSING in offer.")
        else:
            print("   FAILURE: Offers array is empty.")

    # 5. Check Detail View
    print("5. Verifying Detail View (get_task)...")
    detail_resp = requests.get(f"{BASE_URL}/tasks/{task_id}", headers=headers)
    
    # Check for version header (not in standard Response but printed in console)
    # Actually headers are on response
    # Wait, FastAPI Response object wrapping is required to set headers.
    # My code: response = Response(); response.headers[...] -> This creates a NEW response but doesn't return it!
    # I returned _to_task_out(task) which is a Pydantic model. FastAPI converts that to JSONResponse.
    # So the header WONT BE THERE.
    # But the PRINT "DEBUG: Returning Task..." WILL BE in server logs.
    
    if detail_resp.status_code == 200:
        d_task = detail_resp.json()
        d_offers = d_task.get("offers", [])
        print(f"   Detail View Offers count: {len(d_offers)}")
        if len(d_offers) > 0:
             print("   SUCCESS: Offers present in Detail API.")
        else:
             print("   FAILURE: Offers missing in Detail API.")
    else:
        print(f"   Failed to get detail: {detail_resp.text}")

if __name__ == "__main__":
    probe_offers()
