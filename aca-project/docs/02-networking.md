# Phase 02 — Networking

| | |
|---|---|
| **Phase** | 02 |
| **Topic** | Virtual Networking |
| **AZ-104 Domain** | Implement and Manage Virtual Networking |
| **Services** | VNet, Subnets, NSGs |
| **Est. Cost** | None — VNets and NSGs are free |

---

## Navigation

[← Phase 01: Resource Groups](01-resource-groups.md) | [Back to README](../README.md) | [Next: Phase 03 — Compute →](03-compute.md)

---

## What We're Building

A Virtual Network (`qcb-vnet-lab`) with two subnets — `snet-web` and `snet-app` — each protected by its own Network Security Group. This creates the network isolation that separates the web tier from the application tier, and demonstrates the core AZ-104 networking concepts: address space design, subnet segmentation, and stateful firewall rules.

This phase maps to the **Implement and Manage Virtual Networking** domain of AZ-104, specifically: creating and configuring VNets, configuring subnets, and creating and configuring NSGs.

---

## The Technology

### Virtual Network (VNet)

A VNet is Azure's isolated private network. Resources inside a VNet can communicate with each other by default. Resources outside cannot reach in unless explicitly allowed. The VNet has an address space — a range of private IP addresses that all resources inside it draw from.

This project uses `10.0.0.0/16` — the standard RFC 1918 private range, giving 65,536 possible addresses.

### Subnets

A subnet is a subdivision of the VNet's address space used to segment workloads:

| Subnet | CIDR | Purpose | First usable IP |
|--------|------|---------|-----------------|
| `snet-web` | `10.0.1.0/24` | Web tier — `vm-web` (nginx) | 10.0.1.4 |
| `snet-app` | `10.0.2.0/24` | App tier — `vm-app` (Windows) | 10.0.2.4 |

Azure reserves the first four addresses and the last address in every subnet (`.0`, `.1`, `.2`, `.3`, `.255`), leaving 251 usable addresses per `/24`.

> **Design note:** A third `snet-data` subnet (`10.0.3.0/24`) is reserved for storage private endpoints in a future production design but is not deployed in this lab.

### Network Security Groups (NSGs)

An NSG is a stateful firewall attached to a subnet or NIC. Rules have a priority number — **lower = higher priority**. Azure evaluates rules from lowest to highest until a match is found. If no rule matches, the implicit `DenyAllInbound` rule at priority 65500 blocks the traffic.

**Stateful** means return traffic for allowed connections is automatically permitted — no matching outbound rule is needed.

### NSG Rules in This Project

| NSG | Rule | Priority | Protocol | Port | Source | Action |
|---|---|---|---|---|---|---|
| nsg-web | Allow-HTTP | 100 | TCP | 80 | Any | Allow |
| nsg-web | Allow-HTTPS | 110 | TCP | 443 | Any | Allow |
| nsg-app | Allow-From-Web | 100 | TCP | 8080 | 10.0.1.0/24 | Allow |

The app tier (`snet-app`) only accepts traffic from the web subnet — not from the internet or any other source.

---

## Step 1 — Create the Virtual Network

### Azure Portal

1. In the search bar, type **Virtual networks** and select it
2. Click **+ Create**
3. Fill in the **Basics** tab:
   - **Subscription:** QCB PAYG PersonalCloud
   - **Resource group:** `qcb-rg-lab`
   - **Name:** `qcb-vnet-lab`
   - **Region:** East US
4. Click **Next: IP Addresses**
5. Set **IPv4 address space** to `10.0.0.0/16`
6. Delete any pre-populated default subnet
7. Click **Review + create**, then **Create**

### Azure CLI

```bash
az network vnet create \
  --resource-group qcb-rg-lab \
  --name qcb-vnet-lab \
  --address-prefixes 10.0.0.0/16 \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzVirtualNetwork `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-vnet-lab" `
  -Location "eastus" `
  -AddressPrefix "10.0.0.0/16" `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 2 — Create the Subnets

### Azure Portal

1. Open **qcb-vnet-lab**
2. In the left menu, click **Subnets**
3. Click **+ Subnet**:
   - **Name:** `snet-web`
   - **Subnet address range:** `10.0.1.0/24`
   - Click **Save**
4. Click **+ Subnet** again:
   - **Name:** `snet-app`
   - **Subnet address range:** `10.0.2.0/24`
   - Click **Save**

### Azure CLI

```bash
az network vnet subnet create \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-lab \
  --name snet-web \
  --address-prefixes 10.0.1.0/24

az network vnet subnet create \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-lab \
  --name snet-app \
  --address-prefixes 10.0.2.0/24
```

### PowerShell

```powershell
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"

Add-AzVirtualNetworkSubnetConfig `
  -Name "snet-web" `
  -VirtualNetwork $vnet `
  -AddressPrefix "10.0.1.0/24" | Set-AzVirtualNetwork

# Re-fetch — $vnet is stale after Set-AzVirtualNetwork
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"

Add-AzVirtualNetworkSubnetConfig `
  -Name "snet-app" `
  -VirtualNetwork $vnet `
  -AddressPrefix "10.0.2.0/24" | Set-AzVirtualNetwork
```

---

## Step 3 — Create the Network Security Groups

### Azure Portal

1. In the search bar, type **Network security groups** and select it
2. Click **+ Create**:
   - **Resource group:** `qcb-rg-lab`
   - **Name:** `nsg-web`
   - **Region:** East US
   - Click **Review + create**, then **Create**
3. Repeat for `nsg-app`

### Azure CLI

```bash
az network nsg create \
  --resource-group qcb-rg-lab \
  --name nsg-web \
  --tags Project=QCBLab Environment=Lab

az network nsg create \
  --resource-group qcb-rg-lab \
  --name nsg-app \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzNetworkSecurityGroup `
  -ResourceGroupName "qcb-rg-lab" `
  -Location "eastus" `
  -Name "nsg-web" `
  -Tag @{Project="QCBLab"; Environment="Lab"}

New-AzNetworkSecurityGroup `
  -ResourceGroupName "qcb-rg-lab" `
  -Location "eastus" `
  -Name "nsg-app" `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 4 — Add NSG Rules

### Azure Portal

**nsg-web — HTTP and HTTPS inbound:**
1. Open **nsg-web → Inbound security rules → + Add**
2. Rule 1:
   - **Source:** Any | **Destination port:** 80 | **Protocol:** TCP
   - **Action:** Allow | **Priority:** 100 | **Name:** `Allow-HTTP`
   - Click **Add**
3. Rule 2:
   - **Source:** Any | **Destination port:** 443 | **Protocol:** TCP
   - **Action:** Allow | **Priority:** 110 | **Name:** `Allow-HTTPS`
   - Click **Add**

**nsg-app — port 8080 from web subnet only:**
1. Open **nsg-app → Inbound security rules → + Add**
2. Rule:
   - **Source:** IP Addresses | **Source IP:** `10.0.1.0/24`
   - **Destination port:** 8080 | **Protocol:** TCP
   - **Action:** Allow | **Priority:** 100 | **Name:** `Allow-From-Web`
   - Click **Add**

### Azure CLI

```bash
# nsg-web rules
az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name nsg-web \
  --name Allow-HTTP \
  --priority 100 \
  --protocol Tcp \
  --direction Inbound \
  --access Allow \
  --destination-port-range 80

az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name nsg-web \
  --name Allow-HTTPS \
  --priority 110 \
  --protocol Tcp \
  --direction Inbound \
  --access Allow \
  --destination-port-range 443

# nsg-app rule
az network nsg rule create \
  --resource-group qcb-rg-lab \
  --nsg-name nsg-app \
  --name Allow-From-Web \
  --priority 100 \
  --protocol Tcp \
  --direction Inbound \
  --access Allow \
  --source-address-prefix 10.0.1.0/24 \
  --destination-port-range 8080
```

### PowerShell

```powershell
# nsg-web rules
$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-web"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgWeb `
  -Name "Allow-HTTP" -Priority 100 -Protocol Tcp `
  -Direction Inbound -Access Allow `
  -SourceAddressPrefix "*" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange 80 | Set-AzNetworkSecurityGroup

$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-web"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgWeb `
  -Name "Allow-HTTPS" -Priority 110 -Protocol Tcp `
  -Direction Inbound -Access Allow `
  -SourceAddressPrefix "*" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange 443 | Set-AzNetworkSecurityGroup

# nsg-app rule
$nsgApp = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-app"

Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsgApp `
  -Name "Allow-From-Web" -Priority 100 -Protocol Tcp `
  -Direction Inbound -Access Allow `
  -SourceAddressPrefix "10.0.1.0/24" -SourcePortRange "*" `
  -DestinationAddressPrefix "*" -DestinationPortRange 8080 | Set-AzNetworkSecurityGroup
```

---

## Step 5 — Associate NSGs with Subnets

### Azure Portal

1. Open **nsg-web → Subnets → + Associate**
   - **Virtual network:** `qcb-vnet-lab` | **Subnet:** `snet-web`
   - Click **OK**
2. Open **nsg-app → Subnets → + Associate**
   - **Virtual network:** `qcb-vnet-lab` | **Subnet:** `snet-app`
   - Click **OK**

### Azure CLI

```bash
az network vnet subnet update \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-lab \
  --name snet-web \
  --network-security-group nsg-web

az network vnet subnet update \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-lab \
  --name snet-app \
  --network-security-group nsg-app
```

### PowerShell

```powershell
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"
$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-web"
$nsgApp = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-app"

Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name "snet-web" `
  -AddressPrefix "10.0.1.0/24" `
  -NetworkSecurityGroup $nsgWeb | Set-AzVirtualNetwork

$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"

Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name "snet-app" `
  -AddressPrefix "10.0.2.0/24" `
  -NetworkSecurityGroup $nsgApp | Set-AzVirtualNetwork
```

---

## Verification

### Azure Portal

1. Open **qcb-vnet-lab → Subnets** — confirm both subnets show their associated NSG
2. Open **nsg-web → Inbound security rules** — confirm Allow-HTTP (100) and Allow-HTTPS (110)
3. Open **nsg-app → Inbound security rules** — confirm Allow-From-Web (100)

### Azure CLI

```bash
az network vnet show \
  --resource-group qcb-rg-lab \
  --name qcb-vnet-lab \
  --query "{Name:name, Space:addressSpace.addressPrefixes}" \
  --output table

az network vnet subnet list \
  --resource-group qcb-rg-lab \
  --vnet-name qcb-vnet-lab \
  --output table

az network nsg list \
  --resource-group qcb-rg-lab \
  --output table
```

### PowerShell

```powershell
Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab" | Format-List

Get-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork (Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab") | Format-Table

Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" | Format-Table Name, Location
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. Subnets must be created sequentially in CLI.** Parallel calls to `az network vnet subnet create` on the same VNet race on the parent resource and fail. The deploy script creates them one after the other — this is intentional.

**2. NSGs must exist before subnet association.** `az network vnet subnet update --network-security-group` resolves the NSG by name at call time. If the NSG doesn't exist the call fails. The script creates all NSGs before any association.

**3. Re-fetch `$vnet` between PowerShell operations.** After `Set-AzVirtualNetwork`, the local `$vnet` object is stale. Re-fetch with `Get-AzVirtualNetwork` before the next operation. The same applies after adding NSG rules with `Set-AzNetworkSecurityGroup`.

**4. Every NSG has an implicit `DenyAllInbound` at priority 65500.** Azure adds this automatically and it is not visible unless you pass `--include-default` when listing rules. All custom rules must have a lower priority number to be evaluated first.

**5. `PrivateEndpointNetworkPolicies: Disabled` appears on all new subnets.** This is the default state — NSGs and UDRs are not enforced on Private Endpoint traffic. Leave it as-is for this lab.

**6. NSG association is one CLI command but four PowerShell steps.** CLI handles it with `az network vnet subnet update`. PowerShell requires fetching the VNet, fetching the NSG, calling `Set-AzVirtualNetworkSubnetConfig`, then `Set-AzVirtualNetwork`.

---

## Cost at This Phase

**Zero** — VNets, subnets, and NSGs have no cost.

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

```powershell
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 01: Resource Groups](01-resource-groups.md) | [Back to README](../README.md) | [Next: Phase 03 — Compute →](03-compute.md)
