# Nginx + Nextcloud Reverse Proxy — Gotchas

[← Back to README](../../README.md) | [← Nginx](../services/nginx.md)

---

This document captures every known issue running Nextcloud behind an Nginx reverse proxy.
All items below were encountered or verified during the actual build.

---

## 1. Redirect loops and mixed content — `overwriteprotocol`

**Problem:** Nextcloud generates `http://` URLs internally even when the client connects via HTTPS.
Symptoms: redirect loop, browser mixed content warnings, CalDAV/CardDAV clients fail.

**Fix:** Set in `.env`:
```
OVERWRITEPROTOCOL=https
```
Or via occ:
```bash
docker exec -u www-data nextcloud php occ config:system:set overwriteprotocol --value="https"
```

---

## 2. Untrusted domain error on first access

**Problem:** Nextcloud shows "Access through untrusted domain" even with the correct hostname.

**Fix:** `NEXTCLOUD_TRUSTED_DOMAINS` must match *exactly* what the browser sends in the
`Host` header — no trailing slash, no port unless non-standard.

```bash
docker exec -u www-data nextcloud php occ config:system:get trusted_domains
```

---

## 3. `trusted_proxies` — Nextcloud logs proxy IP instead of real client IP

**Problem:** Security checks may reject the connection if the proxy isn't explicitly trusted.

**Fix:** Set the Docker `proxy` network subnet:
```bash
# Find the actual subnet first
docker network inspect proxy | grep Subnet

# Then set it (replace with actual subnet)
docker exec -u www-data nextcloud php occ config:system:set trusted_proxies 0 --value="172.20.0.0/16"
```
> Never use `0.0.0.0/0` — only trust the proxy network CIDR.

---

## 4. Required Nginx proxy headers

If Nginx doesn't send these headers, Nextcloud won't handle HTTPS correctly:

```nginx
location / {
    proxy_pass http://nextcloud;
    proxy_set_header Host                $host;
    proxy_set_header X-Real-IP           $remote_addr;
    proxy_set_header X-Forwarded-For     $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto   $scheme;
    proxy_set_header X-Forwarded-Host    $host;

    # Large file uploads
    client_max_body_size  512M;
    proxy_read_timeout    600s;
    proxy_send_timeout    600s;
}
```

---

## 5. WebDAV / CalDAV / CardDAV returns 404 or 405

**Problem:** Desktop client sync or mobile calendar/contacts sync fails silently.

**Fix:** Add `.well-known` redirects to the Nginx virtual host:
```nginx
location /.well-known/carddav {
    return 301 $scheme://$host/remote.php/dav;
}
location /.well-known/caldav {
    return 301 $scheme://$host/remote.php/dav;
}
```

---

## 6. Large file uploads fail silently

**Problem:** Files over ~1MB fail without a clear error message.

**Fix:** Both Nginx AND PHP must be configured — one without the other is not enough:
- Nginx: `client_max_body_size 512M;`
- Container env: `PHP_UPLOAD_LIMIT=512M` (already in docker-compose.yml)
- Container env: `PHP_MEMORY_LIMIT=512M` (already set)

---

## 7. `occ` commands must run as `www-data`

**Always use:**
```bash
docker exec -u www-data nextcloud php occ <command>
```
Running as root causes file permission issues and incorrect output.

---

## 8. First-run env vars are write-once

Changing `NEXTCLOUD_ADMIN_PASSWORD` in `.env` after the first deploy has no effect.
The initial install writes config to `config/config.php` inside the volume.

**To change the admin password post-install:**
```bash
docker exec -u www-data nextcloud php occ user:resetpassword admin
```

---

## 9. Redis locking — both memcache keys required

Configuring only `memcache.local` leaves file locking disabled, causing concurrent edit
conflicts and potential WebDAV corruption.

Set both (verify after deploy):
```bash
docker exec -u www-data nextcloud php occ config:system:get memcache.locking
# Should return: \OC\Memcache\Redis
```

---

## 10. Missing database indices after fresh install

Always run after first deployment:
```bash
docker exec -u www-data nextcloud php occ db:add-missing-indices
docker exec -u www-data nextcloud php occ db:add-missing-columns
docker exec -u www-data nextcloud php occ db:add-missing-primary-keys
```

---

## 11. Celeron N2820 — performance expectations

- First boot: 3–8 minutes (PHP initialising, DB population) — this is normal
- Preview generation is CPU-intensive — disable on this hardware:
  ```bash
  docker exec -u www-data nextcloud php occ config:system:set enable_previews --value=false --type=bool
  ```
- Redis is critical — without file locking, WebDAV sync can silently corrupt files

---

[← Back to Nginx](../services/nginx.md) | [← Back to Nextcloud](../services/nextcloud.md)
