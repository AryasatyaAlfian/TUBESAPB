import urllib.request, urllib.error
url = "http://127.0.0.1:8000/api/login"
req = urllib.request.Request(url)
try:
    with urllib.request.urlopen(req, timeout=5) as res:
        print(res.status)
        print(res.read().decode("utf-8"))
except urllib.error.HTTPError as e:
    print("HTTP", e.code)
    print(e.read().decode("utf-8"))
except Exception as e:
    print("ERR", e)
