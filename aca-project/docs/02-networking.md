# Phase 02 — Networking

| | |
|---|---|
| **Phase** | 02 |
| **Topic** | Virtual Networking |
| **Services** | VNet, Subnets, NSGs, DNS |
| **Est. Cost** | Minimal — VNets are free, NSGs are free |

---

## Navigation

[← Phase 01: Resource Groups](01-resource-groups.md) | [Back to README](../README.md) | [Next: Phase 03 — Compute →](03-compute.md)

---

## What We're Building

A Virtual Network (`qcb-vnet-main`) with three subnets — web, app, and data — each with its own Network Security Group controlling what traffic can enter and leave. This creates the network isolation that separates QCB's public-facing, internal, and data tiers.

---

## The Technology

### Virtual Network (VNet)

A VNet is Azure's isolated private network. Resources inside a VNet can communicate with each other by default. Resources outside cannot reach in unless you explicitly allow it. Think of it as your own private data centre network, but in Azure.

A VNet has an address space — a range of private IP addresses (e.g. `10.0.0.0/16`) that all resources inside it will draw from.

### Subnets

A subnet is a subdivision of a VNet's address space. You create subnets to logically separate workloads. In QCB's case:

| Subnet | CIDR | Purpose |
|--------|------|---------|
| `qcb-snet-web` | `10.0.1.0/24` | Web tier — Linux VM, load balancer |
| `qcb-snet-app` | `10.0.2.0/24` | App tier — Windows VM |
| `qcb-snet-data` | `10.0.3.0/24` | Data tier — Storage account private endpoint |

Each subnet gets 256 addresses (`/24`), though Azure reserves 5 of them. More than enough for a lab.

### Network Security Groups (NSGs)

An NSG is a stateful firewall attached to a subnet (or NIC). It contains inbound and outbound rules that allow or deny traffic based on source, destination, port, and protocol.

Rules have a priority number — **lower number = higher priority**. Rules are evaluated from lowest to highest until a match is found. If no rule matches, traffic is denied by the default rules.

**Why stateful?** If an inbound connection is allowed, the return traffic is automatically allowed. You don't need to create a matching outbound rule.

### DNS

By default, Azure provides DNS resolution within a VNet — VMs can resolve each other by name automatically. We'll use Azure's default DNS for this project (no custom DNS server needed).

---

## Step 1 — Create the Virtual Network

### Azure CLI

```bash
az network vnet create \
  --resource-group qcb-rg-lab \
  --name qcb-vnet-main \
  --address-prefix 10.0.0.0/16 \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzVirtualNetwork `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-vnet-main" `
  -Location "eastus" `
  -AddressPrefix "10.0.0.0/16" `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

### What This Does

Creates a VNet with address space `10.0.0.0/16` — giving us 65,536 possible addresses to allocate across subnets. We're using the `10.0.0.0` private range which is standard for internal networks.

---

## Step 2 — Create the Subnets

### Azure CLI

```bash
# Web subnet
az network vnet subnet create \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-web \
  --address-prefix 10.0.1.0/24

# App subnet
az network vnet subnet create \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-app \
  --address-prefix 10.0.2.0/24

# Data subnet
az network vnet subnet create \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-data \
  --address-prefix 10.0.3.0/24
```

### PowerShell

```powershell
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-main"

Add-AzVirtualNetworkSubnetConfig -Name "qcb-snet-web" -VirtualNetwork $vnet -AddressPrefix "10.0.1.0/24" | Set-AzVirtualNetwork
Add-AzVirtualNetworkSubnetConfig -Name "qcb-snet-app" -VirtualNetwork $vnet -AddressPrefix "10.0.2.0/24" | Set-AzVirtualNetwork
Add-AzVirtualNetworkSubnetConfig -Name "qcb-snet-data" -VirtualNetwork $vnet -AddressPrefix "10.0.3.0/24" | Set-AzVirtualNetwork
```

> **Note:** In PowerShell, each `Add-AzVirtualNetworkSubnetConfig` pipes directly into `Set-AzVirtualNetwork` to commit the change. You need to re-fetch `$vnet` before adding each subnet, or add all configs before calling `Set-AzVirtualNetwork` once at the end.

---

## Step 3 — Create the Network Security Groups

### Azure CLI

```bash
az network nsg create --resource-group qcb-rg-lab --name qcb-nsg-web --tags Project=QCBLab
az network nsg create --resource-group qcb-rg-lab --name qcb-nsg-app --tags Project=QCBLab
az network nsg create --resource-group qcb-rg-lab --name qcb-nsg-data --tags Project=QCBLab
```

### PowerShell

```powershell
New-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Location "eastus" -Name "qcb-nsg-web" -Tag @{Project="QCBLab"}
New-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Location "eastus" -Name "qcb-nsg-app" -Tag @{Project="QCBLab"}
New-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Location "eastus" -Name "qcb-nsg-data" -Tag @{Project="QCBLab"}
```

---

## Step 4 — Add NSG Rules

### Web NSG — allow HTTP and HTTPS inbound

```bash
# Allow HTTP
az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name qcb-nsg-web \
  --name Allow-HTTP \
  --priority 100 \
  --protocol Tcp \
  --destination-port-range 80 \
  --access Allow \
  --direction Inbound

# Allow HTTPS
az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name qcb-nsg-web \
  --name Allow-HTTPS \
  --priority 110 \
  --protocol Tcp \
  --destination-port-range 443 \
  --access Allow \
  --direction Inbound
```

### App NSG — allow port 8080 from web subnet only

```bash
az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name qcb-nsg-app \
  --name Allow-From-Web \
  --priority 100 \
  --protocol Tcp \
  --source-address-prefix 10.0.1.0/24 \
  --destination-port-range 8080 \
  --access Allow \
  --direction Inbound
```

### PowerShell equivalent (web NSG rules)

```powershell
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "qcb-nsg-web"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
  -Name "Allow-HTTP" -Priority 100 -Protocol Tcp `
  -Direction Inbound -Access Allow `
  -SourceAddressPrefix "*" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange 80 | Set-AzNetworkSecurityGroup

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg `
  -Name "Allow-HTTPS" -Priority 110 -Protocol Tcp `
  -Direction Inbound -Access Allow `
  -SourceAddressPrefix "*" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange 443 | Set-AzNetworkSecurityGroup
```

---

## Step 5 — Associate NSGs with Subnets

### Azure CLI

```bash
az network vnet subnet update \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-web \
  --network-security-group qcb-nsg-web

az network vnet subnet update \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-app \
  --network-security-group qcb-nsg-app

az network vnet subnet update \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-main \
  --name qcb-snet-data \
  --network-security-group qcb-nsg-data
```

### PowerShell

```powershell
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-main"
$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "qcb-nsg-web"
$nsgApp = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "qcb-nsg-app"
$nsgData = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "qcb-nsg-data"

Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "qcb-snet-web" -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgWeb | Set-AzVirtualNetwork
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "qcb-snet-app" -AddressPrefix "10.0.2.0/24" -NetworkSecurityGroup $nsgApp | Set-AzVirtualNetwork
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "qcb-snet-data" -AddressPrefix "10.0.3.0/24" -NetworkSecurityGroup $nsgData | Set-AzVirtualNetwork
```

---

## Verification

```bash
# Confirm VNet and subnets
az network vnet show --resource-group qcb-rg-lab --name qcb-vnet-main --output table
az network vnet subnet list --resource-group qcb-rg-lab --vnet-name qcb-vnet-main --output table

# Confirm NSGs and their rules
az network nsg list --resource-group qcb-rg-lab --output table
az network nsg rule list --resource-group qcb-rg-lab --nsg-name qcb-nsg-web --output table
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

Deleting the resource group removes everything including the VNet, subnets, and NSGs:

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 01: Resource Groups](01-resource-groups.md) | [Back to README](../README.md) | [Next: Phase 03 — Compute →](03-compute.md)
