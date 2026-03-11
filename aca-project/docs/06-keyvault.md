# Phase 06 — Key Vault

| | |
|---|---|
| **Phase** | 06 |
| **Topic** | Key Vault |
| **AZ-104 Domain** | Monitor and Maintain Azure Resources |
| **Services** | Azure Key Vault, Secrets, Managed Identity Access |
| **Est. Cost** | Free tier — first 10,000 operations/month |

---

## Navigation

[← Phase 05: Identity](05-identity.md) | [Back to README](../README.md) | [Next: Phase 07 — Monitoring →](07-monitoring.md)

---

## What We're Building

An Azure Key Vault (`qcb-kv-lab`) using RBAC authorisation. We store the VM admin password as a secret, grant the current user rights to manage secrets, and grant `vm-web`'s managed identity the `Key Vault Secrets User` role so it can retrieve secrets at runtime — without any credentials stored on the VM.

This phase maps to the **Monitor and Maintain Azure Resources** domain of AZ-104, specifically: configuring Key Vault, managing secrets, and configuring access to Key Vault using RBAC.

---

## The Technology

### Azure Key Vault

Key Vault is a managed service for storing secrets, encryption keys, and certificates. It solves the most common security problem in cloud infrastructure: credentials ending up hardcoded in code, config files, or scripts where they get committed to git, logged, or accidentally exposed.

**Three types of objects:**

| Type | What it stores |
|---|---|
| Secrets | Passwords, connection strings, API keys |
| Keys | Cryptographic keys for encryption and signing |
| Certificates | TLS/SSL certificates with automatic renewal |

This project uses **Secrets** only.

### Access Models

Key Vault supports two access models:

| Model | Description |
|---|---|
| Vault access policy | Older model, permissions set per-identity directly on the vault |
| RBAC | Newer, recommended model — uses standard Azure role assignments |

This project uses **RBAC** (`--enable-rbac-authorization true`). It is consistent with how all other access is managed and is Microsoft's recommended approach for new deployments.

### Why Not Just Use Environment Variables?

Environment variables on a VM are visible to anyone with access to that VM, tend to get logged, and are easily accidentally exposed. Key Vault secrets are never exposed in logs, are accessed only by authorised identities, are versioned, and every access is audited.

---

## Step 1 — Create the Key Vault

### Azure Portal

1. Search for **Key vaults** and select it
2. Click **+ Create**
3. Fill in the **Basics** tab:
   - **Subscription:** QCB PAYG PersonalCloud
   - **Resource group:** `qcb-rg-lab`
   - **Key vault name:** `qcb-kv-lab`
   - **Region:** East US
   - **Pricing tier:** Standard
4. Click **Next: Access configuration**
   - **Permission model:** Azure role-based access control
5. Click **Next: Tags**:
   - Add `Project=QCBLab` and `Environment=Lab`
6. Click **Review + create**, then **Create**

### Azure CLI

```bash
az keyvault create \
  --resource-group qcb-rg-lab \
  --name qcb-kv-lab \
  --location eastus \
  --enable-rbac-authorization true \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzKeyVault `
  -ResourceGroupName "qcb-rg-lab" `
  -VaultName "qcb-kv-lab" `
  -Location "eastus" `
  -EnableRbacAuthorization $true `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 2 — Grant Your User Account Secrets Access

Before storing a secret, your user account needs the `Key Vault Secrets Officer` role on the vault.

### Azure Portal

1. Open **qcb-kv-lab → Access Control (IAM)**
2. Click **+ Add → Add role assignment**
3. Select **Key Vault Secrets Officer** → click **Next**
4. **Assign access to:** User, group, or service principal
5. Click **+ Select members** → search for your account → click **Select**
6. Click **Review + assign**

### Azure CLI

```bash
# Get Key Vault resource ID
KV_ID=$(az keyvault show \
  --name qcb-kv-lab \
  --resource-group qcb-rg-lab \
  --query id \
  --output tsv)

# Get current signed-in user object ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)

# Assign role
az role assignment create \
  --assignee "$USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_ID"
```

### PowerShell

```powershell
$kvId   = (Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab").ResourceId
$userId = (Get-AzADUser -SignedIn).Id

New-AzRoleAssignment `
  -ObjectId $userId `
  -RoleDefinitionName "Key Vault Secrets Officer" `
  -Scope $kvId
```

---

## Step 3 — Wait for Role Propagation

```bash
# Required — role assignments take time to propagate through Azure's auth layer
# Without this wait, az keyvault secret set returns a 403 even though the role was just assigned
echo "Waiting 30s for role propagation..."
sleep 30
```

> This `sleep 30` is in the deploy script deliberately. See Gotchas for why it is necessary.

---

## Step 4 — Store the VM Admin Password as a Secret

### Azure Portal

1. Open **qcb-kv-lab → Objects → Secrets**
2. Click **+ Generate/Import**
3. Fill in:
   - **Upload options:** Manual
   - **Name:** `vm-admin-password`
   - **Secret value:** `QCBLab2024!Secure`
4. Click **Create**

### Azure CLI

```bash
az keyvault secret set \
  --vault-name qcb-kv-lab \
  --name "vm-admin-password" \
  --value "QCBLab2024!Secure"
```

### PowerShell

```powershell
$secret = ConvertTo-SecureString "QCBLab2024!Secure" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName "qcb-kv-lab" -Name "vm-admin-password" -SecretValue $secret
```

---

## Step 5 — Grant vm-web Managed Identity Access to Secrets

### Azure Portal

1. Open **qcb-kv-lab → Access Control (IAM)**
2. Click **+ Add → Add role assignment**
3. Select **Key Vault Secrets User** → click **Next**
4. **Assign access to:** Managed identity
5. Click **+ Select members** → Managed identity: Virtual machine → select `vm-web`
6. Click **Select**, then **Review + assign**

### Azure CLI

```bash
# VM_IDENTITY was set in Phase 05 — re-retrieve if running standalone
VM_IDENTITY=$(az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query identity.principalId \
  --output tsv)

KV_ID=$(az keyvault show \
  --name qcb-kv-lab \
  --resource-group qcb-rg-lab \
  --query id \
  --output tsv)

az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID"
```

### PowerShell

```powershell
$vmIdentity = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Identity.PrincipalId
$kvId       = (Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab").ResourceId

New-AzRoleAssignment `
  -ObjectId $vmIdentity `
  -RoleDefinitionName "Key Vault Secrets User" `
  -Scope $kvId
```

---

## Verification

### Azure Portal

1. Open **qcb-kv-lab → Objects → Secrets** — confirm `vm-admin-password` exists
2. Open **qcb-kv-lab → Access Control (IAM) → Role assignments** — confirm both role assignments

### Azure CLI

```bash
az keyvault show \
  --name qcb-kv-lab \
  --resource-group qcb-rg-lab \
  --query "{Name:name, RBAC:properties.enableRbacAuthorization}" \
  --output table

az keyvault secret list \
  --vault-name qcb-kv-lab \
  --output table
```

### PowerShell

```powershell
Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab" | `
  Select-Object VaultName, EnableRbacAuthorization

Get-AzKeyVaultSecret -VaultName "qcb-kv-lab" | Format-Table Name, Enabled, Created
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. The 30-second `sleep` for role propagation is necessary and confirmed.** Without it, `az keyvault secret set` returns a `403 Forbidden` even though the `Key Vault Secrets Officer` role was just assigned. Azure's distributed authorisation layer takes time — typically 15–60 seconds — to propagate new role assignments. The deploy script waits 30 seconds, which was sufficient in testing.

**2. Key Vault soft-delete means the vault name is reserved for 90 days after deletion.** If you delete `qcb-kv-lab` without purging it, the name cannot be reused for 90 days. The teardown script (`destroy-all.sh`) handles this by explicitly deleting and then purging the vault before deleting the resource group.

**3. Key Vault names must be globally unique, 3–24 characters.** Alphanumeric and hyphens only. If `qcb-kv-lab` is taken in another subscription, append a suffix.

**4. RBAC mode vs vault access policies — they are mutually exclusive.** `--enable-rbac-authorization true` sets the vault to RBAC mode. If you attempt to use `az keyvault set-policy` on an RBAC-mode vault, the command succeeds but has no effect — access is controlled entirely through role assignments.

**5. `az ad signed-in-user show` retrieves your user object ID for role assignment.** This is the correct way to get your own object ID in a script context. Hard-coding object IDs in scripts is fragile — always retrieve them dynamically.

---

## Cost at This Phase

| Resource | Free Tier |
|---|---|
| qcb-kv-lab (Standard) | ✅ First 10,000 operations/month |
| Secret storage | ✅ Included in operation allowance |
| Role assignments | ✅ Free |

---

## Teardown — This Phase Only

Key Vault requires an explicit purge to release the name immediately:

```bash
az keyvault delete --name qcb-kv-lab --resource-group qcb-rg-lab
az keyvault purge --name qcb-kv-lab --location eastus
az group delete --name qcb-rg-lab --yes --no-wait
```

```powershell
Remove-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab" -Force
Remove-AzKeyVault -VaultName "qcb-kv-lab" -Location "eastus" -InRemovedState -Force
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 05: Identity](05-identity.md) | [Back to README](../README.md) | [Next: Phase 07 — Monitoring →](07-monitoring.md)
