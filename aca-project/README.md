# Azure Cloud Architecture — QCB Technologies

> **Portfolio project** | AZ-104 hands-on implementation | Azure CLI + PowerShell + Azure Portal

---

## About This Project

QCB Technologies is a small, growing IT managed services company. This project documents the design, deployment, and automation of QCB's core Azure infrastructure — built from scratch using a pay-as-you-go subscription with cost-conscious, tear-down-and-rebuild practices.

The project is structured as a series of phases that together cover every domain of the **AZ-104: Microsoft Azure Administrator** exam. Each phase builds on the last, producing a real, working environment rather than isolated exercises. By the end, a single automation script (`scripts/deploy-all.sh`) rebuilds the entire environment from scratch in 15–20 minutes — and a teardown script (`teardown/destroy-all.sh`) removes everything cleanly to stop all costs.

Every task is documented in three ways:

1. **Azure Portal** — step-by-step navigation through the GUI
2. **Azure CLI** — the command and what it does
3. **PowerShell (Az module)** — the equivalent command

**Honest disclosure:** This is an active learning project built to close real gaps in Azure infrastructure knowledge. Documentation reflects progress as it happens, including gotchas, mistakes, and lessons learned.

---

## What the Scripts Build

The deploy script (`scripts/deploy-all.sh`) runs end-to-end through seven phases and creates the following infrastructure in a single automated run:

| Phase | What Gets Built |
|---|---|
| 01 | Resource group `qcb-rg-lab` with tags |
| 02 | VNet `qcb-vnet-lab`, subnets `snet-web` and `snet-app`, NSGs `nsg-web` and `nsg-app` with inbound rules |
| 03 | NICs `nic-web` and `nic-app` (no public IPs), Linux VM `vm-web` (Ubuntu 22.04, B1s) with nginx, Windows VM `vm-app` (Windows Server 2022, B1s) |
| 04 | Storage account `stqcblab` (Standard LRS, TLS 1.2), blob containers `uploads` and `backups` |
| 05 | System-assigned managed identity on `vm-web`, Storage Blob Data Reader role on `stqcblab` |
| 06 | Key Vault `qcb-kv-lab` (RBAC mode), secret `vm-admin-password`, Key Vault Secrets User role for `vm-web` identity |
| 07 | Log Analytics workspace `qcb-law-main` (PerGB2018, 30-day retention), action group `qcb-ag-ops` (email), CPU metric alert `qcb-alert-cpu-web` (>80% for 5 min) |

The teardown script (`teardown/destroy-all.sh`) purges the Key Vault (bypassing 90-day soft-delete) and deletes the resource group, removing every resource in a single operation.

---

## How This Covers the AZ-104 Exam

The AZ-104 exam is divided into five domains. This project covers all five:

### Domain 1 — Manage Azure Identities and Governance (20–25%)
**Covered in:** Phase 01, Phase 05

- Creating and managing resource groups with tags (Phase 01)
- Understanding subscription scope and resource group as a billing and access boundary (Phase 01)
- Role-Based Access Control (RBAC) — assigning built-in roles at resource scope (Phase 05)
- System-assigned managed identities — enabling, retrieving the principal ID, and assigning roles (Phase 05)
- `az ad signed-in-user show` to retrieve the current user's object ID for role assignments (Phase 06)

### Domain 2 — Implement and Manage Storage (15–20%)
**Covered in:** Phase 04, Phase 05

- Creating storage accounts with specific SKU, kind, access tier, and TLS version (Phase 04)
- Disabling public blob access at the account level (Phase 04)
- Creating blob containers using Entra ID authentication (`--auth-mode login`) rather than storage keys (Phase 04)
- Assigning the `Storage Blob Data Reader` RBAC role to a managed identity (Phase 05)
- Understanding the difference between storage key access and identity-based access (Phase 05)

### Domain 3 — Deploy and Manage Azure Compute Resources (20–25%)
**Covered in:** Phase 03

- Creating virtual machines with explicit NIC references to control network configuration (Phase 03)
- Understanding VM sizes and the burstable B-series tier (Phase 03)
- Using `az vm run-command invoke` to execute scripts inside VMs without public IPs or open ports (Phase 03)
- Installing and configuring software on VMs via the Azure control plane (Phase 03)
- Understanding the VM agent and how Azure communicates with VMs internally (Phase 03)
- No-public-IP architecture — why VMs should not be directly internet-exposed (Phase 03)

### Domain 4 — Implement and Manage Virtual Networking (15–20%)
**Covered in:** Phase 02

- Creating Virtual Networks with custom address spaces (Phase 02)
- Subnet design — dividing address space across tiers (Phase 02)
- Network Security Groups — creating, configuring inbound rules, and associating with subnets (Phase 02)
- NSG rule priorities and the implicit DenyAllInbound rule at priority 65500 (Phase 02)
- Restricting traffic between subnets — app tier only reachable from web tier (Phase 02)
- Understanding stateful firewall behaviour — return traffic is automatically allowed (Phase 02)

### Domain 5 — Monitor and Maintain Azure Resources (10–15%)
**Covered in:** Phase 06, Phase 07

- Azure Key Vault — creating vaults, storing secrets, RBAC access model vs vault access policies (Phase 06)
- Granting managed identities access to Key Vault secrets without credentials (Phase 06)
- Log Analytics Workspaces — creating, configuring retention, understanding the PerGB2018 SKU (Phase 07)
- Azure Monitor action groups — configuring email notifications (Phase 07)
- Metric alert rules — defining conditions, evaluation windows, and linking to action groups (Phase 07)
- Understanding the `microsoft.insights` resource provider and auto-registration (Phase 07)

---

## Scenario

| | |
|---|---|
| **Company** | QCB Technologies Ltd |
| **Domain** | qcbhomelab.online |
| **Size** | Small IT MSP, ~10 staff |
| **Goal** | Deploy and manage core Azure infrastructure across all AZ-104 domains |
| **Primary Region** | `eastus` |
| **Subscription** | QCB PAYG PersonalCloud (Pay-as-you-go) |

---

## Architecture Overview

```
[ qcb-vnet-lab — 10.0.0.0/16 ]
│
├── [ snet-web — 10.0.1.0/24 ]  ←  nsg-web (allow HTTP:80, HTTPS:443 inbound)
│     vm-web — Ubuntu 22.04, B1s, private IP 10.0.1.4
│     nginx serving QCB Technologies page
│     System-assigned managed identity
│       → Storage Blob Data Reader on stqcblab
│       → Key Vault Secrets User on qcb-kv-lab
│
└── [ snet-app — 10.0.2.0/24 ]  ←  nsg-app (allow TCP:8080 from snet-web only)
      vm-app — Windows Server 2022, B1s, private IP 10.0.2.4

[ stqcblab ]      — StorageV2, LRS, Hot, TLS1.2 | containers: uploads, backups
[ qcb-kv-lab ]    — Key Vault, RBAC mode | secret: vm-admin-password
[ qcb-law-main ]  — Log Analytics, PerGB2018, 30-day retention
[ qcb-ag-ops ]    — Action group | email: qcb-alerts@qcbhomelab.online
[ qcb-alert-cpu-web ] — CPU > 80% for 5 min on vm-web → qcb-ag-ops
```

> **No public IPs on any VM.** All VM access is via `az vm run-command` through the Azure control plane. VMs communicate over private IPs only within the VNet.

---

## Design Decisions

| Decision | Reason |
|---|---|
| No public IPs on VMs | Enterprise pattern — VMs not directly internet-exposed. Access via Azure control plane only. Eliminates cost and attack surface. |
| No load balancer | Out of scope for this lab. Would sit in front of `vm-web` in a production deployment. NSG rules for 80/443 are already in place. |
| No data subnet | Simplified to two subnets. A `snet-data` subnet (`10.0.3.0/24`) would be added for storage private endpoints in a production design. |
| Standard_B1s for both VMs | Cheapest burstable tier. Covered by Azure free account (750 hrs/month each for Linux and Windows). |
| Standard_LRS storage | Cheapest replication tier. Three copies in one datacentre — sufficient for a lab. |
| RBAC on Key Vault | Microsoft's recommended model for new deployments. Consistent with how all other access is managed in this project. |
| Containers via `--auth-mode login` | Uses Entra ID identity rather than storage account keys — the secure, recommended approach. |

---

## Repository Structure

```
aca-project/
├── README.md
├── docs/
│   ├── 00-prerequisites.md       ← Tooling, authentication, conventions
│   ├── 01-resource-groups.md     ← Resource groups, tags, subscription scope
│   ├── 02-networking.md          ← VNet, subnets, NSGs, inbound rules
│   ├── 03-compute.md             ← VMs, NICs, no-public-IP pattern, run-command
│   ├── 04-storage.md             ← Storage account, blob containers, TLS
│   ├── 05-identity.md            ← Managed identity, RBAC role assignments
│   ├── 06-keyvault.md            ← Key Vault, secrets, identity-based access
│   ├── 07-monitoring.md          ← Log Analytics, action groups, metric alerts
│   └── 08-automation.md          ← Deploy + teardown scripts, idempotency
├── scripts/
│   └── deploy-all.sh             ← Master deploy script (all 7 phases)
└── teardown/
    └── destroy-all.sh            ← Master teardown — purges KV, deletes RG
```

---

## Phases

| Phase | Topic | AZ-104 Domain | Status |
|-------|-------|---------------|--------|
| [00](docs/00-prerequisites.md) | Prerequisites & Setup | All | ✅ Complete |
| [01](docs/01-resource-groups.md) | Resource Groups & Tags | Identities & Governance | ✅ Complete |
| [02](docs/02-networking.md) | VNet, Subnets, NSGs | Virtual Networking | ✅ Complete |
| [03](docs/03-compute.md) | VMs, NICs, run-command | Compute Resources | ✅ Complete |
| [04](docs/04-storage.md) | Storage Account, Blobs | Storage | ✅ Complete |
| [05](docs/05-identity.md) | Managed Identity, RBAC | Identities & Governance | ✅ Complete |
| [06](docs/06-keyvault.md) | Key Vault, Secrets | Monitor & Maintain | ✅ Complete |
| [07](docs/07-monitoring.md) | Log Analytics, Alerts | Monitor & Maintain | ✅ Complete |
| [08](docs/08-automation.md) | Deploy + Teardown Scripts | All | ✅ Complete |

---

## Naming Convention

| Resource | Name |
|----------|------|
| Resource Group | `qcb-rg-lab` |
| Virtual Network | `qcb-vnet-lab` |
| Subnet (web) | `snet-web` |
| Subnet (app) | `snet-app` |
| NSG (web) | `nsg-web` |
| NSG (app) | `nsg-app` |
| NIC (web) | `nic-web` |
| NIC (app) | `nic-app` |
| Linux VM | `vm-web` |
| Windows VM | `vm-app` |
| Storage Account | `stqcblab` *(no hyphens — Azure enforced)* |
| Blob Container 1 | `uploads` |
| Blob Container 2 | `backups` |
| Key Vault | `qcb-kv-lab` |
| Log Analytics Workspace | `qcb-law-main` |
| Action Group | `qcb-ag-ops` |
| CPU Alert | `qcb-alert-cpu-web` |

---

## Free Tier Coverage

| Resource | Free Tier |
|---|---|
| vm-web (Linux B1s) | ✅ 750 hrs/month |
| vm-app (Windows B1s) | ✅ 750 hrs/month |
| OS Disks (Standard HDD) | ✅ 2× 64 GB managed disks |
| stqcblab (Blob Hot LRS) | ✅ First 5 GB/month |
| qcb-kv-lab | ✅ First 10,000 operations/month |
| qcb-law-main | ✅ First 5 GB/day ingestion |
| Metric alerts | ✅ First 10 rules free |
| VNet, NSGs, NICs | ✅ Always free |
| **Public IPs** | **✅ $0 — none created** |

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

*Part of the Engineering Portfolio — QCB Technologies lab environment. No real client data or credentials included.*
