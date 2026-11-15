# certs/

TLS keys and certificates are **not** stored in this repository. Generate your own
local CA and a `localhost` certificate signed by it before starting the stack:

```bash
# 1. Local CA
openssl genrsa -out localCA.key 2048
openssl req -x509 -new -key localCA.key -sha256 -days 365 -subj "/CN=Local Lab CA" -out localCA.crt

# 2. Server key + certificate request for localhost
openssl genrsa -out localhost.key 2048
openssl req -new -key localhost.key -subj "/CN=localhost" -out localhost.csr

# 3. Sign it with the CA (with a SAN for localhost, proxy, web, waf)
printf "subjectAltName=DNS:localhost,DNS:proxy,DNS:web,DNS:waf" > san.ext
openssl x509 -req -in localhost.csr -CA localCA.crt -CAkey localCA.key -CAcreateserial \
  -days 365 -sha256 -extfile san.ext -out localhost.crt
```

Expected files: `localCA.crt`, `localCA.key`, `localhost.crt`, `localhost.key`.
