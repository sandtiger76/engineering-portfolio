# Runbook

[← Back to README](../../README.md) | [← Backup & DR](backup-dr.md)

---

## What Is a Runbook?

A runbook is a reference document for common operational procedures. It answers the question: *"How do I do X on this platform?"* — for both routine tasks and incident response.

Professional infrastructure teams maintain runbooks so that any engineer can operate the platform, not just the person who built it.

---

## Common Procedures

### Check Platform Health

```bash
# All containers running?
docker compose ps

# Recent logs
docker compose logs --tail=50

# System resources
htop
df -h
```

### Restart a Service

```bash
cd /opt/asi-platform
docker compose restart [service_name]

# Services: nextcloud, postgresql, nginx, gitea, portainer, uptime-kuma, cloudflare-ddns
```

### Full Stack Restart

```bash
cd /opt/asi-platform
docker compose down
docker compose up -d
```

### Deploy Infrastructure from Scratch

```bash
# From your laptop (Ansible control node)
ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml --ask-vault-pass
```

### Update All Container Images

```bash
cd /opt/asi-platform
docker compose pull
docker compose up -d
```

### Renew SSL Certificates (Manual)

```bash
# Certificates renew automatically — only needed if timer fails
certbot renew
docker compose exec nginx nginx -s reload
```

### Check SSL Certificate Expiry

```bash
certbot certificates
# or
echo | openssl s_client -connect nextcloud.qcbhomelab.online:443 2>/dev/null | openssl x509 -noout -dates
```

### View Service Logs

```bash
docker compose logs nextcloud
docker compose logs nginx
docker compose logs postgresql
```

### Connect via Tailscale (Remote Management)

```bash
# SSH to the LXC
ssh root@asi-platform   # Tailscale resolves the hostname

# Access management UIs in browser
# Proxmox:  https://proxmox2  (Tailscale hostname)
# Portainer: http://asi-platform:9000
# Uptime Kuma: http://asi-platform:3001
```

---

## Incident Response

### Service Down (Uptime Kuma Alert)

1. SSH to the LXC via Tailscale
2. Run `docker compose ps` — identify the stopped container
3. Check logs: `docker compose logs [service]`
4. Attempt restart: `docker compose restart [service]`
5. If restart fails, check disk space (`df -h`) and memory (`free -h`)
6. If resource issue — identify resource-hungry container with `docker stats`
7. Document the incident in the [postmortem log](lessons-learned.md)

### Cannot SSH to LXC

1. Log into Proxmox via Tailscale: `https://proxmox2:8006`
2. Open LXC console from the Proxmox UI
3. Diagnose from the console
4. Check Tailscale status: `tailscale status`

### Cloudflare DDNS Not Updating

```bash
docker logs cloudflare-ddns
# Look for API errors or permission denied messages
# Verify API token is still valid in Cloudflare dashboard
```

---

[Next: Lessons Learned →](lessons-learned.md)
