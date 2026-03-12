# Phase 05 — Identity & Access

**AZ-104 Domain:** Manage Azure Identities and Governance &nbsp;|&nbsp; **Services:** Managed Identities, RBAC &nbsp;|&nbsp; **Est. Cost:** Free

---

## Navigation

[← Phase 04](04-storage.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 06 →](06-keyvault.md)

---

## What We're Building

A system-assigned managed identity on `vm-web`, and a role assignment that grants it `Storage Blob Data Reader` on `stqcblab`. This allows the web VM to read blobs from storage using its identity — no credentials stored anywhere on the VM.

---

## The Technology

### Managed Identity

A managed identity is an identity in Entra ID (Azure Active Directory) that Azure manages automatically — no passwords, no keys, no rotation required. You assign it to a resource like a VM, and that resource can request access tokens to authenticate to other Azure services.

| Type | Behaviour |
|---|---|
| System-assigned | Tied to one resource. Created and deleted with the resource. Used in this project. |
| User-assigned | Independent resource. Can be assigned to multiple VMs or services. |

This project uses **system-assigned** — it is enabled on `vm-web` and Azure creates a corresponding service principal in Entra ID automatically.

### RBAC

Role-Based Access Control (RBAC) is how Azure controls who can do what to which resources. An assignment has three parts:

- **Security principal** — who (a user, group, service principal, or managed identity)
- **Role definition** — what (a set of permissions)
- **Scope** — where (management group, subscription, resource group, or individual resource)

In this phase, `vm-web`'s managed identity is assigned `Storage Blob Data Reader` scoped to the `stqcblab` storage account — the narrowest possible scope.

---

## Step 1 — Enable Managed Identity on vm-web

### Azure Portal

1. Open **vm-web → Security → Identity**
2. Under the **System assigned** tab, set **Status** to **On**
3. Click **Save**, then **Yes** on the confirmation dialog
4. Note the **Object (principal) ID** — you will need it for role assignment

### Azure CLI

```bash
az vm identity assign \
  --resource-group qcb-rg-lab \
  --name vm-web
```

### PowerShell

```powershell
$vm = Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web"
Update-AzVM -ResourceGroupName "qcb-rg-lab" -VM $vm -IdentityType SystemAssigned
```

---

## Step 2 — Retrieve the Principal ID

### Azure CLI

```bash
az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query identity.principalId \
  --output tsv
```

### PowerShell

```powershell
(Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Identity.PrincipalId
```

---

## Step 3 — Assign Storage Blob Data Reader to the Identity

### Azure Portal

1. Open **stqcblab → Access Control (IAM) → + Add → Add role assignment**
2. Role: **Storage Blob Data Reader** → Next
3. Assign access to: Managed identity → **+ Select members** → Virtual machine → `vm-web`
4. Click **Select**, then **Review + assign**

### Azure CLI

```bash
STORAGE_ID=$(az storage account show \
  --name stqcblab --resource-group qcb-rg-lab \
  --query id --output tsv)

VM_IDENTITY=$(az vm show \
  --resource-group qcb-rg-lab --name vm-web \
  --query identity.principalId --output tsv)

az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Storage Blob Data Reader" \
  --scope "$STORAGE_ID"
```

### PowerShell

```powershell
$storageId  = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "stqcblab").Id
$vmIdentity = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Identity.PrincipalId

New-AzRoleAssignment `
  -ObjectId $vmIdentity `
  -RoleDefinitionName "Storage Blob Data Reader" `
  -Scope $storageId
```

---

## Verification

### Azure CLI

```bash
az vm show \
  --resource-group qcb-rg-lab --name vm-web \
  --query "identity" --output json

# Note: --all flag is required to return resource-scoped assignments
az role assignment list \
  --assignee $(az vm show --resource-group qcb-rg-lab --name vm-web \
    --query identity.principalId --output tsv) \
  --all --output table
```

### PowerShell

```powershell
$vmIdentity = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Identity.PrincipalId

Get-AzRoleAssignment -ObjectId $vmIdentity | `
  Format-Table RoleDefinitionName, Scope
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. `az role assignment list` without `--all` returns empty results even when assignments exist.** The default scope filter only checks subscription-level assignments. Resource-scoped assignments (like this one, scoped to a storage account) are invisible without `--all`. Always use `--all` when verifying role assignments in this project.

**2. The principal ID in role assignment output may differ from the VM's `identity.principalId`.** The role assignment record stores an internal object ID that can differ from the `principalId` returned by `az vm show`. This is a known display artifact. The assignments are functionally correct — verify by checking the scope and role definition name, not just the principal ID column.

**3. Role propagation takes 1–2 minutes.** After creating a role assignment, there is a delay before it takes effect across Azure's distributed authorisation layer. This is why Phase 06 includes a `sleep 30` before attempting to use the Key Vault role — the same principle applies here.

**4. System-assigned identity is deleted when the VM is deleted.** If you delete `vm-web` and recreate it, a new principal ID is generated. Any role assignments made against the old principal ID become orphaned and must be recreated.

---

## Navigation

[← Phase 04](04-storage.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 06 →](06-keyvault.md)
