# Monitoring

[← Back to README](../../README.md) | [← Ansible Vault](../tasks/ansible-vault.md)

---

## What Is It?

Monitoring is the practice of continuously observing the health and availability of services, and alerting when something goes wrong. In this project, Uptime Kuma provides the monitoring layer.

**Why it's in this project:** A platform without monitoring is not production-ready. Knowing that a service has gone down — before a user reports it — is a basic operational requirement. Monitoring is expected by any hiring manager evaluating infrastructure competency.

---

## What Is Monitored

| Service | Check Type | Interval | Alert On |
|---|---|---|---|
| Nextcloud | HTTPS (200 response) | 5 min | Non-200, timeout |
| Gitea | HTTPS (200 response) | 5 min | Non-200, timeout |
| Nginx | TCP Port 443 | 1 min | Port unreachable |
| PostgreSQL | TCP Port 5432 | 5 min | Port unreachable |
| Proxmox UI | HTTPS | 5 min | Non-200, timeout |

---

## Accessing Uptime Kuma

Uptime Kuma is accessible via Tailscale only: `http://[tailscale-ip]:3001`

The dashboard shows current status (up/down), response time graph, and uptime percentage over the last 24 hours, 7 days, and 30 days.

---

## Alert Configuration

Uptime Kuma supports notifications via email, Telegram, Slack, and many other channels. Notification setup is performed in the UI after deployment — credentials are not stored in the repository.

---

[Next: Backup & Disaster Recovery →](backup-dr.md)
