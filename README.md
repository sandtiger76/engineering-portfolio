# Engineering Portfolio

**Infrastructure · Automation · Cloud**

> Real-world projects across on-premise infrastructure, cloud migration, and intelligent automation — built, documented, and actively maintained.

---

## Navigation

| | Project | Status |
|---|---|---|
| 🔍 | [Job Intelligence Pipeline](./projects/job-intelligence-pipeline/README.md) | 🔨 In progress |
| ☁️ | [SME On-Premise to Azure Migration](./projects/azure-sme-migration/) | 📋 Planning |
| 🧪 | [Azure Lab Projects](./projects/azure-labs/) | 📋 Planning |
| 🛠️ | [Infrastructure Guides](./infrastructure/) | 📋 Planning |

---

## About

IT infrastructure professional with 25+ years of experience across enterprise and SME environments — from trading floors and oil & gas data centres to cloud migrations at global scale.

Career highlights include contributing as a key member of small, high-impact teams delivering large-scale data centre decommissioning programmes across BP's EMEA and Houston environments; architecting and operating NetApp storage platforms supporting mission-critical workloads; and delivering end-to-end Microsoft 365 migrations for SMEs and enterprise clients. Strong foundations in infrastructure operations, Windows and Linux server administration, Active Directory, virtualisation, enterprise NAS/SAN storage, large-scale data migrations, and cloud adoption.

Currently building a homelab-based automation and cloud portfolio — combining a genuine love of infrastructure problem-solving with modern DevOps and cloud-native tooling. Actively working toward AZ-104 certification.

> *On-prem, cloud, or hybrid — the goal is always the same: reliable systems, clean documentation, and problems that stay solved.*

---

## Projects

### 🔍 [Job Intelligence Pipeline](./projects/job-intelligence-pipeline/README.md)
`automation` `n8n` `PostgreSQL` `Docker` `self-hosted` `Proxmox`

An end-to-end automated job discovery and research system running entirely on self-hosted infrastructure. Scrapes job listings on a schedule, stores structured data in PostgreSQL, and generates actionable outputs — ranked opportunities, company research, tailored cover letter drafts, and CV update suggestions.

**Stack:** n8n · PostgreSQL · Redis · Docker · Debian LXC · Proxmox · Grafana · Prometheus · Gitea

**Infrastructure status:** ✅ Core stack deployed and running

---

### ☁️ [SME On-Premise to Azure Migration](./projects/azure-sme-migration/) *(📋 Planning)*
`azure` `microsoft 365` `Entra ID` `Exchange Online` `cloud migration`

Documented end-to-end migration for a small business moving from local servers and third-party hosted email to Microsoft Azure and Microsoft 365 Business. Based on a real-world engagement — covers assessment, identity migration, data migration, cutover strategy, and post-migration documentation.

**Stack:** Azure · Microsoft 365 · Entra ID · Exchange Online · SharePoint Online · OneDrive

---

### 🧪 [Azure Lab Projects](./projects/azure-labs/) *(📋 Planning)*
`AZ-104` `azure` `IaC` `cloud labs`

Hands-on Azure labs built alongside AZ-104 exam preparation. Each lab is documented as a standalone, reproducible guide covering real-world scenarios.

**Topics:** Virtual networking · RBAC · Azure Backup · Azure Monitor · Policy & Governance

---

### 🛠️ [Infrastructure Guides](./infrastructure/) *(📋 Planning)*
`Proxmox` `Docker` `Linux` `LXC` `homelab`

Practical setup and configuration documentation for the infrastructure tooling used across these projects — written to be reproducible from scratch.

**Topics:** Proxmox VE · LXC container management · Docker & Docker Compose · Linux server hardening · Network configuration

---

## Technical Background

| Domain | Skills & Tools |
|---|---|
| Operating Systems | Windows Server 2003–2022, Debian, Ubuntu, NetApp ONTAP |
| Identity & Access | Active Directory, Group Policy, Entra ID |
| Virtualisation | Proxmox VE, VMware ESXi |
| Containers | LXC/LXD, Docker, Docker Compose, Portainer |
| Automation & Scripting | n8n, PowerShell, Bash |
| Storage | NetApp NAS/SAN, NetBackup, Azure Files |
| Cloud | Azure (AZ-104 in progress), Microsoft 365, SharePoint Online |
| Monitoring | Grafana, Prometheus, Loki, Uptime Kuma |
| Version Control | Git, GitHub, Gitea (self-hosted) |
| Networking | VLANs, DNS/DHCP, UFW, Nginx, Tailscale / WireGuard |
| Security | Fail2Ban, HashiCorp Vault, Let's Encrypt / Certbot |

---

## Certifications

| Certification | Year |
|---|---|
| NetApp Certified Data Management Administrator (ONTAP) | 2024 |
| NetApp Certified Data Management Administrator (7-Mode) | 2008 |
| Microsoft Certified Systems Engineer (MCSE) | 2000 |
| CompTIA A+ | 1998 |
| AZ-104 Microsoft Azure Administrator | *In progress* |

---

## Repository Structure

```
engineering-portfolio/
├── README.md                        ← You are here
├── projects/
│   ├── job-intelligence-pipeline/
│   │   ├── README.md                ← Project overview & status
│   │   ├── docs/
│   │   │   ├── setup-guide.md       ← Step-by-step setup
│   │   │   ├── architecture.md      ← Design decisions
│   │   │   └── troubleshooting.md   ← Issues & fixes
│   │   ├── infrastructure/
│   │   │   ├── docker-compose.yml
│   │   │   ├── .env.example
│   │   │   └── prometheus.yml
│   │   ├── n8n-workflows/           ← Exported workflow JSONs
│   │   └── sql/
│   │       └── schema.sql
│   ├── azure-sme-migration/
│   └── azure-labs/
├── infrastructure/
│   ├── proxmox/
│   ├── lxc/
│   ├── docker/
│   └── linux/
└── docs/
```

---

*All projects include architecture decisions, setup steps, issues encountered, and lessons learned.*

