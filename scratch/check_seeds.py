import urllib.request
import json

url = 'https://agriflow-backend-t8o4.onrender.com/api/v1/public/seeds'
req = urllib.request.Request(url, headers={'Accept': 'application/json', 'User-Agent': 'AgriFlow-Test'})
try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
        items = data.get('data', [])
        print(f"Status: {resp.status}, Count: {len(items)}")
        for s in items:
            print("---")
            print("ID:", s.get('id'))
            print("Name:", s.get('name'))
            print("Active:", s.get('is_active'))
            print("Image:", s.get('image_url'))
            print("Stock:", s.get('stock_kg'))
            print("Warehouses:", [w.get('name') for w in s.get('warehouses', [])])
except Exception as e:
    print("Error:", e)
