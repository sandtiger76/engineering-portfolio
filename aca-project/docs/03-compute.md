# Phase 03 — Compute

| | |
|---|---|
| **Phase** | 03 |
| **Topic** | Virtual Machines |
| **Services** | Azure VMs, `az vm run-command` |
| **Est. Cost** | Free tier — `Standard_B1s` Linux (750 hrs/month) + Windows (750 hrs/month) |

---

## Navigation

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)

---

## What We're Building

Two virtual machines — a Linux VM (`vm-web`) in the web subnet and a Windows VM (`vm-app`) in the app subnet. Neither VM has a public IP address. All VM access and verification is handled via `az vm run-command`, which runs commands inside a VM through the Azure control plane without needing SSH, RDP, or any open inbound ports.

---

## Design Decision — No Public IPs on VMs

This project deliberately omits public IPs on VMs. This is the correct enterprise pattern, not a simplification.

**Why no public IPs:**

- **Security** — directly exposing a VM to the internet creates an attack surface. Every public IP on a VM is a target for brute-force, port scanning, and exploitation.
- **Cost** — Standard SKU public IPs are billed per hour. For a tear-down-and-rebuild lab, this adds up across sessions for no practical benefit.
- **Realism** — in production, VMs sit behind a load balancer or Application Gateway. The load balancer holds the public IP; VMs have private IPs only. This project mirrors that architecture.

**How we access VMs instead:**

`az vm run-command invoke` sends a script to the VM agent — a lightweight service running on every Azure VM. The agent executes the script locally and returns output. The VM agent communicates *outbound* to Azure over port 443. No inbound ports need to be open, no public IP is required.

```
Your terminal
    │
    ▼  HTTPS (port 443 outbound from VM)
Azure Control Plane
    │
    ▼
VM Agent (running inside the VM)
    │
    ▼
Script executes locally, output returned
```

This is also how Azure Automation, Azure Policy guest configuration, and most enterprise VM management tooling works under the hood.

---

## The Technology

### Azure Virtual Machines

An Azure VM is an on-demand, scalable compute resource. You choose the OS image, size (CPU/RAM), and the network it connects to. The VM runs inside your VNet and gets a private IP from the subnet it's placed in.

**VM sizes:** For this lab we use `Standard_B1s` — 1 vCPU, 1GB RAM. It's the cheapest burstable size and falls within the Azure free tier (750 hrs/month each for Linux and Windows).

### NICs

A Network Interface Card (NIC) is the Azure resource that connects a VM to a subnet. You create the NIC separately and pass it to `az vm create` with `--nics`. This gives you explicit control over the NIC configuration — in this case, no public IP is attached.

When `az vm create` creates a NIC automatically (without `--nics`), it attaches a public IP by default. Creating the NIC manually first lets us avoid that.

---

## Step 1 — Create the NICs

```bash
# Web NIC — no public IP, NSG from subnet
az network nic create \
  --resource-group qcb-rg-lab \
  --name nic-web \
  --vnet-name qcb-vnet-lab \
  --subnet snet-web \
  --network-security-group nsg-web

# App NIC — no public IP, NSG from subnet
az network nic create \
  --resource-group qcb-rg-lab \
  --name nic-app \
  --vnet-name qcb-vnet-lab \
  --subnet snet-app \
  --network-security-group nsg-app
```

```powershell
$vnet = Get-AzVirtualNetwork -ResourceGroupName "qcb-rg-lab" -Name "qcb-vnet-lab"
$subnetWeb = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "snet-web"
$subnetApp = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "snet-app"
$nsgWeb = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-web"
$nsgApp = Get-AzNetworkSecurityGroup -ResourceGroupName "qcb-rg-lab" -Name "nsg-app"

New-AzNetworkInterface `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "nic-web" `
  -Location "eastus" `
  -Subnet $subnetWeb `
  -NetworkSecurityGroup $nsgWeb

New-AzNetworkInterface `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "nic-app" `
  -Location "eastus" `
  -Subnet $subnetApp `
  -NetworkSecurityGroup $nsgApp
```

> Notice there is no `-PublicIpAddress` parameter. This is intentional — both VMs are private-only.

---

## Step 2 — Create the Linux VM (Web Tier)

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

```powershell
$nicWeb = Get-AzNetworkInterface -ResourceGroupName "qcb-rg-lab" -Name "nic-web"
$cred = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "vm-web" `
  -Location "eastus" `
  -NetworkInterface $nicWeb `
  -Image "Ubuntu2204" `
  -Size "Standard_B1s" `
  -Credential $cred `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> `--generate-ssh-keys` creates an SSH key pair at `~/.ssh/id_rsa` if one doesn't exist. The key is stored but never used in this project — all access is via `run-command`.

---

## Step 3 — Create the Windows VM (App Tier)

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

```powershell
$nicApp = Get-AzNetworkInterface -ResourceGroupName "qcb-rg-lab" -Name "nic-app"
$cred = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "vm-app" `
  -Location "eastus" `
  -NetworkInterface $nicApp `
  -Image "Win2022Datacenter" `
  -Size "Standard_B1s" `
  -Credential $cred `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> In Phase 06, the password is moved to Key Vault. Hardcoding it in the script is a deliberate starting point that the identity phase then improves on.

---

## Step 4 — Install nginx on the Linux VM

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --command-id RunShellScript \
  --scripts "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html"
```

```powershell
Invoke-AzVMRunCommand `
  -ResourceGroupName "qcb-rg-lab" `
  -VMName "vm-web" `
  -CommandId "RunShellScript" `
  -ScriptString "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html"
```

---

## Step 5 — Verify via run-command

```bash
# Confirm nginx is serving
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --command-id RunShellScript \
  --scripts "curl -s http://localhost | head -3"

# Confirm Windows VM is running
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name vm-app \
  --command-id RunPowerShellScript \
  --scripts "hostname; (Get-ComputerInfo).WindowsProductName"
```

---

## Verification

```bash
# List both VMs and their power state
az vm list --resource-group qcb-rg-lab --show-details --output table

# Confirm NICs have private IPs only — no public IP column should be populated
az network nic list --resource-group qcb-rg-lab \
  --query "[].{NIC:name, PrivateIP:ipConfigurations[0].privateIPAddress, Subnet:ipConfigurations[0].subnet.id}" \
  --output table
```

---

## Gotchas & Lessons Learned

> *Updated as the phase is implemented.*

---

## Cost at This Phase

| Resource | Free tier |
|---|---|
| vm-web (Linux B1s) | ✅ 750 hrs/month |
| vm-app (Windows B1s) | ✅ 750 hrs/month |
| Standard HDD managed disks | ✅ Covered |
| NICs | ✅ Free |
| **Total public IP cost** | **$0 — none created** |

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)
