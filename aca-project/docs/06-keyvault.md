# Phase 06 — Key Vault

| | |
|---|---|
| **Phase** | 06 |
| **Topic** | Key Vault |
| **Services** | Azure Key Vault, Secrets, Managed Identity Access |
| **Est. Cost** | Very low — first 10,000 operations/month free |

---

## Navigation

[← Phase 05: Identity](05-identity.md) | [Back to README](../README.md) | [Next: Phase 07 — Monitoring →](07-monitoring.md)

---

## What We're Building

An Azure Key Vault (`qcb-kv-lab`) to store secrets — specifically the VM admin password that we hardcoded in Phase 03. We'll then grant the web VM's managed identity permission to read secrets from the vault, so applications running on that VM can retrieve credentials at runtime without any secrets stored in code or config files.

---

## The Technology

### Azure Key Vault

Key Vault is a managed service for storing and controlling access to secrets, encryption keys, and certificates. It solves one of the most common security problems: credentials and secrets ending up hardcoded in code, config files, scripts, or environment variables — where they get committed to git, emailed around, or left on servers.

Key Vault centralises secrets behind Entra ID authentication and RBAC. Nothing accesses a secret without being explicitly authorised.

**Three types of objects Key Vault manages:**

| Type | What it stores |
|------|---------------|
| Secrets | Passwords, connection strings, API keys |
| Keys | Cryptographic keys for encryption/signing |
| Certificates | TLS/SSL certificates with automatic renewal |

For this project we focus on **Secrets**.

### Access Models

Key Vault has two access models:

- **Vault access policy** — the older model, permissions set per-identity on the vault itself
- **RBAC** — the newer, recommended model, uses standard Azure role assignments

We use **RBAC** — it's consistent with the rest of the project and is Microsoft's recommended approach for new deployments.

### Why Not Just Use Environment Variables?

Environment variables on a VM are visible to anyone with access to that VM — and they tend to get logged, exported, or accidentally exposed. Key Vault secrets are:

- Never exposed in logs
- Accessed only by authorised identities
- Versioned — old versions are retained
- Audited — every access is logged

---

## Step 1 — Create the Key Vault

```bash
az keyvault create \
  --resource-group qcb-rg-lab \
  --name qcb-kv-lab \
  --location eastus \
  --enable-rbac-authorization true \
  --tags Project=QCBLab Environment=Lab
```

```powershell
New-AzKeyVault `
  -ResourceGroupName "qcb-rg-lab" `
  -VaultName "qcb-kv-lab" `
  -Location "eastus" `
  -EnableRbacAuthorization $true `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> `--enable-rbac-authorization true` uses the RBAC model instead of vault access policies.

> **Gotcha:** Key Vault names must be globally unique, 3–24 characters. If `qcb-kv-lab` is taken, add a number suffix.

---

## Step 2 — Grant Yourself Secrets Access

Before you can add secrets, your user account needs the `Key Vault Secrets Officer` role:

```bash
# Get your user object ID
USER_ID=$(az ad signed-in-user show --query id --output tsv)

# Get Key Vault resource ID
KV_ID=$(az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab --query id --output tsv)

# Assign role
az role assignment create \
  --assignee "$USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_ID"
```

```powershell
$userId = (Get-AzADUser -SignedIn).Id
$kvId = (Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab").ResourceId

New-AzRoleAssignment `
  -ObjectId $userId `
  -RoleDefinitionName "Key Vault Secrets Officer" `
  -Scope $kvId
```

> **Gotcha:** Role propagation takes 1–2 minutes. If you immediately try to add a secret and get a `403 Forbidden`, wait and retry.

---

## Step 3 — Store the VM Admin Password as a Secret

```bash
az keyvault secret set \
  --vault-name qcb-kv-lab \
  --name "vm-admin-password" \
  --value "<YourVMPassword>"
```

```powershell
$secret = ConvertTo-SecureString "<YourVMPassword>" -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName "qcb-kv-lab" -Name "vm-admin-password" -SecretValue $secret
```

---

## Step 4 — Grant the Web VM Managed Identity Access to Secrets

```bash
# Get VM managed identity principal ID
VM_IDENTITY=$(az vm show --resource-group qcb-rg-lab --name qcb-vm-web-01 --query identity.principalId --output tsv)

# Get Key Vault resource ID
KV_ID=$(az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab --query id --output tsv)

# Assign Key Vault Secrets User role
az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID"
```

```powershell
$vmIdentity = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01").Identity.PrincipalId
$kvId = (Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab").ResourceId

New-AzRoleAssignment `
  -ObjectId $vmIdentity `
  -RoleDefinitionName "Key Vault Secrets User" `
  -Scope $kvId
```

---

## Step 5 — Test Secret Retrieval from the VM

Using `run-command`, we simulate what an application running on the VM would do — retrieve the secret using the VM's managed identity:

```bash
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --command-id RunShellScript \
  --scripts "
    TOKEN=\$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H 'Metadata:true' | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"access_token\"])')
    SECRET=\$(curl -s 'https://qcb-kv-lab.vault.azure.net/secrets/vm-admin-password?api-version=7.0' -H \"Authorization: Bearer \$TOKEN\" | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"value\"])')
    echo \"Secret retrieved successfully: \${#SECRET} characters\"
  "
```

### What This Does

The script runs inside the VM and:
1. Calls the IMDS endpoint (local to every Azure VM) to get an access token for Key Vault
2. Uses that token to call the Key Vault REST API
3. Prints the secret length (not the value) to confirm retrieval worked

No credentials stored anywhere. The VM authenticates using its managed identity automatically.

---

## Verification

```bash
# List secrets (names only, not values)
az keyvault secret list --vault-name qcb-kv-lab --output table

# Show secret metadata (not value)
az keyvault secret show --vault-name qcb-kv-lab --name vm-admin-password --query "{Name:name, Created:attributes.created, Enabled:attributes.enabled}" --output table

# List role assignments on the vault
az role assignment list --scope $(az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab --query id --output tsv) --output table
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

Key Vault has soft-delete enabled by default — deleted vaults are retained for 90 days and the name cannot be reused during that period. To permanently delete (purge):

```bash
az group delete --name qcb-rg-lab --yes --no-wait

# If you need to reuse the vault name, purge it after deletion:
az keyvault purge --name qcb-kv-lab --location eastus
```

```powershell
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob

# Purge if needed:
Remove-AzKeyVault -VaultName "qcb-kv-lab" -Location "eastus" -InRemovedState -Force
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 05: Identity](05-identity.md) | [Back to README](../README.md) | [Next: Phase 07 — Monitoring →](07-monitoring.md)
