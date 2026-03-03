# Troubleshooting Guide

> ← [Back to Project README](../README.md)

---

## Issues Log

| # | Issue | Root Cause | Fix |
|---|---|---|---|
| 1 | n8n: Permission denied on startup | Data folder owned by root; n8n runs as UID 1000 | `chown -R 1000:1000 /opt/automation/n8n/data` then `docker compose restart n8n` |
| 2 | Prometheus: Failed to start | `prometheus.yml` config file not yet created | Created `prometheus.yml` manually before running `docker compose up` |
| 3 | n8n: Secure cookie error | n8n requires HTTPS for cookies by default; no TLS in local environment | Set `N8N_SECURE_COOKIE=false` in `.env`, then `docker compose down && docker compose up -d` |
| 4 | Grafana: Password not updating after `.env` change | PostgreSQL retains the original initialised password | Reset via `docker exec -it grafana grafana-cli admin reset-admin-password` |
| 5 | Gitea: SSH git push prompts for password | SSH connecting to port 22 (LXC host) instead of port 2222 (Gitea container) | Updated remote URL to use port 2222 and added SSH key to Gitea |
| 6 | Grafana dashboard 193: container metrics blank | Dashboard 193 is outdated — metric names don't match current cAdvisor | Use dashboard ID 19792 instead |
| 7 | Prometheus: docker job DNS failure | `host.docker.internal` does not resolve on Linux Docker | Not required for container monitoring — defer to later phase |
---

## Issue Detail

### Issue 1 — n8n: Permission denied on startup

**Symptom:**
n8n container exits immediately after `docker compose up`. Logs show permission denied errors.
```bash
docker logs n8n --tail 20
```

**Root cause:**
The `/opt/automation/n8n/data` directory was created as root. n8n runs internally as user `node` (UID 1000) and cannot write to the directory.

**Fix:**
```bash
chown -R 1000:1000 /opt/automation/n8n/data
docker compose restart n8n
```

---

### Issue 2 — Prometheus: Failed to start

**Symptom:**
Prometheus container exits on startup.

**Root cause:**
`prometheus.yml` did not exist when `docker compose up` was run. Prometheus requires its config file to be present at startup — it does not create a default.

**Fix:**
```bash
nano /opt/automation/prometheus/prometheus.yml
```

Minimum working config:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

Then restart:
```bash
docker compose restart prometheus
```

---

### Issue 3 — n8n: Secure cookie error

**Symptom:**
n8n starts but the browser shows a cookie/security error when trying to log in.

**Root cause:**
n8n defaults to requiring HTTPS for secure cookies. The local environment has no TLS configured yet.

**Fix:**
Add `N8N_SECURE_COOKIE=false` to `/opt/automation/.env`, then restart:
```bash
docker compose down && docker compose up -d
```

> This is acceptable for a local homelab environment. When Nginx + Let's Encrypt SSL is configured (Phase 3), this setting can be removed.

---

### Issue 4 — Grafana: Password not updating after `.env` change

**Symptom:**
Updated `GRAFANA_ADMIN_PASSWORD` in `.env` and restarted the stack, but the old password still works and the new one does not.

**Root cause:**
`GF_SECURITY_ADMIN_PASSWORD` only applies on first initialisation. Once Grafana has written its database it ignores the environment variable on subsequent starts.

**Fix:**
```bash
docker exec -it grafana grafana-cli admin reset-admin-password YOUR_NEW_PASSWORD
```

---

### Issue 5 — Gitea: SSH git push prompts for password instead of using key

**Symptom:**
Running `git push gitea --all` prompts for `git@192.168.1.9's password:` instead of using the SSH key.

**Root cause:**
The git remote URL `git@192.168.1.9:admin/engineering-portfolio.git` connects to port 22 — the SSH port of the LXC container itself, not Gitea. Gitea's SSH service is mapped to port **2222** in `docker-compose.yml`.

**Fix:**

1. Add the SSH public key to Gitea — profile icon → **Settings** → **SSH / GPG Keys** → **Add Key** → paste contents of `~/.ssh/id_ed25519.pub`

2. Update the remote URL:
```bash
git remote set-url gitea ssh://git@192.168.1.9:2222/admin/engineering-portfolio.git
```

3. Verify:
```bash
ssh -T git@192.168.1.9 -p 2222
# Expected: Hi there, admin! You've successfully authenticated...
```

---

### Issue 6 — Grafana dashboard 193: container metrics blank

**Symptom:**
Imported Grafana dashboard ID 193 (Docker container monitoring) but all panels showed no data.

**Root cause:**
Dashboard 193 is outdated and uses metric names that no longer match current cAdvisor output.

**Fix:**
Use dashboard ID **19792** instead — this is a modern cAdvisor dashboard compatible with current metric names.

1. In Grafana: **Dashboards** → **New** → **Import**
2. Enter ID `19792` → **Load**
3. Select Prometheus data source → **Import**

---

### Issue 7 — Prometheus: docker job DNS failure

**Symptom:**
Prometheus targets page shows the `docker` job as DOWN with error:
```
dial tcp: lookup host.docker.internal on 127.0.0.11:53: no such host
```

**Root cause:**
`host.docker.internal` is a Docker Desktop convention for resolving the host machine. It does not resolve in Linux Docker environments.

**Fix:**
This job is not required for container monitoring — cAdvisor covers that. The `docker` job is for Docker daemon metrics which requires a separate exporter. Leave it for now and address in a later phase.

---

*← [Back to Project README](../README.md)*
