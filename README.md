---
title: README
description: 
published: true
date: 2026-03-11T10:10:44.884Z
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

> *A complete end-to-end migration for a fictional 15-person SME — transitioning from a fully on‑premises, physical Windows Server environment and IMAP email to a cloud-based Microsoft 365 platform, including security hardening and infrastructure decommissioning.*

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

This project was built to deliberately close gaps in my end‑to‑end Azure infrastructure experience and complete the overall cloud picture. I learn best by implementing a real  environment, testing it, and then deepening that understanding through iteration. 

The project draws from each major area of the AZ‑104 curriculum — including networking, compute, storage, identity, monitoring, and automation — and turns those topics into practical, working implementations.

All work is carried out in a pay‑as‑you‑go Azure subscription, using free-tier services where possible and short‑lived resources where not. Everything is designed to be created, tested, and then removed to keep costs minimal, while still reflecting real-world Azure usage patterns.

The documentation is written in plain, accessible language, with the goal of explaining not just what was built, but why — focusing on the decisions, trade-offs, and dependencies that are often hard to grasp when learning from reference documentation alone.


**Honest disclosure:** This is an active learning project. The documentation reflects progress as it happens rather than a polished, finished guide. Some areas are explored more deeply than others as my understanding evolves.

**Why I built it:** To gain genuine, hands-on Azure infrastructure experience across the full AZ‑104 scope, and to anchor that learning in real implementations rather than theory alone.

**What I hope you take from it:** A practical, end‑to‑end reference for core Azure infrastructure concepts


**[→ View Project](./aca-project/README.md)**

---

## Background

| Area | Experience |
|---|---|
| **Cloud Migration** | Global data centre decommissions, NetApp NAS/SAN to cloud, Azure NetApp Files, Cloud Volumes ONTAP, AWS migration tooling, StorageX, SPMT, Sharegate |
| **Microsoft 365** | Entra ID · Exchange Online · SharePoint Online · OneDrive · Teams · Intune · Conditional Access |
| **Enterprise Storage** | NetApp NAS/SAN architect and administrator |
| **Infrastructure** | Windows Server · Linux Server · Active Directory · DNS · DHCP · Proxmox |
| **Containerisation** | Docker · Docker Compose · Portainer · LXC *(actively building hands-on experience)* |
| **Automation & IaC** | Ansible · PowerShell · Bash *(actively building hands-on experience)* |
| **Monitoring** | Prometheus · Grafana · cAdvisor *(ctively building hands-on experience)* |
| **Networking** | VLANs · Tailscale · Nginx · pfSense · OpenWRT (actively building hands-on experience) |
| **Cloud Platforms** | Microsoft Azure · AWS *(actively building hands-on experience)* |
| **Version Control** | Git · GitHub *(actively building hands-on experience)* |

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly documented. No client data, credentials, or confidential information is included anywhere in this repository.*
