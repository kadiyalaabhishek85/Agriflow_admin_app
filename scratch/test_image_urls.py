import urllib.request

urls = [
    ("Chia seeds", "https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1790016051636_h6ls6mdo.jpg"),
    ("Red Gram", "https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1784693962421_xbkunmg6.png"),
    ("TDN-58 Groundnut", "https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1784694110100_ccbllxa7.jpg"),
    ("light (presigned S3)", "https://oeniehlddcnxevjkjlzh.storage.supabase.co/storage/v1/s3/uploads/82341558-0065-47a8-bcb1-68c32098d1e1.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=78b4d0eb730da1370aa17e7b6535e063%2F20260928%2Fap-southeast-1%2Fs3%2Faws4_request&X-Amz-Date=20260928T034052Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=599ceda0e69df903752c2fa439bd24dea88ac1f616828eaa57b7ada1cd8ed05f")
]

for name, url in urls:
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp:
            print(f"{name}: HTTP {resp.status}, Content-Type: {resp.headers.get('Content-Type')}, Length: {resp.headers.get('Content-Length')}")
    except Exception as e:
        print(f"{name}: FAILED with {e}")
