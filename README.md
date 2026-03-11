# Quintin Boshoff — Engineering Portfolio

**IT Infrastructure & Cloud Migration | Learning in Public**

[LinkedIn](#) · [GitHub](https://github.com/sandtiger76/engineering-portfolio)

---

## About This Portfolio

I'm an IT infrastructure engineer with 25+ years of experience across desktop support, server infrastructure, enterprise storage, and large-scale cloud migrations. Most recently I worked as a Data Migration SME on BP's global data centre decommission programme, planning and executing migrations from on-premises NetApp NAS/SAN infrastructure to cloud platforms across European, Houston, and ANZ sites.

When that contract wound down, I found myself in a familiar position for experienced infrastructure engineers — the market had moved, and the skills that made me valuable at BP didn't map cleanly onto job descriptions asking for specific cloud platform experience or modern DevOps tooling.

So I decided to do something about it.

This portfolio documents that journey. Each project is something I built or delivered hands-on, with honest notes about what I knew going in, what I learned, and where I used tools like AI to help me get there. I'm also using this portfolio to learn Git and GitHub properly — so the documentation and structure here is part of the learning too.

If you're an engineer in a similar position, or someone trying to deliver one of these projects yourself, I hope the documentation is useful.

---

## How This Portfolio Is Structured

Each project has two layers of documentation:

- **A plain-English summary** — what the project is, why it exists, and what it achieves, written for anyone
- **Detailed technical documentation** — implementation steps, decisions, and rationale for engineers and hiring managers who want to go deeper

Lab environments and fictional scenarios are clearly labelled throughout. No real client data, credentials, or confidential information appears anywhere in this repository.

---

## Projects

---

### 📁 [m365-project](./m365-project/README.md) — Microsoft 365 Migration

> *A complete end-to-end Microsoft 365 Business Premium migration for a fictional 15-person SME — from on-premises Windows Server and IMAP email, through to full cloud platform with security hardening and infrastructure decommission.*

This project documents the kind of migration I've delivered in the real world for SME clients. The scenario uses a fictional company, but every step reflects what you'd encounter in a genuine engagement — including the awkward bits like SharePoint information architecture decisions, NTFS permission cleanup, and the backup gap Microsoft 365 doesn't solve for you.

**Why I built it:** To create a repeatable, documented blueprint that I could share — both as a portfolio piece and as something genuinely useful to anyone planning a similar migration.

**What I hope you take from it:** A clear, honest guide to planning and delivering an M365 migration end-to-end, including the decisions that often get glossed over in vendor documentation.

**[→ View Project](./m365-project/README.md)**

---

### 🖥️ [asi-project](./asi-project/README.md) — Automated Self-Hosted Infrastructure

> *A self-hosted infrastructure platform running on a Proxmox homelab — containerised, monitored, security-hardened, and fully provisioned from a single Ansible command.*

I've spent most of my career supporting and migrating infrastructure that other people built. I understood how it worked, but I hadn't built modern containerised infrastructure from scratch myself, and I'd never written infrastructure-as-code. This project was my attempt to fix that.

The stack runs Nextcloud as the core application — a self-hosted SharePoint/OneDrive equivalent — alongside PostgreSQL, Redis, Nginx, Prometheus, Grafana, and Portainer. The entire thing is provisioned via Ansible and version-controlled in Git.

**Honest disclosure:** I'm still learning here. The Ansible code was developed with AI assistance. I understand what it does and why, but I won't pretend I wrote it from scratch. The value for me was learning how all the pieces fit together — VLAN isolation, container networking, reverse proxying, monitoring, and what it actually takes to make a self-hosted platform production-grade.

**Why I built it:** To get hands-on with containerisation, IaC, and modern infrastructure tooling — areas I was curious about but had no practical experience in.

**What I hope you take from it:** A working reference for anyone building a similar homelab platform, and an honest account of what the learning process actually looks like.

**[→ View Project](./asi-project/README.md)**

---

### ☁️ [aca-project](./aca-project/README.md) — Azure Cloud Architecture

> *A hands-on Azure learning project — implementing a complete, connected infrastructure across the core domains of the AZ-104 curriculum, documented as I go.*

My cloud migration work at BP was real and substantial, but I was on the data and migration side — I didn't build the cloud infrastructure, that was done by other teams. I could plan a migration to Azure NetApp Files or Cloud Volumes ONTAP, but I couldn't spin up the Azure environment myself.

This project is me fixing that gap directly. Rather than just studying for AZ-104, I'm implementing the concepts hands-on — virtual networks, VMs, storage accounts, Entra ID, Azure Monitor, and automated deployment — and documenting each piece as I go.

**Honest disclosure:** This is active learning. The documentation reflects where I am in the process, not a finished polished guide. Some sections will be more complete than others. I'm using an Azure account with free-tier services where possible, paying for short-lived resources where needed, and deleting everything that incurs cost when I'm done with it.

**Why I built it:** To build genuine Azure hands-on experience, not just theoretical knowledge — and to document it in a way that might help someone else learning the same material.

**What I hope you take from it:** An honest learning journal with working implementations across the core Azure infrastructure domains.

**[→ View Project](./aca-project/README.md)**

---

## Background

| Area | Experience |
|---|---|
| **Cloud Migration** | Data Migration SME at BP — global data centre decommissions, NetApp NAS/SAN to cloud, Azure NetApp Files, Cloud Volumes ONTAP, AWS migration tooling, StorageX, SPMT, Sharegate |
| **Microsoft 365** | Entra ID · Exchange Online · SharePoint Online · OneDrive · Teams · Intune · Conditional Access |
| **Enterprise Storage** | NetApp NAS/SAN architect and administrator — 10+ years across BP global estate |
| **Infrastructure** | Windows Server · Active Directory · DNS · DHCP · VMware · Proxmox |
| **Containerisation** | Docker · Docker Compose · Portainer · LXC *(actively learning)* |
| **Automation & IaC** | Ansible · PowerShell · Bash *(actively learning)* |
| **Monitoring** | Prometheus · Grafana · cAdvisor *(actively learning)* |
| **Networking** | VLANs · Tailscale · Nginx · pfSense · OpenWRT |
| **Cloud Platforms** | Microsoft Azure · AWS *(actively building hands-on experience)* |
| **Version Control** | Git · GitHub *(actively learning)* |

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly documented. No client data, credentials, or confidential information is included anywhere in this repository.*
