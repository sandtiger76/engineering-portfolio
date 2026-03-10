# Security Overview

[← Back to README](../../README.md) | [← Design Decisions](DECISIONS.md)

---

## Security Philosophy

Security in this project is not an afterthought — it is a design constraint applied from the start. The goal is a platform that is genuinely secure by default, not one that has security bolted on later.

The core principle: **reduce attack surface at every layer.**

---

## Security Layers

### 1. Network — No Open Ports

Zero inbound ports are forwarded on the router. This alone eliminates the most common homelab attack vector — exposed services on open ports.

- Public traffic enters via Cloudflare's proxy network only
- Your real IP address is never visible to the internet
- The management plane is unreachable from the internet entirely

### 2. Zero-Trust Management — Tailscale

All infrastructure management (Proxmox, Portainer, Uptime Kuma, SSH) is accessible only via Tailscale.

Tailscale uses WireGuard under the hood — a modern, audited VPN protocol. Every device must be authenticated and authorised before it can reach any management service. There is no way to access these services without being on the Tailnet.

### 3. Application Layer — Cloudflare WAF

Nextcloud and Gitea sit behind Cloudflare's Web Application Firewall (free tier). This provides:
- Protection against common web exploits (SQLi, XSS)
- Rate limiting on login pages
- Bot protection
- DDoS mitigation

### 4. SSL/TLS — Automated Certificate Management

All public services use HTTPS with certificates issued by Let's Encrypt. Certificates are renewed automatically via a cron job — no manual renewal, no certificate expiry incidents.

The DNS-01 challenge method is used — meaning certificate renewal never requires an open port.

### 5. Secrets Management — Ansible Vault

No credentials, API tokens, or passwords exist in plaintext anywhere in the repository. All sensitive values are encrypted using Ansible Vault before being committed to Git.

This means the repository can be made public without exposing any secrets.

### 6. OS Hardening

- UFW firewall enabled — default deny inbound, explicit allow rules only
- fail2ban — automatic IP banning after repeated failed authentication attempts
- SSH — password authentication disabled, key-based auth only
- Non-root service accounts — no service runs as root

---

## Security Summary Table

| Control | Implementation | Purpose |
|---|---|---|
| No open ports | Router — zero port forwarding | Eliminates direct internet exposure |
| Zero-trust network | Tailscale (WireGuard) | Secure management plane access |
| DDoS / WAF | Cloudflare free tier | Application layer protection |
| IP masking | Cloudflare proxy | Real IP never exposed |
| Encrypted transit | Let's Encrypt TLS | All public traffic encrypted |
| Automated renewal | Certbot + Cloudflare DNS API | No certificate expiry risk |
| Secrets encryption | Ansible Vault | No plaintext credentials in Git |
| Firewall | UFW — default deny | Host-level network control |
| Brute force protection | fail2ban | Automatic attacker lockout |
| Least privilege | Non-root service users | Limits blast radius of compromise |
| Auth hardening | SSH key-only, no passwords | Eliminates password brute force |

---

## What This Maps To In Enterprise

| Homelab Implementation | Enterprise Equivalent |
|---|---|
| Cloudflare proxy | Reverse proxy / CDN (Akamai, CloudFront) |
| Tailscale | Corporate VPN / Zero Trust Network Access (ZTNA) |
| Ansible Vault | HashiCorp Vault / AWS Secrets Manager |
| UFW | Host-based firewall / Security Groups |
| Let's Encrypt automation | Internal PKI / automated cert management |
| fail2ban | SIEM alert + auto-block response |

---

[Next: Nextcloud →](services/nextcloud.md)
