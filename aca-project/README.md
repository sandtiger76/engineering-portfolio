# QCB Technologies — Azure Infrastructure Lab

> **Portfolio project** | AZ-104 hands-on implementation | Azure CLI + PowerShell + Automation

---

## About This Project

QCB Technologies is a small, growing IT managed services company based in the Isle of Man. This project documents the design, deployment, and automation of QCB's core Azure infrastructure — built from scratch using a pay-as-you-go subscription with cost-conscious, tear-down-and-rebuild practices.

Every task is documented in three ways:
1. **Azure CLI** — the command and what it does
2. **PowerShell (Az module)** — the equivalent command
3. **Why** — the decision, trade-off, or dependency behind it

At the end of each phase, an automation script ties everything together so the full environment can be rebuilt in a single run.

**Honest disclosure:** This is an active learning project built to close real gaps in Azure infrastructure knowledge. Documentation reflects progress as it happens.

---

## Scenario

| | |
|---|---|
| **Company** | QCB Technologies Ltd |
| **Domain** | qcbhomelab.online |
| **Size** | Small IT MSP, ~10 staff |
| **Goal** | Migrate internal tooling and client-facing services to Azure |
| **Primary Region** | UK South (London) |
| **Subscription type** | Pay-as-you-go |

QCB needs a secure, observable, and repeatable Azure environment covering web-facing services, internal app workloads, data storage, identity management, and monitoring — all built with least-privilege access and no hardcoded credentials.

---

## Architecture Overview

```
Internet
    │
    ▼
[ Load Balancer ] (Public IP)
    │
    ▼
[ Web Subnet ] — Linux VM (web-vm-01)     ← NSG: allow 80/443 inbound
    │
    ▼
[ App Subnet ] — Windows VM (app-vm-01)   ← NSG: allow 8080 from web subnet only
    │
    ▼
[ Data Subnet ] — Storage Account         ← Private Endpoint, no public access
    │
[ Key Vault ]  — Secrets, accessed via Managed Identity (no passwords in code)
[ Log Analytics ] — Centralised monitoring, VM insights, alerts
```

---

## Repository Structure

```
qcb-azure-lab/
├── README.md                        ← This file (project overview)
├── docs/
│   ├── 00-prerequisites.md          ← Subscription setup, tooling, naming conventions
│   ├── 01-resource-groups.md        ← Phase 1: Foundation
│   ├── 02-networking.md             ← Phase 2: VNet, Subnets, NSGs
│   ├── 03-compute.md                ← Phase 3: Virtual Machines, Load Balancer
│   ├── 04-storage.md                ← Phase 4: Storage Account, Blob, File Share
│   ├── 05-identity.md               ← Phase 5: RBAC, Managed Identities
│   ├── 06-keyvault.md               ← Phase 6: Key Vault, Secrets, Access Policies
│   ├── 07-monitoring.md             ← Phase 7: Log Analytics, Alerts, Diagnostics
│   └── 08-automation.md             ← Phase 8: Full rebuild script
├── scripts/
│   ├── cli/                         ← Azure CLI scripts per phase
│   ├── powershell/                  ← PowerShell scripts per phase
│   └── deploy-all.sh                ← Full environment rebuild (end-to-end)
└── teardown/
    └── destroy-all.sh               ← Safely deletes all QCB lab resources
```

---

## Phases

| Phase | Topic | Key Services | Status |
|-------|-------|--------------|--------|
| [00](docs/00-prerequisites.md) | Prerequisites & Setup | Azure CLI, PowerShell Az, naming conventions | 🔲 Planned |
| [01](docs/01-resource-groups.md) | Resource Groups & Subscriptions | Resource Groups, Tags | 🔲 Planned |
| [02](docs/02-networking.md) | Networking | VNet, Subnets, NSGs, Peering, DNS | 🔲 Planned |
| [03](docs/03-compute.md) | Compute | Linux VM, Windows VM, Load Balancer, Availability | 🔲 Planned |
| [04](docs/04-storage.md) | Storage | Storage Account, Blob, File Share, Lifecycle Policies | 🔲 Planned |
| [05](docs/05-identity.md) | Identity & Access | RBAC, Managed Identities, Entra ID | 🔲 Planned |
| [06](docs/06-keyvault.md) | Key Vault | Secrets, Keys, Access via Managed Identity | 🔲 Planned |
| [07](docs/07-monitoring.md) | Monitoring | Log Analytics, Azure Monitor, Alerts, VM Insights | 🔲 Planned |
| [08](docs/08-automation.md) | Automation | Full deploy + teardown scripts | 🔲 Planned |

---

## Naming Convention

All resources follow a consistent naming pattern:

```
qcb-<resource-type>-<descriptor>-<number>
```

| Resource | Example Name |
|----------|-------------|
| Resource Group | `qcb-rg-lab` |
| Virtual Network | `qcb-vnet-main` |
| Subnet | `qcb-snet-web`, `qcb-snet-app`, `qcb-snet-data` |
| Network Security Group | `qcb-nsg-web`, `qcb-nsg-app` |
| Virtual Machine | `qcb-vm-web-01`, `qcb-vm-app-01` |
| Load Balancer | `qcb-lb-web` |
| Storage Account | `qcbstorage01` *(no hyphens — Azure limitation)* |
| Key Vault | `qcb-kv-lab` |
| Log Analytics Workspace | `qcb-law-main` |

---

## Cost Controls

This lab is designed to be as cheap as possible:

- **VM sizes**: `Standard_B1s` (cheapest burstable, ~£3/month if left running)
- **Tear down after each session**: Use `teardown/destroy-all.sh` — rebuild takes ~10 minutes
- **Region**: UK South — closest to Isle of Man, competitive pricing
- **Storage**: LRS (locally redundant) — cheapest replication tier
- **No reserved instances** — pay-as-you-go only, resources deleted between sessions
- **Free tier where available**: Log Analytics (first 5GB/day free), Key Vault (10k operations free)

> Estimated cost per active session (2–3 hours): **< £0.50**
> Estimated cost if VMs accidentally left running overnight: **~£0.30**

---

## Documentation Format

Each phase doc follows this structure:

```markdown
## What We're Building
Brief description of the goal and how it fits QCB's scenario.

## Prerequisites
What must exist before this phase.

## Step X — <Task Name>

### Why
The business or technical reason for this step.

### Azure CLI
\`\`\`bash
az <command>
\`\`\`

### PowerShell
\`\`\`powershell
<Az command>
\`\`\`

### What This Does
Explanation of what happened under the hood.

## Verification
How to confirm it worked.

## Teardown
How to remove just this phase's resources.
```

---

## Tools Required

| Tool | Purpose | Install |
|------|---------|---------|
| Azure CLI | Primary CLI tool | [docs.microsoft.com/cli/azure/install-azure-cli](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| PowerShell 7+ | Cross-platform shell | [aka.ms/powershell](https://aka.ms/powershell) |
| Az PowerShell module | Azure cmdlets | `Install-Module -Name Az` |
| Git | Version control | [git-scm.com](https://git-scm.com) |

---

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/<your-username>/qcb-azure-lab.git
cd qcb-azure-lab

# 2. Log in to Azure
az login

# 3. Confirm your subscription
az account show

# 4. Start with Phase 0
cat docs/00-prerequisites.md
```

---

## AZ-104 Curriculum Coverage

| AZ-104 Domain | Covered In |
|---------------|-----------|
| Manage Azure identities and governance | Phase 01, 05 |
| Implement and manage storage | Phase 04 |
| Deploy and manage Azure compute resources | Phase 03 |
| Implement and manage virtual networking | Phase 02 |
| Monitor and maintain Azure resources | Phase 07 |

---

*Built by [Your Name] — Isle of Man | [qcbhomelab.online](https://qcbhomelab.online)*
