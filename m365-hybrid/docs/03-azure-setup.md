[← 02 — AD Provisioning Scripts](02-ad-scripts.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [04 — Hybrid Identity →](04-hybrid-identity.md)

---

# 03 — Azure Resource Setup

## Introduction

Microsoft Azure is Microsoft's cloud platform — a global network of data centres where you can run virtual machines, store data, manage identities, and much more, paying only for what you use. Where Microsoft 365 handles the productivity layer (email, Teams, SharePoint), Azure handles the infrastructure layer.

In this project, Azure serves two purposes. First, it provides the cloud infrastructure that supports hybrid identity — specifically the network and compute resources needed to run Entra Connect Sync. Second, it gives us a structured, governed place to manage cloud resources using resource groups, which are logical containers that keep everything organised and easy to clean up.

A resource group is simply a folder in Azure. Everything inside it — virtual machines, storage accounts, network components — is grouped together so you can manage, monitor, and delete them as a unit. Good resource group design is a hallmark of a well-run Azure environment.

---

## What We Are Building

| Resource Group | Purpose |
|---|---|
| RG-Identity | Hybrid identity resources (Entra Connect Sync) |
| RG-Networking | Virtual network, subnets, and network security groups |
| RG-Management | Log Analytics workspace, alerts, monitoring |
| RG-UserServices | Migration staging and user-facing Azure services |
| RG-Shared | Automation accounts and shared resources |

All resources are deployed to the UK South region, which is the closest Azure region for this project.

---

## Implementation Steps

### Step 1 — Log in to Azure

Open a terminal and log in using the Azure CLI:

```bash
az login
az account set --subscription "QCB PAYG PersonalCloud"
```

Or using PowerShell:

```powershell
Connect-AzAccount
Set-AzContext -SubscriptionName "QCB PAYG PersonalCloud"
```

Confirm the correct subscription is active before creating anything:

```bash
az account show --output table
```

### Step 2 — Create the Resource Groups

```bash
az group create --name RG-Identity    --location uksouth
az group create --name RG-Networking  --location uksouth
az group create --name RG-Management  --location uksouth
az group create --name RG-UserServices --location uksouth
az group create --name RG-Shared      --location uksouth
```

Verify all five were created:

```bash
az group list --output table
```

### Step 3 — Create the Virtual Network

The virtual network provides private IP connectivity for any Azure-hosted resources, including the VM that will run Entra Connect Sync.

```bash
az network vnet create \
  --name VNET-QCBHomelab \
  --resource-group RG-Networking \
  --location uksouth \
  --address-prefix 10.10.0.0/16 \
  --subnet-name SNET-Identity \
  --subnet-prefix 10.10.1.0/24
```

Add a management subnet:

```bash
az network vnet subnet create \
  --name SNET-Management \
  --resource-group RG-Networking \
  --vnet-name VNET-QCBHomelab \
  --address-prefix 10.10.2.0/24
```

### Step 4 — Create a Network Security Group

A Network Security Group (NSG) is a basic firewall that controls what traffic is allowed in and out of a subnet. For the Identity subnet, we want to restrict inbound access to RDP only from trusted sources.

```bash
az network nsg create \
  --name NSG-Identity \
  --resource-group RG-Networking \
  --location uksouth

# Allow RDP inbound — restrict source to your own IP in production
az network nsg rule create \
  --name Allow-RDP \
  --nsg-name NSG-Identity \
  --resource-group RG-Networking \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-range 3389

# Associate NSG with the Identity subnet
az network vnet subnet update \
  --name SNET-Identity \
  --resource-group RG-Networking \
  --vnet-name VNET-QCBHomelab \
  --network-security-group NSG-Identity
```

> In a lab environment, RDP can be opened broadly for convenience. In production, restrict the source IP to your office or use Azure Bastion. Note that Bastion incurs cost — for this lab, use the Serial Console or RDP directly.

### Step 5 — Create a Log Analytics Workspace

Log Analytics is where Azure sends monitoring data, security alerts, and diagnostic logs. It is the foundation for any visibility into what is happening in the environment.

```bash
az monitor log-analytics workspace create \
  --workspace-name LAW-QCBHomelab \
  --resource-group RG-Management \
  --location uksouth \
  --sku PerGB2018
```

### Step 6 — Verify the Setup

```bash
# List all resources across all resource groups
az resource list --output table

# Check the virtual network
az network vnet show \
  --name VNET-QCBHomelab \
  --resource-group RG-Networking \
  --output table
```

---

## Cost Awareness

The resources created here are very low cost for a lab. The virtual network is free. The Log Analytics workspace charges only for data ingested — minimal in a lab. No virtual machines are created in this document; those are addressed in document 04 when we deploy the Entra Connect Sync server.

Before ending any session, always confirm nothing unexpected is running:

```bash
az resource list --output table
az vm list -d --output table
```

---

[← 02 — AD Provisioning Scripts](02-ad-scripts.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [04 — Hybrid Identity →](04-hybrid-identity.md)
