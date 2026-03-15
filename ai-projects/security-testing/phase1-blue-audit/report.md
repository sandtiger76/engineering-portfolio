# Phase 1 — Blue Team Audit Report

**Date:** 2026-03-15
**Start time:** ~18:04 UTC
**Auditor:** Blue Team (AI agent, read-only)
**Scope:** 10.20.0.10 (asi-platform), 10.20.0.11 (automation2)

---

## Executive Summary

Both hosts are Debian 12 LXC containers running on Proxmox, booted earlier today. Both run Docker and are functionally online. The surface area is meaningfully different between the two.

**asi-platform** is reasonably hardened for a lab host. Root SSH access requires a key. TLS is properly configured for the two public-facing services (Nextcloud, Gitea). The most significant finding is an unexpected Tailscale overlay network that connects this lab host directly to the workstation — bypassing the VLAN firewall entirely.

**automation2** has multiple severe misconfigurations. The Docker daemon is listening on TCP 0.0.0.0:2375 with no TLS and no authentication. Root SSH login with password authentication is explicitly enabled. There is no host-level firewall. Any of these three issues individually would be considered critical; together they make this host trivially ownable from anywhere on the lab network.

**Finding count by severity:**

| Severity | asi-platform | automation2 | Total |
|----------|-------------|-------------|-------|
| Critical | 0 | 2 | 2 |
| High | 1 | 3 | 4 |
| Medium | 2 | 4 | 6 |
| Low | 3 | 3 | 6 |
| Info | 5 | 5 | 10 |

---

## Host: 10.20.0.10 — asi-platform

**OS:** Debian GNU/Linux 12 (bookworm)
**Kernel:** 6.17.9-1-pve
**Virtualisation:** LXC container (Proxmox)
**Uptime at audit time:** 1h 33m (booted 16:30 today, after several earlier reboots during lab setup)
**Load:** 1.24 / 1.06 / 0.86

### Services running
- sshd, docker, containerd, postfix (localhost only), cron, tailscaled, systemd-networkd

### Docker containers
| Container | Image | Exposed ports |
|-----------|-------|---------------|
| nginx | nginx:alpine | 0.0.0.0:80, 0.0.0.0:443 |
| nextcloud | nextcloud:apache | internal only |
| gitea | gitea/gitea:latest | internal only |
| postgresql | postgres:16 | internal only |
| cloudflare-ddns | favonia/cloudflare-ddns | none |

---

### [HIGH] — Tailscale overlay network bypasses VLAN isolation

**What it is:** Tailscale is installed, running, and connected. The host has Tailscale IP `100.114.7.81`. The workstation (`quintin-M70q`) is also on the same Tailscale network at `100.123.183.26`. Traffic can flow between them via the Tailscale overlay regardless of the OpenWrt VLAN firewall rules that are supposed to prevent Lab → LAN communication.

**Where:** `tailscaled.service` running; `tailscale status` confirmed peer `quintin-M70q` at `100.123.183.26`.

**Why it matters:** The lab isolation model assumes Lab → LAN is REJECT at the firewall. Tailscale creates a persistent, encrypted tunnel that circumvents this entirely. If an attacker compromises asi-platform, they have a direct routed path to the workstation over Tailscale — a path that OpenWrt never sees and cannot block. The VLAN firewall policy is effectively void for this host.

**Recommended fix:** Remove Tailscale from lab hosts, or — if Tailscale is needed for remote admin — add a Tailscale ACL policy that prevents lab hosts from initiating connections to the workstation node. The current state defeats the lab's threat model.

---

### [MEDIUM] — Password authentication enabled (SSH)

**What it is:** `sshd -T` confirms `passwordauthentication yes` is the effective setting. The `sshd_config` has `#PasswordAuthentication yes` commented out, but the Debian 12 default is `yes`. Root login is set to `without-password` (key-only for root), which is correct — but non-root users with shells (e.g. `appuser`) are exposed to password brute force.

**Where:** `/etc/ssh/sshd_config` — line is commented out, falling back to default.

**Why it matters:** `appuser` (uid 1001) has a login shell (`/bin/bash`) and no observed password policy. Password spraying or brute force against this account is possible from any host on the lab network.

**Recommended fix:** Explicitly set `PasswordAuthentication no` in `sshd_config`. Use key-based auth only.

---

### [MEDIUM] — authorized_keys has execute bit set (0700)

**What it is:** `/root/.ssh/authorized_keys` has permissions `0700` (`rwx------`) instead of the expected `0600` (`rw-------`). The file is owned by root with no group/other access, so the practical risk is low — but the execute bit is anomalous.

**Where:** `stat /root/.ssh/authorized_keys` → `Access: (0700/-rwx------)`

**Why it matters:** Functionally harmless in isolation, but some SSH implementations or security hardening tools may reject or warn on executable authorized_keys files. It indicates the file was not created through the normal `ssh-copy-id` workflow and warrants investigation.

**Recommended fix:** `chmod 600 /root/.ssh/authorized_keys`

---

### [LOW] — No host-level firewall

**What it is:** `iptables -L` shows INPUT and OUTPUT chains with policy ACCEPT and zero rules. Docker manages its own FORWARD rules, but the host itself has no packet filtering on inbound connections.

**Where:** iptables INPUT chain — 0 rules, policy ACCEPT.

**Why it matters:** If any service were misconfigured to bind to 0.0.0.0 unexpectedly, there is no host firewall as a backstop. Defence in depth is absent.

**Recommended fix:** Add host-level INPUT rules allowing only SSH (22) and the intended service ports, with a default DROP policy.

---

### [LOW] — All Docker images have pending updates

**What it is:** All five images (`nginx:alpine`, `nextcloud:apache`, `gitea/gitea:latest`, `postgres:16`, `favonia/cloudflare-ddns:latest`) show the `U` flag in `docker images` output, indicating newer versions are available.

**Where:** `docker images` output.

**Why it matters:** Running outdated images means any CVEs patched in newer releases are present in the running environment.

**Recommended fix:** Schedule regular `docker compose pull && docker compose up -d` or use Watchtower/Renovate for automated image updates.

---

### [LOW] — Postfix running (no apparent use case)

**What it is:** Postfix MTA is running and listening on `127.0.0.1:25`. It is not exposed externally.

**Where:** `systemctl list-units`, `ss -tlnp`.

**Why it matters:** Postfix is a non-trivial service with its own attack surface. If it is not being used to relay mail from containerised applications, it is unnecessary. The journal shows a postfix-resolvconf failure at one point.

**Recommended fix:** If no application requires local mail relay, disable and remove postfix.

---

### [INFO] — Public-facing services via Cloudflare proxy

Nextcloud (`nextcloud.homelab.local`) and Gitea (`gitea.homelab.local`) are publicly accessible via Cloudflare proxy. TLS is configured for TLSv1.2/1.3 with strong ciphers. Let's Encrypt certificates are in place with a certbot cron for auto-renewal. Gitea has public registration disabled and requires sign-in to view. PostgreSQL and Gitea containers are internal-only (not port-mapped to host). Nginx mounts `/etc/letsencrypt` read-only.

### [INFO] — Cloudflare DDNS with API token

`cloudflare-ddns` container runs with `cap_drop: ALL`, `no-new-privileges: true`, and `read_only: true`. Well-hardened. The Cloudflare API token is stored in `/opt/asi-platform/.env` (not in the compose file).

### [INFO] — appuser account

`appuser` (uid 1001, gid 995, shell `/bin/bash`, home `/home/appuser`) exists. No sudo privileges observed. Home directory SSH key status not checked. Purpose unclear — not obviously tied to any running container.

### [INFO] — Repeated networking.service failures in journal

LXC container has recurring `Failed to start networking.service` errors on boot — likely a DHCP interface mismatch in the LXC template. Not a security issue; operational noise.

### [INFO] — Sensitive files located

- `/opt/asi-platform/.env` — contains credentials (Cloudflare token, Postgres, Nextcloud admin, Gitea DB). Readable by root only.
- `/opt/asi-platform/data/gitea/gitea/jwt/private.pem` — Gitea JWT signing key. Container-internal use.
- `/etc/letsencrypt/` — TLS private keys present on host.

---

## Host: 10.20.0.11 — automation2

**OS:** Debian GNU/Linux 12 (bookworm)
**Kernel:** 6.17.9-1-pve
**Virtualisation:** LXC container (Proxmox)
**Uptime at audit time:** 1h 33m (booted 16:30 today)
**Load:** 1.24 / 1.06 / 0.86

### Services running
- sshd, docker, containerd, postfix (localhost only), cron, systemd-networkd

### Docker containers
| Container | Image | Exposed ports |
|-----------|-------|---------------|
| n8n | n8nio/n8n:latest | 0.0.0.0:5678 |
| portainer | portainer/portainer-ce:latest | 0.0.0.0:9000 |
| gitea | gitea/gitea:latest | 0.0.0.0:3000, 0.0.0.0:2222 |
| prometheus | prom/prometheus:latest | 0.0.0.0:9090 |
| grafana | grafana/grafana:latest | 0.0.0.0:3001 |
| jobhunt-api | node:18-alpine | 0.0.0.0:3099 |
| cadvisor | gcr.io/cadvisor/cadvisor | internal only |
| redis | redis:7-alpine | internal only |
| postgres | postgres:16 | internal only |

---

### [CRITICAL] — Docker daemon TCP API exposed on 0.0.0.0:2375 (no TLS, no authentication)

**What it is:** The Docker daemon is configured to listen on `tcp://0.0.0.0:2375` in addition to the Unix socket, with no TLS and no client certificate authentication. This is explicitly set in `/etc/docker/daemon.json`:
```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```
Verified exploitable during this audit — `curl http://10.20.0.11:2375/version` returns full Docker version JSON and `curl http://10.20.0.11:2375/containers/json` lists all running containers, unauthenticated.

**Where:** `/etc/docker/daemon.json`, confirmed via `ss -tlnp` (port 2375/tcp `*:2375`).

**Why it matters:** The Docker API provides complete control over the Docker daemon. An attacker can:
- List, inspect, start, stop, and delete all containers
- Create a new container with the host root filesystem bind-mounted and write arbitrary files (e.g. SSH keys, cron jobs, `/etc/passwd`)
- Achieve full root-equivalent host compromise in seconds, no credentials required
- Pivot laterally to other lab hosts using root's SSH key found in `/root/.ssh/id_ed25519`

This is a trivially exploitable path to full host compromise from any host on the 10.20.0.0/24 network.

**Recommended fix:** Remove the `tcp://` entry from `daemon.json` entirely. If remote Docker API access is needed, use SSH tunnelling (`docker context`) or TLS mutual authentication (client certs). Restart dockerd after the change.

---

### [CRITICAL] — Root SSH login with password authentication explicitly enabled

**What it is:** `/etc/ssh/sshd_config` explicitly sets:
```
PermitRootLogin yes
PasswordAuthentication yes
```
Both are uncommented, active, and non-default. Root login with a password is open to any host on the network.

**Where:** `/etc/ssh/sshd_config`.

**Why it matters:** Combined with no host firewall and a live network interface on the lab subnet, any machine on 10.20.0.0/24 (including Kali at 10.20.0.20) can attempt to brute-force the root password directly. Even a short wordlist or common-password spray could succeed. Root compromise of this host gives an attacker access to all 9 running containers and their data.

**Recommended fix:** Set `PermitRootLogin prohibit-password` (or `no`), set `PasswordAuthentication no`, and reload sshd. Ensure root's `authorized_keys` contains the correct workstation key before making this change.

---

### [HIGH] — No host-level firewall; all service ports fully exposed

**What it is:** `iptables -L` shows INPUT and OUTPUT chains with policy ACCEPT and zero custom rules. All nine exposed container ports (2222, 2375, 3000, 3001, 5678, 9000, 9090, 3099, and SSH 22) are reachable from anywhere on the network with no restriction.

**Where:** iptables INPUT chain — 0 rules, policy ACCEPT.

**Why it matters:** There is no backstop if any service's own authentication fails or is bypassed. The Docker API (2375) and Portainer (9000) issues identified here are exploitable precisely because there is no firewall to limit who can reach them.

**Recommended fix:** Implement host-level iptables (or nftables) rules with a default DROP policy. Allow only the necessary ports, and consider restricting management interfaces (2375, 9000, 9090) to the workstation IP only (10.20.0.0/24 → specific IP, not the subnet, where possible).

---

### [HIGH] — Portainer accessible via unencrypted HTTP, with Docker socket access

**What it is:** Portainer is running on port 9000/HTTP (plain, not HTTPS). It has `/var/run/docker.sock` bind-mounted as read-write. Anyone who can access the Portainer web UI can, through Portainer, control all Docker containers on the host.

**Where:** `docker inspect portainer` → Binds include `/var/run/docker.sock:/var/run/docker.sock:rw`. Port 9000 confirmed listening.

**Why it matters:** Portainer is a container management web interface. With Docker socket access, it is effectively a root shell. Accessing it over HTTP means the admin session cookie and credentials traverse the network in cleartext.

**Recommended fix:** Restrict Portainer to localhost or a specific management IP using host firewall rules. Enable Portainer's built-in HTTPS (port 9443). Consider whether Portainer is needed given that Docker socket access is already available via SSH.

---

### [HIGH] — N8N_SECURE_COOKIE=false; n8n served on HTTP only

**What it is:** The n8n container has `N8N_SECURE_COOKIE=false` in its environment, meaning the `Secure` flag is not set on session cookies. N8n is served on port 5678 with no TLS. The `N8N_BASIC_AUTH_ACTIVE=true` means credentials are sent as base64-encoded HTTP Basic Auth headers on every request.

**Where:** `docker inspect n8n` environment variables, docker-compose.yml.

**Why it matters:** HTTP Basic Auth credentials and session cookies transit the network in cleartext. A passive network observer on 10.20.0.0/24 can capture n8n credentials. N8n has access to the internal Postgres database and is configured with Redis for queue management — credential compromise gives an attacker persistent workflow execution capability.

**Additional finding:** `WEBHOOK_URL=http://192.168.1.9:5678/` — this points to the production LAN server (`automation`, 192.168.1.9) rather than the lab host. This is a misconfiguration (Lab → LAN is REJECTED at the firewall) and reveals awareness of LAN topology within a lab container.

**Recommended fix:** Put n8n behind a TLS reverse proxy (nginx with Let's Encrypt, similar to asi-platform). Set `N8N_SECURE_COOKIE=true`. Update WEBHOOK_URL to point to the correct lab host. Consider switching from Basic Auth to n8n's native authentication.

---

### [MEDIUM] — Root has outbound SSH private key; 10 known hosts

**What it is:** `/root/.ssh/` contains an `id_ed25519` private key (created 2026-03-03), a corresponding public key, and a `known_hosts` file with 10 hashed host entries (plus a `known_hosts.old` with more). Root is actively initiating SSH sessions to other hosts.

**Where:** `ls -la /root/.ssh/` on automation2.

**Why it matters:** If automation2 is compromised, the attacker inherits root's SSH private key and can attempt to authenticate to any of the 10+ hosts in `known_hosts`. The hashed format prevents reading destinations directly, but an attacker with full host access can use the key to attempt connections or check Bash history. The scope of what those 10 hosts are is unknown — they could include other lab machines or (if there was prior LAN connectivity) production hosts.

**Recommended fix:** Audit what automation2's root key is authorised for. If it's used for automation jobs, consider replacing with a dedicated service account key with narrower permissions. Review and trim `known_hosts`.

---

### [MEDIUM] — Prometheus exposed on 9090, no authentication

**What it is:** Prometheus is listening on `0.0.0.0:9090` with no authentication layer. Prometheus scrapes cAdvisor (container metrics) and Docker metrics. The Prometheus HTTP API allows querying all collected time series.

**Where:** Port 9090 confirmed listening; `prometheus.yml` shows scrape targets including `cadvisor:8080` and `host.docker.internal:9323`.

**Why it matters:** Prometheus metrics expose detailed information about container resource usage, network traffic patterns, and process activity. An unauthenticated attacker can query the API to enumerate running workloads, timing patterns, and internal network topology without triggering any auth failure.

**Recommended fix:** Put Prometheus behind a reverse proxy with authentication, or restrict port 9090 to localhost via firewall. The Grafana instance (port 3001) is the intended consumer and can be the only allowed client.

---

### [MEDIUM] — Grafana on HTTP only (port 3001)

**What it is:** Grafana is accessible on port 3001 with no TLS. Admin credentials (`GF_SECURITY_ADMIN_PASSWORD`) are set via environment variable and transmitted in cleartext over HTTP.

**Where:** Docker-compose port mapping `3001:3000`, no TLS configuration observed.

**Why it matters:** Grafana admin access provides full dashboard control, and potentially datasource credentials. HTTP means login credentials are cleartext on the wire.

**Recommended fix:** Place Grafana behind a TLS reverse proxy, or configure Grafana's native TLS.

---

### [MEDIUM] — cAdvisor mounts host root filesystem (read-only)

**What it is:** The cAdvisor container is started with the following bind mounts:
```
/:/rootfs:ro
/var/run:/var/run:ro
/sys:/sys:ro
/var/lib/docker/:/var/lib/docker:ro
```
This is the standard cAdvisor deployment, but it grants the container read access to the entire host filesystem and all Docker metadata.

**Where:** docker-compose.yml `cadvisor` service.

**Why it matters:** If cAdvisor itself is compromised (e.g. via a vulnerability in its web interface), an attacker has read access to every file on the host, including `/opt/automation/.env`, `/root/.ssh/`, and all container data volumes. CAdvisor's own port (8080) is not externally mapped, which is correct — but it is accessible to all other containers on the `automation_automation` bridge.

**Recommended fix:** This is largely unavoidable for cAdvisor's function. Mitigate by ensuring cAdvisor is not reachable externally (currently correct) and by applying host firewall rules that prevent other compromised containers from reaching its internal port unnecessarily.

---

### [LOW] — All Docker images have pending updates

Same as asi-platform — all nine images are flagged with `U` in `docker images` output.

**Recommended fix:** `docker compose pull && docker compose up -d` on a regular schedule.

---

### [LOW] — No inter-container network segmentation

**What it is:** All containers (n8n, postgres, redis, gitea, portainer, prometheus, grafana, cadvisor, jobhunt-api) share a single bridge network: `automation_automation`. There is no internal network segmentation.

**Where:** `docker network ls`, docker-compose.yml — single `automation` network.

**Why it matters:** If any container is compromised, the attacker can freely communicate with all other containers on the bridge — including postgres (5432), redis (6379), and cAdvisor (8080). Compare with asi-platform, which uses separate `proxy` and `internal` networks.

**Recommended fix:** Segment containers onto purpose-specific networks. At minimum, put the database and redis on an isolated internal network accessible only by the services that need them.

---

### [LOW] — Postfix running (no apparent use case)

Same observation as asi-platform — Postfix MTA running on localhost only. Unnecessary unless applications require local mail relay.

---

### [INFO] — Sensitive files located

- `/opt/automation/.env` — contains Postgres credentials, n8n auth credentials, Grafana admin password, Gitea admin password, jobhunt DB password. Readable by root only (not checked for world-readable).
- `/opt/automation/portainer/portainer.key` — Portainer internal key.
- `/opt/automation/portainer/certs/key.pem` — TLS private key (for Portainer's HTTPS, which appears to be on port 9443 — not observed as actively serving).
- `/opt/automation/gitea/gitea/jwt/private.pem` — Gitea JWT signing key.

### [INFO] — Redis and PostgreSQL are internal-only

Neither redis (6379) nor postgres (5432) are port-mapped to the host. Both are only accessible within the `automation_automation` Docker bridge. This is correct.

### [INFO] — Gitea SSH on port 2222

Gitea's SSH interface is mapped to host port 2222. No authentication bypass observed; Gitea's own auth applies. This is an additional SSH-like surface but requires valid Gitea credentials.

### [INFO] — No Tailscale on automation2

Unlike asi-platform, automation2 has no Tailscale. The VLAN isolation applies correctly to this host (no overlay bypass observed). The Lab → LAN REJECT rule is the only boundary.

### [INFO] — shadow file permissions correct on both hosts

`/etc/shadow` is `rw-r-----` (0640) owned root:shadow on both hosts. Not world-readable.

### [INFO] — Root password hash algorithm

Both hosts use yescrypt (`[HASH REDACTED]`) for root password hashing — a modern algorithm. If passwords are weak this doesn't help much, but the hashing itself is not the weak point.

---

## What Was Not Checked

- **Actual credential values** — `.env` files were inspected for keys only; values were not read. This is by policy (Blue Team does not exfiltrate credentials).
- **appuser home directory on asi-platform** — `/home/appuser/.ssh/` was not checked. Skipped to limit scope; should be reviewed in remediation.
- **Gitea internal configuration** — Did not authenticate to Gitea to check for public repositories, weak admin credentials, or exposed tokens.
- **Nextcloud internal state** — Did not log in to Nextcloud; admin credential strength unknown.
- **n8n workflows** — Did not authenticate to n8n; existing workflows may contain sensitive credentials stored in workflow nodes.
- **Portainer state** — Did not authenticate to Portainer; could not verify whether a Portainer admin account exists or what its credential strength is.
- **Known_hosts resolution on automation2** — Hashed; not resolved. Could not determine which hosts root has connected to.
- **Container escape paths** — Not tested (read-only audit). cAdvisor's root mount was noted as theoretical risk but not explored.
- **Cloudflare API token scope** — Token is present in `.env`. Its actual permission scope in the Cloudflare dashboard was not checked.
- **Web application vulnerability testing** — No fuzzing, injection testing, or authenticated scanning was performed. This is Phase 2 scope.
- **Inter-VLAN routing validation** — Did not attempt to reach 192.168.1.x from lab hosts to confirm firewall rules are functioning as described (except inferring from configuration).

---

## Baseline Notes

- Both hosts are fresh builds (booted today for the first time in final configuration, after several iterative reboots during setup).
- Both hosts share identical kernel versions (6.17.9-1-pve) and are running the same base Debian 12 image.
- Neither host has apt upgradable packages — base OS packages are current as of install. Security exposure is entirely in application/container layer.
- The shared load average (1.24/1.06/0.86) across both hosts at audit time is likely a reporting artefact of the LXC environment sharing the Proxmox host's counters, not a real load issue.
- No evidence of active intrusion or unexpected processes at audit time.
