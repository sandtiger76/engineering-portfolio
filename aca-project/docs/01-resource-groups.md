# Phase 01 — Resource Groups & Subscription Management

**AZ-104 Domain:** Manage Azure Identities and Governance &nbsp;|&nbsp; **Services:** Resource Groups, Tags, Subscriptions &nbsp;|&nbsp; **Est. Cost:** Free

---

## Navigation

[← Phase 00](00-prerequisites.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 02 →](02-networking.md)

---

## What We're Building

A single resource group (`qcb-rg-lab`) that contains every resource in this project. Tags are applied so resources are clearly identified, and the resource group acts as both a cost boundary and a teardown target — deleting it removes everything inside in a single operation.

---

## The Technology

### What is a Resource Group?

A resource group is a logical container for Azure resources. Every resource you create — a VM, a storage account, a virtual network — must live inside one. Think of it as a folder, but with capabilities that matter for real infrastructure work:

- **Lifecycle management:** Delete the resource group and everything inside is deleted. This is how teardown works in this project — one command removes the entire lab.
- **Access control:** RBAC permissions applied at the resource group level cascade to all resources inside.
- **Cost tracking:** Azure cost reports can be filtered by resource group, making it easy to see exactly what a project costs. This is why tags matter — they let you identify and report on resources across multiple resource groups or subscriptions.
- **Region assignment:** A resource group has a region, but resources inside do not have to be in the same region. The resource group region determines where the metadata is stored.

### Tags

Tags are key-value pairs attached to resources for organisation, cost tracking, and automation. This project applies `Project=QCBLab` and `Environment=Lab` to every resource. In the deploy script, tags are passed as a single variable: `TAGS="Project=QCBLab Environment=Lab"`.

---

## Step 1 — Create the Resource Group

### Azure Portal

1. Sign in to [portal.azure.com](https://portal.azure.com)
2. In the top search bar, type **Resource groups** and select it
3. Click **+ Create**
4. Fill in the **Basics** tab:
   - **Subscription:** your subscription
   - **Resource group:** `qcb-rg-lab`
   - **Region:** East US
5. Click **Next: Tags**
6. Add two tags:
   - Name: `Project` / Value: `QCBLab`
   - Name: `Environment` / Value: `Lab`
7. Click **Review + create**, then **Create**

### Azure CLI

```bash
az group create \
  --name qcb-rg-lab \
  --location eastus \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzResourceGroup `
  -Name "qcb-rg-lab" `
  -Location "eastus" `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 2 — Verify the Resource Group

### Azure Portal

1. Navigate to **Resource groups**
2. Click **qcb-rg-lab**
3. Confirm the Overview pane shows Location: East US, Provisioning state: Succeeded, and both tags

### Azure CLI

```bash
az group show \
  --name qcb-rg-lab \
  --query "{Name:name, Location:location, State:properties.provisioningState}" \
  --output table
```

Expected output:
```
Name        Location    State
----------  ----------  ---------
qcb-rg-lab  eastus      Succeeded
```

### PowerShell

```powershell
Get-AzResourceGroup -Name "qcb-rg-lab" | Format-List
```

---

## Step 3 — View and Update Tags

### Azure Portal

1. Open **qcb-rg-lab**
2. In the left menu, click **Tags**
3. Add, edit, or remove tags as needed
4. Click **Apply**

### Azure CLI

```bash
# View current tags
az group show --name qcb-rg-lab --query tags

# Add or update a single tag — additive, existing tags preserved
az group update \
  --name qcb-rg-lab \
  --set tags.CostCentre=IT
```

### PowerShell

```powershell
# View current tags
(Get-AzResourceGroup -Name "qcb-rg-lab").Tags

# Add or update a tag safely — read, merge, write back
$rg = Get-AzResourceGroup -Name "qcb-rg-lab"
$rg.Tags["CostCentre"] = "IT"
Set-AzResourceGroup -Name "qcb-rg-lab" -Tag $rg.Tags
```

---

## Step 4 — Check Subscription Context

### Azure CLI

```bash
az account show --query "{Name:name, ID:id, State:state}" --output table
```

### PowerShell

```powershell
Get-AzContext | Select-Object Name, Subscription, Tenant
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. `az group create` is idempotent.** Running it against an existing group with the same location returns `Succeeded` without error. Tags on re-run are merged, not replaced. Safe in automation scripts without a check-then-create pattern.

**2. Tag handling differs significantly between CLI and PowerShell.**

| Behaviour | Azure CLI | PowerShell |
|---|---|---|
| Add a single tag | `--set tags.Key=Value` — additive, existing tags preserved | `Set-AzResourceGroup -Tag @{Key="Value"}` — **replaces all tags** |
| Safe additive update | Default behaviour | Must read → merge → write back manually |

In PowerShell, always read existing tags first, modify the hashtable, then write it back — otherwise you silently wipe all other tags.

**3. Use `--set tags.Key=Value` not `--tags` for additive CLI updates.** The `--tags` flag on `az group update` replaces all tags. The `--set tags.Key=Value` syntax adds or updates a single tag without touching others.

**4. `NetworkWatcherRG` always appears in `az group list`.** Azure creates this automatically when Network Watcher is enabled for a region. Leave it alone.

**5. Tags are returned alphabetically sorted.** Regardless of the order you set them, Azure returns tag keys sorted alphabetically. Cosmetic only — no functional impact.

---

## Navigation

[← Phase 00](00-prerequisites.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 02 →](02-networking.md)
