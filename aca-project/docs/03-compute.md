# Phase 03 — Compute

| | |
|---|---|
| **Phase** | 03 |
| **Topic** | Virtual Machines |
| **AZ-104 Domain** | Deploy and Manage Azure Compute Resources |
| **Services** | Azure VMs, NICs, `az vm run-command` |
| **Est. Cost** | Free tier — Linux B1s (750 hrs/month) + Windows B1s (750 hrs/month) |

---

## Navigation

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)

---

## What We're Building

Two virtual machines — a Linux VM (`vm-web`) in `snet-web` running nginx, and a Windows VM (`vm-app`) in `snet-app`. Neither VM has a public IP. All access and verification is via `az vm run-command`, which executes scripts inside a VM through the Azure control plane without SSH, RDP, or any open inbound ports.

This phase maps to the **Deploy and Manage Azure Compute Resources** domain of AZ-104, specifically: creating and configuring VMs, understanding VM sizes, configuring VM networking, and using the Azure control plane to manage VMs without direct connectivity.

---

## Design Decisions

### No Public IPs on VMs

| Reason | Detail |
|---|---|
| Security | A public IP on a VM is a direct attack surface — exposed to brute-force, port scanning, and exploitation |
| Cost | Standard SKU public IPs are billed per hour — eliminated entirely in this project |
| Realism | In production, VMs sit behind a load balancer. The load balancer holds the public IP; VMs have private IPs only |

### No Load Balancer

Out of scope for this lab. In a production design a load balancer would sit in front of `vm-web` and hold the public IP. The NSG rules for ports 80 and 443 are already in place on `nsg-web` for when one is added.

### Why Create NICs Separately?

When `az vm create` creates a NIC automatically (without `--nics`), it attaches a public IP by default. Creating the NICs first gives explicit control — no public IP, correct subnet, correct NSG.

### How VM Access Works Without Public IPs

`az vm run-command invoke` sends a script to the VM agent — a lightweight service on every Azure VM. The agent executes it locally and returns the output. The VM agent communicates **outbound** to Azure over port 443. No inbound ports need to be open.

```
Your terminal  →  HTTPS (port 443 outbound from VM)  →  Azure Control Plane  →  VM Agent  →  Script runs locally
```

---

## The Technology

### VM Size — Standard_B1s

1 vCPU, 1GB RAM. The B-series is burstable — the VM earns CPU credits during idle periods and spends them during bursts. The B1s is the cheapest size in Azure and is covered by the free account (750 hrs/month each for Linux and Windows B1s).

---

## Step 1 — Create the NICs

### Azure Portal

1. Search for **Network interfaces** and select it
2. Click **+ Create**, fill in:
   - **Resource group:** `qcb-rg-lab` | **Name:** `nic-web` | **Region:** East US
   - **Virtual network:** `qcb-vnet-lab` | **Subnet:** `snet-web`
   - **NIC network security group:** `nsg-web`
   - **Public IP address:** None
   - Click **Review + create**, then **Create**
3. Repeat for `nic-app`:
   - **Name:** `nic-app` | **Subnet:** `snet-app` | **NSG:** `nsg-app` | **Public IP:** None

### Azure CLI

```bash
az network nic create \
  --resource-group qcb-rg-lab \
  --name nic-web \
  --vnet-name qcb-vnet-lab \
  --subnet snet-web \
  --network-security-group nsg-web

az network nic create \
  --resource-group qcb-rg-lab \
  --name nic-app \
  --vnet-name qcb-vnet-lab \
  --subnet snet-app \
  --network-security-group nsg-app
```

### PowerShell

```powershell
$vnet   = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"
$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-web"
$nsgApp = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-app"

New-AzNetworkInterface `
  -ResourceGroupName "qcb-rg-lab" -Name "nic-web" -Location "eastus" `
  -Subnet (Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "snet-web") `
  -NetworkSecurityGroup $nsgWeb

New-AzNetworkInterface `
  -ResourceGroupName "qcb-rg-lab" -Name "nic-app" -Location "eastus" `
  -Subnet (Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "snet-app") `
  -NetworkSecurityGroup $nsgApp
```

> No `-PublicIpAddress` parameter — both NICs are intentionally private only.

---

## Step 2 — Create the Linux VM (vm-web)

### Azure Portal

1. Search **Virtual machines → + Create → Azure virtual machine**
2. **Basics:**
   - **Resource group:** `qcb-rg-lab` | **Name:** `vm-web` | **Region:** East US
   - **Image:** Ubuntu Server 22.04 LTS | **Size:** Standard_B1s
   - **Authentication:** SSH public key | **Username:** `qcbadmin`
3. **Disks:** OS disk type → Standard HDD
4. **Networking:** NIC → `nic-web` | Public IP → None
5. Click **Review + create**, then **Create**

### Azure CLI

```bash
az vm create \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --nics nic-web \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --storage-sku Standard_LRS \
  --admin-username qcbadmin \
  --generate-ssh-keys \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
$nicWeb = Get-AzNetworkInterface -ResourceGroupName "qcb-rg-lab" -Name "nic-web"
$cred   = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" -Name "vm-web" -Location "eastus" `
  -NetworkInterface $nicWeb -Image "Ubuntu2204" -Size "Standard_B1s" `
  -Credential $cred -Tag @{Project="QCBLab"; Environment="Lab"}
```

> In the deploy script `--generate-ssh-keys` is used for automation. In PowerShell, `Get-Credential` prompts interactively.

---

## Step 3 — Create the Windows VM (vm-app)

### Azure Portal

1. **Virtual machines → + Create → Azure virtual machine**
2. **Basics:**
   - **Resource group:** `qcb-rg-lab` | **Name:** `vm-app` | **Region:** East US
   - **Image:** Windows Server 2022 Datacenter | **Size:** Standard_B1s
   - **Username:** `qcbadmin` | **Password:** *(strong password — moved to Key Vault in Phase 06)*
3. **Disks:** OS disk type → Standard HDD
4. **Networking:** NIC → `nic-app` | Public IP → None
5. Click **Review + create**, then **Create**

### Azure CLI

```bash
az vm create \
  --resource-group qcb-rg-lab \
  --name vm-app \
  --nics nic-app \
  --image Win2022Datacenter \
  --size Standard_B1s \
  --storage-sku Standard_LRS \
  --admin-username qcbadmin \
  --admin-password "QCBLab2024!Secure" \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
$nicApp = Get-AzNetworkInterface -ResourceGroupName "qcb-rg-lab" -Name "nic-app"
$cred   = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" -Name "vm-app" -Location "eastus" `
  -NetworkInterface $nicApp -Image "Win2022Datacenter" -Size "Standard_B1s" `
  -Credential $cred -Tag @{Project="QCBLab"; Environment="Lab"}
```

> The password is hardcoded in the deploy script as a deliberate starting point. Phase 06 moves it to Key Vault — illustrating the problem that secrets management solves.

---

## Step 4 — Install nginx on vm-web

### Azure Portal

1. Open **vm-web → Operations → Run command → RunShellScript**
2. Paste and click **Run**:
```bash
sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html
```

### Azure CLI

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --command-id RunShellScript \
  --scripts "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html"
```

### PowerShell

```powershell
Invoke-AzVMRunCommand `
  -ResourceGroupName "qcb-rg-lab" -VMName "vm-web" `
  -CommandId "RunShellScript" `
  -ScriptString "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html"
```

---

## Verification

### Azure Portal

1. **Virtual machines** — confirm both `vm-web` and `vm-app` show **Running**
2. **vm-web → Networking** — private IP `10.0.1.4`, no public IP
3. **vm-app → Networking** — private IP `10.0.2.4`, no public IP
4. **vm-web → Run command → RunShellScript** — run `curl -s http://localhost | head -3`

### Azure CLI

```bash
# Both VMs and power state
az vm list --resource-group qcb-rg-lab --show-details --output table

# Confirm private IPs only — no public IP column populated
az network nic list \
  --resource-group qcb-rg-lab \
  --query "[].{NIC:name, PrivateIP:ipConfigurations[0].privateIPAddress}" \
  --output table

# Confirm nginx responding
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --command-id RunShellScript \
  --scripts "curl -s http://localhost | head -3"
```

### PowerShell

```powershell
Get-AzVM -ResourceGroupName "qcb-rg-lab" | Format-Table Name, Location

Get-AzNetworkInterface -ResourceGroupName "qcb-rg-lab" | `
  Select-Object Name, @{N="PrivateIP";E={$_.IpConfigurations[0].PrivateIpAddress}}

Invoke-AzVMRunCommand `
  -ResourceGroupName "qcb-rg-lab" -VMName "vm-web" `
  -CommandId "RunShellScript" -ScriptString "curl -s http://localhost | head -3"
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. `az vm run-command invoke` for nginx install is slow.** The full `apt-get update && apt-get install nginx` takes 2–3 minutes. The command blocks until complete — do not cancel it. Output includes debconf warnings about non-interactive terminal — these are harmless.

**2. Windows VM provisioning takes significantly longer than Linux.** Expect 5–8 minutes for `vm-app` vs 2–3 minutes for `vm-web`. This is normal — Windows Server images are larger and require more first-boot configuration.

**3. Private IPs are deterministic in this setup.** Because the NICs are the first resources assigned in each subnet, Azure assigns `10.0.1.4` to `nic-web` and `10.0.2.4` to `nic-app`. Azure always reserves `.0`–`.3`, so `.4` is the first usable address.

**4. `--generate-ssh-keys` creates a key that is never used.** The SSH key is generated at `~/.ssh/id_rsa` if one does not exist. All access in this project is via run-command so the key is not needed — it causes no issues.

**5. If `az vm create` is run without `--nics`, Azure creates a NIC with a public IP automatically.** Always pass `--nics` with a pre-created NIC to maintain explicit control over the network configuration.

**6. `--storage-sku Standard_LRS` must be specified explicitly.** Without it, `az vm create` may default to Premium_LRS depending on CLI version, which is not covered by the free tier disk allowance.

---

## Cost at This Phase

| Resource | Free Tier |
|---|---|
| vm-web (Linux B1s) | ✅ 750 hrs/month |
| vm-app (Windows B1s) | ✅ 750 hrs/month |
| OS Disks (Standard HDD) | ✅ 2× 64 GB managed disks |
| nic-web, nic-app | ✅ Free |
| Public IPs | ✅ $0 — none created |

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

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)
