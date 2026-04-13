# Engineering Portfolio

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

### Hybrid Microsoft Environment(./m365-hybrid/README.md)**


This project documents the design and implementation of a complete hybrid Microsoft environment, built from scratch for a fictional professional services firm called QCB Homelab Consultants. It was created as a hands-on portfolio piece to demonstrate practical, real-world capability across the Microsoft 365 and Azure technology stack.

The environment reflects how a modern SMB would actually operate — cloud-first, identity-driven, and secure by design — rather than a textbook exercise. Every decision made here has a reason behind it, and where there were alternatives, those trade-offs are explained.

**[→ View Project](./m365-hybrid/README.md)**

---

### ☁️ [Azure Cloud Architecture](./aca-project/README.md)

> *Hands-on Azure infrastructure across all AZ-104 exam domains, with architecture diagrams and deploy/destroy scripts.*

A two-tier private network hosts a Linux web server and Windows application VM, wired together with managed identity, Key Vault secrets, blob storage, and live monitoring. Nothing is exposed to the internet. Everything deploys from a single script and tears down cleanly.

**Disclosure:** The architecture and learning approach are mine. The deploy and destroy scripts were written with AI assistance, reviewed and tested throughout.

Inside: a practical end-to-end reference for core Azure concepts, documented from someone working through it in real time.

**[→ View Project](./aca-project/README.md)**

---

### 🗄️ [Building a Self-Hosted NetApp Lab on Proxmox VE](./netapp-ontap-proxmox/README.md)

> *The official ONTAP simulator guide covers VMware. This one covers Proxmox, including every undocumented failure along the way.*

A complete guide to deploying NetApp ONTAP simulators on self-hosted Proxmox VE. Covers a two-node HA cluster with SnapMirror DR replication
to a single-node cluster, with support for nearly all ONTAP features including SVMs, NFS, CIFS, iSCSI, FlexClone, SnapVault and more.

Inside: a complete guide with every panic explained and fixed.

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

A growing series of experiments running AI agents against real infrastructure — covering automation, security, cloud operations, and infrastructure management. Each project starts with a question, runs against live systems, and documents what actually happened, including the failures, the surprises, and where human judgement still mattered.

**[→ View Projects](./ai-projects/README.md)**

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly documented. No client data, credentials, or confidential information is included anywhere in this repository. All materials are published openly and may be reused freely. Feedback, corrections, and suggestions are very welcome.*
