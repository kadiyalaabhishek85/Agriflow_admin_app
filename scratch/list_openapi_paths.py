import json

with open('live_openapi.json', 'r', encoding='utf-8') as f:
    d = json.load(f)

print('=== ALL LIVE OPENAPI PATHS & OPERATIONS ===')
for path, methods in sorted(d.get('paths', {}).items()):
    for method, op in methods.items():
        summary = op.get('summary', '')
        tags = op.get('tags', [])
        sec = 'Auth' if op.get('security') else 'Public'
        print(f"{method.upper():6} {path:45} [{sec}] {tags} - {summary}")
