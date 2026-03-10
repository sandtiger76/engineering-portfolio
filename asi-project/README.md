# Automated Self-Hosted Infrastructure

> **Production-grade infrastructure automation on a £0 cloud bill.**
> *A fully self-hosted platform — provisioned from scratch with a single Ansible command.*

---

## What Is This?

This project demonstrates the design, deployment, and automation of a complete self-hosted infrastructure platform — built on consumer hardware, managed entirely as code, and secured to production standards.

Every service, every configuration file, every firewall rule is version-controlled and reproducible. Destroying the entire stack and rebuilding it from scratch takes a single command.

This is not a tutorial follow-along. It is an original infrastructure design — making deliberate architectural decisions, accepting real trade-offs, and documenting the reasoning behind every choice.

---

## Why This Project Exists

Cloud platforms are powerful, but they come with a cost — financial and operational. Large organisations spend enormous budgets on services that could be self-hosted securely and cheaply. This project proves that enterprise-grade practices — Infrastructure as Code, zero-trust networking, automated certificate management, container orchestration, and disaster recovery planning — do not require an enterprise budget.

The entire stack runs on a single low-power mini PC, costs nothing to operate beyond electricity, and is managed with the same tooling used in professional infrastructure teams worldwide.

---

## What This Demonstrates

| Capability | Implementation |
|---|---|
| Infrastructure as Code | Ansible — full stack provisioned from a single command |
| Containerisation | Docker + Docker Compose — all services containerised |
| Secrets Management | Ansible Vault — no plaintext credentials anywhere |
| Zero-Trust Networking | Tailscale — management plane never exposed to internet |
| Reverse Proxy + SSL | Nginx + Let's Encrypt — automated certificate management |
| Dynamic DNS | Cloudflare API — automatic IP updates, domain always resolves |
| Security Hardening | UFW firewall, fail2ban, OS hardening, no open inbound ports |
| Monitoring | Uptime Kuma — service health visibility |
| Disaster Recovery | Documented RTO/RPO, automated backups, tested restore procedure |
| Version Control | Gitea — self-hosted Git, all code lives on the platform itself |

---

## The Stack

```
Internet
    │
    ▼
Cloudflare (DNS + WAF + DDoS protection)
    │
    ▼
Dynamic DNS (auto-updated via Cloudflare API)
    │
    ▼
Nginx Reverse Proxy (SSL termination — Let's Encrypt)
    │
    ├──► Nextcloud (collaboration platform)
    │
    ├──► Gitea (self-hosted Git)
    │
    └──► [Management plane — Tailscale only]
              ├── Portainer
              ├── Uptime Kuma
              └── Proxmox
```

---

## Hardware

| Component | Spec |
|---|---|
| Host | Intel NUC DN2820FYKH |
| CPU | Intel Celeron N2820 @ 2.13GHz (2 cores) |
| RAM | 8GB DDR3 |
| Storage | 128GB SSD (OS) + 238GB (backups) |
| Hypervisor | Proxmox VE |
| Router | Cudy WR3000 (OpenWrt 24.10) |

> *Deliberate constraint: proving enterprise practices do not require enterprise hardware.*

---

## Network & Traffic Flow

```mermaid
flowchart TD
    User(["👤 User / Browser"])
    CF["☁️ Cloudflare\nProxy + WAF + SSL"]
    Router["🔀 OpenWrt Router\nPort Forward 80/443"]
    Nginx["🔀 Nginx\nReverse Proxy + SSL Termination\n192.168.1.11"]
    NC["📦 Nextcloud\nnextcloud.qcbhomelab.online"]
    GT["📦 Gitea\ngitea.qcbhomelab.online"]
    TS["🔒 Tailscale\nManagement Plane"]
    Admin(["👤 Admin"])
    PX["🖥️ Proxmox\n192.168.1.7:8006"]
    PT["📦 Portainer\n:9000"]
    UK["📦 Uptime Kuma\n:3001"]

    User -->|"HTTPS 443"| CF
    CF -->|"Proxied — real IP hidden"| Router
    Router -->|"Port Forward 443"| Nginx
    Nginx -->|"HTTP proxy_pass"| NC
    Nginx -->|"HTTP proxy_pass"| GT

    Admin -->|"Tailscale VPN\n100.x.x.x"| TS
    TS --> PX
    TS --> PT
    TS --> UK

    style CF fill:#F6821F,color:#fff
    style TS fill:#205299,color:#fff
    style Nginx fill:#269539,color:#fff
```

---

## Service Architecture

```mermaid
graph TB
    subgraph Public["🌐 Public (via Cloudflare)"]
        Nginx["nginx:alpine\nPorts 80, 443"]
    end

    subgraph Proxy_Network["🔗 proxy network (172.19.0.0/16)"]
        NC["nextcloud:apache"]
        GT["gitea/gitea"]
    end

    subgraph Internal_Network["🔒 internal network"]
        PG["postgres:16"]
        RD["redis:alpine"]
        PT["portainer/portainer-ce"]
        UK["louislam/uptime-kuma"]
        CF["favonia/cloudflare-ddns"]
    end

    subgraph Host["🖥️ LXC Host (192.168.1.11)"]
        TS["tailscaled\nTailscale IP: 100.114.7.81"]
        CB["certbot\nAuto-renew timer"]
    end

    Nginx --> NC
    Nginx --> GT
    NC --> PG
    NC --> RD
    GT --> PG

    style Public fill:#fff3e0
    style Proxy_Network fill:#e8f5e9
    style Internal_Network fill:#e3f2fd
    style Host fill:#f3e5f5
```

---

## Ansible Deployment Flow

```mermaid
flowchart TD
    Start(["▶ ansible-playbook site.yml"])

    subgraph Play1["Play 1 — localhost → Proxmox API"]
        P1["proxmox_lxc\nCreate LXC, configure TUN, wait for SSH"]
    end

    subgraph Play2["Play 2 — SSH → asi-platform"]
        SEC["security\nUFW + fail2ban"]
        DOC["docker\nDocker CE + networks + directory tree"]
        SSL["ssl\ncertbot + Cloudflare DNS-01\nWildcard cert *.qcbhomelab.online"]
        PG["postgresql\ndocker-compose.yml + .env from vault"]
        NC["nextcloud\nContainer + occ post-config"]
        GT["gitea\nContainer + admin user + repo"]
        NX["nginx\nvhost configs + container"]
        PO["portainer\nManagement UI :9000"]
        UK["uptime_kuma\nMonitoring :3001"]
        DD["cloudflare_ddns\nDDNS container"]
        TS["tailscale\nInstall + idempotent auth"]
        BK["backup\nDaily cron — pg_dump + tar"]
    end

    Start --> P1
    P1 --> SEC
    SEC --> DOC
    DOC --> SSL
    SSL --> PG
    PG --> NC
    PG --> GT
    NC --> NX
    GT --> NX
    NX --> PO
    NX --> UK
    NX --> DD
    NX --> TS
    TS --> BK

    style Play1 fill:#fff3e0
    style Play2 fill:#e8f5e9
    style Start fill:#205299,color:#fff
```

---

## Quick Start (Full Stack Deployment)

```bash
# Clone the repository
git clone https://gitea.qcbhomelab.online/quintin/asi-platform.git
cd asi-platform

# Configure your secrets
cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml
ansible-vault encrypt ansible/group_vars/all/vault.yml

# Deploy everything
ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml --ask-vault-pass
```

That's it. The entire platform builds itself.

---

## Documentation Index

### Project
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Design Decisions (ADR)](docs/DECISIONS.md)
- [Security Overview](docs/SECURITY.md)

### Services
- [Nextcloud](docs/services/nextcloud.md) — Self-hosted collaboration platform
- [PostgreSQL](docs/services/postgresql.md) — Relational database backend
- [Nginx](docs/services/nginx.md) — Reverse proxy and SSL termination
- [Portainer](docs/services/portainer.md) — Container management UI
- [Uptime Kuma](docs/services/uptime-kuma.md) — Service monitoring
- [Gitea](docs/services/gitea.md) — Self-hosted Git platform
- [Cloudflare DDNS](docs/services/cloudflare-ddns.md) — Dynamic DNS automation

### Tasks
- [Proxmox LXC Setup](docs/tasks/proxmox-lxc.md)
- [Docker Installation](docs/tasks/docker.md)
- [OpenWrt Network Configuration](docs/tasks/openwrt-network.md)
- [Tailscale Setup](docs/tasks/tailscale.md)
- [SSL Certificate Setup](docs/tasks/ssl-certificates.md)
- [Ansible Vault — Secrets Management](docs/tasks/ansible-vault.md)
- [Nginx + Nextcloud Reverse Proxy Gotchas](docs/tasks/nginx-nextcloud-gotchas.md)

### Operations
- [Monitoring](docs/operations/monitoring.md)
- [Backup & Disaster Recovery](docs/operations/backup-dr.md)
- [Runbook](docs/operations/runbook.md)
- [Lessons Learned](docs/operations/lessons-learned.md)

---

## Author

**Quintin** — Infrastructure Engineer
[qcbhomelab.online](https://qcbhomelab.online) · [GitHub](https://github.com/qcb)

---

*All infrastructure provisioned via Ansible. No manual steps beyond initial Proxmox installation and API token generation.*
