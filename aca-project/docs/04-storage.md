# Phase 04 — Storage

| | |
|---|---|
| **Phase** | 04 |
| **Topic** | Azure Storage |
| **AZ-104 Domain** | Implement and Manage Storage |
| **Services** | Storage Account, Blob Containers |
| **Est. Cost** | Free tier — first 5 GB/month |

---

## Navigation

[← Phase 03: Compute](03-compute.md) | [Back to README](../README.md) | [Next: Phase 05 — Identity →](05-identity.md)

---

## What We're Building

A storage account (`stqcblab`) with two blob containers — `uploads` and `backups`. The account is configured with TLS 1.2 enforcement, no public blob access, and identity-based authentication rather than storage keys.

This phase maps to the **Implement and Manage Storage** domain of AZ-104, specifically: creating and configuring storage accounts, configuring blob storage, understanding redundancy options, and securing storage with access controls and TLS enforcement.

---

## The Technology

### Storage Account

A storage account is the top-level namespace for all Azure Storage services. The account name becomes part of every URL for data stored inside it (e.g. `https://stqcblab.blob.core.windows.net`). Settings for redundancy, performance, and access are configured at the account level.

### Redundancy

| Option | Description | Cost |
|---|---|---|
| LRS | 3 copies within one datacentre | Cheapest |
| ZRS | 3 copies across availability zones | Mid |
| GRS | LRS + async copy to a second region | Higher |
| GZRS | ZRS + async copy to a second region | Highest |

This project uses **Standard_LRS** — three local copies, lowest cost, sufficient for a lab.

### Blob Storage

Blob storage is for unstructured data — files, images, backups, logs. Data is organised in **containers** and accessed over HTTPS. Containers in this project:

| Container | Purpose |
|---|---|
| `uploads` | Incoming files from applications |
| `backups` | Backup data |

### `--auth-mode login`

The deploy script uses `--auth-mode login` when creating containers. This authenticates using your Entra ID identity rather than a storage account key — the secure, recommended approach. It requires the caller to have an appropriate RBAC role on the storage account (e.g. `Storage Blob Data Contributor`).

---

## Step 1 — Create the Storage Account

### Azure Portal

1. Search for **Storage accounts** and select it
2. Click **+ Create**
3. Fill in the **Basics** tab:
   - **Subscription:** QCB PAYG PersonalCloud
   - **Resource group:** `qcb-rg-lab`
   - **Storage account name:** `stqcblab`
   - **Region:** East US
   - **Performance:** Standard
   - **Redundancy:** Locally-redundant storage (LRS)
4. Click **Next: Advanced**
   - **Minimum TLS version:** Version 1.2
   - **Allow Blob public access:** Disabled
5. Click **Next: Tags**
   - Add `Project=QCBLab` and `Environment=Lab`
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

1. Open **stqcblab**
2. In the left menu, click **Containers**
3. Click **+ Container**:
   - **Name:** `uploads`
   - **Public access level:** Private (no anonymous access)
   - Click **Create**
4. Repeat for `backups`

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

### Azure Portal

1. Open **stqcblab → Overview** — confirm SKU: Standard LRS, TLS: 1.2
2. Click **Containers** — confirm both `uploads` and `backups` exist
3. Click **Configuration** — confirm **Blob public access: Disabled**

### Azure CLI

```bash
az storage account show \
  --name stqcblab \
  --resource-group qcb-rg-lab \
  --query "{Name:name, SKU:sku.name, TLS:minimumTlsVersion}" \
  --output table

az storage container list \
  --account-name stqcblab \
  --auth-mode login \
  --output table
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

**1. Transient Azure API error on first run — exit code 3 at container creation.** The deploy script failed at the `az storage container create` step on the first run with exit code 3. This is a transient Azure ARM API error — there was no structural issue with the script or command. Re-running the script immediately succeeded cleanly. All `az` commands in the script are idempotent, so re-running is always safe.

**2. `--min-tls-version` deprecation warning.** Azure CLI emits a general deprecation notice about the `--min-tls-version` flag, warning that `TLS1_0` and `TLS1_1` values are retired as of 2026-02-03. The script uses `TLS1_2` which is the current required value — the warning is informational only and does not affect the operation.

**3. Storage account names must be globally unique, 3–24 characters, lowercase letters and numbers only.** No hyphens allowed — Azure enforces this. If `stqcblab` is already taken in another subscription, append a number suffix.

**4. `--auth-mode login` requires an RBAC role on the storage account.** If you run the container create commands manually as a different user or service principal, ensure they have at least `Storage Blob Data Contributor` on the storage account. The deploy script runs as the signed-in user who created the account and inherits implicit access.

**5. `--access-tier Hot` is the default for StorageV2 but specifying it explicitly is good practice.** It makes the intent clear in the script and prevents unexpected defaults if Microsoft changes behaviour in a future CLI version.

---

## Cost at This Phase

| Resource | Free Tier |
|---|---|
| stqcblab (Standard LRS) | ✅ First 5 GB/month hot blob storage |
| Container create operations | ✅ Covered under free tier operations |
| Data transfer (intra-region) | ✅ Free |

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

[← Phase 03: Compute](03-compute.md) | [Back to README](../README.md) | [Next: Phase 05 — Identity →](05-identity.md)
