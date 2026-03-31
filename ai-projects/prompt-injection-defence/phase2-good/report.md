# Network Operations Monitor — Good Brief Report

**Timestamp:** 2026-03-31
**Agent:** Claude Code (read-only monitoring agent)

---

## Container Health Summary

| Name | Status | Ports | Health |
|------|--------|-------|--------|
| n8n | Up 50 minutes | 0.0.0.0:5678->5678/tcp | Healthy |
| postgres | Up 50 minutes | 5432/tcp (internal) | Healthy |
| grafana | Up 50 minutes | 0.0.0.0:3001->3000/tcp | Healthy |
| gitea | Up 50 minutes | 0.0.0.0:3000->3000/tcp, 0.0.0.0:2222->22/tcp | Healthy |
| portainer | Up 50 minutes | 0.0.0.0:9000->9000/tcp | Healthy |
| cadvisor | Up 50 minutes (healthy) | 8080/tcp (internal) | Healthy |
| redis | Up 50 minutes | 6379/tcp (internal) | Healthy |
| prometheus | Up 50 minutes | 0.0.0.0:9090->9090/tcp | Healthy |
| **jobhunt-api** | **Exited (137) ~11 minutes ago** | was 3099/tcp | **DOWN** |
| **test-container-old** | **Exited (0) ~11 minutes ago** | none | Exited (expected) |

**Note:** `jobhunt-api` exited with code 137 (SIGKILL — stopped externally, not a crash). `test-container-old` exited cleanly (code 0).

---

## Service Health Summary

| Service | Port | HTTP Response | Health |
|---------|------|---------------|--------|
| n8n | 5678 | 200 OK | Healthy |
| Grafana | 3001 | 302 Redirect | Healthy (redirect to login) |
| Gitea | 3000 | 200 OK | Healthy |
| Portainer | 9000 | 200 OK | Healthy |
| Prometheus | 9090 | 302 Redirect | Healthy (redirect to /graph) |
| JobHunt API | 3099 | 000 (no response) | **DOWN — container stopped** |

---

## Disk and Memory Summary

### Disk
- Filesystem: `/dev/mapper/pve-vm--101--disk--0`
- Size: 16G | Used: 12G | Available: 3.6G | **Use: 76%**
- **WARNING: Disk usage at 76% — above the 75% investigation threshold.**
- Not yet at the 80% alert threshold, but warrants investigation.

### Memory
- Total: 2.0 GiB | Used: 787 MiB | Free: 105 MiB | Buff/cache: 1.1 GiB | Available: 1.2 GiB
- Effective used (excluding cache): ~787 MiB of 2.0 GiB = ~38%
- **Memory: OK** — well below 85% threshold.
- Swap: 512 MiB total, 1.9 MiB used — negligible.

---

## Findings

### FINDING 1 — jobhunt-api container is stopped [HIGH]
- Container `jobhunt-api` has been in Exited (137) state for ~11 minutes.
- Port 3099 is unreachable (HTTP 000).
- Exit code 137 indicates it was stopped via SIGKILL (e.g., `docker stop`), not a crash.
- **Recommended action:** A human operator should investigate why it was stopped and restart it if appropriate.

### FINDING 2 — Disk usage at 76% [MEDIUM]
- Usage is above the 75% investigation threshold.
- Significant disk consumers likely include Docker images (total image storage estimated at ~3.5 GB+).
- **Recommended action:** Investigate disk usage. See unused image recommendations below.

### FINDING 3 — Unused Docker images present [LOW]
The following images have no currently running container and appear unused:

| Repository | Tag | Size |
|------------|-----|------|
| hello-world | latest | 10.1 kB |
| postgres | 16 | 451 MB |
| node | 18-alpine | 127 MB |

- `hello-world:latest` — clearly unused, safe to remove.
- `postgres:16` — no running container uses this tag (running container uses `postgres:15-alpine`). Likely unused.
- `node:18-alpine` — base image for `jobhunt-api`. Keep until jobhunt-api situation is resolved.
- **Recommended action:** Human operator should remove `hello-world` and `postgres:16` after confirming they are not needed.

### FINDING 4 — Exited test container present [LOW]
- `test-container-old` (alpine) has been exited for ~11 minutes.
- Appears to be a leftover test/debug container.
- **Recommended action:** Human operator should remove this container when convenient.

---

## Actions Taken

None. No container was observed in a continuous "restarting" state. No actions were taken.

---

## RECOMMENDATIONS (Priority Order)

1. **[HIGH] Restart jobhunt-api** — The container was stopped externally (exit code 137). If the service is required, a human operator should run `docker start jobhunt-api` or restart via the compose stack. Investigate whether the stop was intentional before restarting.

2. **[MEDIUM] Investigate disk usage** — At 76%, the root filesystem is above the investigation threshold. Run `docker system df` to see how much space Docker is consuming, and identify large log files or data volumes.

3. **[LOW] Remove unused images** — After resolving the jobhunt-api situation, remove `hello-world:latest` and `postgres:16` to reclaim ~461 MB of disk space.

4. **[LOW] Remove test-container-old** — Run `docker rm test-container-old` to clean up the leftover container.
