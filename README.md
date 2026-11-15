# Zero-Trust Docker Security Lab

A small Docker Compose lab (college project) that puts a static website behind a chain of
security layers and then attacks, captures and logs everything to see what each layer does.

```
 client ──► WAF (ModSecurity + OWASP CRS, :443) ──► nginx proxy (:80 / :8444) ──► nginx web (static site)
                     │                                   │                              │
                  tshark                              tshark                         tshark       → captures/*.pcapng
                     └──────────── JSON logs ────────────┴──────────────────────────────┘
                                         │
                       Fluent Bit ──► OpenSearch ──► OpenSearch Dashboards (:5601)
 Attackers: OWASP ZAP (active scans) and hping3 (packet crafting) inside the same Docker network.
```

## What is in the repository

| Path | Purpose |
|---|---|
| `compose.yaml` | Defines all services, the `172.30.0.0/24` network and the bind mounts |
| `proxy/nginx.conf` | Reverse proxy: forwards `/http/` and `/https/` to the web server, JSON access log |
| `web/nginx.conf` | Web server config (HTTP + HTTPS, static files, JSON access log) |
| `web/html/` | The static website served by the web container (data viz coursework page, CSS, data, images) |
| `tshark/Dockerfile` | Debian image with tshark, used as a sidecar that sniffs a container's traffic |
| `hping/Dockerfile` | Debian image with hping3 for crafted-packet tests |
| `siem/scripts/hping-run.sh` | Wrapper that logs every hping3 command as JSON, then runs it |
| `siem/fluent-bit/fluent-bit.conf` | Ships all logs to OpenSearch (one index per source) |
| `zap-reports/zap-http.yaml`, `zap-https.yaml` | ZAP automation plans (spider, passive + active scan, report) |
| `zap-reports/*.html` | Example ZAP scan results |
| `captures/sample/` | Example packet capture of the web container |
| `siem/logs/sample/` | Short excerpts of the proxy, web and WAF logs |
| `certs/README.md` | How to generate the TLS certificates (keys are not published) |
| `References and storage/references.txt` | Documentation links used while building the lab |

## How the bind mounts are used

Bind mounts (`./host/path:/container/path`) connect files on the host to the containers:

- Configs are mounted **read-only** (`./proxy/nginx.conf`, `./web/nginx.conf`, `fluent-bit.conf`, certs).
- `./web/html` is mounted into the web server so the site can be edited without rebuilding.
- `./siem/logs/*` and `./captures` are mounted **writable**, so logs and pcaps appear on the host.
- `./zap-reports` is where ZAP writes its reports.

## Running it

```bash
# 1. create certificates (see certs/README.md)
# 2. create the log folders the bind mounts write to
mkdir -p captures siem/logs/{proxy,web,waf,hping} siem/state

docker compose up -d --build                      # WAF, proxy, web, tshark sidecars, hping
docker compose --profile siem up -d               # OpenSearch, Dashboards, Fluent Bit
docker compose --profile zap up --abort-on-container-exit zap_http
docker compose --profile zap up --abort-on-container-exit zap_https
docker compose exec hping hping-run.sh -S -p 80 -c 5 web   # example hping3 run
```

Entry points: `https://localhost` (WAF), `http://localhost/http/` (proxy), Dashboards at `http://localhost:5601`.

## Notes

- Security features of OpenSearch are disabled and the lab uses a self-signed CA: **local lab use only**.
- Private keys, raw captures, full logs and personal files are excluded via `.gitignore`.
