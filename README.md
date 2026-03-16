# Quintin Boshoff — Engineering Portfolio

**IT Infrastructure Engineer & Cloud Migration Consultant**

[LinkedIn](https://www.linkedin.com/in/quintin-boshoff-1905033/)

---

## About This Portfolio

I'm an IT infrastructure engineer and cloud migration consultant with over 25 years of experience across end-user computing, server and platform operations, enterprise storage, and large-scale infrastructure transformation. In the latter part of my career, my focus shifted toward planning and delivering complex data migration and modernisation projects, guiding transitions from on-premises environments to cloud platforms across multiple regions and sites.

Cloud platforms, automation, and AI-assisted tooling have become increasingly central to how infrastructure is designed and operated. I made a deliberate decision to build hands-on experience with modern tooling alongside my existing background, and these projects are the result.

Each project reflects real-world decision-making. The outcomes and trade-offs are documented, including what went wrong.

---

## How This Portfolio Is Structured

Each project has two layers of documentation:

- A plain-English summary covering what the project is, why it exists, and what it achieves, written for any audience
- Detailed technical documentation with implementation steps, decisions, and rationale for engineers and hiring managers who want to go deeper

Lab environments and fictional scenarios are clearly labelled throughout. No real client data, credentials, or confidential information appears anywhere in this repository.

---

## Projects

---

### 📁 [Microsoft 365 Migration](./m365-project/README.md)

> *A complete on-premises to Microsoft 365 migration for a fictional 15-person SME, from planning to decommission.*

This documents the kind of migration that catches people out in practice: SharePoint information architecture decisions, NTFS permission cleanup before cutover, and the backup gap Microsoft 365 doesn't solve for you. The scenario is fictional. Every step reflects a real engagement.

Inside: a repeatable blueprint covering the decisions that vendor documentation tends to gloss over.

**[→ View Project](./m365-project/README.md)**

---

### ☁️ [Azure Cloud Architecture](./aca-project/README.md)

> *Hands-on Azure infrastructure across all AZ-104 exam domains, with architecture diagrams and deploy/destroy scripts.*

A two-tier private network hosts a Linux web server and Windows application VM, wired together with managed identity, Key Vault secrets, blob storage, and live monitoring. Nothing is exposed to the internet. Everything deploys from a single script and tears down cleanly.

**Disclosure:** The architecture and learning approach are mine. The full deploy and destroy scripts were written with AI assistance, reviewed and tested throughout.

Inside: a practical end-to-end reference for core Azure concepts, documented from someone working through it in real time.

**[→ View Project](./aca-project/README.md)**

---

### 🗄️ [NetApp ONTAP Simulator on Proxmox](./netapp-ontap-proxmox/README.md)

> *The official ONTAP simulator guide covers VMware. This one covers Proxmox, including every undocumented failure along the way.*

Getting the ONTAP 9.6 simulator running on Proxmox took significant trial and error. The CPU type, machine type, RAM allocation, disk prep before first boot, and LIF placement after setup are all wrong by default and none of it is in the official docs.

Inside: a full walkthrough from OVA to working cluster, with every panic explained and fixed.

**[→ View Project](./netapp-ontap-proxmox/README.md)**

---

### 🖥️ [Automated Self-Hosted Infrastructure](./asi-project/README.md)

> *A self-hosted platform on a Proxmox homelab, containerised, monitored, security-hardened, and provisioned from a single Ansible command.*

Nextcloud, PostgreSQL, Redis, Nginx, Grafana, and Portainer, all version-controlled and reproducible. The entire stack deploys from one command and tears down the same way. This was a deliberate attempt to build hands-on experience with containerisation and infrastructure-as-code from scratch.

**Disclosure:** The Ansible code was written with AI assistance. The value was learning what the components do, how they fit together, and what it takes to build something that can be torn down and redeployed from code.

Inside: a working reference for anyone building a similar platform, plus an account of what the learning process actually looks like.

**[→ View Project](./asi-project/README.md)**

---

### 🤖 [AI Projects](./ai-projects/README.md)

> *What can AI actually do in a real IT environment? Not in demos. On live systems, with real consequences.*

Five experiments testing AI on real infrastructure: SSH access to a live homelab, full control of an Azure environment, building a production application with no development background, an inventory request that came back as a security audit, and a controlled test pitting an AI security analyst against an AI ethical hacker on the same live environment.

Inside: what worked, what failed, and where human judgement still mattered.

**[→ View Project](./ai-projects/README.md)**

---

## Background

| Area | Experience |
|---|---|
| **Cloud Migration** | Global data centre decommissions · NetApp NAS/SAN to cloud · Azure NetApp Files · Cloud Volumes ONTAP · AWS migration tooling · StorageX · SPMT · Sharegate |
| **Microsoft 365** | Entra ID · Exchange Online · SharePoint Online · OneDrive · Teams · Intune · Conditional Access |
| **Enterprise Storage** | NetApp NAS/SAN, architecture, administration, and global operational support |
| **Infrastructure** | Windows Server · Linux · Active Directory · DNS · DHCP · Proxmox · VMware |
| **Containerisation** | Docker · Docker Compose · Portainer · LXC *(actively learning)* |
| **Automation & IaC** | Ansible · PowerShell · Bash *(actively learning)* |
| **Monitoring** | Prometheus · Grafana · cAdvisor *(actively learning)* |
| **Networking** | VLANs · Tailscale · Nginx · pfSense · OpenWRT *(actively learning)* |
| **Cloud Platforms** | Microsoft Azure · AWS *(actively learning)* |
| **Version Control** | Git · GitHub *(actively learning)* |

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly documented. No client data, credentials, or confidential information is included anywhere in this repository. All materials are published openly and may be reused freely. Feedback, corrections, and suggestions are very welcome.*