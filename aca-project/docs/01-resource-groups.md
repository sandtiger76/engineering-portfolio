# Phase 01 — Resource Groups & Subscription Management

| | |
|---|---|
| **Phase** | 01 |
| **Topic** | Resource Groups & Subscription Management |
| **AZ-104 Domain** | Manage Azure Identities and Governance |
| **Services** | Resource Groups, Tags, Subscriptions |
| **Est. Cost** | None — resource groups are free |

---

## Navigation

[← Phase 00: Prerequisites](00-prerequisites.md) | [Back to README](../README.md) | [Next: Phase 02 — Networking →](02-networking.md)

---

## What We're Building

A single resource group (`qcb-rg-lab`) that contains every resource in this project. We apply tags so resources are clearly identified, and use the resource group as both a cost boundary and a teardown target — deleting it removes everything inside instantly.

This phase maps to the **Manage Azure Identities and Governance** domain of AZ-104, specifically: managing subscriptions, managing resource groups, and applying resource tags.

---

## The Technology

### What is a Resource Group?

A resource group is a logical container for Azure resources. Every resource you create — a VM, a storage account, a virtual network — must live inside one. It behaves like a folder, but with additional capabilities:

- **Lifecycle management:** Delete the resource group and everything inside is deleted. This is how teardown works — one command removes the entire lab.
- **Access control:** RBAC permissions applied at the resource group level cascade to all resources inside.
- **Billing boundary:** Azure cost reports can be filtered by resource group, making it easy to see exactly what a project costs.
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
   - **Subscription:** QCB PAYG PersonalCloud
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
3. Confirm the Overview pane shows:
   - Location: East US
   - Provisioning state: Succeeded
   - Tags: Project=QCBLab, Environment=Lab

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

### Azure Portal

1. Click your account name in the top-right corner
2. The active subscription is shown in the dropdown

### Azure CLI

```bash
az account show --query "{Name:name, ID:id, State:state}" --output table
```

### PowerShell

```powershell
Get-AzContext | Select-Object Name, Subscription, Tenant
```

---

## Verification Checklist

- [ ] `az group show --name qcb-rg-lab` returns `Succeeded`
- [ ] Tags visible: `Project=QCBLab`, `Environment=Lab`
- [ ] Subscription shows `QCB PAYG PersonalCloud`

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. `az group create` is idempotent.** Running it against an existing group with the same location returns `Succeeded` without error. Tags on re-run are merged, not replaced. Safe in automation scripts without a check-then-create pattern. Confirmed on second run after exit code 3 in Phase 04.

**2. Tag handling differs significantly between CLI and PowerShell.**

| Behaviour | Azure CLI | PowerShell |
|---|---|---|
| Add a single tag | `--set tags.Key=Value` — additive, existing tags preserved | `Set-AzResourceGroup -Tag @{Key="Value"}` — **replaces all tags** |
| Safe additive update | Default behaviour | Must read → merge → write back manually |

In PowerShell, always read the existing tags first, modify the hashtable, then write it back — otherwise you silently wipe all other tags.

**3. Use `--set tags.Key=Value` not `--tags` for additive CLI updates.** The `--tags` flag on `az group update` replaces all tags. The `--set tags.Key=Value` syntax adds or updates a single tag without touching others.

**4. `NetworkWatcherRG` always appears in `az group list`.** Azure creates this automatically when Network Watcher is enabled for a region. Leave it alone — it does not affect the lab and should not be deleted.

**5. Tags are returned alphabetically sorted.** Regardless of the order you set them, Azure returns tag keys sorted alphabetically in JSON output. Cosmetic only — no functional impact.

---

## Cost at This Phase

**Zero** — resource groups have no cost.

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

[← Phase 00: Prerequisites](00-prerequisites.md) | [Back to README](../README.md) | [Next: Phase 02 — Networking →](02-networking.md)
