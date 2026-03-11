# Phase 04 — Storage

| | |
|---|---|
| **Phase** | 04 |
| **Topic** | Azure Storage |
| **Services** | Storage Account, Blob Storage, File Share, Lifecycle Policies |
| **Est. Cost** | Very low — LRS storage, minimal data |

---

## Navigation

[← Phase 03: Compute](03-compute.md) | [Back to README](../README.md) | [Next: Phase 05 — Identity →](05-identity.md)

---

## What We're Building

An Azure Storage Account (`qcbstorage01`) with a blob container for unstructured data and a file share for shared storage. We'll apply a lifecycle policy that automatically moves old blobs to a cheaper tier, and lock down the account so it has no public internet access.

---

## The Technology

### Storage Account

An Azure Storage Account is the top-level container for all Azure Storage services. It's the namespace — the account name becomes part of every URL for data stored inside it (e.g. `https://qcbstorage01.blob.core.windows.net`).

Everything flows from the storage account: blob storage, file shares, queues, and tables all live inside one. You set redundancy, performance tier, and access settings at the account level.

### Redundancy Options

| Option | What it means | Cost |
|--------|--------------|------|
| LRS | 3 copies in one datacentre | Cheapest |
| ZRS | 3 copies across availability zones | Mid |
| GRS | LRS + async copy to a second region | Higher |
| GZRS | ZRS + async copy to a second region | Highest |

We use **LRS** (Locally Redundant Storage) — 3 copies within a single datacentre. Sufficient for a lab, lowest cost.

### Blob Storage

Blob (Binary Large Object) storage is for unstructured data — files, images, backups, logs. Data is stored in **containers** (like folders) and accessed via HTTP/HTTPS.

Blobs have three **access tiers:**

| Tier | Use case | Cost to store | Cost to access |
|------|----------|--------------|----------------|
| Hot | Frequently accessed | Higher | Lower |
| Cool | Infrequently accessed | Lower | Higher |
| Archive | Rarely accessed | Lowest | Highest + rehydration delay |

### File Share

Azure Files provides a fully managed SMB file share in the cloud. VMs can mount it like a network drive. It's the Azure equivalent of a traditional file server.

### Lifecycle Policies

A lifecycle policy is a rule set that automatically transitions blobs between tiers or deletes them based on age. For example: move to Cool after 30 days, move to Archive after 90 days, delete after 365 days.

---

## Step 1 — Create the Storage Account

```bash
az storage account create \
  --resource-group qcb-rg-lab \
  --name qcbstorage01 \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --tags Project=QCBLab Environment=Lab
```

```powershell
New-AzStorageAccount `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcbstorage01" `
  -Location "eastus" `
  -SkuName "Standard_LRS" `
  -Kind "StorageV2" `
  -AccessTier "Hot" `
  -AllowBlobPublicAccess $false `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> **Gotcha:** Storage account names must be globally unique across all of Azure, 3–24 characters, lowercase letters and numbers only — no hyphens. If `qcbstorage01` is taken, try `qcbstorage02` etc.

---

## Step 2 — Create a Blob Container

```bash
az storage container create \
  --account-name qcbstorage01 \
  --name qcb-data \
  --auth-mode login
```

```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "qcbstorage01").Context
New-AzStorageContainer -Name "qcb-data" -Context $ctx
```

> `--auth-mode login` uses your Entra ID credentials rather than a storage key — the preferred approach.

---

## Step 3 — Upload a Test Blob

```bash
echo "QCB Technologies test file" > /tmp/qcb-test.txt

az storage blob upload \
  --account-name qcbstorage01 \
  --container-name qcb-data \
  --name qcb-test.txt \
  --file /tmp/qcb-test.txt \
  --auth-mode login
```

```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "qcbstorage01").Context
Set-AzStorageBlobContent -Container "qcb-data" -File "/tmp/qcb-test.txt" -Blob "qcb-test.txt" -Context $ctx
```

---

## Step 4 — Create a File Share

```bash
az storage share create \
  --account-name qcbstorage01 \
  --name qcb-fileshare \
  --quota 1 \
  --auth-mode login
```

```powershell
$ctx = (Get-AzStorageAccount -ResourceGroupName "qcb-rg-lab" -Name "qcbstorage01").Context
New-AzStorageShare -Name "qcb-fileshare" -Context $ctx
```

> `--quota 1` sets a 1GB quota. Increase as needed.

---

## Step 5 — Apply a Lifecycle Policy

### Azure CLI

```bash
az storage account management-policy create \
  --account-name qcbstorage01 \
  --resource-group qcb-rg-lab \
  --policy '{
    "rules": [
      {
        "name": "MoveToCool",
        "enabled": true,
        "type": "Lifecycle",
        "definition": {
          "filters": {"blobTypes": ["blockBlob"]},
          "actions": {
            "baseBlob": {
              "tierToCool": {"daysAfterModificationGreaterThan": 30},
              "tierToArchive": {"daysAfterModificationGreaterThan": 90},
              "delete": {"daysAfterModificationGreaterThan": 365}
            }
          }
        }
      }
    ]
  }'
```

### PowerShell

```powershell
$action = Add-AzStorageAccountManagementPolicyAction -BaseBlobAction TierToCool -daysAfterModificationGreaterThan 30
$action = Add-AzStorageAccountManagementPolicyAction -InputObject $action -BaseBlobAction TierToArchive -daysAfterModificationGreaterThan 90
$action = Add-AzStorageAccountManagementPolicyAction -InputObject $action -BaseBlobAction Delete -daysAfterModificationGreaterThan 365

$filter = New-AzStorageAccountManagementPolicyFilter -BlobType blockBlob
$rule = New-AzStorageAccountManagementPolicyRule -Name "MoveToCool" -Action $action -Filter $filter

Set-AzStorageAccountManagementPolicy -ResourceGroupName "qcb-rg-lab" -StorageAccountName "qcbstorage01" -Rule $rule
```

---

## Verification

```bash
# Confirm account exists
az storage account show --name qcbstorage01 --resource-group qcb-rg-lab --output table

# List containers
az storage container list --account-name qcbstorage01 --auth-mode login --output table

# List blobs
az storage blob list --account-name qcbstorage01 --container-name qcb-data --auth-mode login --output table

# List file shares
az storage share list --account-name qcbstorage01 --auth-mode login --output table
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 03: Compute](03-compute.md) | [Back to README](../README.md) | [Next: Phase 05 — Identity →](05-identity.md)
