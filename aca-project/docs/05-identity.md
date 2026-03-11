# Phase 05 — Identity & Access

| | |
|---|---|
| **Phase** | 05 |
| **Topic** | Identity & Access Management |
| **Services** | RBAC, Managed Identities, Entra ID |
| **Est. Cost** | None — RBAC and managed identities are free |

---

## Navigation

[← Phase 04: Storage](04-storage.md) | [Back to README](../README.md) | [Next: Phase 06 — Key Vault →](06-keyvault.md)

---

## What We're Building

Role-based access control (RBAC) assignments on QCB's resource group, and a system-assigned managed identity on the web VM so it can authenticate to other Azure services without any credentials stored anywhere.

---

## The Technology

### Entra ID (formerly Azure Active Directory)

Entra ID is Azure's identity platform. Every user, service principal, and managed identity that interacts with Azure is authenticated through Entra ID. It's the foundation that RBAC sits on top of.

You don't manage Entra ID directly in this project — it's the background system that makes identity work.

### Role-Based Access Control (RBAC)

RBAC is how Azure controls who can do what to which resources. It has three components:

- **Security principal** — who: a user, group, service principal, or managed identity
- **Role definition** — what: a set of permissions (e.g. "Reader" = read-only, "Contributor" = read/write, "Owner" = full control)
- **Scope** — where: management group, subscription, resource group, or individual resource

When you assign a role, you're saying: *this principal can do these actions at this scope.*

**Built-in roles you'll use most:**

| Role | Permissions |
|------|------------|
| Owner | Full control, including assigning roles to others |
| Contributor | Create and manage resources, cannot assign roles |
| Reader | View resources only |
| Storage Blob Data Contributor | Read/write/delete blob data |
| Key Vault Secrets User | Read secrets from Key Vault |

### Managed Identity

A managed identity is an identity in Entra ID that is automatically managed by Azure — you don't create passwords or rotate keys. You assign it to a resource (like a VM), and that resource can then authenticate to other Azure services using that identity.

There are two types:

- **System-assigned:** tied to a single resource, deleted when the resource is deleted
- **User-assigned:** independent resource, can be assigned to multiple VMs or services

**Why this matters:** Instead of storing a password or connection string in your VM to access a storage account, the VM authenticates using its managed identity. No credentials, no secrets to rotate, no accidental exposure in code.

---

## Step 1 — View Current Role Assignments

```bash
az role assignment list \
  --resource-group qcb-rg-lab \
  --output table
```

```powershell
Get-AzRoleAssignment -ResourceGroupName "qcb-rg-lab" | Format-Table DisplayName, RoleDefinitionName, Scope
```

---

## Step 2 — Assign a Reader Role to a User

This demonstrates how you'd give a colleague read-only access to the resource group.

```bash
# Get your own user object ID first
az ad signed-in-user show --query id --output tsv

# Assign Reader role (replace <object-id> with the output above)
az role assignment create \
  --assignee "<object-id>" \
  --role "Reader" \
  --scope "/subscriptions/<sub-id>/resourceGroups/qcb-rg-lab"
```

```powershell
$userId = (Get-AzADUser -SignedIn).Id

New-AzRoleAssignment `
  -ObjectId $userId `
  -RoleDefinitionName "Reader" `
  -ResourceGroupName "qcb-rg-lab"
```

> This is demonstrating the pattern. In practice you'd assign this to a colleague's object ID, not your own.

---

## Step 3 — Enable Managed Identity on the Web VM

```bash
az vm identity assign \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01
```

```powershell
$vm = Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01"
Update-AzVM -ResourceGroupName "qcb-rg-lab" -VM $vm -IdentityType SystemAssigned
```

### What This Does

Enables a system-assigned managed identity on the VM. Azure creates an identity in Entra ID and associates it with the VM. The VM can now request tokens from the Azure Instance Metadata Service (IMDS) endpoint — a local API available inside every VM at `http://169.254.169.254`.

---

## Step 4 — Get the Managed Identity's Object ID

```bash
az vm show \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --query identity.principalId \
  --output tsv
```

```powershell
(Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01").Identity.PrincipalId
```

Save this — you'll use it in Phase 06 to grant Key Vault access to the VM.

---

## Step 5 — Assign Storage Blob Reader to the Managed Identity

This allows the web VM to read blobs from the storage account using its identity — no keys required.

```bash
# Get the storage account resource ID
STORAGE_ID=$(az storage account show --name qcbstorage01 --resource-group qcb-rg-lab --query id --output tsv)

# Get the VM's managed identity principal ID
VM_IDENTITY=$(az vm show --resource-group qcb-rg-lab --name qcb-vm-web-01 --query identity.principalId --output tsv)

# Assign role
az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Storage Blob Data Reader" \
  --scope "$STORAGE_ID"
```

```powershell
$storageId = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "qcbstorage01").Id
$vmIdentity = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01").Identity.PrincipalId

New-AzRoleAssignment `
  -ObjectId $vmIdentity `
  -RoleDefinitionName "Storage Blob Data Reader" `
  -Scope $storageId
```

---

## Step 6 — Verify the Assignment

```bash
az role assignment list \
  --assignee "$VM_IDENTITY" \
  --output table
```

```powershell
Get-AzRoleAssignment -ObjectId $vmIdentity | Format-Table RoleDefinitionName, Scope
```

---

## Verification

```bash
# Confirm managed identity is enabled
az vm show --resource-group qcb-rg-lab --name qcb-vm-web-01 --query identity --output json

# List all role assignments on the resource group
az role assignment list --resource-group qcb-rg-lab --output table
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

Role assignments are automatically removed when you delete the resource group. No separate cleanup needed.

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 04: Storage](04-storage.md) | [Back to README](../README.md) | [Next: Phase 06 — Key Vault →](06-keyvault.md)
