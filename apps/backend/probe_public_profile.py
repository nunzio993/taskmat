import requests
import asyncio
import sys
import uuid

BASE_URL = "http://localhost:8000"

def run_probe():
    # 1. Create a test user via API (or assume one exists). 
    # Since auth is required for creation, we'll try to find an existing user or just use a known ID if we had one.
    # Beacuse I can't easily create a user without full auth flow in this simple script, 
    # I will attempt to read a public profile of a user that likely exists (e.g., seeded).
    # Based on file listing, there are seed scripts. Let's assume ID 1 or 2 exists.
    
    target_user_id = 1
    
    print(f"Probing Public Profile for User {target_user_id}...")
    
    try:
        resp = requests.get(f"{BASE_URL}/users/{target_user_id}/public")
        if resp.status_code == 404:
            print("User 1 not found. Trying User 2...")
            target_user_id = 2
            resp = requests.get(f"{BASE_URL}/users/{target_user_id}/public")
            
        if resp.status_code != 200:
            print(f"FAILED to get public profile: {resp.status_code} {resp.text}")
            return

        data = resp.json()
        print("SUCCESS: Retrieved public profile.")
        print(f"Data: {data}")
        
        # Privacy Check
        forbidden_fields = ['email', 'phone', 'addresses', 'payment_methods']
        for field in forbidden_fields:
            if field in data and data[field] is not None:
                print(f"CRITICAL FAILURE: Privacy leak! Field '{field}' is present.")
                return
            # Note: Pydantic might not serialize them if excluded, or return None. 
            # My schema DOES NOT have them, so they shouldn't exist in the dict at all 
            # OR Pydantic returns them as None if I defined them but set them to exclude. 
            # My schema `PublicUserResponse` does NOT define them. Good.
            
        if 'stats' not in data:
            print("FAILURE: Stats missing.")
            return
            
        print("Privacy Check: PASSED (Sensitive fields are absent)")
        print(f"Stats: {data['stats']}")
        
        # Check Reviews
        print(f"\nProbing Reviews for User {target_user_id}...")
        resp_rev = requests.get(f"{BASE_URL}/users/{target_user_id}/reviews")
        if resp_rev.status_code != 200:
            print(f"FAILED to get reviews: {resp_rev.status_code}")
            return
            
        rev_data = resp_rev.json()
        print(f"SUCCESS: Retrieved reviews. Count: {rev_data['total']}")
        print(f"First Page Items: {len(rev_data['items'])}")
        
    except Exception as e:
        print(f"EXCEPTION: {e}")

if __name__ == "__main__":
    run_probe()
