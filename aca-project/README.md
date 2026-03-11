# Azure Cloud Architecture — QCB Technologies

> **Portfolio project** | AZ-104 hands-on implementation | Azure CLI + PowerShell + Automation

---

## About This Project

QCB Technologies is a small, growing IT managed services company. This project documents the design, deployment, and automation of QCB's core Azure infrastructure — built from scratch using a pay-as-you-go subscription with cost-conscious, tear-down-and-rebuild practices.

Every task is documented in three ways:

1. **Azure CLI** — the command and what it does
2. **PowerShell (Az module)** — the equivalent command
3. **Why** — the decision, trade-off, or dependency behind it

At the end of the project, a master automation script ties everything together so the full environment can be rebuilt in a single run.

**Honest disclosure:** This is an active learning project built to close real gaps in Azure infrastructure knowledge. Documentation reflects progress as it happens, including gotchas, mistakes, and lessons learned.

---

## Scenario

| | |
|---|---|
| **Company** | QCB Technologies Ltd |
| **Domain** | qcbhomelab.online |
| **Size** | Small IT MSP, ~10 staff |
| **Goal** | Deploy and manage core Azure infrastructure across all major AZ-104 domains |
| **Primary Region** | `eastus` *(replace with your preferred region)* |
| **Subscription type** | Pay-as-you-go |

---

## Architecture Overview

```
Internet
    │
    ▼
[ Load Balancer ] (Public IP — load balancer only)
    │
    ▼
[ Web Subnet ] — Linux VM (qcb-vm-web-01)       ← NSG: allow 80/443 inbound
    │
    ▼
[ App Subnet ] — Windows VM (qcb-vm-app-01)     ← NSG: allow 8080 from web subnet only
    │
    ▼
[ Data Subnet ] — Storage Account               ← No public access
    │
[ Key Vault ]     — Secrets via Managed Identity (no hardcoded credentials)
[ Log Analytics ] — Centralised monitoring, alerts, VM Insights
```

> **No public IPs on VMs.** All VM access is handled via `az vm run-command` through the Azure control plane — a realistic enterprise pattern.

---

## Repository Structure

```
aca-project/
├── README.md                            ← This file
├── docs/
│   ├── 00-prerequisites.md              ← Tooling, authentication, conventions
│   ├── 01-resource-groups.md            ← Resource groups, tags, subscription setup
│   ├── 02-networking.md                 ← VNet, subnets, NSGs, DNS
│   ├── 03-compute.md                    ← VMs, load balancer, availability
│   ├── 04-storage.md                    ← Storage account, blob, file share
│   ├── 05-identity.md                   ← RBAC, managed identities, Entra ID
│   ├── 06-keyvault.md                   ← Key Vault, secrets, access policies
│   ├── 07-monitoring.md                 ← Log Analytics, alerts, diagnostics
│   └── 08-automation.md                 ← Full deploy + teardown automation
├── scripts/
│   ├── cli/                             ← Azure CLI scripts per phase
│   └── powershell/                      ← PowerShell scripts per phase
├── teardown/
│   └── destroy-all.sh                   ← Master teardown — deletes everything
└── claude/
    ├── 00-prerequisites/CLAUDE.md
    ├── 01-resource-groups/CLAUDE.md
    ├── 02-networking/CLAUDE.md
    ├── 03-compute/CLAUDE.md
    ├── 04-storage/CLAUDE.md
    ├── 05-identity/CLAUDE.md
    ├── 06-keyvault/CLAUDE.md
    ├── 07-monitoring/CLAUDE.md
    └── 08-automation/CLAUDE.md
```

---

## Phases

| Phase | Topic | Key Services | Status |
|-------|-------|--------------|--------|
| [00](docs/00-prerequisites.md) | Prerequisites & Setup | Azure CLI, PowerShell Az, conventions | ✅ Complete |
| [01](docs/01-resource-groups.md) | Resource Groups | Resource Groups, Tags, Subscriptions | 🔲 Planned |
| [02](docs/02-networking.md) | Networking | VNet, Subnets, NSGs, DNS | 🔲 Planned |
| [03](docs/03-compute.md) | Compute | Linux VM, Windows VM, Load Balancer | 🔲 Planned |
| [04](docs/04-storage.md) | Storage | Storage Account, Blob, File Share, Lifecycle | 🔲 Planned |
| [05](docs/05-identity.md) | Identity & Access | RBAC, Managed Identities, Entra ID | 🔲 Planned |
| [06](docs/06-keyvault.md) | Key Vault | Secrets, Keys, Managed Identity Access | 🔲 Planned |
| [07](docs/07-monitoring.md) | Monitoring | Log Analytics, Azure Monitor, Alerts | 🔲 Planned |
| [08](docs/08-automation.md) | Automation | Full rebuild + teardown scripts | 🔲 Planned |

---

## Naming Convention

```
qcb-<resource-type>-<descriptor>-<number>
```

| Resource | Name |
|----------|------|
| Resource Group | `qcb-rg-lab` |
| Virtual Network | `qcb-vnet-lab` |
| Subnet (web) | `snet-web` |
| Subnet (app) | `snet-app` |
| Subnet (data) | `snet-data` |
| NSG | `nsg-web`, `nsg-app` |
| Linux VM | `qcb-vm-web-01` |
| Windows VM | `qcb-vm-app-01` |
| Load Balancer | `qcb-lb-web` |
| Storage Account | `qcbstorage01` *(no hyphens — Azure limitation)* |
| Key Vault | `qcb-kv-lab` |
| Log Analytics | `qcb-law-main` |

---

## Cost Controls

- **No public IPs on VMs** — VM access via `az vm run-command` only
- **VM sizes:** `Standard_B1s` — cheapest burstable tier
- **Storage:** LRS (locally redundant) — cheapest replication
- **Tear down after every session** — see [teardown/destroy-all.sh](teardown/destroy-all.sh)
- **Free tier services used where available** — Log Analytics (5GB/day free), Key Vault (10k ops free)
- **Rebuild takes ~10 minutes** from the master script

---

## Documentation Format

Each phase doc follows this structure:

```
## What We're Building
## Prerequisites
## The Technology — what it is and why we're using it
## Step X — <Task>
   ### Why
   ### Azure CLI
   ### PowerShell
   ### What This Does
## Verification
## Gotchas & Lessons Learned
## Teardown (this phase only)
## Navigation
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

## Tools Required

| Tool | Install |
|------|---------|
| Azure CLI | [docs.microsoft.com/cli/azure](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |
| PowerShell 7+ | [aka.ms/powershell](https://aka.ms/powershell) |
| Az PowerShell module | `Install-Module -Name Az` |
| Git | [git-scm.com](https://git-scm.com) |

---

➡️ **Start here:** [docs/00-prerequisites.md](docs/00-prerequisites.md)

---

*Part of the [Engineering Portfolio](../README.md) — QCB Technologies lab environment. No real client data or credentials included.*
