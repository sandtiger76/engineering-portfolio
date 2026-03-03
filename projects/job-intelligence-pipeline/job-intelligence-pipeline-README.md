# Job Intelligence Pipeline

**Automated job discovery, research, and application assistance — self-hosted on local infrastructure.**

`n8n` `PostgreSQL` `Redis` `Docker` `Debian LXC` `Proxmox` `Grafana` `Prometheus`

---

## Overview

A fully automated pipeline that monitors job listing sources, stores structured opportunity data in a local database, and generates actionable outputs — helping identify the best-fit roles, research target companies, and produce tailored application materials.

The entire stack runs on self-hosted hardware. No third-party SaaS, no cloud dependency. Just a Proxmox homelab running Debian LXC containers and Docker Compose.

**The pipeline covers:**
1. Scheduled scraping of job listing sources
2. Structured data storage and deduplication
3. Filtering and scoring against a defined profile
4. Company research enrichment
5. AI-assisted cover letter drafting and CV tailoring suggestions

---

## Architecture

```
Internet / Job Sources
         ↓
    [n8n Workflows]          ← Orchestrates everything
    /     |      \
[Scraper] [APIs] [RSS]
         ↓
   [PostgreSQL]              ← Stores all job & company data
         ↕
      [Redis]                ← Queue & caching
         ↓
  [AI / LLM Layer]           ← Cover letter & CV suggestions
         ↓
  [Output: Reports / Files]

         ↕
  [Grafana + Prometheus]     ← Monitoring & observability
  [Portainer]                ← Container management
  [Gitea]                    ← Self-hosted version control (mirrored to GitHub)
  [Nginx]                    ← Reverse proxy + SSL termination
```

All services communicate over a private Docker bridge network. A self-hosted Gitea instance mirrors all commits to this GitHub repository.

---

## Infrastructure

### Host: Proxmox VE (proxmox / 192.168.1.2)

| Property | Value |
|---|---|
| CPU | Intel Core i5-7500T @ 2.70 GHz (4 cores) |
| RAM | 16 GB DDR4 |
| OS Disk | 238.5 GB NVMe |
| Backup Disk | 111.8 GB SATA SSD |
| Sync Disk | 238.5 GB USB |

### LXC Container: automation (VMID 103)

| Setting | Value |
|---|---|
| OS | Debian 12 (Bookworm) |
| IP | 192.168.1.9 |
| vCPU | 2 |
| RAM | 3072 MiB |
| Disk | 40 GB (local-lvm) |
| Docker | Docker CE + Compose plugin |

---

## Services

| Service | Port | Purpose |
|---|---|---|
| n8n | 5678 | Workflow automation & orchestration |
| PostgreSQL | internal | Primary database |
| Redis | internal | Queue management & caching |
| Portainer | 9000 | Docker container management UI |
| Gitea | 3000 / 2222 | Self-hosted Git (mirrors to GitHub) |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3001 | Dashboards & visualisation |
| Nginx | 80 / 443 | Reverse proxy + SSL *(planned)* |

---

## Repository Structure

```
job-intelligence-pipeline/
├── README.md                    ← This file
├── infrastructure/
│   ├── lxc-setup.md             ← LXC container provisioning
│   ├── docker-compose.yml       ← Full stack definition
│   ├── .env.example             ← Environment variable template
│   └── prometheus.yml           ← Prometheus scrape config
├── n8n-workflows/
│   ├── job-scraper.json         ← Scraping workflow export
│   ├── job-scorer.json          ← Filtering/scoring workflow
│   └── cover-letter-gen.json    ← AI output workflow
├── docs/
│   ├── architecture.md          ← Detailed architecture notes
│   ├── setup-guide.md           ← Step-by-step setup guide
│   └── troubleshooting.md       ← Issues encountered & fixes
└── sql/
    └── schema.sql               ← Database schema
```

---

## Setup Guide

Full step-by-step setup is documented in [`docs/setup-guide.md`](./docs/setup-guide.md).

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/sandtiger76/engineering-portfolio.git
cd engineering-portfolio/projects/job-intelligence-pipeline

# 2. Copy and configure environment variables
cp infrastructure/.env.example infrastructure/.env
nano infrastructure/.env

# 3. Start the stack
cd infrastructure
docker compose up -d

# 4. Verify all services
docker compose ps
```

---

## Current Status

### ✅ Completed — Infrastructure Foundation (2026-03-02)

All 7 core containers deployed and running on Proxmox LXC:

| Container | Status |
|---|---|
| postgres | ✅ Running |
| redis | ✅ Running |
| n8n | ✅ Running |
| portainer | ✅ Running |
| gitea | ✅ Running |
| prometheus | ✅ Running |
| grafana | ✅ Running |

### 🔨 In Progress

- [ ] Static DHCP reservation for `192.168.1.9`
- [ ] Grafana → Prometheus data source connection
- [ ] Grafana dashboards for container monitoring
- [ ] Gitea initialisation and GitHub mirror setup
- [ ] n8n first workflow (job scraper)

### 📋 Planned

- [ ] Nginx reverse proxy with Let's Encrypt SSL
- [ ] Database schema design for job data
- [ ] Job scraping workflows (n8n)
- [ ] Scoring / filtering logic
- [ ] AI layer integration (cover letter & CV outputs)
- [ ] Tailscale VPN mesh for secure remote access
- [ ] Vault (HashiCorp) for secrets management
- [ ] Ansible playbooks for reproducible provisioning

---

## Issues Encountered

Documented honestly — real projects have real problems.

| Issue | Cause | Fix |
|---|---|---|
| n8n permission denied on startup | Data folder owned by root; n8n runs as UID 1000 | `chown -R 1000:1000 /opt/automation/n8n/data` |
| Prometheus failed to start | `prometheus.yml` config file missing | Created manually before `docker compose up` |
| n8n secure cookie error | No TLS in local environment | Set `N8N_SECURE_COOKIE=false` in `.env` |
| Grafana password not updating | PostgreSQL retains original initialised password | Reset via `psql` and `grafana-cli admin reset-admin-password` |

---

## Design Decisions

**Why self-hosted instead of cloud?**
Full control, zero running costs, and demonstrates real infrastructure skills — provisioning, networking, container orchestration, monitoring. A cloud-hosted equivalent would hide all of that.

**Why n8n instead of custom code?**
n8n provides visual workflow documentation, built-in error handling, and exportable JSON workflows that can be versioned in Git. The automation logic is transparent and reproducible.

**Why PostgreSQL over SQLite?**
Production-grade from day one. Enables multi-service access, proper indexing for job search queries, and realistic schema design.

**Why Gitea alongside GitHub?**
Self-hosted version control demonstrates a complete DevOps environment. Gitea mirrors to GitHub for public visibility while keeping a local copy.

---

## Planned Enhancements

- **Ollama + Open WebUI** — Local LLM for offline cover letter generation (no data leaves the network)
- **Qdrant / Chroma** — Vector database for semantic job matching against a skills profile
- **Ansible playbooks** — Full infrastructure-as-code provisioning so the stack can be rebuilt from scratch in minutes
- **VS Code Server** — Browser-based IDE for editing workflows and scripts from any device

---

*Part of the [Engineering Portfolio](../../README.md) — documenting real infrastructure work.*
