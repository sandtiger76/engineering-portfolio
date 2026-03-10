# Architecture Overview

[← Back to README](../../README.md)

---

## Overview

This platform follows a layered architecture — separating the public-facing application tier from the private infrastructure management plane. These two layers have different security requirements and are accessed through entirely different mechanisms.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     CLOUDFLARE                              │
│         DNS · WAF · DDoS Protection · Proxy                 │
│              qcbhomelab.online                              │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTPS (443)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  CUDY WR3000 (OpenWrt)                      │
│              Dynamic IP — auto-updated via                  │
│                   Cloudflare DDNS API                       │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               PROXMOX VE — Intel NUC                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              DOCKER LXC CONTAINER                   │   │
│  │                                                     │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │  Nginx   │  │Nextcloud │  │   PostgreSQL      │  │   │
│  │  │ (proxy + │→ │          │→ │   (database)      │  │   │
│  │  │   SSL)   │  │          │  │                   │  │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │   │
│  │                                                     │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │  Gitea   │  │Portainer │  │  Uptime Kuma      │  │   │
│  │  │  (git)   │  │(docker   │  │  (monitoring)     │  │   │
│  │  │          │  │  mgmt)   │  │                   │  │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │   │
│  │                                                     │   │
│  │  ┌──────────┐  ┌──────────────────────────────┐    │   │
│  │  │Cloudflare│  │        Tailscale              │    │   │
│  │  │   DDNS   │  │  (management plane access)    │    │   │
│  │  └──────────┘  └──────────────────────────────┘    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

                    MANAGEMENT PLANE
                         │
                    (Tailscale only)
                         │
              ┌──────────┴──────────┐
              │   Engineer Laptop   │
              │  (anywhere, secure) │
              └─────────────────────┘
```

---

## Network Design

### Public Access (Application Tier)

Nextcloud and Gitea are reachable publicly via `qcbhomelab.online`. Cloudflare acts as an intermediary — your real IP address is never exposed to the internet. All traffic is encrypted via HTTPS with certificates issued by Let's Encrypt.

**Critically: zero inbound ports are open on the router.** Cloudflare connects outbound via a proxy relationship. This is standard practice in modern infrastructure design.

### Private Access (Management Plane)

Portainer, Uptime Kuma, Proxmox, and SSH access are **never exposed publicly**. They are only accessible via Tailscale — a zero-trust overlay network. Even if Cloudflare were misconfigured, the management plane remains unreachable.

### Dynamic DNS

The public IP assigned by the ISP changes periodically. A lightweight container running on the NUC polls the current public IP and updates the Cloudflare DNS record via API when it changes. The domain always resolves correctly without manual intervention.

---

## Service Responsibilities

| Service | Role | Access |
|---|---|---|
| Nginx | Reverse proxy, SSL termination | Public via Cloudflare |
| Nextcloud | Collaboration platform (files, calendar, contacts) | Public via Cloudflare |
| PostgreSQL | Database backend for Nextcloud and Gitea | Internal only |
| Gitea | Self-hosted Git — hosts this project's Ansible code | Public via Cloudflare |
| Portainer | Docker container management UI | Tailscale only |
| Uptime Kuma | Service health monitoring and alerting | Tailscale only |
| Cloudflare DDNS | Keeps DNS record updated with current public IP | Outbound only |
| Tailscale | Zero-trust management network | Device auth only |

---

## Automation Layer

The entire stack above the Proxmox installation is provisioned by Ansible. The Ansible control node runs from the engineer's laptop. One command creates the LXC, installs Docker, deploys all services, configures the firewall, and sets up Tailscale.

See [Ansible Vault — Secrets Management](../tasks/ansible-vault.md) for how credentials are handled.

---

## Key Design Principles

**Reproducibility** — destroying and rebuilding the entire platform is a deliberate, tested procedure, not an emergency.

**Least privilege** — each service runs as a non-root user. No service has more network access than it needs.

**Secrets separation** — no credentials exist in plaintext in the repository. Ansible Vault encrypts all sensitive values.

**Documentation as code** — architecture decisions, runbooks, and DR procedures live in the same repository as the infrastructure code.

---

[Next: Design Decisions →](DECISIONS.md)
