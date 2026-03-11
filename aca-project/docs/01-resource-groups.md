# Phase 01 — Resource Groups & Subscription Management

| | |
|---|---|
| **Phase** | 01 |
| **Topic** | Resource Groups & Subscription Management |
| **Services** | Resource Groups, Tags, Azure Policy (basic) |
| **Est. Cost** | None — resource groups are free |

---

## Navigation

[← Phase 00: Prerequisites](00-prerequisites.md) | [Back to README](../README.md) | [Next: Phase 02 — Networking →](02-networking.md)

---

## What We're Building

A single resource group (`qcb-rg-lab`) that will contain every resource in this project. We'll apply tags to it so resources are clearly identified, and explore how Azure uses resource groups as a management and billing boundary.

---

## The Technology

### What is a Resource Group?

A resource group is a logical container for Azure resources. Every resource you create — a VM, a storage account, a virtual network — must live inside a resource group. You can think of it like a folder, but with more capabilities:

- **Lifecycle management:** Delete the resource group and everything inside it is deleted. This is how we do our teardown at the end of each session.
- **Access control:** RBAC permissions can be applied at the resource group level, cascading down to all resources inside.
- **Billing boundary:** You can filter your Azure cost reports by resource group, making it easy to see exactly what a project costs.
- **Region assignment:** A resource group has a region, but resources inside it don't have to be in the same region. The resource group region just determines where the metadata is stored.

### Why a Single Resource Group for This Project?

In production, you'd often separate resource groups by environment (dev/test/prod) or by workload. For this lab, a single resource group keeps things simple and makes teardown a single command — delete the group and everything is gone.

### Tags

Tags are key-value pairs you attach to resources for organisation, cost tracking, and automation. They're optional but a professional habit — in real environments, untagged resources are a management nightmare.

---

## Step 1 — Create the Resource Group

### Azure CLI

```bash
az group create \
  --name qcb-rg-lab \
  --location eastus \
  --tags Project=QCBLab Environment=Lab Owner=QCBTechnologies
```

### PowerShell

```powershell
New-AzResourceGroup `
  -Name "qcb-rg-lab" `
  -Location "eastus" `
  -Tag @{Project="QCBLab"; Environment="Lab"; Owner="QCBTechnologies"}
```

### What This Does

Creates a resource group called `qcb-rg-lab` in `eastus` with three tags attached. The tags don't do anything functionally — they're metadata that helps with filtering, cost reports, and automation later.

---

## Step 2 — Verify the Resource Group Exists

### Azure CLI

```bash
az group show --name qcb-rg-lab --output table
```

### PowerShell

```powershell
Get-AzResourceGroup -Name "qcb-rg-lab" | Format-List
```

---

## Step 3 — List All Resource Groups

Useful to confirm your subscription state at any point:

### Azure CLI

```bash
az group list --output table
```

### PowerShell

```powershell
Get-AzResourceGroup | Format-Table ResourceGroupName, Location, ProvisioningState
```

---

## Step 4 — View and Update Tags

Tags can be added, changed, or removed at any time without affecting the resources inside.

### View current tags

```bash
az group show --name qcb-rg-lab --query tags
```

```powershell
(Get-AzResourceGroup -Name "qcb-rg-lab").Tags
```

### Add or update a tag

```bash
az group update \
  --name qcb-rg-lab \
  --set tags.CostCentre=IT
```

```powershell
$rg = Get-AzResourceGroup -Name "qcb-rg-lab"
$rg.Tags["CostCentre"] = "IT"
Set-AzResourceGroup -Name "qcb-rg-lab" -Tag $rg.Tags
```

> **Gotcha:** In PowerShell, `Set-AzResourceGroup -Tag` replaces all tags — not just the one you changed. Always read the existing tags first, modify the object, then write it back (as shown above).

---

## Step 5 — Understand Subscription Context

Before creating anything, it's worth confirming you're in the right subscription. This is especially important if you manage multiple Azure accounts.

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
- [ ] Tags are visible: `Project`, `Environment`, `Owner`
- [ ] Subscription context is correct

---

## Gotchas & Lessons Learned

> *Updated: 2026-03-11*

**1. `az group create` is idempotent.** Running it on an already-existing group with the same location returns `Succeeded` rather than an error. Tags on re-run are merged, not replaced. Safe to use in automation scripts without a check-then-create pattern.

**2. Tag handling differs significantly between CLI and PowerShell.** This is one of the most important behavioural differences between the two tools:

| Behaviour | Azure CLI | PowerShell |
|---|---|---|
| Add a single tag | `az group update --set tags.Key=Value` — additive, existing tags preserved | `Set-AzResourceGroup -Tag @{Key="Value"}` — **replaces all tags** |
| Safe additive update | Default behaviour | Must read → merge → write back manually |

In PowerShell, always read the existing tags first, modify the hashtable, then write it back — otherwise you will silently wipe all other tags.

**3. Use `--set tags.Key=Value` not `--tags` for additive CLI updates.** The `--tags` flag on `az group update` replaces all tags. The `--set tags.Key=Value` syntax adds or updates a single tag without touching others.

**4. `az configure --defaults` succeeds silently.** There is no confirmation output. Verify it took effect with `az configure --list-defaults` or by checking `~/.azure/config`.

**5. Tags are returned alphabetically sorted by Azure.** Regardless of the order you set them, Azure returns tag keys sorted alphabetically in JSON output. This is cosmetic only — it has no functional impact.

**6. NetworkWatcherRG will always appear in `az group list`.** It is Azure-managed, tied to Network Watcher being enabled for the region. Leave it alone — it does not affect the lab.

---

## Teardown — This Phase Only

To remove just the resource group (and everything inside it):

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

```powershell
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob
```

> `--no-wait` / `-AsJob` returns immediately and runs the deletion in the background. Use `az group list` to confirm it's gone.

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Cost at This Phase

**Zero** — resource groups have no cost.

---

## Navigation

[← Phase 00: Prerequisites](00-prerequisites.md) | [Back to README](../README.md) | [Next: Phase 02 — Networking →](02-networking.md)
