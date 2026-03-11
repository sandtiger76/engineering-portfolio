# Phase 03 — Compute

| | |
|---|---|
| **Phase** | 03 |
| **Topic** | Virtual Machines & Load Balancer |
| **Services** | Azure VMs, Load Balancer, Availability Sets, `az vm run-command` |
| **Est. Cost** | Low — `Standard_B1s` VMs, delete after each session |

---

## Navigation

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)

---

## What We're Building

Two virtual machines — a Linux VM in the web subnet and a Windows VM in the app subnet — plus a load balancer in front of the web VM. No public IPs are assigned to the VMs themselves. All VM access is handled via `az vm run-command`, which lets you run commands inside a VM through the Azure control plane without needing SSH or RDP.

---

## The Technology

### Azure Virtual Machines

An Azure VM is an on-demand, scalable compute resource. You choose the OS image, size (CPU/RAM), and the network it connects to. The VM runs inside your VNet and gets a private IP from the subnet it's placed in.

**VM sizes:** Azure has hundreds of VM sizes. For this lab we use `Standard_B1s` — 1 vCPU, 1GB RAM. It's the cheapest burstable size, adequate for testing, and costs very little per hour.

### No Public IPs on VMs

Normally you'd assign a public IP to a VM to SSH or RDP into it. We're deliberately avoiding this for two reasons:

1. **Cost** — public IPs have a small hourly charge
2. **Security** — exposing VMs directly to the internet is poor practice

Instead, we use `az vm run-command invoke` to run commands inside the VM through the Azure management plane. Azure handles the connection internally — no open ports, no public IP required.

### Load Balancer

A load balancer distributes incoming traffic across multiple backend VMs. In QCB's case, it sits in front of the web tier and provides a single public endpoint. The load balancer itself has a public IP — the VMs behind it do not.

**Azure Load Balancer (Basic SKU)** is free for lab use and sufficient for single-VM testing.

### Availability

In production, you'd use an Availability Set or Availability Zones to protect against hardware failures. We create an Availability Set here for the web tier to demonstrate the concept, even though we only have one VM.

---

## Step 1 — Create the Load Balancer Public IP

```bash
az network public-ip create \
  --resource-group qcb-rg-lab \
  --name qcb-pip-lb \
  --sku Basic \
  --allocation-method Static \
  --tags Project=QCBLab
```

```powershell
New-AzPublicIpAddress `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-pip-lb" `
  -Location "eastus" `
  -Sku "Basic" `
  -AllocationMethod "Static" `
  -Tag @{Project="QCBLab"}
```

---

## Step 2 — Create the Load Balancer

```bash
az network lb create \
  --resource-group qcb-rg-lab \
  --name qcb-lb-web \
  --sku Basic \
  --public-ip-address qcb-pip-lb \
  --frontend-ip-name qcb-lb-frontend \
  --backend-pool-name qcb-lb-backend \
  --tags Project=QCBLab
```

```powershell
$pip = Get-AzPublicIpAddress -ResourceGroupName "qcb-rg-lab" -Name "qcb-pip-lb"

$frontend = New-AzLoadBalancerFrontendIpConfig -Name "qcb-lb-frontend" -PublicIpAddress $pip
$backend = New-AzLoadBalancerBackendAddressPoolConfig -Name "qcb-lb-backend"

New-AzLoadBalancer `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-lb-web" `
  -Location "eastus" `
  -Sku "Basic" `
  -FrontendIpConfiguration $frontend `
  -BackendAddressPool $backend `
  -Tag @{Project="QCBLab"}
```

---

## Step 3 — Create an Availability Set

```bash
az vm availability-set create \
  --resource-group qcb-rg-lab \
  --name qcb-avset-web \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 2 \
  --tags Project=QCBLab
```

```powershell
New-AzAvailabilitySet `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-avset-web" `
  -Location "eastus" `
  -PlatformFaultDomainCount 2 `
  -PlatformUpdateDomainCount 2 `
  -Sku "Aligned" `
  -Tag @{Project="QCBLab"}
```

---

## Step 4 — Create the Linux VM (Web Tier)

```bash
az vm create \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --vnet-name qcb-vnet-main \
  --subnet qcb-snet-web \
  --availability-set qcb-avset-web \
  --public-ip-address "" \
  --nsg "" \
  --admin-username qcbadmin \
  --generate-ssh-keys \
  --tags Project=QCBLab Environment=Lab
```

> `--public-ip-address ""` explicitly sets no public IP.
> `--nsg ""` skips creating a new NSG — our subnet NSG handles traffic.

```powershell
$cred = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-vm-web-01" `
  -Location "eastus" `
  -Image "Ubuntu2204" `
  -Size "Standard_B1s" `
  -VirtualNetworkName "qcb-vnet-main" `
  -SubnetName "qcb-snet-web" `
  -Credential $cred `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> PowerShell will prompt for credentials. Use a strong password — Azure enforces complexity requirements.

---

## Step 5 — Create the Windows VM (App Tier)

```bash
az vm create \
  --resource-group qcb-rg-lab \
  --name qcb-vm-app-01 \
  --image Win2022Datacenter \
  --size Standard_B1s \
  --vnet-name qcb-vnet-main \
  --subnet qcb-snet-app \
  --public-ip-address "" \
  --nsg "" \
  --admin-username qcbadmin \
  --admin-password "<YourSecurePassword123!>" \
  --tags Project=QCBLab Environment=Lab
```

> Replace `<YourSecurePassword123!>` with a real password. In Phase 06 we move secrets to Key Vault.

```powershell
$cred = Get-Credential -UserName "qcbadmin" -Message "Enter VM admin password"

New-AzVM `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-vm-app-01" `
  -Location "eastus" `
  -Image "Win2022Datacenter" `
  -Size "Standard_B1s" `
  -VirtualNetworkName "qcb-vnet-main" `
  -SubnetName "qcb-snet-app" `
  -Credential $cred `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 6 — Test VM Access with run-command

This is how we verify VMs are working without SSH or RDP.

### Linux VM

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --command-id RunShellScript \
  --scripts "hostname && echo 'Web VM is running'"
```

### Windows VM

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-app-01 \
  --command-id RunPowerShellScript \
  --scripts "hostname; Write-Host 'App VM is running'"
```

### What This Does

`az vm run-command` sends a script to the VM agent (a lightweight service running on every Azure VM). The agent executes it locally and returns the output. No inbound port needs to be open — the VM agent communicates outbound to Azure over port 443.

---

## Step 7 — Install a Web Server on the Linux VM

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --command-id RunShellScript \
  --scripts "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl start nginx && sudo systemctl enable nginx && echo 'QCB Technologies Web Server' | sudo tee /var/www/html/index.html"
```

---

## Verification

```bash
# List VMs and their state
az vm list --resource-group qcb-rg-lab --output table

# Check VM power state
az vm get-instance-view --resource-group qcb-rg-lab --name qcb-vm-web-01 \
  --query instanceView.statuses[1] --output table

# Get load balancer public IP
az network public-ip show --resource-group qcb-rg-lab --name qcb-pip-lb \
  --query ipAddress --output tsv
```

---

## Cost Management — Stop VMs Between Sessions

VMs incur compute charges while running. Stop (deallocate) them when not in use:

```bash
az vm deallocate --resource-group qcb-rg-lab --name qcb-vm-web-01
az vm deallocate --resource-group qcb-rg-lab --name qcb-vm-app-01
```

```powershell
Stop-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01" -Force
Stop-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-app-01" -Force
```

> **Deallocate vs Stop:** Stopping a VM from inside the OS keeps it in a "Stopped" state — you still pay for compute. `az vm deallocate` releases the compute resources so you pay only for the disk.

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 02: Networking](02-networking.md) | [Back to README](../README.md) | [Next: Phase 04 — Storage →](04-storage.md)
