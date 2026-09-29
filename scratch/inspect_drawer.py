import re

with open('AdminMobile UIUX.html', 'r', encoding='utf-8') as f:
    html = f.read()

print('=== DRAWER NAV ITEMS IN AdminMobile UIUX.html ===')
drawer_matches = re.findall(r'onclick="[^"]*(?:openScreen|switchScreen|showScreen|navTo)\(\'([^\']+)\'\)[^"]*"[^>]*>(.*?)<', html)
if not drawer_matches:
    drawer_matches = re.findall(r'data-screen=["\']([^"\']+)["\']', html)
for m in drawer_matches[:30]:
    print(' -', m)

print('\n=== SCREENS IN AdminMobile UIUX.html ===')
screen_matches = re.findall(r'id=["\']screen-([^"\']+)["\']', html)
for s in screen_matches:
    print(' - screen-' + s)
