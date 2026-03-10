# Cloudflare DDNS

[← Back to README](../../README.md)

---

## What Is It?

Dynamic DNS (DDNS) is a service that automatically updates DNS records when a server's public IP address changes. Most residential and small business internet connections are assigned a dynamic IP — one that can change at any time when the router reconnects to the ISP.

Without DDNS, a changing IP would make the hosted services unreachable until the DNS records were manually updated. With DDNS, the update happens automatically within minutes of the IP changing.

**Why it's in this project:** `qcbhomelab.online` is hosted on a residential internet connection with a dynamic IP. The DDNS container ensures Nextcloud and Gitea remain reachable even after an IP change, with zero manual intervention.

---

## Why We Need It

The three public-facing DNS records must always point to the current public IP:

| Record | Purpose |
|---|---|
| `qcbhomelab.online` | Apex domain |
| `nextcloud.qcbhomelab.online` | Nextcloud |
| `gitea.qcbhomelab.online` | Gitea |

The DDNS container checks the current public IP every 5 minutes and updates any Cloudflare A records that have drifted.

---

## Technical Implementation

### Container Configuration

```yaml
cloudflare-ddns:
  image: favonia/cloudflare-ddns:latest
  container_name: cloudflare-ddns
  restart: unless-stopped
  environment:
    - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    - DOMAINS=qcbhomelab.online,nextcloud.qcbhomelab.online,gitea.qcbhomelab.online
    - PROXIED=true
    - IP6_PROVIDER=none
  networks:
    - internal
```

### Environment Variables

| Variable | Value | Purpose |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | from `.env` | Cloudflare API authentication |
| `DOMAINS` | comma-separated list | Records to keep updated |
| `PROXIED` | true | Keep orange cloud on — don't expose real IP |
| `IP6_PROVIDER` | none | Suppress IPv6 probing on IPv4-only connection |

### Verification

```bash
# Check container logs
docker logs cloudflare-ddns

# Confirm DNS resolves via Cloudflare proxy (should return Cloudflare IPs, not real IP)
dig qcbhomelab.online +short
dig nextcloud.qcbhomelab.online +short
```

Expected log output when working correctly:
```
🌐 Detected the IPv4 address 62.68.174.87
🤷 The A records of qcbhomelab.online are already up to date
🤷 The A records of nextcloud.qcbhomelab.online are already up to date
🤷 The A records of gitea.qcbhomelab.online are already up to date
⏰ Checking the IP addresses in about 4m57s . . .
```

When an IP change is detected it will show `✅ Updated` instead of `🤷 already up to date`.

### Security Hardening

The container runs with maximum restriction:

```yaml
read_only: true
cap_drop: [ALL]
security_opt:
  - no-new-privileges:true
```

All Linux capabilities dropped, filesystem read-only, privilege escalation prevented. The container only makes outbound HTTPS calls — it needs no filesystem writes and no special privileges.

### Ansible Role

Provisioned by: `ansible/roles/cloudflare_ddns/`

The role uses `blockinfile` to inject the service block into `docker-compose.yml`. Requires the `community.docker` collection:

```bash
ansible-galaxy collection install community.docker
```

> **Note:** `blockinfile` adds Ansible marker comments inside `docker-compose.yml`. This is fine for idempotency but makes the file slightly less clean for manual reading. On a greenfield deploy the role is the right path — the markers won't be noticeable. For this project we deployed manually first and the role serves as the documented repeatable procedure.

---

## Gotchas & Notes

**`CF_API_TOKEN` is deprecated — use `CLOUDFLARE_API_TOKEN`**
Older documentation and examples use `CF_API_TOKEN` as the environment variable name. The current `favonia/cloudflare-ddns` image expects `CLOUDFLARE_API_TOKEN`. Using the old name causes silent authentication failures.

**`IP6_PROVIDER=none` required on IPv4-only connections**
Without this, the container repeatedly attempts to detect an IPv6 address, logs errors, and clutters the output. Setting `IP6_PROVIDER=none` suppresses IPv6 probing entirely on networks that don't have IPv6.

**`PROXIED=true` is critical for security**
Without this, the DDNS container would update records with the orange cloud OFF, exposing the real public IP directly. Always set `PROXIED=true` to ensure Cloudflare continues proxying traffic.

**Cloudflare API token scope**
The token only needs `Zone → DNS → Edit` permission scoped to `qcbhomelab.online`. The same token used for SSL certificate issuance (Certbot) works here — no separate token needed.

**Check interval**
The container checks every ~5 minutes. An IP change will be reflected in DNS within 5 minutes of the router reconnecting.

---

[← Back to README](../../README.md)
