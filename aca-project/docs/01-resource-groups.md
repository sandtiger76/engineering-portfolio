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

> *This section is updated as the phase is implemented.*

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
