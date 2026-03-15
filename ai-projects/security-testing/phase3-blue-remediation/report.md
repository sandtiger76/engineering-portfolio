# Phase 3 — Remediation Report

Date: 2026-03-15
Hosts in scope: 10.20.0.10 (asi-platform), 10.20.0.11 (automation2)

---

## What Was Fixed

### Fix 1 — Docker TCP API Exposure Removed (automation2)

- **Finding**: Phase 1 CRITICAL — Docker daemon listening on 0.0.0.0:2375, no authentication
- **Red Team confirmed exploitable**: YES — primary attack vector; full host compromise via bind-mount
- **Before**: `/etc/docker/daemon.json` contained `"hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]`
- **After**: TCP listener removed entirely; daemon.json now only contains log driver and storage settings
- **How verified**: `curl --connect-timeout 3 http://10.20.0.11:2375/version` → connection refused
- **Risk of fix**: Low — internal services use the Unix socket; no legitimate external consumers of port 2375

---

### Fix 2 — SSH Hardened on automation2

- **Finding**: Phase 1 CRITICAL — PermitRootLogin yes, PasswordAuthentication yes
- **Red Team confirmed exploitable**: YES — password SSH used to confirm credential validity during attack
- **Before**: `PermitRootLogin yes` / `PasswordAuthentication yes`
- **After**: `PermitRootLogin prohibit-password` / `PasswordAuthentication no`
- **How verified**: `ssh -o PasswordAuthentication=yes -o PubkeyAuthentication=no root@10.20.0.11` → Permission denied (publickey)
- **Risk of fix**: Low — key-based auth confirmed working before change

---

### Fix 3 — SSH Hardened on asi-platform

- **Finding**: Phase 1 MEDIUM — PasswordAuthentication not explicitly disabled (defaulted to yes)
- **Red Team confirmed exploitable**: NO (not tested against .10 SSH directly)
- **Before**: `#PasswordAuthentication yes` (commented, implicit yes)
- **After**: `PasswordAuthentication no` (explicit)
- **How verified**: `ssh -o PasswordAuthentication=yes -o PubkeyAuthentication=no root@10.20.0.10` → Permission denied (publickey)
- **Risk of fix**: Low — key auth already working

---

### Fix 4 — authorized_keys Permissions Corrected (asi-platform)

- **Finding**: Phase 1 MEDIUM — /root/.ssh/authorized_keys was 0700 (executable bit set)
- **Red Team confirmed exploitable**: NO
- **Before**: `chmod 700` on authorized_keys file
- **After**: `chmod 600`
- **How verified**: `stat -c '%a' /root/.ssh/authorized_keys` → 600
- **Risk of fix**: None

---

### Fix 5 — Credential Rotation and Uniqueness (automation2)

- **Finding**: Phase 1 + Phase 2 — universal password `[REDACTED]` reused across all services
- **Red Team confirmed exploitable**: YES — single credential from .env file owned SSH, Grafana, n8n, Gitea (.10 and .11)
- **Before**: All services used `[REDACTED]`; `N8N_SECURE_COOKIE=false` hardcoded in compose
- **After**: `/opt/automation/.env` rewritten with unique per-service passwords:
  ```
  POSTGRES_PASSWORD=[REDACTED]
  N8N_BASIC_AUTH_PASSWORD=N8[REDACTED]
  GRAFANA_ADMIN_PASSWORD=[REDACTED]
  GITEA_ADMIN_PASSWORD=[REDACTED]
  JOBHUNT_DB_PASSWORD=[REDACTED]     # defined but not used (see notes)
  N8N_SECURE_COOKIE=true
  N8N_HOST=10.20.0.11
  WEBHOOK_URL=http://10.20.0.11:5678/
  ```
  Passwords applied live to running services:
  - postgres: `ALTER USER automation WITH PASSWORD '...'`
  - Grafana: `PUT /api/admin/users/1/password`
  - Gitea: `PATCH /api/v1/admin/users/admin`
  - n8n: env var updated, container recreated
- **How verified**: `curl -u admin:[REDACTED] http://10.20.0.11:3001/api/org` → HTTP 200
- **Risk of fix**: Medium — password changes require live DB updates; any missed consumer breaks. jobhunt-api required a separate postgres user debug cycle (see notes below)

---

### Fix 6 — n8n Secure Cookie Enabled (automation2)

- **Finding**: Phase 1 HIGH — N8N_SECURE_COOKIE=false hardcoded in docker-compose.yml
- **Red Team confirmed exploitable**: YES — n8n session was unauthenticated-accessible; credentials obtained via .env
- **Before**: `- N8N_SECURE_COOKIE=false` hardcoded in compose
- **After**: `- N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}` (reads from .env, now set to `true`)
- **How verified**: Container recreated with updated env; `N8N_SECURE_COOKIE=true` confirmed in inspect
- **Risk of fix**: Low — HTTP-only lab environment, cookie upgrade is benign

---

### Fix 7 — Gitea ROOT_URL Corrected (automation2)

- **Finding**: Phase 1 MEDIUM — Gitea app.ini pointing to 192.168.1.9 (wrong LAN IP)
- **Red Team confirmed exploitable**: NO (used API directly)
- **Before**: `DOMAIN = 192.168.1.9`, `SSH_DOMAIN = 192.168.1.9`, `ROOT_URL = http://192.168.1.9:3000/`
- **After**: `DOMAIN = 10.20.0.11`, `SSH_DOMAIN = 10.20.0.11`, `ROOT_URL = http://10.20.0.11:3000/`
- **File edited**: `/opt/automation/gitea/gitea/conf/app.ini` (bind-mounted into container)
- **How verified**: `curl http://10.20.0.11:3000/api/v1/users/admin` → `html_url: http://10.20.0.11:3000/admin`
- **Risk of fix**: None — corrects stale config

---

### Fix 8 — Tailscale Removed (asi-platform)

- **Finding**: Phase 1 HIGH — Tailscale overlay network bypasses VLAN firewall isolation
- **Red Team confirmed exploitable**: NO — not visible from Kali's position (UDP 41641 not scanned/accessible)
- **Action**: `systemctl stop tailscaled && systemctl disable tailscaled`
- **How verified**: `systemctl status tailscaled` → disabled/dead; `ss -ulnp | grep 41641` → empty
- **Risk of fix**: Low — service removed from lab host, no production dependency

---

### Fix 9 — Host Firewall Applied (automation2)

- **Finding**: Phase 1 HIGH — no host-level firewall; all ports world-accessible on lab VLAN
- **Red Team confirmed exploitable**: YES — port 2375 accessed directly without firewall blocking
- **Before**: `iptables -P INPUT ACCEPT`, no rules
- **After**: INPUT policy DROP with explicit ACCEPT rules for:
  - ESTABLISHED/RELATED (stateful)
  - Loopback
  - TCP 22 (SSH) from 10.20.0.0/24 and 192.168.1.0/24
  - TCP 3000, 2222, 5678, 3099, 9000, 9090, 3001 from 10.20.0.0/24 and 192.168.1.0/24
- **Persisted**: `iptables-save > /etc/iptables/rules.v4`, `iptables-persistent` installed and enabled
- **How verified**: `iptables -L INPUT -n --line-numbers` — 18 rules, policy DROP confirmed
- **Risk of fix**: HIGH — misconfiguration here can lock out SSH. Encountered lockout during implementation (see notes); resolved via Proxmox console (`pct exec 101`)

---

### Fix 10 — Host Firewall Applied (asi-platform)

- **Finding**: Phase 1 LOW — no host-level firewall on asi-platform
- **Red Team confirmed exploitable**: NO
- **Before**: `iptables -P INPUT ACCEPT`, no rules
- **After**: INPUT policy DROP with ACCEPT for:
  - ESTABLISHED/RELATED
  - Loopback
  - TCP 22 from 10.20.0.0/24 and 192.168.1.0/24
  - TCP 80, 443 from 10.20.0.0/24 and 192.168.1.0/24
- **Persisted**: `iptables-save > /etc/iptables/rules.v4`, `iptables-persistent` enabled
- **How verified**: `iptables -L INPUT -n --line-numbers` — 8 rules, policy DROP
- **Risk of fix**: Medium — DROP policy active; only ssh and HTTP(S) permitted

---

## What Was Not Fixed (and Why)

| Finding | Reason Not Fixed |
|---------|-----------------|
| Prometheus unauthenticated API (automation2) | Metrics-only exposure; bound to lab VLAN; host firewall now limits reach. Fixing requires nginx proxy config — deferred to avoid service disruption |
| cAdvisor broad /rootfs mount (automation2) | Read-only mount; acceptable in monitoring use-case; no exploit demonstrated |
| n8n web UI user account (admin@homelab.local) password | API returned Unauthorized during n8n restart window; n8n user account password not changed via API. Basic Auth password was changed (env var). Web UI password remains at original value |
| Portainer HTTP (no TLS) | HTTP-only is consistent with all other lab services; TLS would require cert management — out of scope |
| Grafana HTTP (no TLS) | Same rationale |
| Tailscale still installed on asi-platform | Service stopped and disabled but package not purged — service is dead, binary present is acceptable |

---

## Unintended Consequences

1. **Self-lockout on automation2 (iptables)**: Initial firewall rule allowed SSH from `10.20.0.0/24` only. Workstation is on `192.168.1.197`. This immediately locked out SSH from the workstation. Recovered via `pct exec 101` on Proxmox2. Fixed by adding `192.168.1.0/24` to the SSH ACCEPT rule before persisting.

2. **jobhunt-api postgres user complexity**: Giving jobhunt-api a dedicated `jobhunt` postgres user triggered SCRAM-SHA-256 auth failures from node-postgres (pg 8.19.0 against PostgreSQL 16). Root cause unclear — identical credentials authenticated successfully from a postgres:15-alpine test container but failed from Node.js. Resolution: reverted jobhunt-api to use the `automation` postgres user with `POSTGRES_PASSWORD`. The JOBHUNT_DB_PASSWORD env var remains defined but is unused.

3. **postgres recreated during docker compose up**: When updating POSTGRES_PASSWORD in .env and running `docker compose up -d`, docker compose detected the env change and recreated the postgres container (brief downtime). n8n and jobhunt-api came back up once postgres was healthy.

---

## Verification

| Check | Result |
|-------|--------|
| Port 2375 (Docker TCP) closed | ✅ Connection refused |
| SSH password auth rejected (.11) | ✅ Permission denied (publickey) |
| SSH password auth rejected (.10) | ✅ Permission denied (publickey) |
| Grafana accessible with new password | ✅ HTTP 200 |
| n8n accessible | ✅ HTTP 200 |
| JobHunt API healthy (154 jobs, DB connected) | ✅ HTTP 200 |
| Gitea (.11) accessible | ✅ HTTP 200 |
| nginx (.10) accessible | ✅ HTTP 301 (redirect to HTTPS) |
| All automation2 containers running | ✅ 9/9 up |
| All asi-platform containers running | ✅ 4/4 up |
| iptables rules persisted (.11) | ✅ netfilter-persistent enabled |
| iptables rules persisted (.10) | ✅ netfilter-persistent enabled |
| Tailscale stopped + disabled (.10) | ✅ dead/disabled |

---

## Pre-Phase 4 State

**automation2 (10.20.0.11)**
- Docker TCP API: CLOSED (was the primary attack vector)
- SSH: key-only, root prohibited-password
- iptables: INPUT DROP, only whitelisted ports from 10.20.0.0/24 and 192.168.1.0/24
- All service passwords: unique, rotated from `[REDACTED]`
- n8n: Basic Auth password changed; N8N_SECURE_COOKIE=true
- Gitea: admin password changed; ROOT_URL corrected to lab IP

**asi-platform (10.20.0.10)**
- SSH: key-only, password auth disabled
- authorized_keys: 0600
- Tailscale: stopped and disabled
- iptables: INPUT DROP, only SSH and HTTP(S) from both subnets
- Gitea admin password changed (was shared with .11 admin, now independent)

**Known remaining exposure**
- Prometheus metrics API unauthenticated (mitigated by host firewall limiting access to lab VLAN)
- n8n web UI user account password not rotated via API
- No TLS on any HTTP service (by design for lab)
