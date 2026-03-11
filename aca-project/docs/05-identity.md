# Phase 05 — Identity & Access

| | |
|---|---|
| **Phase** | 05 |
| **Topic** | Identity & Access Management |
| **AZ-104 Domain** | Manage Azure Identities and Governance |
| **Services** | Managed Identities, RBAC |
| **Est. Cost** | None — RBAC and managed identities are free |

---

## Navigation

[← Phase 04: Storage](04-storage.md) | [Back to README](../README.md) | [Next: Phase 06 — Key Vault →](06-keyvault.md)

---

## What We're Building

A system-assigned managed identity on `vm-web`, and a role assignment that grants it `Storage Blob Data Reader` on `stqcblab`. This allows the web VM to read blobs from storage using its identity — no credentials stored anywhere.

This phase maps to the **Manage Azure Identities and Governance** domain of AZ-104, specifically: configuring managed identities, assigning RBAC roles at resource scope, understanding the difference between system-assigned and user-assigned identities, and retrieving principal IDs for role assignment.

---

## The Technology

### Managed Identity

A managed identity is an identity in Entra ID (Azure Active Directory) that Azure manages automatically — no passwords, no keys, no rotation required. You assign it to a resource (like a VM), and that resource can request access tokens to authenticate to other Azure services.

There are two types:

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

In this phase, `vm-web`'s managed identity is assigned `Storage Blob Data Reader` scoped to the `stqcblab` storage account resource — the narrowest possible scope.

---

## Step 1 — Enable Managed Identity on vm-web

### Azure Portal

1. Open **vm-web**
2. In the left menu, click **Security → Identity**
3. Under the **System assigned** tab, set **Status** to **On**
4. Click **Save**
5. Click **Yes** on the confirmation dialog
6. Note the **Object (principal) ID** — you will need it for role assignment

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

### Azure Portal

The Object (principal) ID is shown on the **Identity** blade after enabling the managed identity.

### Azure CLI

```bash
az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query identity.principalId \
  --output tsv
```

From the lab run, this returned: `ce4e1613-36a7-44f5-91c8-1372f3892186`

### PowerShell

```powershell
(Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Identity.PrincipalId
```

---

## Step 3 — Assign Storage Blob Data Reader to the Identity

### Azure Portal

1. Open **stqcblab**
2. In the left menu, click **Access Control (IAM)**
3. Click **+ Add → Add role assignment**
4. Select role: **Storage Blob Data Reader** → click **Next**
5. **Assign access to:** Managed identity
6. Click **+ Select members**:
   - **Managed identity:** Virtual machine
   - Select **vm-web**
7. Click **Select**, then **Review + assign**

### Azure CLI

```bash
# Get the storage account resource ID
STORAGE_ID=$(az storage account show \
  --name stqcblab \
  --resource-group qcb-rg-lab \
  --query id \
  --output tsv)

# Get the VM managed identity principal ID
VM_IDENTITY=$(az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query identity.principalId \
  --output tsv)

# Assign the role
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

### Azure Portal

1. Open **stqcblab → Access Control (IAM) → Role assignments**
2. Filter by **Storage Blob Data Reader** — confirm `vm-web` appears

### Azure CLI

```bash
# Show identity on the VM
az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query "identity" \
  --output json

# List role assignments for the identity
# Note: --all flag is required to return resource-scoped assignments
az role assignment list \
  --assignee $(az vm show --resource-group qcb-rg-lab --name vm-web \
    --query identity.principalId --output tsv) \
  --all \
  --output table
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

**2. The principal ID in role assignment output differs from the VM's `identity.principalId`.** The role assignment record stores an internal object ID that may differ from the `principalId` returned by `az vm show`. This is a known display artifact in Azure CLI. The assignments are functionally correct — verify by checking the scope and role definition name, not just the principal ID column.

**3. Role propagation takes 1–2 minutes.** After creating a role assignment, there is a delay before it takes effect across Azure's distributed authorization layer. This is why Phase 06 includes a `sleep 30` before attempting to use the Key Vault role — the same principle applies here.

**4. System-assigned identity is deleted when the VM is deleted.** If you delete `vm-web` and recreate it, a new principal ID is generated. Any role assignments made against the old principal ID become orphaned and must be recreated.

**5. Transient ARM error on first run affected Phase 05.** The first script run exited with code 3 in Phase 04, but the `az vm identity assign` command from Phase 05 had already executed successfully before the failure. When the script was re-run, the idempotent identity assign command succeeded again without issue.

---

## Cost at This Phase

**Zero** — managed identities and RBAC role assignments are free.

---

## Teardown — This Phase Only

Role assignments are automatically removed when the resource group is deleted.

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

```powershell
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 04: Storage](04-storage.md) | [Back to README](../README.md) | [Next: Phase 06 — Key Vault →](06-keyvault.md)
