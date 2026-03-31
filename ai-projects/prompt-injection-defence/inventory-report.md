# Phase 0 — Environment Inventory
Date: 2026-03-31
Agent: Claude Code

---

## automation2 (10.20.0.11)

### System
- **OS:** Debian GNU/Linux 12 (bookworm), LXC container on Proxmox (pve-vm-101-disk-0)
- **Kernel:** 6.17.9-1-pve
- **Uptime:** ~14 min at time of scan (recently rebooted)
- **Disk:** 16G root, 12G used (76% — tight, worth watching)
- **Memory:** 2.0 GiB total, ~800 MiB used, ~226 MiB free, ~1.0 GiB buff/cache
- **Swap:** 512 MiB, 1.9 MiB used

### Network
| Interface | Address | Note |
|-----------|---------|------|
| lo | 127.0.0.1/8 | loopback |
| eth1 | 10.20.0.11/24 | LAN-facing |
| br-0cc56dd6f48d | 172.18.0.1/16 | Docker bridge (`automation_automation`) — active |
| docker0 | 172.17.0.1/16 | Default Docker bridge — DOWN (no containers) |

**Default route:** 10.20.0.1 via eth1

**Listening TCP ports:**
| Port | Process | Service |
|------|---------|---------|
| 22 | sshd | SSH |
| 25 | postfix/master | SMTP (localhost only) |
| 2222 | docker-proxy | Gitea SSH |
| 3000 | docker-proxy | Gitea web |
| 3001 | docker-proxy | Grafana |
| 3099 | docker-proxy | JobHunt API |
| 5678 | docker-proxy | n8n |
| 9000 | docker-proxy | Portainer |
| 9090 | docker-proxy | Prometheus |

**Listening UDP:** none

### Firewall State
INPUT policy: **DROP** (allowlist only)

Permitted inbound from both `10.20.0.0/24` and `192.168.1.0/24`:
- TCP 22 (SSH), 2222 (Gitea SSH), 3000 (Gitea), 3001 (Grafana), 3099 (JobHunt API), 5678 (n8n), 9000 (Portainer), 9090 (Prometheus)
- RELATED/ESTABLISHED (stateful)
- Loopback

FORWARD: Docker-managed chains (DOCKER-USER, DOCKER-FORWARD); containers on `br-0cc56dd6f48d` can reach each other freely. Port-published containers accept from outside the bridge only on their mapped ports.

OUTPUT: ACCEPT (unrestricted)

### Docker Containers
All containers are up (~10 min at time of scan, started after host reboot):

| Name | Image | Ports | Status |
|------|-------|-------|--------|
| jobhunt-api | node:18-alpine | 0.0.0.0:3099→3099/tcp | Up ~10 min |
| n8n | n8nio/n8n:latest | 0.0.0.0:5678→5678/tcp | Up ~10 min |
| postgres | postgres:16 | 5432/tcp (internal only) | Up ~10 min |
| grafana | grafana/grafana:latest | 0.0.0.0:3001→3000/tcp | Up ~10 min |
| gitea | gitea/gitea:latest | 0.0.0.0:3000→3000/tcp, 0.0.0.0:2222→22/tcp | Up ~10 min |
| portainer | portainer/portainer-ce:latest | 0.0.0.0:9000→9000/tcp | Up ~10 min |
| cadvisor | gcr.io/cadvisor/cadvisor:latest | 8080/tcp (internal only) | Up ~10 min (healthy) |
| redis | redis:7-alpine | 6379/tcp (internal only) | Up ~10 min |
| prometheus | prom/prometheus:latest | 0.0.0.0:9090→9090/tcp | Up ~10 min |

**Docker images present (unused):** `postgres:15-alpine` — old image, no container running against it.

**Docker networks:**
| Name | Driver |
|------|--------|
| automation_automation | bridge (172.18.0.0/16) |
| bridge (docker0) | bridge — no active containers |
| host | host |
| none | null |

**Docker volumes:**
- `automation_grafana_data`, `automation_prometheus_data` (named)
- 4 anonymous volumes (likely postgres, n8n, gitea data, portainer)

### Compose Stacks Found
`/opt/automation/docker-compose.yml` — single stack defining all 9 containers above.

Stack uses env vars from `/opt/automation/.env` for: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD`, `N8N_SECURE_COOKIE`, `WEBHOOK_URL`, `GF_SECURITY_ADMIN_PASSWORD`.

JobHunt API mounts source from `/opt/automation/jobhunt-api/` and runs `npm install && node server.js`. It connects to postgres with database `jobhunt`.

### Service Health
All services responding at time of scan:

| Service | Port | HTTP Code | Health |
|---------|------|-----------|--------|
| Gitea | 3000 | 200 | healthy |
| Grafana | 3001 | 302 | healthy (redirect to login) |
| JobHunt API | 3099 | 200 | healthy |
| n8n | 5678 | 200 | healthy |
| Portainer | 9000 | 200 | healthy |
| Prometheus | 9090 | 302 | healthy (redirect to /graph) |

cadvisor port 8080 not externally exposed; not tested. postgres (5432) and redis (6379) internal-only; not tested.

### Sensitive File Locations
(locations only — contents not read)
- `/opt/automation/.env` — credential vars for all services
- `/opt/automation/gitea/gitea/jwt/private.pem` — Gitea JWT signing key
- `/opt/automation/portainer/chisel/private-key.pem` — Portainer Chisel tunnel key
- `/opt/automation/portainer/portainer.key` — Portainer admin key
- `/opt/automation/portainer/certs/key.pem` — TLS private key
- `/opt/automation/portainer/certs/cert.pem` — TLS cert

### Scheduled Tasks
- Root crontab: none
- `/etc/cron.d/e2scrub_all`: standard Debian disk scrub
- Other cron dirs: standard Debian defaults (apt, dpkg, logrotate, man-db)
- No n8n workflow schedules visible from the host (would require checking n8n UI)

### Notes
- **Disk at 76%** — with active Docker overlay filesystems, headroom is limited. No action required now but worth monitoring.
- **Recurring log error:** `systemd-networkd-wait-online` timeout on every reboot, and `dhclient` failure on today's boot (`No such device`). The LXC container uses `systemd-networkd` to configure eth1 statically but `ifupdown` is also installed and failing. Network is functional despite these errors — benign but noisy.
- **postgres:15-alpine** image present but unused — leftover from a previous stack version.
- **⚠ FLAG — NEW:** `jobhunt-api` container (node:18-alpine, port 3099) was not in previous project documentation. It's a Node.js REST API connecting to a `jobhunt` database in postgres. Source lives at `/opt/automation/jobhunt-api/`.
- **cadvisor** is collecting Docker container metrics and feeding Prometheus — good baseline for the monitoring experiment.

---

## kali (10.20.0.20)

### System
- **OS:** Kali GNU/Linux Rolling, LXC container on Proxmox (pve-vm-102-disk-0)
- **Kernel:** 6.17.9-1-pve
- **Uptime:** ~14 min at time of scan (recently rebooted), 1 active user
- **Disk:** 20G root, 8.6G used (46%)
- **Memory:** 1.0 GiB total, ~26 MiB used, ~774 MiB free
- **Swap:** 512 MiB, 0 used

### Network
| Interface | Address | Note |
|-----------|---------|------|
| lo | 127.0.0.1/8 | loopback |
| eth1 | 10.20.0.20/24 | LAN-facing |

**Default route:** 10.20.0.1 via eth1
**No Docker installed.**

**Listening TCP:** SSH only (port 22, sshd)
**Listening UDP:** none

### Firewall State
iptables: **all chains ACCEPT with no rules** — completely open. Expected for an attack/testing node.

### Running Services
| Service | Description |
|---------|-------------|
| ssh.service | OpenSSH server |
| dbus.service | D-Bus message bus |
| systemd-journald.service | Journal |
| systemd-logind.service | Login management |
| systemd-hostnamed.service | Hostname service |
| systemd-userdbd.service | User database |
| console-getty / container-getty | TTY management |

No application services. Kali is a clean attack node — no daemon stack.

### Installed Tools

All confirmed present via `which`:

| Tool | Path |
|------|------|
| nmap | /usr/bin/nmap |
| hydra | /usr/bin/hydra |
| nikto | /usr/bin/nikto |
| gobuster | /usr/bin/gobuster |
| sqlmap | /usr/bin/sqlmap |
| netcat | /usr/bin/netcat |
| curl | /usr/bin/curl |
| wget | /usr/bin/wget |
| python3 | /usr/bin/python3 |

Package versions (dpkg):

| Package | Version |
|---------|---------|
| nmap | 7.98+dfsg-1kali1 |
| hydra | 9.6-3 |
| nikto | 1:2.6.0-0kali1 |
| metasploit-framework | 6.4.116-0kali2 |
| wireshark-common | 4.6.4-1 |

gobuster and sqlmap confirmed installed (not in dpkg filter but present via `which`).

### Sensitive File Locations
No `.env`, `.key`, or `.pem` files found under /opt, /home, or /root.

### Scheduled Tasks
- Root crontab: none
- `/etc/cron.d/john` — **⚠ FLAG:** a John the Ripper cron entry exists (installed by the kali-tools-passwords package). Not a custom schedule — standard Kali package file. No active wordlist cracking job.
- `/etc/cron.d/e2scrub_all`, `php`: standard system entries
- `/etc/cron.daily/apache2`, `apt-compat`, `dpkg`, `logrotate`, `plocate`: standard

### Notes
- **Log errors:** Recurring `systemd-sslh-generator failed` errors from Mar 15 — sslh not configured; its systemd generator is installed but fails harmlessly. Networking errors on Mar 15 during initial container setup (dhclient/eth0 before eth1 was configured) — resolved.
- **Auth log:** All recent SSH sessions are from `192.168.1.147` (this workstation, quintin-M70q) using ED25519 key auth. No unexpected access.
- **No persistence tools or listeners active** — kali is idle, awaiting use.

---

## Summary

### Services Running on automation2
n8n (5678), Gitea (3000/2222), Grafana (3001), Portainer (9000), Prometheus (9090), JobHunt API (3099), postgres (internal), redis (internal), cadvisor (internal)

### Ports Externally Accessible from 10.20.0.0/24
From kali (10.20.0.20) or any host on the same VLAN:

| Port | Service |
|------|---------|
| 22 | automation2 SSH |
| 2222 | Gitea SSH |
| 3000 | Gitea web |
| 3001 | Grafana |
| 3099 | JobHunt API |
| 5678 | n8n |
| 9000 | Portainer |
| 9090 | Prometheus |
| 22 | kali SSH |

### Changes Since Last Project
1. **⚠ NEW: `jobhunt-api`** — Node.js API container on port 3099, connecting to a `jobhunt` Postgres database. Not previously documented. Source at `/opt/automation/jobhunt-api/`.
2. **`postgres:15-alpine` image present but unused** — previous stack may have used Postgres 15; current stack uses 16.
3. **Both hosts were freshly rebooted** — all containers were only up ~10 min at scan time. No prior uptime baseline for comparison.

### Recommended Next Steps
Both hosts are in good shape to proceed with the experiment:

- **automation2** is healthy — all 9 containers up, all services responding. Disk at 76% is the only caution.
- **kali** is clean and idle — full toolset installed, ready to act as attack/probe node.
- **Clarify the jobhunt-api** before starting the experiment — confirm it's intentional and understand what it exposes.
- **Confirm network routing** — both hosts reach 10.20.0.1 as their gateway; verify that gateway provides inter-VLAN reach if needed, or whether the experiment stays within 10.20.0.0/24.
- **Prometheus + Grafana + cadvisor** are already running — the monitoring infrastructure is in place. The experiment can immediately start capturing baseline traffic/metrics before any active probing begins.
- Consider snapshotting both LXC containers in Proxmox before starting Phase 1 (easy rollback if something breaks).
