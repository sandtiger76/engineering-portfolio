# 04 — OneDrive & Home Folders

## In Plain English

Each member of staff at QCB Homelab Consultants has a personal H: drive on the file server — a folder that belongs to them individually and is not shared with colleagues. These are personal work files: notes, local copies of documents, work-in-progress files. Right now, these only exist on the server, with no backup and no way to access them without a VPN. This workstream migrates each person's H: drive into their individual OneDrive for Business account, giving them secure personal cloud storage that works from any device.

## Why This Matters

Personal home folders on an on-premises server represent an invisible risk. If the server fails, or a member of staff leaves and their folder is inadvertently deleted, that content is gone. OneDrive for Business provides automatic sync to the cloud, version history, recycle bin recovery, and access from any device. It also sets the foundation for Files On-Demand — staff can see all their files without downloading them all, which is particularly valuable for laptops with limited storage.

## Prerequisites

- All 15 staff licensed with Microsoft 365 Business Premium (completed in `01d`)
- OneDrive for Business provisioned for all staff (happens automatically on first sign-in, or can be pre-provisioned via PowerShell)
- SPMT installed on QCBHC-DC01 (confirmed in workstream 03)
- Source H: drives accessible at `\\QCBHC-DC01\Home\<username>`
- Each user's OneDrive URL known or derivable from UPN
- File Share migration (workstream 03) completed — SPMT already familiar to the engineer

---

## Source and Target Mapping

Each user's H: drive maps to their individual OneDrive for Business:

| Source Path | OneDrive Target |
|---|---|
| `\\QCBHC-DC01\Home\alice.martin` | `https://qcbhomelab-my.sharepoint.com/personal/alice_martin_qcbhomelab_online` |
| `\\QCBHC-DC01\Home\bob.chen` | `https://qcbhomelab-my.sharepoint.com/personal/bob_chen_qcbhomelab_online` |
| `\\QCBHC-DC01\Home\carol.jones` | `https://qcbhomelab-my.sharepoint.com/personal/carol_jones_qcbhomelab_online` |
| ... (15 users total) | ... |

### OneDrive URL Pattern

OneDrive personal site URLs follow a consistent pattern:
```
https://<tenant>-my.sharepoint.com/personal/<firstname>_<lastname>_<domain>_<tld>
```

For `alice.martin@qcbhomelab.online`:
```
https://qcbhomelab-my.sharepoint.com/personal/alice_martin_qcbhomelab_online
```

> **Note:** Dots and @ symbols in UPNs are converted to underscores in the OneDrive URL. Hyphens in the tenant name are preserved.

---

## Phase 1 — Pre-Provision OneDrive Accounts

OneDrive is provisioned when a user signs in for the first time. To ensure all 15 OneDrive accounts exist before the migration runs, pre-provision them via PowerShell.

```powershell
# Connect to SharePoint Online
Connect-SPOService -Url https://qcbhomelab-admin.sharepoint.com

# Pre-provision OneDrive for all licensed users
$users = @(
    "alice.martin@qcbhomelab.online",
    "bob.chen@qcbhomelab.online",
    "carol.jones@qcbhomelab.online"
    # ... all 15 users
)

Request-SPOPersonalSite -UserEmails $users -NoWait
```

Wait 15–30 minutes for provisioning to complete before running SPMT.

> **Screenshot:** `screenshots/04-onedrive/01_onedrive_preprovisioned.png`
> *SharePoint Admin Center → Active sites showing OneDrive personal sites created for all 15 users*

---

## Phase 2 — Configure Files On-Demand Policy

### Key Decision: Configure Files On-Demand Before Users Start Syncing

Files On-Demand is a OneDrive sync client feature that allows users to see all their files in File Explorer without downloading them locally. Files are downloaded on demand when opened. This is the correct default for most business deployments.

The risk documented in `05-sharepoint-design-and-pitfalls.md` applies here: if users start syncing before Files On-Demand is configured, they may inadvertently download everything locally, overwrite cloud content with empty local copies, or fill their device storage.

**The correct sequence is:**
1. Migrate files to OneDrive via SPMT (cloud only)
2. Configure Files On-Demand policy via Intune or Group Policy before users sign into the sync client
3. Users sign in — sync client respects the policy and does not bulk-download

### Configure via Intune (Recommended)

In Intune, create a Windows Configuration Profile using Settings Catalog:

- **OneDrive → Use OneDrive Files On-Demand:** Enabled
- **OneDrive → Silently sign in users to the OneDrive sync client with their Windows credentials:** Enabled
- **OneDrive → Set the sync client update ring:** Production

> **Screenshot:** `screenshots/04-onedrive/02_intune_onedrive_policy.png`
> *Intune configuration profile showing OneDrive Files On-Demand policy settings*

### Configure via Group Policy (Lab Alternative)

For the lab environment running Entra Connect, the equivalent Group Policy setting is:

- Path: `Computer Configuration → Administrative Templates → OneDrive`
- Setting: **Use OneDrive Files On-Demand** → Enabled

---

## Phase 3 — SPMT Migration (OneDrive Mode)

### How SPMT Maps H: Drives to OneDrive Accounts

SPMT includes a specific mode for migrating to OneDrive for Business. Each migration task maps one source folder to one user's OneDrive. The destination is the `/Documents` folder within the user's OneDrive by default, though this can be configured.

For 15 users, 15 migration tasks are configured — one per user. SPMT can run all tasks simultaneously.

### Bulk CSV Migration (Recommended for Multiple Users)

Rather than configuring 15 tasks manually in the SPMT GUI, use the bulk CSV import feature:

1. In SPMT, select **JSON or CSV file for bulk migration**
2. Prepare the CSV:

```csv
Source,SourceDocLib,SourceSubFolder,TargetWeb,TargetDocLib,TargetSubFolder
\\QCBHC-DC01\Home\alice.martin,,,"https://qcbhomelab-my.sharepoint.com/personal/alice_martin_qcbhomelab_online",Documents,
\\QCBHC-DC01\Home\bob.chen,,,"https://qcbhomelab-my.sharepoint.com/personal/bob_chen_qcbhomelab_online",Documents,
\\QCBHC-DC01\Home\carol.jones,,,"https://qcbhomelab-my.sharepoint.com/personal/carol_jones_qcbhomelab_online",Documents,
```

3. Save as `onedrive-migration.csv`
4. Import into SPMT and review the task list — confirm all 15 users appear
5. Click **Migrate**

> **Screenshot:** `screenshots/04-onedrive/03_spmt_onedrive_tasks.png`
> *SPMT showing all 15 OneDrive migration tasks loaded from CSV*

### Running the Migration

> **Screenshot:** `screenshots/04-onedrive/04_spmt_onedrive_progress.png`
> *SPMT migration progress showing files migrating to individual OneDrive accounts*

> **Screenshot:** `screenshots/04-onedrive/05_spmt_onedrive_complete.png`
> *SPMT summary showing all 15 tasks completed successfully*

---

## Phase 4 — Post-Migration Verification

### Verify Content in OneDrive Admin

1. Navigate to **SharePoint Admin Center** → **User profiles** → select a user → **Manage personal site**
2. Or navigate directly to the user's OneDrive URL
3. Confirm the `Documents` folder contains the migrated content

> **Screenshot:** `screenshots/04-onedrive/06_onedrive_content_verified.png`
> *OneDrive for Business showing alice.martin's migrated Documents folder*

### Verify via OneDrive Web (As User)

1. Sign in as `alice.martin@qcbhomelab.online` at `https://onedrive.live.com/login` or via the Microsoft 365 portal
2. Navigate to **My files**
3. Confirm files are present

> **Screenshot:** `screenshots/04-onedrive/07_onedrive_user_view.png`
> *OneDrive web showing migrated files from the user's perspective*

---

## Communicating the Change to Users

In a real engagement, this workstream requires a clear user communication. The key points to convey:

- Their H: drive files are now in OneDrive — accessible from any device without VPN
- Nothing has been deleted from the server yet — the H: drive remains as a fallback during transition
- The sync client will appear in Windows taskbar after sign-in — files are visible in File Explorer under **OneDrive - QCB Homelab Consultants**
- Files On-Demand means not everything downloads immediately — a cloud icon means the file is available but not yet local; clicking opens it normally

> **Suggested user communication template:**
>
> *"Your personal H: drive files have been moved to OneDrive. You can access them from the Microsoft 365 portal or through File Explorer once you sign in to OneDrive on your device. If you cannot find something, your H: drive remains accessible until [cutover date]. Contact IT if you have any questions."*

---

## Files On-Demand: Preventing the Sync Overwrite Problem

As documented in `05-sharepoint-design-and-pitfalls.md`, the sync overwrite problem occurs when:

1. Files are migrated to OneDrive (cloud)
2. User signs into the sync client on a device with old local copies of the same files
3. The sync client merges or overwrites cloud files with local versions

**Prevention:**
- Migrate H: drive files to OneDrive **before** configuring the sync client on user devices
- Apply the Files On-Demand policy via Intune before devices are enrolled
- Advise users not to manually copy from H: drive to local machines during the migration window
- The H: drive is read-only from the migration start date (enforced at NTFS level if possible)

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| All 15 OneDrive accounts provisioned | SharePoint Admin Center → Active sites | 15 personal sites visible |
| Files present in each OneDrive | Browse each personal site | Migrated content in Documents folder |
| File counts match source | PowerShell comparison | Source and destination counts match |
| Files On-Demand policy applied | Check OneDrive sync client status icon | Cloud icons (not green ticks) on all files |
| User can access from web | Sign in as user → OneDrive web | Files visible and openable |
| User can access from sync client | Sign in to OneDrive on Windows device | Files visible in File Explorer |
| No overwrite errors | Review SPMT migration report | Zero failed items |

### File Count Verification (PowerShell)

```powershell
# Count files in source H: drive for one user
(Get-ChildItem -Path '\\QCBHC-DC01\Home\alice.martin' -Recurse -File).Count

# Verify OneDrive content via PnP PowerShell
Connect-PnPOnline -Url "https://qcbhomelab-my.sharepoint.com/personal/alice_martin_qcbhomelab_online" -Interactive
Get-PnPListItem -List "Documents" -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" } | Measure-Object
```

---

## Summary

This workstream delivered the following:

- **OneDrive for Business** pre-provisioned for all 15 staff via PowerShell
- **Files On-Demand** policy configured via Intune before any user sync client activity
- **SPMT migration** completed — each user's H: drive content migrated to their individual OneDrive account using bulk CSV task configuration
- **Post-migration verification** completed — content confirmed present and accessible from both web and sync client

**What this enables next:**

- H: drive folders on QCBHC-DC01 can be set to read-only and decommissioned once staff confirm access to their OneDrive content
- Intune device enrolment (workstream 07) will automatically configure the OneDrive sync client on enrolled devices
- The Files On-Demand policy ensures enrolled devices do not bulk-download all content on first sync
- Combined with SharePoint (workstream 03) and Teams (workstream 06), staff now have full cloud file access without any dependency on the on-premises server or VPN
