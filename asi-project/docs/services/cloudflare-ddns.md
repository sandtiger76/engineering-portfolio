# Cloudflare DDNS

[← Back to README](../../README.md) | [← Gitea](gitea.md)

---

## What Is It?

DDNS stands for Dynamic DNS. Most home internet connections are assigned a dynamic IP address — meaning the public IP address your router uses can change at any time when your ISP renews it.

This is a problem for hosting services — if your IP changes, your domain name stops resolving to your server.

Cloudflare DDNS solves this by running a lightweight background process that monitors your current public IP address and automatically updates your DNS record via the Cloudflare API whenever it changes. Your domain always points to the right place, without any manual intervention.

**Why it's in this project:** It is a prerequisite for hosting anything publicly on a home internet connection. It also demonstrates API-driven automation — a fundamental infrastructure skill.

---

## Why We Need It

Without DDNS, `qcbhomelab.online` would stop working every time the ISP assigns a new IP address. With DDNS, the update happens automatically within minutes of any IP change, and the platform remains accessible without any manual action.

---

## Technical Implementation

The `cloudflare-ddns` Docker image handles this automatically.

```yaml
cloudflare-ddns:
  image: favonia/cloudflare-ddns:latest
  container_name: cloudflare-ddns
  restart: unless-stopped
  environment:
    - CF_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    - DOMAINS=qcbhomelab.online,nextcloud.qcbhomelab.online,gitea.qcbhomelab.online
    - PROXIED=true
    - UPDATE_CRON=@every5m
  networks:
    - internal
```

### How It Works

1. Every 5 minutes the container checks your current public IP
2. If the IP has changed, it calls the Cloudflare API to update the DNS A record
3. Cloudflare propagates the change globally within seconds
4. `PROXIED=true` ensures the Cloudflare proxy remains active — your real IP is never in the DNS record

### Required Cloudflare API Token Permissions

The API token needs minimal permissions — principle of least privilege:

| Permission | Reason |
|---|---|
| Zone — DNS — Edit | To update A records |
| Zone — Zone — Read | To find the zone ID |

This token is stored in Ansible Vault, never in plaintext.

### Ansible Role

Provisioned by: `ansible/roles/cloudflare-ddns/`

---

## Gotchas & Notes

- Use `PROXIED=true` — this is critical. Without it, the real IP address would be exposed in DNS records, defeating the Cloudflare security model
- The API token must be a **scoped API token**, not the global API key — scoped tokens follow least privilege and can be revoked independently
- Verify the DDNS container is working by checking its logs after first deployment: `docker logs cloudflare-ddns`

---

[Next: Proxmox LXC Setup →](../tasks/proxmox-lxc.md)
