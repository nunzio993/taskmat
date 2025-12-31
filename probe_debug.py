
import requests
import json

BASE_URL = "http://localhost:8000"

def probe_debug():
    print("--- Probing Debug Endpoint ---")
    try:
        # Check if tasks router is mounted at /tasks or root
        # In main.py: app.include_router(api_router, prefix="/api/v1") ?? 
        # Wait, previous probes used BASE_URL/tasks...
        # In main.py:
        # app.include_router(auth.router, prefix="/auth", tags=["auth"])
        # app.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
        
        # So it should be /tasks/debug_probe
        
        url = f"{BASE_URL}/tasks/debug_probe"
        print(f"GET {url} ...")
        r = requests.get(url)
        print(f"Status: {r.status_code}")
        if r.status_code == 200:
            print("Response:", r.json())
            print("SUCCESS: Code updates are ACTIVE.")
        else:
            print("FAILURE: Endpoint not found or error.")
            print("Response:", r.text)
            
    except Exception as e:
        print(f"EXCEPTION: {e}")

if __name__ == "__main__":
    probe_debug()
