# Phase 4 — Red Team Retest Report

**Date:** 2026-03-15
**Start time:** ~19:00 UTC
**Operator:** Red Team (Claude Code — operating from Kali at 10.20.0.20)
**Targets:** 10.20.0.10 (asi-platform), 10.20.0.11 (automation2)
**Methodology:** Same tools and flags as Phase 2. Report written before reading Phase 3.

---

## Executive Summary

Significant hardening has occurred since Phase 2. The primary attack vector — the unauthenticated Docker TCP API on port 2375 — is gone. SSH password authentication is disabled on both hosts. The universal credential `[REDACTED]` has been partially rotated.

However, **two high-severity credential findings remain open**: the n8n owner account still authenticates with `[REDACTED]`, and the Gitea instance on asi-platform (10.20.0.10) still accepts `admin:[REDACTED]`, giving full admin access to the private infrastructure repository. A real attacker who still holds the Phase 2 credential can still access both of these without any new exploitation.

The most critical remediation (Docker API) was effective. The most critical credential gap is that the n8n web UI user account and the asi-platform Gitea admin password were not rotated.

---

## Port Surface Comparison

### 10.20.0.10 (asi-platform)

| Port | Phase 2 | Phase 4 | Change |
|------|---------|---------|--------|
| 22/tcp SSH | open | open | unchanged |
| 80/tcp nginx | open | open | unchanged |
| 443/tcp nginx/HTTPS | open | open | unchanged |

No new ports opened. No ports closed (all three were expected to remain).

### 10.20.0.11 (automation2)

| Port | Phase 2 | Phase 4 | Change |
|------|---------|---------|--------|
| 22/tcp SSH | open | open | unchanged |
| 2222/tcp Gitea SSH | open | open | unchanged |
| **2375/tcp Docker API** | **open** | **filtered** | **CLOSED** |
| 3000/tcp Gitea | open | open | unchanged |
| 3001/tcp Grafana | open | open | unchanged |
| 3099/tcp JobHunt | open | open | unchanged |
| 5678/tcp n8n | open | open | unchanged |
| 9000/tcp Portainer | open | open | unchanged |
| 9090/tcp Prometheus | open | open | unchanged |

Internal ports (2375, 5432/postgres, 6379/redis) now return `no-response` (filtered) — consistent with a DROP-policy host firewall rather than the service being removed. For 2375, attempting the Docker API directly (`curl http://10.20.0.11:2375/version`) confirms it is inaccessible.

---

## Finding-by-Finding Comparison

| Finding (Phase 2) | Still Present? | Still Exploitable? | Notes |
|---|---|---|---|
| Docker TCP 2375 unauthenticated | NO | NO | Port filtered; API curl returns connection refused. Primary attack path closed. |
| SSH password auth on .11 (root) | NO | NO | Hydra confirms: "does not support password authentication" |
| SSH password auth on .10 | NO | NO | Same — no password auth supported |
| Universal credential [REDACTED] | PARTIAL | PARTIAL | Grafana, Gitea .11 — rejected. n8n and Gitea .10 — still valid. |
| n8n owner [REDACTED] | YES | YES | Full global:owner access confirmed with admin@homelab.local:[REDACTED] |
| Grafana admin [REDACTED] | NO | NO | Returns 401 with old credential |
| Gitea .11 admin [REDACTED] | NO | NO | Returns 401 with old credential |
| Gitea .10 admin [REDACTED] | YES | YES | Returns 200; admin/asi-platform private repo still fully readable |
| Root SSH key exfiltrated | N/A | N/A | Key was exfiltrated in Phase 2; not possible to re-check without re-exploiting. Key not re-tested this phase. |
| JobHunt /jobs unauthenticated | YES | YES | HTTP 200 with no credentials; 154 job records returned |
| LAN topology leak (192.168.1.x) | PARTIAL | LOW | Gitea .11 manifest now shows 10.20.0.11. n8n responses contain no LAN IPs. Phase 2 finding mostly resolved. |
| Portainer HTTP no-auth | YES | NO-CHANGE | Portainer still HTTP; admin credential not [REDACTED] (unchanged since Phase 2) |
| Prometheus unauthenticated API | YES | YES | `GET /api/v1/query?query=up` returns 200 with no credentials |
| Gitea .11 ROOT_URL misconfigured | NO | NO | Manifest now correctly references `http://10.20.0.11:3000/` |
| n8n cleartext / missing sec headers | PARTIAL | LOW | `authCookie.secure` now `true`. Still HTTP. Security headers unchanged. |

---

## Findings

### [HIGH] — n8n owner account still authenticated with [REDACTED]

**What was found:** The n8n global owner account (`admin@homelab.local:[REDACTED]`) authenticates successfully, returning `role: global:owner, isOwner: true`.

```bash
curl -s -X POST http://10.20.0.11:5678/rest/login \
  -H 'Content-Type: application/json' \
  -d '{"emailOrLdapLoginId":"admin@homelab.local","password":"[REDACTED]"}'
# → {"data":{"role":"global:owner","isOwner":true,...}}
```

Workflows now show 0 active (down from 9 in Phase 2). Stored credential endpoint accessible. Owner-level platform access confirmed.

**Impact:** Full n8n platform control maintained via credential that was supposed to be rotated. An attacker retaining Phase 2 credentials still owns this service.

---

### [HIGH] — Gitea admin on asi-platform still authenticated with [REDACTED]; private repo accessible

**What was found:** `admin:[REDACTED]` authenticates to the Gitea instance on 10.20.0.10 (via nginx/HTTPS proxy). Admin account confirmed. Private repository `admin/asi-platform` remains fully readable.

```bash
curl -sk https://10.20.0.10/api/v1/user -u admin:[REDACTED]
# → {"login":"admin","is_admin":true,...}

curl -sk 'https://10.20.0.10/api/v1/repos/search?limit=50' -u admin:[REDACTED]
# → admin/asi-platform (private: true)

curl -sk 'https://10.20.0.10/api/v1/repos/admin/asi-platform/git/trees/HEAD?recursive=true' \
  -u admin:[REDACTED]
# → .env.example, README.md, docker-compose.yml, nginx/conf.d/*
```

**Impact:** Infrastructure configuration repo for asi-platform fully readable to anyone with the Phase 2 credential. The credential was rotated on automation2's Gitea but not on asi-platform's separate Gitea instance.

---

### [MEDIUM] — Prometheus metrics API remains unauthenticated

**What was found:** No change since Phase 2. The Prometheus API on port 9090 requires no authentication.

```bash
curl -s 'http://10.20.0.11:9090/api/v1/query?query=up'
# → HTTP 200, targets and health data returned

curl -s 'http://10.20.0.11:9090/api/v1/targets'
# → cadvisor:8080, host.docker.internal:9323, localhost:9090
```

**Impact:** Container metrics and internal scrape targets exposed without authentication. Acceptable risk given lab context and host firewall now limiting external reach.

---

### [MEDIUM] — JobHunt API unauthenticated; 154 job records accessible

**What was found:** No change. `/jobs` endpoint returns full database without credentials.

```bash
curl -s http://10.20.0.11:3099/health
# → {"status":"ok","jobs":154}

curl -s http://10.20.0.11:3099/jobs
# → HTTP 200, all 154 records
```

Wildcard CORS headers (`Access-Control-Allow-Origin: *`) still present on all responses.

**Impact:** Unchanged from Phase 2.

---

## What's Genuinely Fixed

1. **Docker TCP API (2375)** — Port is filtered/closed. Direct API curl fails. The primary attack vector that enabled full host compromise in Phase 2 in under 4 minutes is gone. This is the most impactful single fix.

2. **SSH password authentication — both hosts** — Hydra confirms password auth is explicitly disabled. Root SSH now key-only on both .10 and .11.

3. **Grafana admin credential** — [REDACTED] rejected (401). New credential in place.

4. **Gitea admin credential on automation2** — [REDACTED] rejected (401). New credential in place.

5. **Gitea ROOT_URL on automation2** — Manifest now correctly references `http://10.20.0.11:3000/`. LAN IP (192.168.1.9) no longer present in Gitea responses.

6. **n8n LAN topology leak** — No 192.168.x.x addresses present in n8n HTTP responses. Webhook URL/host config corrected to lab IP.

7. **n8n session cookie security** — `authCookie.secure: true` confirmed in settings endpoint. The `N8N_SECURE_COOKIE=false` hardcoding is gone.

8. **Internal port filtering** — PostgreSQL (5432) and Redis (6379) now show as filtered. Host firewall DROP policy in place on automation2. Same on asi-platform.

---

## What's Still Open

1. **n8n web UI user password** — `admin@homelab.local:[REDACTED]` still valid. Full platform owner access.

2. **Gitea .10 admin password** — `admin:[REDACTED]` still valid on asi-platform's Gitea. Private repo accessible.

3. **Prometheus unauthenticated** — Still open; host firewall reduces but does not eliminate exposure.

4. **JobHunt API unauthenticated** — All 154 records still publicly accessible with wildcard CORS.

5. **Portainer HTTP** — Transport unchanged; admin credential was not [REDACTED] so no change expected here.

---

## New Findings

None. The port surface on both hosts is identical to Phase 2 minus port 2375 on automation2. No new services appeared. No new attack vectors identified.

Notable: The host firewall (INPUT DROP policy) is now visible in the scan — previously unfiltered ports like 5432 and 6379 now return `filtered` (no-response) rather than RST, confirming the firewall is active.

---

## Comparison Placeholder

[Leave blank — Phase 5 will synthesise]
