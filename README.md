# Engineering Portfolio

**Infrastructure · Automation · Cloud**

A collection of real-world technical projects spanning on-premise infrastructure, cloud migration, and intelligent automation — built, documented, and maintained as a living record of hands-on engineering work.

---

## About

IT infrastructure professional with 25+ years of experience across enterprise and SME environments — from trading floors and oil & gas data centres to cloud migrations at global scale.

Career highlights include contributing as a key member of small, high‑impact teams delivering large‑scale data centre decommissioning programmes across BP’s EMEA and Houston environments; architecting and operating NetApp storage platforms supporting mission‑critical workloads; and delivering end‑to‑end Microsoft 365 migrations for SMEs and enterprise customers. Strong foundations in infrastructure operations, Windows and Linux server administration, Active Directory, virtualisation, enterprise NAS/SAN storage, large‑scale data migrations, and cloud adoption initiatives.

Currently building out a homelab-based automation and cloud portfolio — combining a genuine love of infrastructure problem-solving with modern DevOps and cloud-native tooling.

> *On-prem, cloud, or hybrid — the goal is always the same: reliable systems, clean documentation, and problems that stay solved.*

---

## Projects

### 🔍 Job Intelligence Pipeline
`automation` `n8n` `PostgreSQL` `Docker` `self-hosted` `web scraping`

An end-to-end automated job discovery and research system, hosted entirely on local infrastructure. Scrapes job listings from predefined sources, stores structured data in PostgreSQL, and produces actionable outputs — ranked opportunities, company research, tailored cover letter drafts, and CV update suggestions.

**Stack:** n8n · PostgreSQL · Redis · Docker · Debian LXC · Grafana · Prometheus

> 📂 [View project →](./projects/job-intelligence-pipeline/)

---

### ☁️ SME On-Premise to Azure Migration (📋 Planning)
`azure` `microsoft 365` `cloud migration` `Entra ID` `Exchange Online`

Documented end-to-end migration for a small business moving from local servers and third-party hosted email to Microsoft Azure and Microsoft 365 Business. Covers assessment, planning, identity migration, data migration, cutover, and post-migration documentation — based on a real-world engagement.

**Stack:** Azure · Microsoft 365 · Entra ID · Exchange Online · SharePoint Online · OneDrive

> 📂 [View project →](./projects/azure-sme-migration/)

---

### 🧪 Azure Lab Projects (📋 Planning)
`AZ-104` `azure` `IaC` `cloud labs`

Hands-on Azure labs built alongside AZ-104 exam preparation. Each lab is documented as a standalone, reproducible guide covering real-world scenarios — not just exam theory.

Topics: Virtual networking · RBAC · Azure Backup · Azure Monitor · Policy & Governance

> 📂 [View labs →](./projects/azure-labs/)

---

### 🛠️ Infrastructure Guides (📋 Planning)
`Proxmox` `Docker` `Linux` `LXC` `homelab`

Practical setup and configuration documentation for the infrastructure tooling used across these projects. Written to be reproducible by anyone building similar environments.

Topics: Proxmox VE · LXC container management · Docker & Docker Compose · Linux server setup · Network configuration

> 📂 [View guides →](./infrastructure/)

---

## Technical Background

| Domain | Experience |
|---|---|
| Operating Systems | Windows Server, Debian, Ubuntu, NetApp ONTAP|
| Identity & Access | Active Directory, Group Policy, Entra ID |
| Virtualisation | Proxmox VE, VMware ESX |
| Containers | VM/LXC, Docker, Docker Compose, Portainer |
| Automation & Scripting | n8n, PowerShell, Bash|
| Storage | NetApp NAS/SAN, enterprise backup (NetBackup), Azure Files |
| Cloud | Azure, Microsoft 365, SharePoint Online |
| Monitoring | Grafana, Prometheus, Loki, Uptime Kuma |
| Version Control | Git, GitHub, Gitea (self-hosted) |
| Networking | VLANs, DNS/DHCP, UFW, VPN (Tailscale/WireGuard), Nginx |
| Security | Fail2Ban, Vault (HashiCorp), Let's Encrypt / Certbot |

---

## Repository Structure

```
engineering-portfolio/
├── README.md
├── projects/
│   ├── job-intelligence-pipeline/
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

## Project Status

| Project | Status |
|---|---|
| Job Intelligence Pipeline | 🔨 In progress |
| SME Azure Migration | 📋 Planning |
| Azure Lab Projects | 📋 Planning |
| Infrastructure Guides | 📋 Planning |

---

*All projects are documented with architecture decisions, setup steps, lessons learned, and where applicable — what I'd do differently next time.*
