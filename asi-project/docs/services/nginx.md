# Nginx

[← Back to README](../../README.md) | [← PostgreSQL](postgresql.md)

---

## What Is It?

Nginx (pronounced "engine-x") is a high-performance web server and reverse proxy. In this project it acts as the front door to all public-facing services — receiving incoming web requests and routing them to the correct application container.

It also handles SSL termination — meaning it manages the encrypted HTTPS connection with the user's browser, so that the application containers themselves do not need to deal with encryption.

Nginx powers approximately 34% of all websites on the internet. It is the industry standard for this role.

**Why it's in this project:** Without a reverse proxy, each service would need its own port number, which is insecure and unprofessional. Nginx allows all services to be accessed on standard HTTPS port 443, with routing handled by domain name.

---

## Why We Need It

Nginx performs four critical functions in this architecture:

1. **Reverse proxying** — routes `nextcloud.qcbhomelab.online` to the Nextcloud container and `gitea.qcbhomelab.online` to the Gitea container, all on port 443
2. **SSL termination** — manages the wildcard Let's Encrypt certificate, handles encrypted connections, forwards plain HTTP internally
3. **Security headers** — adds HSTS, X-Frame-Options, Content-Security-Policy, Referrer-Policy to every response
4. **Cloudflare IP restoration** — recovers the real client IP from the `CF-Connecting-IP` header so application logs show real visitors, not Cloudflare's proxy IPs

---

## Technical Implementation

### Container Configuration

```yaml
nginx:
  image: nginx:alpine
  container_name: nginx
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/conf.d:/etc/nginx/conf.d:ro
    - /etc/letsencrypt:/etc/letsencrypt:ro
  networks:
    - proxy
```

Nginx is the **only** container with ports exposed to the host. All other containers communicate on internal Docker networks.

### Configuration File Layout

```
nginx/conf.d/
├── default.conf      — HTTP → HTTPS redirect (port 80)
├── real_ip.conf      — Cloudflare IP restoration (shared, loaded once)
├── nextcloud.conf    — Nextcloud virtual host + SSL + headers
└── gitea.conf        — Gitea virtual host + SSL
```

> **Important:** Cloudflare IP trust directives (`set_real_ip_from`, `real_ip_header`) must live in a single shared `real_ip.conf` — **not** in individual vhost files. Duplicating them across vhost files causes Nginx to fail on startup with `"real_ip_header" directive is duplicate`.

### Cloudflare IP Restoration

Since all traffic arrives via Cloudflare's proxy network, Nginx sees Cloudflare's IPs rather than real client IPs. `real_ip.conf` corrects this:

```nginx
# real_ip.conf — loaded once, shared across all vhosts
set_real_ip_from 103.21.244.0/22;
set_real_ip_from 103.22.200.0/22;
set_real_ip_from 103.31.4.0/22;
set_real_ip_from 104.16.0.0/13;
set_real_ip_from 104.24.0.0/14;
set_real_ip_from 108.162.192.0/18;
set_real_ip_from 131.0.72.0/22;
set_real_ip_from 141.101.64.0/18;
set_real_ip_from 162.158.0.0/15;
set_real_ip_from 172.64.0.0/13;
set_real_ip_from 173.245.48.0/20;
set_real_ip_from 188.114.96.0/20;
set_real_ip_from 190.93.240.0/20;
set_real_ip_from 197.234.240.0/22;
set_real_ip_from 198.41.128.0/17;
real_ip_header CF-Connecting-IP;
```

### Nextcloud Virtual Host

```nginx
server {
    listen 443 ssl;
    server_name nextcloud.qcbhomelab.online;

    ssl_certificate     /etc/letsencrypt/live/qcbhomelab.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/qcbhomelab.online/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header Referrer-Policy no-referrer;

    # Large file uploads
    client_max_body_size 512M;
    proxy_read_timeout   300s;
    proxy_send_timeout   300s;

    # Disable buffering for large transfers
    proxy_buffering         off;
    proxy_request_buffering off;

    # WebDAV / CalDAV / CardDAV redirects
    location /.well-known/carddav { return 301 $scheme://$host/remote.php/dav; }
    location /.well-known/caldav  { return 301 $scheme://$host/remote.php/dav; }

    location / {
        proxy_pass http://nextcloud;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header Destination       $http_destination;
    }
}
```

### SSL Certificate

- **Type:** Wildcard — covers `*.qcbhomelab.online` and `qcbhomelab.online`
- **Issuer:** Let's Encrypt E8
- **Challenge:** DNS-01 via Cloudflare API — no open ports required during renewal
- **Location:** `/etc/letsencrypt/live/qcbhomelab.online/`
- **Auto-renewal:** `certbot.timer` systemd unit — runs twice daily
- **Expires:** 2026-06-08 (auto-renews at 30 days remaining)

The wildcard certificate covers all current and future subdomains — adding a new service requires only a new Nginx vhost, not a new certificate.

### Trusted Proxies — Network Subnet

The `proxy` Docker network subnet on this deployment is `172.19.0.0/16`. This is set in Nextcloud's `TRUSTED_PROXIES` environment variable so Nextcloud trusts headers forwarded by the Nginx container.

```bash
# Verify subnet on your deployment
docker network inspect proxy | grep Subnet
```

### Ansible Role

Provisioned by: `ansible/roles/nginx/`

Key variables:
```yaml
nginx_conf_dir: /opt/asi-platform/nginx
compose_dir: /opt/asi-platform
base_domain: qcbhomelab.online
letsencrypt_email: admin@qcbhomelab.online
certbot_staging: false
cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
```

Nginx config changes trigger a **reload** handler (not restart) — graceful, zero downtime:
```yaml
handlers:
  - name: reload nginx
    community.docker.docker_container_exec:
      container: nginx
      command: nginx -s reload
```

---

## Gotchas & Notes

**`real_ip_header` duplicate directive crashes Nginx**
Never put `set_real_ip_from` or `real_ip_header` in individual vhost files. Put them once in a shared `real_ip.conf`. Nginx will refuse to start with `"real_ip_header" directive is duplicate` if they appear more than once.

**521 errors during build — expected behind Cloudflare proxy**
Cloudflare cannot reach a private LAN IP from the internet. 521 errors during build are normal — test directly with `curl --resolve domain:443:127.0.0.1` to verify Nginx is working before port forwarding is configured.

**Port forwarding required for external access**
OpenWrt must forward ports 80 and 443 to `192.168.1.11`. Without this, Cloudflare's proxy cannot reach Nginx and all external requests return 521.

**DNS-01 challenge — no port 80 required for cert issuance**
Certbot uses the Cloudflare API to prove domain ownership — no inbound ports needed. Certificates can be issued and renewed even with zero open router ports.

**Cloudflare SSL mode — use "Full (strict)"**
Set in Cloudflare dashboard: SSL/TLS → Overview → Full (strict). This verifies the origin certificate is valid rather than accepting any certificate. Already satisfied since a valid Let's Encrypt cert is installed.

**`proxy_buffering off` required for large uploads**
Without this, Nginx buffers large file uploads to disk causing timeouts. Both `proxy_buffering` and `proxy_request_buffering` must be off for Nextcloud.

**WebDAV `Destination` header must be forwarded**
`proxy_set_header Destination $http_destination` is required — without it, desktop client file moves and renames silently fail.

---

See also: [Nginx + Nextcloud Reverse Proxy Gotchas](../tasks/nginx-nextcloud-gotchas.md)

---

[Next: Portainer →](portainer.md)
