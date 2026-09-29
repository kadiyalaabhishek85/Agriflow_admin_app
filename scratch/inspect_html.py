import re

with open('AdminMobile UIUX.html', 'r', encoding='utf-8') as f:
    text = f.read()

print('AdminMobile UIUX.html size:', len(text))
screens = re.findall(r'id=["\']([^"\']+)["\']', text)
print('Key IDs in AdminMobile UIUX.html:')
for s in screens:
    if any(k in s.lower() for k in ['screen', 'tab', 'flow', 'page', 'modal', 'drawer', 'view', 'bill', 'market', 'manager', 'rate', 'report', 'log', 'credit']):
        print(' -', s)

with open('Manager Dashboard UIUX.html', 'r', encoding='utf-8') as f:
    mgr_text = f.read()

print('\nManager Dashboard UIUX.html size:', len(mgr_text))
mgr_screens = re.findall(r'id=["\']([^"\']+)["\']', mgr_text)
print('Key IDs in Manager Dashboard UIUX.html:')
for s in mgr_screens:
    if any(k in s.lower() for k in ['screen', 'tab', 'flow', 'page', 'modal', 'drawer', 'view', 'bill', 'market', 'manager', 'rate', 'report', 'log', 'credit']):
        print(' -', s)
