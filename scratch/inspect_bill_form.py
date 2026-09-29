with open('Manager Dashboard UIUX.html', 'r', encoding='utf-8') as f:
    mgr_html = f.read()

start = mgr_html.find('id="flow-add-bill"')
if start != -1:
    end = mgr_html.find('</section>', start)
    if end == -1: end = mgr_html.find('</div>\n        </div>', start)
    print('=== flow-add-bill in Manager Dashboard UIUX.html ===')
    print(mgr_html[start:start + 2000])

with open('AdminMobile UIUX.html', 'r', encoding='utf-8') as f:
    admin_html = f.read()

start2 = admin_html.find('openBillingForm')
if start2 != -1:
    print('\n=== openBillingForm in AdminMobile UIUX.html ===')
    print(admin_html[start2:start2 + 1000])
