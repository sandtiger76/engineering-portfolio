# Engineering Portfolio

**Infrastructure · Automation · Cloud**

A collection of real-world technical projects spanning on-premise infrastructure, cloud migration, and intelligent automation — built, documented, and maintained as a living record of hands-on engineering work.

---

## About

Over a decade of IT experience across enterprise environments: workstation and server administration (Windows & Linux), Active Directory, large-scale storage infrastructure, data management, and cloud migrations. This portfolio bridges that foundation with modern engineering practices — automation pipelines, cloud architecture, and infrastructure-as-code.

Each project here is fully documented, reproducible, and reflects the kind of work that gets things running (and keeps them that way).

---

## Projects

### 🔍 Job Intelligence Pipeline
`automation` `n8n` `web scraping` `database` `self-hosted`

An end-to-end automated job discovery and research system, hosted entirely on local infrastructure.

**What it does:**
- Scrapes predefined job listing sources on a schedule
- Stores structured job data in a local database
- Filters and ranks opportunities based on configurable criteria
- Enriches listings with company research data
- Generates tailored cover letter drafts and CV update suggestions per role

**Stack:** n8n (workflow automation) · PostgreSQL · Docker · Self-hosted Linux server

**Why it matters:** Demonstrates real-world automation thinking — not just connecting APIs, but building a practical pipeline with data persistence, scheduling, and actionable output. The entire infrastructure (servers, database, orchestration) is provisioned and managed locally.

> 📂 [View project documentation →](./projects/job-intelligence-pipeline/)

---

### ☁️ SME On-Premise to Azure Migration
`azure` `microsoft 365` `cloud migration` `infrastructure`

A documented end-to-end migration for a small business moving from local servers and third-party hosted email to a fully integrated Microsoft Azure and Microsoft 365 environment.

**Scope:**
- Assessment of existing on-premise infrastructure
- Migration planning and cutover strategy
- Azure Active Directory setup and hybrid identity configuration
- Exchange Online / Microsoft 365 Business deployment
- Data migration (files, email, shared resources)
- Post-migration support and documentation

**Stack:** Azure · Microsoft 365 · Entra ID · Exchange Online · Azure Files

**Why it matters:** Mirrors the real migration projects that SMEs undertake every day — balancing business continuity with modernisation. Fully documented for reproducibility.

> 📂 [View project documentation →](./projects/azure-sme-migration/)

---

### 🧪 Azure Lab Projects *(In Progress)*
`az-104` `azure` `iac` `cloud labs`

Hands-on Azure labs and mini-projects built in parallel with AZ-104 exam preparation. Each lab is documented as a standalone guide, covering real scenarios rather than just exam theory.

Planned topics include:
- Virtual network design and peering
- Azure Backup and Recovery Services Vault
- Role-Based Access Control (RBAC) implementation
- Azure Monitor and alerting pipelines
- Policy and governance frameworks

> 📂 [View labs →](./projects/azure-labs/)

---

### 🛠️ Infrastructure Guides
`proxmox` `docker` `linux` `homelab` `self-hosted`

Practical how-to documentation for infrastructure tools used across these projects — written to be useful for anyone building similar environments.

Topics covered:
- Proxmox VE setup and VM/LXC management
- Docker and Docker Compose for self-hosted services
- Linux server hardening basics
- Network configuration and VLAN segmentation

> 📂 [View guides →](./infrastructure/)

---

## Repository Structure

```
engineering-portfolio/
├── projects/
│   ├── job-intelligence-pipeline/
│   ├── azure-sme-migration/
│   └── azure-labs/
├── infrastructure/
│   ├── proxmox/
│   ├── docker/
│   └── linux/
└── README.md
```

---

## Technical Background

| Domain | Experience |
|---|---|
| Operating Systems | Windows Server (2012–2022), Ubuntu, Debian, RHEL |
| Identity & Access | Active Directory, Group Policy, Entra ID |
| Virtualisation | Proxmox VE, Hyper-V, VMware |
| Containers | Docker, Docker Compose |
| Automation | n8n, PowerShell, Bash |
| Storage | Enterprise NAS/SAN, Azure Files, backup solutions |
| Cloud | Azure (AZ-104 in progress), Microsoft 365 |
| Networking | VLANs, DNS, DHCP, firewalls, VPN |

---

## Status

| Project | Status |
|---|---|
| Job Intelligence Pipeline | 🔨 In progress |
| SME Azure Migration | 📋 Planning |
| Azure Lab Projects | 🔨 In progress |
| Infrastructure Guides | ✍️ Ongoing |

---

*All projects are documented with architecture decisions, setup steps, lessons learned, and where applicable — what I'd do differently next time.*
