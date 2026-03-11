---
title: README
description: 
published: true
date: 2026-03-11T09:25:36.092Z
tags: 
editor: markdown
dateCreated: 2026-02-28T17:36:23.462Z
---

# Quintin Boshoff — Engineering Portfolio

**IT Infrastructure & Cloud Migration | Learning in Public**

[LinkedIn](#) · [GitHub](https://github.com/sandtiger76/engineering-portfolio)

---

## About This Portfolio

I’m an IT infrastructure engineer with over 25 years of experience across desktop support, server platforms, enterprise storage, and large-scale infrastructure transformation. 

Over the latter part of my career, my focus has been on planning and delivering complex data migration and modernization initiatives—guiding transitions from traditional on‑premises environments to cloud-based platforms operating across multiple regions.

I've always been curious by nature and genuinely enjoy learning. As the technology landscape shifted toward cloud-native architectures, automation, and infrastructure as code, I decided to deliberately build on my existing skills, utilizing modern tooling and practices that my career hadn’t naturally required yet.

This portfolio documents that journey. Each project represents work I have designed and implemented end-to-end, reflecting real-world decision-making as well as the outcomes and lessons learned along the way. The repository also reflects my use of modern tooling—including AI-assisted workflows—to accelerate learning, experimentation, and problem-solving.

In parallel, this space serves as a practical exercise in applying Git and GitHub effectively, with an emphasis on clear structure, documentation, and reproducibility as first-class deliverables.

If you’re working on similar infrastructure modernization or cloud-focused initiatives, I hope the projects and write-ups here prove useful and informative.

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

> *A complete end-to-end Microsoft 365 Business Premium migration for a fictional 15-person SME — from on-premises Windows Server and IMAP email, through to a full cloud platform with security hardening and infrastructure decommissioning.*

This project documents the kind of migration I’ve delivered in the real world for SME clients. The scenario uses a fictional company, but every step reflects what you’d encounter in a genuine engagement — including the often-overlooked realities like SharePoint information architecture decisions, NTFS permission cleanup, and the backup gap Microsoft 365 doesn’t solve for you.

**Why I built it:** To create a repeatable, documented blueprint that I could share

**What I hope you take from it:** A clear, honest guide to planning and delivering an M365 migration end-to-end, including the decisions that often get glossed over in vendor documentation.

**[→ View Project](./m365-project/README.md)**

---

### 🖥️ [asi-project](./asi-project/README.md) — Automated Self-Hosted Infrastructure

> *A self-hosted infrastructure platform running on a Proxmox homelab — containerised, monitored, security-hardened, and fully provisioned from a single Ansible command.*

I’ve spent most of my career supporting and migrating infrastructure that other people built. I understood how it worked, but I hadn’t built a modern containerised platform from scratch myself, or owned the infrastructure-as-code end‑to‑end. This project was my first attempt to fix that.

The stack runs Nextcloud as the core application — a self-hosted collaboration and file‑sharing platform — alongside PostgreSQL, Redis, Nginx, Prometheus, Grafana, and Portainer. The entire platform is provisioned via Ansible and version-controlled in Git.

**Honest disclosure:** This was a learning project. The Ansible code was developed with AI assistance. I understand what it does and why, but I won’t claim it was written entirely from scratch. The value for me was two‑fold: first, learning how the components fit together — VLAN isolation, container networking, reverse proxying, monitoring, and what it actually takes to make a self‑hosted platform production‑grade; and second, using that understanding to build infrastructure that can be torn down and redeployed from a single command. That’s what infrastructure‑as‑code means in practice, and I wanted to experience it directly rather than just read about it.

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
