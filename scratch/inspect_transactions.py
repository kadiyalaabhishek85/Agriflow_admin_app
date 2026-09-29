import json

with open('live_openapi.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

print('=== TRANSACTION PATHS ===')
for p, methods in d.get('paths', {}).items():
    if 'transaction' in p or 'bill' in p or 'invoice' in p:
        for m, op in methods.items():
            print(f"{m.upper()} {p}")
            print(json.dumps(op, indent=2))

print('\n=== TRANSACTION / BILLING SCHEMAS ===')
for name, s in d.get('components', {}).get('schemas', {}).items():
    if any(k in name.lower() for k in ['transaction', 'bill', 'invoice']):
        print(f"--- {name} ---")
        print(json.dumps(s, indent=2))
