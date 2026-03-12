# Phase 04 — Storage

**AZ-104 Domain:** Implement and Manage Storage &nbsp;|&nbsp; **Services:** Storage Account, Blob Containers &nbsp;|&nbsp; **Est. Cost:** Free (first 5 GB/month)

---

## Navigation

[← Phase 03](03-compute.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 05 →](05-identity.md)

---

## What We're Building

A storage account (`stqcblab`) with two blob containers — `uploads` and `backups`. The account is configured with TLS 1.2 enforcement, no public blob access, and identity-based authentication rather than storage keys.

---

## The Technology

### Storage Account

A storage account is the top-level namespace for all Azure Storage services. The account name becomes part of every URL for data stored inside it (e.g. `https://stqcblab.blob.core.windows.net`). Settings for redundancy, performance, and access are configured at the account level.

### Redundancy Options

| Option | Description | Cost |
|---|---|---|
| LRS | 3 copies within one datacentre | Cheapest |
| ZRS | 3 copies across availability zones | Mid |
| GRS | LRS + async copy to a second region | Higher |
| GZRS | ZRS + async copy to a second region | Highest |

This project uses **Standard_LRS** — three local copies, lowest cost, sufficient for a lab.

### Blob Storage

Blob storage is for unstructured data — files, images, backups, logs. Data is organised in **containers** (think folders) and accessed over HTTPS.

| Container | Purpose |
|---|---|
| `uploads` | Incoming files from applications |
| `backups` | Backup data |

### `--auth-mode login`

The deploy script uses `--auth-mode login` when creating containers. This authenticates using your Entra ID identity rather than a storage account key — the secure, recommended approach. It requires the caller to have an appropriate RBAC role on the storage account (e.g. `Storage Blob Data Contributor`).

---

## Step 1 — Create the Storage Account

### Azure Portal

1. Search for **Storage accounts → + Create**
2. Resource group: `qcb-rg-lab` | Name: `stqcblab` | Region: East US
3. Performance: Standard | Redundancy: Locally-redundant storage (LRS)
4. Click **Next: Advanced**:
   - Minimum TLS version: Version 1.2
   - Allow Blob public access: Disabled
5. Add tags `Project=QCBLab` and `Environment=Lab`
6. Click **Review + create**, then **Create**

### Azure CLI

```bash
az storage account create \
  --resource-group qcb-rg-lab \
  --name stqcblab \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzStorageAccount `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "stqcblab" `
  -Location "eastus" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2" `
  -AccessTier "Hot" `
  -AllowBlobPublicAccess $false `
  -MinimumTlsVersion "TLS1_2" `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 2 — Create the Blob Containers

### Azure Portal

1. Open **stqcblab → Containers → + Container**
2. Name: `uploads` | Public access level: Private → **Create**
3. Repeat for `backups`

### Azure CLI

```bash
az storage container create \
  --account-name stqcblab \
  --name uploads \
  --auth-mode login

az storage container create \
  --account-name stqcblab \
  --name backups \
  --auth-mode login
```

### PowerShell

```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "stqcblab").Context

New-AzStorageContainer -Name "uploads" -Context $ctx -Permission Off
New-AzStorageContainer -Name "backups" -Context $ctx -Permission Off
```

---

## Verification

### Azure CLI

```bash
az storage account show \
  --name stqcblab --resource-group qcb-rg-lab \
  --query "{Name:name, SKU:sku.name, TLS:minimumTlsVersion}" \
  --output table

az storage container list \
  --account-name stqcblab --auth-mode login --output table
```

### PowerShell

```powershell
Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "stqcblab" | `
  Select-Object StorageAccountName, `
    @{N="SKU";E={$_.Sku.Name}}, `
    @{N="TLS";E={$_.MinimumTlsVersion}}

$ctx = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "stqcblab").Context
Get-AzStorageContainer -Context $ctx
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. Transient Azure API error on first run — exit code 3 at container creation.** The deploy script failed at `az storage container create` on the first run with no structural issue in the script. Re-running immediately succeeded. This is a known behaviour with Azure ARM — transient 5xx errors are possible on first use of a resource type in a new resource group. `set -e` causes the script to exit cleanly rather than continue in a broken state.

**2. `--min-tls-version` deprecation warning.** Azure CLI emits a general deprecation notice about the `--min-tls-version` flag, warning that `TLS1_0` and `TLS1_1` values are retired as of 2026-02-03. The script uses `TLS1_2` which is the current required value — the warning is informational only.

**3. Storage account names must be globally unique, 3–24 characters, lowercase letters and numbers only.** No hyphens allowed — Azure enforces this. If `stqcblab` is already taken, append a number suffix.

**4. `--auth-mode login` requires an RBAC role on the storage account.** If running the container create commands as a different user or service principal, ensure they have at least `Storage Blob Data Contributor` on the storage account.

**5. `--access-tier Hot` is the default for StorageV2 but specifying it explicitly is good practice.** It makes the intent clear in the script and prevents unexpected defaults if Microsoft changes behaviour in a future CLI version.

---

## Navigation

[← Phase 03](03-compute.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 05 →](05-identity.md)
