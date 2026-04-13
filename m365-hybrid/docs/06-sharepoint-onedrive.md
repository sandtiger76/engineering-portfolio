[← 05 — Microsoft 365 & Exchange Online](05-m365-exchange.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [07 — Microsoft Teams →](07-teams.md)

---

# 06 — SharePoint & OneDrive

## Overview — What This Document Covers

One of the most visible changes when a business moves to Microsoft 365 is what happens to files. Instead of a shared drive on a server in the office, files live in the cloud — accessible from any device, from any location, with built-in version history and the ability for multiple people to work on the same document at the same time.

Microsoft 365 provides two file storage services. OneDrive is personal storage — each user gets their own space in the cloud, equivalent to a "My Documents" folder that follows them everywhere. SharePoint is shared team storage — each department or office gets a shared site where the whole team can store and collaborate on documents.

This document covers setting both up and, critically, how to migrate existing files from a traditional file server into the cloud — which is the real-world challenge most organisations face when making this transition. Two different migration tools are used and compared, reflecting the current Microsoft-recommended approach for each scenario.

---

## Introduction

When organisations move to Microsoft 365, one of the most significant changes is what happens to file storage. Traditionally, files lived on a file server in the office — a physical or virtual server with shared folders that users mapped as network drives. Microsoft 365 replaces this with two cloud services: OneDrive for personal files and SharePoint for shared team files.

OneDrive is each user's personal file storage in the cloud. Think of it as a My Documents folder that follows the user anywhere, syncs to their devices, and is protected by Microsoft's infrastructure rather than a server in a cupboard.

SharePoint is the shared collaboration layer. Each office location gets its own SharePoint site with a document library that all members can access and collaborate on. Files stored there are available from any device, with built-in versioning, access control, and co-authoring.

In this project, two migration tools are used side by side to demonstrate their different strengths:

- **SPMT (SharePoint Migration Tool)** — used for OneDrive home folder migrations, covering both single and bulk migration modes
- **Migration Manager** — used for SharePoint team site migrations, the modern web-based approach that Microsoft now recommends over SPMT for new deployments

---

## What We Are Building

| Source (Legacy) | Destination | Tool |
|---|---|---|
| C:\Data\Home\j.carter | OneDrive for Business — James Carter | SPMT (single) |
| C:\Data\Home\o.brown | OneDrive for Business — Olivia Brown | SPMT (bulk) |
| C:\Data\Home\m.reed | OneDrive for Business — Michael Reed | SPMT (bulk) |
| C:\Data\Home\s.miller | OneDrive for Business — Sophia Miller | SPMT (bulk) |
| C:\Data\Home\d.wong | OneDrive for Business — Daniel Wong | SPMT (bulk) |
| C:\Data\Home\e.chan | OneDrive for Business — Emily Chan | SPMT (bulk) |
| C:\Data\Group\London | SharePoint — QCB London | Migration Manager |
| C:\Data\Group\NewYork | SharePoint — QCB New York | Migration Manager |
| C:\Data\Group\HongKong | SharePoint — QCB Hong Kong | Migration Manager |

---

## Prerequisites

- Microsoft 365 Business Premium licences assigned to all users (document 05)
- Users synced from Active Directory and visible in Entra ID (document 04)
- SharePoint Admin Center accessible at `https://qcbazoutlook362-admin.sharepoint.com`

---

## Implementation Steps

### Step 1 — Access the SharePoint Admin Center

Log in to the Microsoft 365 Admin Center at **admin.microsoft.com** and navigate to **Admin centers → SharePoint**. This opens the SharePoint Admin Center.

> **Note on SharePoint URLs:** The SharePoint Admin Center URL uses the tenant name assigned by Microsoft at tenant creation — in this environment `qcbazoutlook362` — not the custom domain `qcbhomelab.online`. SharePoint site URLs follow the same pattern: `qcbazoutlook362.sharepoint.com/sites/<sitename>`. This cannot be changed without a full tenant rename operation, which is a one-time irreversible action. For a lab of this size, accepting the tenant name is the correct approach.

### Step 2 — Create Team Sites

Create a SharePoint Team Site for each office location. A Team Site includes a document library, a SharePoint page, and an associated Microsoft 365 Group that controls membership.

In the SharePoint Admin Center, navigate to **Sites → Active sites → Create → Team site** and create the following three sites:

| Site name | Site address | Owner |
|---|---|---|
| QCB London | qcbazoutlook362.sharepoint.com/sites/qcb-london | j.carter@qcbhomelab.online |
| QCB New York | qcbazoutlook362.sharepoint.com/sites/qcb-newyork | m.reed@qcbhomelab.online |
| QCB Hong Kong | qcbazoutlook362.sharepoint.com/sites/qcb-hongkong | d.wong@qcbhomelab.online |

> **Important:** The site address is permanent and cannot be changed after creation. Agree the naming convention before creating sites.

After creating each site, select it in the **Active sites** list and click **Membership** in the toolbar. Add the second office user as a Member:

| Site | Owner (already set) | Add as Member |
|---|---|---|
| QCB London | j.carter | o.brown |
| QCB New York | m.reed | s.miller |
| QCB Hong Kong | d.wong | e.chan |

Contractors (a.hassan and p.novak) are not added to any SharePoint team sites. They access company data through MAM-managed apps on their personal devices only.

> You will also see two system-generated sites in Active sites — **All Company** and **Group for Answers in Viva Eng...** — both are auto-created by Microsoft 365 and can be safely ignored.

### Step 3 — Configure SharePoint Sharing Settings

Navigate to **Policies → Sharing** in the SharePoint Admin Center. The default settings are too permissive and must be tightened.

**External sharing sliders** — both SharePoint and OneDrive default to **Anyone** (most permissive). Drag both down to **Only people in your organisation**.

**File and folder links** — the default link type defaults to **Anyone with the link**. Change this to **Only people in your organisation**. Leave the default permission as **Edit** — changing it to View would require users to manually set edit permissions every time they share internally, which adds friction with no security benefit in this environment.

Click **Save**.

Navigate to **Policies → Access control** and configure the following:

| Setting | Value | Reason |
|---|---|---|
| Unmanaged devices | Allow full access | Conditional Access in document 10 handles this at the identity layer |
| Idle session sign-out | Off | Acceptable for a small trusted team |
| Network location | Off | No IP-based restrictions required |
| Apps that don't use modern authentication | Block access | Consistent with CA02 — defence in depth |

The legacy authentication block here is separate from Conditional Access policy CA02 but complementary — if one layer is misconfigured, the other still protects the environment.

### Step 4 — Pre-Provision OneDrive for All Users

OneDrive for Business is not provisioned automatically when a licence is assigned. It is created the first time a user signs in, or it can be pre-provisioned by an administrator. Pre-provisioning is required before running any migration tool — SPMT will fail with "This OneDrive does not exist" if the destination has not been provisioned.

On QCBHC-DC01, install the SharePoint Online Management Shell and connect:

```powershell
# If a previous version is installed, uninstall it first
Uninstall-Module Microsoft.Online.SharePoint.PowerShell -Force -AllVersions

# Install fresh
Install-Module Microsoft.Online.SharePoint.PowerShell -Force

# Connect — opens a modern browser authentication window
Connect-SPOService -Url "https://qcbazoutlook362-admin.sharepoint.com"
```

> **Do not use the `-Credential` parameter** — it uses legacy authentication which does not support MFA and will fail with an AggregateException. The `Connect-SPOService` command without credentials triggers a modern browser popup for authentication. If the popup flashes and immediately disappears on Windows Server, this is caused by Web Account Manager (WAM) intercepting the request — see Troubleshooting below.

Once connected, provision OneDrive for all staff:

```powershell
$users = @(
    "j.carter@qcbhomelab.online",
    "o.brown@qcbhomelab.online",
    "m.reed@qcbhomelab.online",
    "s.miller@qcbhomelab.online",
    "d.wong@qcbhomelab.online",
    "e.chan@qcbhomelab.online"
)

Request-SPOPersonalSite -UserEmails $users -NoWait
Write-Host "OneDrive provisioning requested for all users" -ForegroundColor Green
```

The `-NoWait` flag queues all requests immediately rather than waiting for each to complete sequentially. Wait 2-5 minutes then verify:

```powershell
Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'" | Select-Object Owner, Url
```

All six users should appear with URLs in the format:

```
https://qcbazoutlook362-my.sharepoint.com/personal/j_carter_qcbhomelab_online
```

> **OneDrive URL format:** Microsoft converts dots and @ symbols in UPNs to underscores. `j.carter@qcbhomelab.online` becomes `j_carter_qcbhomelab_online`. This matters when building CSV files that reference OneDrive URLs directly.

### Step 5 — Create Dummy File Server Data

On QCBHC-DC01, create a realistic folder structure representing a legacy file server. This provides meaningful data to migrate and validates the end-to-end process.

```powershell
# 06-Create-FileServerData.ps1
# Run as Domain Admin on QCBHC-DC01

$users = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan")
$locations = @("London","NewYork","HongKong")

# Create user home folders
foreach ($user in $users) {
    $path = "C:\Data\Home\$user"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    "This is a sample document for $user." | Out-File "$path\My Notes.txt"
    "Financial summary Q1 2024" | Out-File "$path\Q1 Summary.txt"
    New-Item -ItemType Directory -Path "$path\Projects" -Force | Out-Null
    "Project Alpha notes" | Out-File "$path\Projects\Project Alpha.txt"
    Write-Host "Created home folder for $user" -ForegroundColor Green
}

# Create shared location folders
foreach ($loc in $locations) {
    $path = "C:\Data\Group\$loc"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    "Team policies for $loc office" | Out-File "$path\Team Policies.txt"
    "$loc office procedures" | Out-File "$path\Office Procedures.txt"
    New-Item -ItemType Directory -Path "$path\Shared Projects" -Force | Out-Null
    Write-Host "Created shared folder for $loc" -ForegroundColor Green
}
```

Verify the structure was created correctly:

```powershell
Get-ChildItem C:\Data -Recurse | Select-Object FullName
```

The output should show 6 user home folders each containing 3 files and a Projects subfolder, and 3 location folders each containing 2 files and a Shared Projects subfolder.

### Step 6 — Migrate Home Folders to OneDrive Using SPMT

Download and install SPMT on QCBHC-DC01:

```
https://www.microsoft.com/en-us/download/details.aspx?id=103627
```

Launch SPMT and sign in with a Global Administrator account. The home screen shows two sections — **SharePoint** and **File share**. All migrations in this step use the **File share** section.

#### 6a — Single Migration (j.carter)

Click **Add new migration** under File share and select **Single file share source**.

| Field | Value |
|---|---|
| Source path | C:\Data\Home\j.carter |
| Folder option | Migrate selected folder and folder contents |
| Destination type | OneDrive |
| OneDrive destination | j.carter@qcbhomelab.online |

On the **Review settings** screen:

| Setting | Value | Notes |
|---|---|---|
| Only perform scanning | Off | Turn On in production for a pre-migration dry run |
| Preserve file share permissions | Off | OneDrive uses its own permission model |
| Automatic user mapping | On | Maps source folder to correct destination user |

Click **Start**. The transfer itself completes in approximately 1 minute. Total elapsed time for the first migration in a session is closer to 10 minutes due to SPMT initialisation and connection overhead. Subsequent migrations in the same session are significantly faster as the Microsoft 365 connection is already established.

#### 6b — Bulk Migration (Remaining 5 Users)

For the remaining 5 users, use bulk migration via CSV file. Create the following file on DC01:

```powershell
$csv = @"
C:\Data\Home\o.brown,,,https://qcbazoutlook362-my.sharepoint.com/personal/o_brown_qcbhomelab_online,Documents,
C:\Data\Home\m.reed,,,https://qcbazoutlook362-my.sharepoint.com/personal/m_reed_qcbhomelab_online,Documents,
C:\Data\Home\s.miller,,,https://qcbazoutlook362-my.sharepoint.com/personal/s_miller_qcbhomelab_online,Documents,
C:\Data\Home\d.wong,,,https://qcbazoutlook362-my.sharepoint.com/personal/d_wong_qcbhomelab_online,Documents,
C:\Data\Home\e.chan,,,https://qcbazoutlook362-my.sharepoint.com/personal/e_chan_qcbhomelab_online,Documents,
"@

$csv | Out-File "C:\Data\bulk-migration.csv" -Encoding utf8
Write-Host "SPMT bulk migration CSV created" -ForegroundColor Green
```

> **SPMT CSV format:** Six columns — Source, SourceDocLib, SourceSubFolder, TargetWeb, TargetDocLib, TargetSubFolder. Empty columns must still be represented with commas. No header row. The target for OneDrive must be the full personal site URL, not the user's email address.

In SPMT, click **Add new migration → Bulk migration using JSON or CSV file** and browse to `C:\Data\bulk-migration.csv`. SPMT processes all 5 users in parallel, completing in approximately the same total time as a single migration.

### Step 7 — Migrate Group Folders to SharePoint Using Migration Manager

Migration Manager is the modern web-based migration platform built into the SharePoint Admin Center. Unlike SPMT which is a desktop application, Migration Manager runs from the browser and delegates the actual file transfer to an agent installed on the source server. This architecture supports multiple agents simultaneously and provides centralised monitoring and reporting.

#### 7a — Install the Migration Manager Agent on DC01

In the SharePoint Admin Center, navigate to **Migration → File shares → Get started**. Click **Download agent** and run the installer on QCBHC-DC01.

During installation, select **User Credential Authentication** and enter the domain administrator credentials (`QCBHOMELAB\Administrator`) when prompted. The agent installs as a Windows service running under this account.

On the Finish screen, test agent access:

```
\\QCBHC-DC01\C$\Data\Group
```

The response should confirm **You have access to this file share** in green. Click **Close**.

Back in the browser, the Migration Manager page should show **Agent connected** with a green tick.

#### 7b — Create Named File Shares on DC01

Migration Manager expects proper named Windows file shares as source paths. Using admin shares (C$) can cause scanning issues where files at the share root are skipped. Create named shares for each location folder on DC01:

```powershell
New-SmbShare -Name "London"   -Path "C:\Data\Group\London"   -FullAccess "QCBHOMELAB\Administrator"
New-SmbShare -Name "NewYork"  -Path "C:\Data\Group\NewYork"  -FullAccess "QCBHOMELAB\Administrator"
New-SmbShare -Name "HongKong" -Path "C:\Data\Group\HongKong" -FullAccess "QCBHOMELAB\Administrator"
```

#### 7c — Scan the Source Paths

In the Migration Manager **Scans** tab, click **Add source path** and add each share:

| Source path | Add all subfolders option |
|---|---|
| \\QCBHC-DC01\London | **Untick** |
| \\QCBHC-DC01\NewYork | **Untick** |
| \\QCBHC-DC01\HongKong | **Untick** |

> **Critical:** The **Add all subfolders as source paths** option is ticked by default and must be manually unticked. When ticked, Migration Manager treats each subfolder as an independent source path and ignores files sitting directly at the share root. Since the location folders contain files at the root (Team Policies.txt, Office Procedures.txt), this option must be off.

Each scan completes quickly and should show **Ready to migrate** with **File count: 2**. If File count shows 0, the option was left ticked — delete the scan entry and re-add it with the option unticked.

#### 7d — Run the Bulk Migration

Create the Migration Manager bulk migration CSV on DC01:

```powershell
$csv = @"
FileSharePath,,,SharePointSite,DocLibrary,DocSubFolder
\\QCBHC-DC01\London,,,https://qcbazoutlook362.sharepoint.com/sites/qcb-london,Documents,
\\QCBHC-DC01\NewYork,,,https://qcbazoutlook362.sharepoint.com/sites/qcb-newyork,Documents,
\\QCBHC-DC01\HongKong,,,https://qcbazoutlook362.sharepoint.com/sites/qcb-hongkong,Documents,
"@

$csv | Out-File "C:\Data\mm-bulk-migration.csv" -Encoding utf8
Write-Host "Migration Manager CSV created" -ForegroundColor Green
```

> **Migration Manager CSV format differs from SPMT:** Migration Manager includes a header row (`FileSharePath,,,SharePointSite,DocLibrary,DocSubFolder`) and the destination is the SharePoint site URL. SPMT uses no header row and the OneDrive destination is the personal site URL. Using the wrong format in either tool causes a format validation error.

In Migration Manager, click the **Migrations** tab → **Add task → Bulk migration** → upload `C:\Data\mm-bulk-migration.csv`. Name the task, confirm Agent group shows **Default (active agents: 1)**, and click **Run**.

Three migration tasks will appear — one per location — progressing from **Waiting for agent** to **In progress** to **Complete**.

### Step 8 — Verify the Migrations

**OneDrive:** Sign in to office.com as `j.carter@qcbhomelab.online` and click OneDrive. The Documents library should contain My Notes.txt, Q1 Summary.txt, and a Projects folder containing Project Alpha.txt. Repeat for at least one user from the bulk migration (e.g. o.brown) to confirm the CSV migration also completed.

**SharePoint:** Browse to each team site and confirm the files appear in the Documents library:

| Site | Expected files |
|---|---|
| qcbazoutlook362.sharepoint.com/sites/qcb-london | Team Policies.txt, Office Procedures.txt |
| qcbazoutlook362.sharepoint.com/sites/qcb-newyork | Team Policies.txt, Office Procedures.txt |
| qcbazoutlook362.sharepoint.com/sites/qcb-hongkong | Team Policies.txt, Office Procedures.txt |

### Step 9 — Configure OneDrive Sync on Client Devices

OneDrive Known Folder Move is configured via Intune policy in document 08, which silently redirects each user's Desktop, Documents, and Pictures folders to OneDrive during device enrolment. No manual action is required on the device.

Users can additionally sync any SharePoint document library to their local device by navigating to the library in a browser and clicking **Sync**.

---

## What to Expect

Once these steps are complete, all six staff members have their personal files in OneDrive and their office shared files in the corresponding SharePoint team site. Files are accessible from any device via browser or through the OneDrive sync client on Windows. The two migration approaches are documented side by side — SPMT for personal storage, Migration Manager for shared storage — reflecting the current Microsoft tooling landscape.

---

## Troubleshooting

**SPMT: "This OneDrive does not exist. Please provision it before migration."**
OneDrive has not been pre-provisioned. Run the `Request-SPOPersonalSite` script in Step 4 and wait 2-5 minutes. Verify with `Get-SPOSite` before retrying.

**Connect-SPOService fails with "No valid OAuth 2.0 authentication session"**
This typically means an outdated version of the SharePoint Online Management Shell is installed. Uninstall all versions with `Uninstall-Module Microsoft.Online.SharePoint.PowerShell -Force -AllVersions`, reinstall fresh, and connect again without the `-Credential` parameter.

**Connect-SPOService browser popup flashes and immediately disappears**
Web Account Manager (WAM) is intercepting the authentication flow on Windows Server. Run the following before connecting:
```powershell
Set-MgGraphOption -DisableLoginByWAM $true
```

**Migration Manager scan shows File count: 0**
The **Add all subfolders as source paths** option was left ticked. Delete the scan entry and re-add the source path with the option unticked. This option is ticked by default and must be manually cleared when files sit at the share root.

**Migration Manager picks up subfolders only, not root files**
Ensure the source path is a proper named Windows share (`\\server\sharename`) rather than an admin share path (`\\server\C$\path\folder`). Create named shares using `New-SmbShare` as documented in Step 7b, then re-add the source path.

**SPMT bulk CSV fails with format error**
SPMT CSV must have exactly 6 columns with no header row. Empty columns must still be represented with commas. The OneDrive target must be the full personal site URL — not the user's email address. Ensure the file is saved as UTF-8 encoding.

**Migration Manager CSV fails with invalid destination error**
The Migration Manager CSV format differs from SPMT. It requires a header row and the destination is the SharePoint site URL, not the OneDrive personal URL. Verify the correct format is being used for each tool.

---

## Common Questions & Troubleshooting

**Q1: Files migrated successfully but users cannot see them in SharePoint or OneDrive. What should I check?**

First confirm the migration completed without errors in the tool's report — a "completed" status does not always mean all files transferred successfully. Check the migration log for skipped or failed items. Then confirm the destination path is correct: OneDrive personal sites follow the format `https://tenant-my.sharepoint.com/personal/firstname_lastname_domain_com` and any typo will result in files landing in the wrong location or failing silently. Have the affected user sign into OneDrive in a browser and check the exact URL of their personal site.

**Q2: Migration is extremely slow — hundreds of files per hour rather than thousands. What can be done to improve throughput?**

Migration speed is affected by several factors: file count matters more than total size (many small files migrate slower than fewer large files due to per-file overhead), network bandwidth between the source and Microsoft's datacentres, and the time of day (Microsoft throttles migration traffic during business hours in some regions). For large migrations, schedule bulk transfers overnight or over weekends. SPMT supports parallel task execution — run multiple tasks simultaneously for different source paths rather than one large task. Migration Manager distributes work across multiple agent machines, which is the more scalable approach for large environments.

**Q3: Some files failed to migrate with a "file name contains invalid characters" error. How should these be handled?**

SharePoint Online does not support certain characters in file and folder names that Windows file systems allow — including `# % & * : < > ? / \ { | }` and names that end in a space or period. The migration tools generate a report of failed items. The cleanest approach is to fix the names at the source before re-running the migration, rather than renaming in SharePoint after the fact. PowerShell can be used to scan and rename problematic files in bulk before migration begins.

**Q4: After migration, files in SharePoint show the migration service account as the author rather than the original user. Can this be corrected?**

This is expected behaviour when migrating with a service account — SharePoint records the account that uploaded the file as the modifier. SPMT and Migration Manager both support a `-SPUserMappingFile` or user mapping option that maps source usernames to destination Microsoft 365 accounts, which preserves original authorship metadata. This mapping must be configured before the migration runs — it cannot be applied retroactively to already-migrated content without re-migrating.

**Q5: OneDrive Known Folder Move (KFM) is configured via Intune but users' desktops and documents are not syncing. What should I check?**

KFM requires the OneDrive sync client to be signed in with the user's work account and running on the device. Confirm the sync client is installed, signed in, and not paused. In the Intune policy, verify the tenant ID in the KFM configuration profile is correct — a wrong tenant ID will cause KFM to silently fail. Also check that the user does not have a Group Policy or registry setting blocking KFM from a previous configuration, and that the folders being redirected do not contain paths longer than 260 characters, which OneDrive cannot sync.

---
