# Job Intelligence Pipeline

**Automated job discovery, research, and application assistance — self-hosted on local infrastructure.**

`n8n` `PostgreSQL` `Redis` `Docker` `Debian LXC` `Proxmox` `Grafana` `Prometheus` `Gitea`

> ← [Back to Portfolio](../../README.md)

---

## Contents

- [What This Project Does](#what-this-project-does)
- [Architecture](#architecture)
- [Infrastructure](#infrastructure)
- [Services](#services)
- [Repository Structure](#repository-structure)
- [Setup Guide](#setup-guide)
- [Current Status](#current-status)
- [Issues Encountered](#issues-encountered)
- [Design Decisions](#design-decisions)
- [Planned Enhancements](#planned-enhancements)

---

## What This Project Does

Finding the right job takes time — scanning multiple sites daily, researching companies, rewriting your CV and cover letter for each application. This project automates as much of that process as possible.

**The pipeline works in five stages:**

| Stage | What happens |
|---|---|
| 1. Discover | n8n workflows scrape predefined job listing sources on a schedule |
| 2. Store | Structured job data is deduplicated and written to PostgreSQL |
| 3. Score | Jobs are filtered and ranked against a configurable skills profile |
| 4. Research | Company data is enriched from secondary sources |
| 5. Output | AI-assisted cover letter drafts and CV update suggestions are generated per role |

**Everything runs locally.** No third-party SaaS subscriptions, no cloud dependency, no data leaving the network. The entire stack — from orchestration to database to monitoring — lives on a Proxmox homelab.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Job Sources (Internet)              │
│         Job boards · Company sites · RSS feeds       │
└────────────────────────┬────────────────────────────┘
                         ↓
┌────────────────────────────────────────────────────┐
│                   n8n (Port 5678)                  │
│           Workflow orchestrator — schedules,       │
│           scrapes, transforms, and routes data     │
└───────┬──────────────┬────────────────┬────────────┘
        ↓              ↓                ↓
┌──────────────┐ ┌──────────┐  ┌──────────────────┐
│  PostgreSQL  │ │  Redis   │  │   AI / LLM Layer  │
│  (internal)  │ │(internal)│  │  Cover letters &  │
│  Job & company│ │Queue &   │  │  CV suggestions   │
│  data store  │ │caching   │  └──────────────────┘
└──────────────┘ └──────────┘
        ↓
┌──────────────────────────────────────────────────┐
│              Output Layer                        │
│   Ranked job list · Company profiles ·           │
│   Tailored cover letters · CV update notes       │
└──────────────────────────────────────────────────┘

Supporting services (all containers on same bridge network):
  ├── Portainer  (9000)  — Container management UI
  ├── Gitea      (3000)  — Self-hosted Git, mirrored to GitHub
  ├── Prometheus (9090)  — Metrics collection
  ├── Grafana    (3001)  — Dashboards & alerting
  └── Nginx      (80/443)— Reverse proxy + SSL [planned]
```

All containers communicate over a private Docker bridge network (`automation`). Internal services (PostgreSQL, Redis) are not exposed outside the network.

---

## Infrastructure

### Proxmox Host — `proxmox` (192.168.1.2)

| Property | Value |
|---|---|
| CPU | Intel Core i5-7500T @ 2.70 GHz (4 cores) |
| RAM | 16 GB DDR4-2400 |
| OS / VM Disk | 238.5 GB NVMe (Proxmox OS + pve-data LVM) |
| Backup Disk | 111.8 GB SATA SSD (`/mnt/sata-ssd`) |
| Sync Disk | 238.5 GB USB (`/mnt/usbdrive` — Syncthing) |

### LXC Container — `automation` (192.168.1.9)

| Setting | Value |
|---|---|
| VMID | 103 |
| OS | Debian 12 (Bookworm) |
| IP | 192.168.1.9 (static DHCP reservation) |
| vCPU | 2 |
| RAM | 3072 MiB |
| Swap | 1024 MiB |
| Disk | 40 GB (local-lvm) |
| Docker | Docker CE + Compose plugin |
| Unprivileged | Yes (nesting=1, keyctl=1) |

---

## Services

| Service | Port | Purpose | Status |
|---|---|---|---|
| n8n | 5678 | Workflow automation & orchestration | ✅ Running |
| PostgreSQL | internal | Primary database | ✅ Running |
| Redis | internal | Queue management & caching | ✅ Running |
| Portainer | 9000 | Docker container management UI | ✅ Running |
| Gitea | 3000 / 2222 | Self-hosted Git (mirrors to GitHub) | ✅ Running |
| Prometheus | 9090 | Metrics collection | ✅ Running |
| Grafana | 3001 | Dashboards & visualisation | ✅ Running |
| Nginx | 80 / 443 | Reverse proxy + SSL | 📋 Planned |

---

## Repository Structure

```
job-intelligence-pipeline/
├── README.md                        ← You are here
├── docs/
│   ├── setup-guide.md               ← Full step-by-step setup
│   ├── architecture.md              ← Design decisions & rationale
│   └── troubleshooting.md           ← Issues encountered & fixes
├── infrastructure/
│   ├── docker-compose.yml           ← Full stack definition
│   ├── .env.example                 ← Environment variable template (no secrets)
│   └── prometheus.yml               ← Prometheus scrape config
├── n8n-workflows/
│   ├── job-scraper.json             ← Scraping workflow export
│   ├── job-scorer.json              ← Filtering & scoring workflow
│   └── cover-letter-gen.json        ← AI output workflow
└── sql/
    └── schema.sql                   ← Database schema
```

---

## Setup Guide

Full step-by-step setup is in [docs/setup-guide.md](./docs/setup-guide.md).

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/sandtiger76/engineering-portfolio.git
cd engineering-portfolio/projects/job-intelligence-pipeline

# 2. Copy and configure environment variables
cp infrastructure/.env.example infrastructure/.env
nano infrastructure/.env        # Set your passwords

# 3. Start the stack
cd infrastructure
docker compose up -d

# 4. Verify all services are running
docker compose ps
```

> ⚠️ Never commit your `.env` file. Use `.env.example` as the template — it contains placeholder values only.

---

## Current Status

### ✅ Phase 1 Complete — Infrastructure Foundation *(2026-03-02)*

All 7 core containers deployed and running on Proxmox LXC `automation`:

| Container | Status | Port |
|---|---|---|
| postgres | ✅ Running | internal |
| redis | ✅ Running | internal |
| n8n | ✅ Running | 5678 |
| portainer | ✅ Running | 9000 |
| gitea | ✅ Running | 3000, 2222 |
| prometheus | ✅ Running | 9090 |
| grafana | ✅ Running | 3001 |

### 🔨 Phase 2 — In Progress

- [ ] Static DHCP reservation for `192.168.1.9`
- [ ] Connect Grafana to Prometheus as data source
- [ ] Build Grafana dashboards for container monitoring
- [ ] Initialise Gitea repository and configure GitHub mirror
- [ ] Enable Docker autostart: `systemctl enable docker`
- [ ] Build first n8n workflow (job scraper)

### 📋 Phase 3 — Planned

- [ ] Nginx reverse proxy with Let's Encrypt SSL
- [ ] Database schema design for job data storage
- [ ] Job scraping workflows (n8n) — initial target sources
- [ ] Scoring and filtering logic against a skills/preference profile
- [ ] AI layer integration for cover letter and CV output
- [ ] Tailscale VPN mesh for secure remote access
- [ ] HashiCorp Vault for secrets management
- [ ] Ansible playbooks for reproducible provisioning

---

## Issues Encountered

Documented honestly — real projects have real problems.

| Issue | Root Cause | Fix |
|---|---|---|
| n8n: Permission denied on startup | Data folder owned by root; n8n runs as UID 1000 | `chown -R 1000:1000 /opt/automation/n8n/data` then `docker compose restart n8n` |
| Prometheus: Failed to start | `prometheus.yml` config file not yet created | Created `prometheus.yml` manually before running `docker compose up` |
| n8n: Secure cookie error | n8n requires HTTPS for cookies by default; no TLS in local environment | Set `N8N_SECURE_COOKIE=false` in `.env`, then `docker compose down && docker compose up -d` |
| Grafana: Password not updating after `.env` change | PostgreSQL retains the original initialised password | Reset via `psql` directly and `grafana-cli admin reset-admin-password` |

Full details and commands are in [docs/troubleshooting.md](./docs/troubleshooting.md).

---

## Design Decisions

**Why self-hosted instead of cloud?**
Full control, zero ongoing cost, and it surfaces real infrastructure skills — provisioning, container orchestration, networking, monitoring. Running the same stack on a managed cloud service would hide all of that.

**Why n8n for orchestration?**
n8n workflows are visual, version-controllable as JSON, and debuggable without code. They document the automation logic naturally, which is ideal for a portfolio. Built-in error handling and retry logic also means fewer brittle custom scripts.

**Why PostgreSQL instead of SQLite?**
Production-grade from day one. Supports concurrent access from multiple services, proper indexing for job search queries, and realistic relational schema design. It also mirrors the kind of stack you'd find in a real environment.

**Why Gitea alongside GitHub?**
Gitea demonstrates a complete self-hosted DevOps environment — not just the public-facing result. It mirrors to GitHub for visibility while keeping a local copy with full history. It's also useful for private workflows that shouldn't be public.

**Why Redis alongside PostgreSQL?**
n8n uses Redis for its queue when running in queue mode. Separating queue/cache from persistent storage is the correct architecture for a scalable workflow system, even at homelab scale.

---

## Planned Enhancements

| Enhancement | Purpose |
|---|---|
| Ollama + Open WebUI | Run a local LLM for cover letter generation — no data leaves the network |
| Qdrant / Chroma | Vector database for semantic job matching against a skills profile |
| Ansible playbooks | Full infrastructure-as-code so the stack can be rebuilt from scratch in minutes |
| VS Code Server | Browser-based IDE for editing workflows and scripts from any device |
| Tailscale | Secure remote access to the stack without exposing ports |

---

*Part of the [Engineering Portfolio](../../README.md)*
