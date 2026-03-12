# Quintin Boshoff — Engineering Portfolio

**IT Infrastructure Engineer & Cloud Migration Consultant**

[LinkedIn](https://www.linkedin.com/in/quintin-boshoff-1905033/)

---

## About This Portfolio

I'm an IT infrastructure engineer and cloud migration consultant with over 25 years of experience spanning end-user computing, server and platform operations, enterprise storage, and large-scale infrastructure transformation. Over the latter part of my career, my focus shifted toward planning and delivering complex data migration and modernisation initiatives — guiding transitions from traditional on-premises environments to cloud-based platforms across multiple regions and sites.

I've always been curious by nature and genuinely enjoy learning. As the IT landscape continues to evolve, cloud platforms, automation, and AI‑assisted tooling have become increasingly central to how infrastructure is designed and operated. I made a deliberate decision to expand my hands‑on experience with modern tooling, building practical skills that complement my existing infrastructure background.

Each project reflects real‑world decision‑making, as well as the outcomes and lessons learned along the way.

In parallel, this space serves as a practical exercise in applying Git and GitHub effectively, with an emphasis on clear structure, documentation, and reproducibility.

---

## How This Portfolio Is Structured

Each project has two layers of documentation:

- **A plain-English summary** — what the project is, why it exists, and what it achieves, written for any audience
- **Detailed technical documentation** — implementation steps, decisions, and rationale for engineers and hiring managers who want to go deeper

Lab environments and fictional scenarios are clearly labelled throughout. No real client data, credentials, or confidential information appears anywhere in this repository.

---

## Projects

---

### 📁 [Microsoft 365 Migration](./m365-project/README.md)

> *A complete end-to-end migration for a fictional 15-person SME — transitioning from a fully on-premises Windows Server environment and IMAP email to a cloud-based Microsoft 365 platform, including security hardening and infrastructure decommissioning.*

This project documents the kind of migration I've delivered in the real world for SME clients. The scenario uses a fictional company, but every step reflects what you'd encounter in a genuine engagement — including the often-overlooked realities like SharePoint information architecture decisions, NTFS permission cleanup, and the backup gap that Microsoft 365 doesn't solve for you.

**Why I built it:** To create a repeatable, documented blueprint — useful both as a portfolio piece and as a practical guide for anyone planning a similar migration.

**What I hope you take from it:** A clear, honest guide to planning and delivering an M365 migration end-to-end, including the decisions that often get glossed over in vendor documentation.

**[→ View Project](./m365-project/README.md)**

---

### 🖥️ [Automated Self-Hosted Infrastructure](./asi-project/README.md)

> *A self-hosted infrastructure platform running on a Proxmox homelab — containerised, monitored, security-hardened, and fully provisioned from a single Ansible command.*

Throughout my career I've built, supported, and migrated infrastructure across physical, virtualised, and cloud environments. What I hadn't done was work with containerisation or infrastructure-as-code — two areas that have become increasingly central to modern infrastructure practice. This project was my attempt to change that.

The stack runs Nextcloud as the core application — a self-hosted cloud collaboration and file-sharing platform — alongside PostgreSQL (instead of the default SQLite), Redis, Nginx, Prometheus, Grafana, and Portainer. The entire platform is provisioned via Ansible and version-controlled in Git.

**Why I built it:** To get hands-on with containerisation, IaC, and modern infrastructure tooling — areas I was curious about but had no practical experience in.

**What I hope you take from it:** A working reference for anyone building a similar homelab platform, and an honest account of what the learning process actually looks like.

**Honest disclosure:** The Ansible code was written with AI assistance.  The value of this project was not authorship of every line, but learning what the components do, how they fit together, and what it actually takes to build a self‑hosted cloud platform that can be torn down and redeployed from code. Experiencing that full lifecycle firsthand — including repeatable deploy and destroy from a single automated command — is what infrastructure‑as‑code means to me, and I wanted to learn it by building rather than just reading about it.


**[→ View Project](./asi-project/README.md)**

---

### ☁️ [Azure Cloud Architecture](./aca-project/README.md)

> *Hands-on Azure infrastructure across AZ-104 domains: networking, compute, storage, identity, monitoring, and automation — with architecture diagrams and phased deploy/destroy scripts.*

A two-tier private network hosts a Linux web server and Windows application VM — neither exposed to the internet — wired together with managed identity, Key Vault secrets, blob storage, and live monitoring, all deployable from a single script and designed to tear down cleanly so you only pay for what you use. This project builds a complete Azure environment that touches every major AZ-104 exam domain — documented with the decisions made, the trade-offs considered, and the lessons learned along the way. 

**Why I built it:** I believe the best way to understand Azure infrastructure is to build it, break it, and document everything along the way.

**What I hope you take from it:** A practical, end-to-end reference for core Azure infrastructure concepts — written from the perspective of someone working through it in real time.

**Honest disclosure:** The architectural design, learning plan, and scenario are mine. The automation scripts and deployment orchestration (e.g., multi-phase `deploy`/`destroy` scripts) were developed with AI assistance.


**[→ View Project](./aca-project/README.md)**


---

### 🤖 [AI Projects](./ai-projects/README.md)

> *Hands-on tests of AI in infrastructure engineering — real capabilities, limitations, and risks.*

**Key questions explored:**
- Can AI write and deploy infrastructure as code (IaC) playbooks like Ansible?
- Can it fully manage homelab infrastructure end-to-end?
- Can AI build a full-stack interactive website hosted in a homelab?
- What are the real risks?

**Why I built it:** To learn AI's true capabilities by building — does it deliver on promises, work reliably, or need constant babysitting?

**What I hope you take from it:** My honest answers to some of these questions, including wins, failures and security concerns

**[→ View Projects](./ai-projects/README.md)**


---

## Background

| Area | Experience |
|---|---|
| **Cloud Migration** | Global data centre decommissions · NetApp NAS/SAN to cloud · Azure NetApp Files · Cloud Volumes ONTAP · AWS migration tooling · StorageX · SPMT · Sharegate |
| **Microsoft 365** | Entra ID · Exchange Online · SharePoint Online · OneDrive · Teams · Intune · Conditional Access |
| **Enterprise Storage** | NetApp NAS/SAN — architecture, administration, and global operational support |
| **Infrastructure** | Windows Server · Linux · Active Directory · DNS · DHCP · Proxmox · VMware |
| **Containerisation** | Docker · Docker Compose · Portainer · LXC *(actively learning)* |
| **Automation & IaC** | Ansible · PowerShell · Bash *(actively learning)* |
| **Monitoring** | Prometheus · Grafana · cAdvisor *(actively learning)* |
| **Networking** | VLANs · Tailscale · Nginx · pfSense · OpenWRT *(actively learning)* |
| **Cloud Platforms** | Microsoft Azure · AWS *(actively learning)* |
| **Version Control** | Git · GitHub *(actively learning)* |

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly documented. No client data, credentials, or confidential information is included anywhere in this repository. All materials are published openly and may be reused freely. Feedback, corrections, and suggestions are very welcome.*
