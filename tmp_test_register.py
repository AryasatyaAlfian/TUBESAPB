import urllib.request, urllib.error, json
url = 'http://127.0.0.1:8000/api/register'
data = json.dumps({'name': 'test', 'email': 'test@example.com', 'password': 'secret123', 'password_confirmation': 'secret123', 'user_type': 'mahasiswa', 'nim': '12345678'}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req, timeout=5) as res:
        print(res.status)
        print(res.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print('HTTP', e.code)
    print(e.read().decode('utf-8'))
except Exception as e:
    print('ERR', e)
