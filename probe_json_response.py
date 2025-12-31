
import requests
import json

BASE_URL = "http://localhost:8000"

def probe_json():
    print("--- Probing JSON Response for test@example.com ---")
    
    # Login
    email = "test@example.com"
    password = "password" # Assuming seed password
    
    print(f"Logging in as {email}...")
    auth_resp = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    
    if auth_resp.status_code != 200:
        print(f"Login failed: {auth_resp.text}")
        return

    token = auth_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 1. Get Created Tasks
    print("1. Fetching GET /tasks/created ...")
    r = requests.get(f"{BASE_URL}/tasks/created?client_id=1", headers=headers) # client_id param is ignored by my endpoint logic usually? 
    # Endpoint definition: async def get_created_tasks(client_id: int, ...)
    # Wait, it REQUIRES client_id param.
    # User 1 ID is 1.
    
    # Wait, endpoint def:
    # @router.get("/created", ...)
    # async def get_created_tasks(client_id: int, ...)
    
    r = requests.get(f"{BASE_URL}/tasks/created?client_id=1", headers=headers)
    
    if r.status_code != 200:
        print(f"GET /tasks/created failed: {r.text}")
        return
        
    tasks = r.json()
    print(f"Got {len(tasks)} tasks.")
    
    for t in tasks:
        print(f"Task {t['id']}: Offers Count = {len(t.get('offers', []))}")
        if len(t.get('offers', [])) > 0:
            print("   JSON Offers Content sample:", json.dumps(t['offers'][0], indent=2))

    # 2. Get Specific Task Detail (Task 2)
    print("\n2. Fetching GET /tasks/2 (Detail View) ...")
    r2 = requests.get(f"{BASE_URL}/tasks/2", headers=headers)
    if r2.status_code == 200:
        t2 = r2.json()
        print(f"Task 2 Detail: Offers Count = {len(t2.get('offers', []))}")
        if len(t2.get('offers', [])) > 0:
            print("   JSON Offers Content:", json.dumps(t2['offers'], indent=2))
    else:
        print(f"GET /tasks/2 failed: {r2.text}")

if __name__ == "__main__":
    probe_json()
