
import requests
import json
import random

BASE_URL = "http://localhost:8000"

def probe_direct_offers():
    print("--- Probing Direct Offers Endpoint ---")
    
    rand_id = random.randint(10000, 99999)
    email = f"probe_client_{rand_id}@example.com"
    password = "password123"
    
    # 1. Register Client
    print(f"1. Registering Client {email}...")
    try:
        r = requests.post(f"{BASE_URL}/auth/register", json={
            "email": email, "password": password, "role": "client", "first_name": "P", "last_name": "C"
        })
        if r.status_code != 200: print(f"Reg failed: {r.text}"); return
    except Exception as e: print(e); return

    # Login
    auth_resp = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    token = auth_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Create Task
    print("2. Creating Task...")
    t_resp = requests.post(f"{BASE_URL}/tasks/", json={
        "title": "Probe Task", "description": "D", "category": "G", "price_cents": 100, "lat": 0, "lon": 0, "urgency": "low"
    }, headers=headers)
    task_id = t_resp.json()["id"]
    print(f"   Task ID: {task_id}")
    
    # 3. Helper + Offer
    h_email = f"probe_helper_{rand_id}@example.com"
    print(f"3. Registering Helper {h_email}...")
    requests.post(f"{BASE_URL}/auth/register", json={
        "email": h_email, "password": password, "role": "helper", "first_name": "P", "last_name": "H"
    })
    h_auth = requests.post(f"{BASE_URL}/auth/login", json={"email": h_email, "password": password})
    h_token = h_auth.json()["access_token"]
    h_headers = {"Authorization": f"Bearer {h_token}"}
    
    print("   Submitting Offer...")
    requests.post(f"{BASE_URL}/tasks/{task_id}/offers", json={"price_cents": 50, "message": "Offer"}, headers=h_headers)
    
    # 4. Check Direct Endpoint
    print(f"4. Checking GET /tasks/{task_id}/offers ...")
    offers_resp = requests.get(f"{BASE_URL}/tasks/{task_id}/offers", headers=headers)
    
    if offers_resp.status_code == 200:
        offers = offers_resp.json()
        print(f"   Direct Endpoint Count: {len(offers)}")
        print(json.dumps(offers, indent=2))
        
        if len(offers) > 0:
            print("   SUCCESS: Offers exist and are reachable via direct endpoint.")
        else:
            print("   FAILURE: Direct endpoint returned 0 offers.")
    else:
        print(f"   Error calling direct endpoint: {offers_resp.text}")

    # 5. Check Task Detail (for comparison)
    print(f"5. Checking GET /tasks/{task_id} ...")
    task_resp = requests.get(f"{BASE_URL}/tasks/{task_id}", headers=headers)
    task_data = task_resp.json()
    embedded_offers = task_data.get("offers", [])
    print(f"   Task Detail Offers Count: {len(embedded_offers)}")

if __name__ == "__main__":
    probe_direct_offers()
