with open('AdminMobile UIUX.html', 'r', encoding='utf-8') as f:
    html = f.read()

start = html.find('id="screen-billing"')
if start != -1:
    end = html.find('id="screen-', start + 20)
    print('=== screen-billing in AdminMobile UIUX.html ===')
    print(html[start:end if end != -1 else start + 2500])

with open('Manager Dashboard UIUX.html', 'r', encoding='utf-8') as f:
    mgr_html = f.read()

m_start = mgr_html.find('id="screen-billing"')
if m_start != -1:
    m_end = mgr_html.find('id="screen-', m_start + 20)
    print('\n=== screen-billing in Manager Dashboard UIUX.html ===')
    print(mgr_html[m_start:m_end if m_end != -1 else m_start + 2500])
