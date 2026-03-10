# Uptime Kuma

[← Back to README](../../README.md) | [← Portainer](portainer.md)

---

## What Is It?

Uptime Kuma is a self-hosted monitoring tool that checks whether your services are up and running, and alerts you when they are not. It provides a clean dashboard showing the status and response time of every service, with uptime history over time.

It is the self-hosted equivalent of services like Pingdom or UptimeRobot — but running on your own infrastructure, with no subscription required.

**Why it's in this project:** No infrastructure deployment is complete without monitoring. Knowing that a service has gone down before a user reports it is a basic operational requirement. Including monitoring demonstrates that this project is built with operational maturity in mind, not just deployment.

---

## Why We Need It

Uptime Kuma watches every service in the stack and alerts immediately if something becomes unavailable. On constrained hardware, services can occasionally restart or become slow — Uptime Kuma makes this visible.

It also produces the kind of uptime metrics and status dashboards that are expected in any professional infrastructure environment.

**Access:** Tailscale only — `http://[tailscale-ip]:3001`. Never exposed publicly.

---

## Technical Implementation

```yaml
uptime-kuma:
  image: louislam/uptime-kuma:latest
  container_name: uptime-kuma
  restart: unless-stopped
  volumes:
    - uptime_kuma_data:/app/data
  networks:
    - internal
```

### What Is Monitored

| Monitor | Type | Check Interval |
|---|---|---|
| Nextcloud | HTTPS | Every 5 minutes |
| Gitea | HTTPS | Every 5 minutes |
| Nginx | TCP Port | Every 1 minute |
| PostgreSQL | TCP Port (5432) | Every 5 minutes |
| Proxmox UI | HTTPS | Every 5 minutes |

### Ansible Role

Provisioned by: `ansible/roles/uptime-kuma/`

The role deploys the container. Monitor configuration is done via the Uptime Kuma UI after deployment — this is a documented manual step (the Uptime Kuma API for automated monitor creation is limited).

---

## Gotchas & Notes

- Uptime Kuma persists its configuration in a volume — this must be included in backups
- Notification setup (email, Telegram, etc.) is configured in the UI after deployment — credentials are not stored in the repository

---

[Next: Gitea →](gitea.md)
