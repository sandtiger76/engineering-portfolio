# 03 — File Share Migration

## In Plain English

QCB Homelab Consultants stores all company documents on a Windows file server in the office — project files, technical documents, company templates, and administration records are all on a shared network drive. This only works when staff are on-site or connected via VPN. This workstream moves everything from the file server into SharePoint Online, where files are accessible from any device, anywhere, with proper version control and without a VPN.

## Why This Matters

The SMB file share on QCBHC-DC01 is entirely dependent on the on-premises server being online and accessible. There is no offsite copy, no version history, and no way to recover from accidental deletion beyond whatever manual backup exists. Moving to SharePoint Online eliminates all of these risks while adding co-authoring, version history, recycle bin recovery, and a platform that works whether staff are in the office, at a client site, or working from home.

## Prerequisites

- SharePoint Online site created and document libraries configured (designed in `05-sharepoint-design-and-pitfalls.md`)
- All 15 staff licensed with Microsoft 365 Business Premium (completed in `01d`)
- SPMT (SharePoint Migration Tool) installed on QCBHC-DC01
- NTFS permission matrix documented (from `00-discovery-and-planning.md`)
- Network share accessible from the machine running SPMT (`\\QCBHC-DC01\Company`)
- Migration credentials: an account with both read access to the source share and SharePoint Admin or Site Collection Admin rights

---

## Source and Target Mapping

| Source (SMB) | Target (SharePoint Online) |
|---|---|
| `\\QCBHC-DC01\Company\Projects` | QCB Homelab Consultants site → Projects library |
| `\\QCBHC-DC01\Company\TechLibrary` | QCB Homelab Consultants site → Technical Library library |
| `\\QCBHC-DC01\Company\Templates` | QCB Homelab Consultants site → Templates library |
| `\\QCBHC-DC01\Company\Administration` | QCB Homelab Consultants site → Administration library |

> **SharePoint site URL:** `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`

---

## SharePoint Migration Tool (SPMT) Overview

SPMT is Microsoft's free migration tool for moving content from file shares and SharePoint on-premises into SharePoint Online or OneDrive for Business. It runs on-premises (on the same server as the source files, or a machine with network access to them), authenticates to the Microsoft 365 tenant, and transfers content directly.

### Installing SPMT

1. On QCBHC-DC01, download SPMT from: `https://aka.ms/SPMT`
2. Run the installer — no additional prerequisites beyond .NET Framework 4.6.2 or later
3. Launch SPMT and sign in with the M365 admin account: `m365admin@qcbhomelab.online`

> **Screenshot:** `screenshots/03-file-share/01_spmt_installed.png`
> *SPMT launch screen showing sign-in completed*

---

## Phase 1 — Pre-Migration Scan

### Key Decision: Always Run the Pre-Migration Scan

The pre-migration scan is the most important step in any SPMT migration. It analyses the source content and produces a report of:

- **Invalid characters** in file or folder names (SharePoint rejects `# % & * : < > ? / \ { | } ~`)
- **File path length** violations (SharePoint has a 400-character URL limit)
- **File type restrictions** (certain file types are blocked in SharePoint)
- **Large files** that may cause timeout issues

Running the scan before the live migration means problems are identified and resolved before anything is moved. Discovering these issues during a live migration wastes time and leaves the migration in a partial state.

### Running the Pre-Migration Scan

1. In SPMT, select **Start your first migration**
2. Choose **File Share** as the source type
3. Enter the source path: `\\QCBHC-DC01\Company`
4. Do **not** specify a destination yet — instead, select **Scan only** mode
5. Click **Next** → name the scan task: `QCB-Company-Share-Scan`
6. Click **Migrate** (the scan runs without moving any files)

> **Screenshot:** `screenshots/03-file-share/02_spmt_scan_config.png`
> *SPMT scan configuration showing source path and scan-only mode selected*

### Reviewing the Scan Report

After the scan completes:

1. Click **View scan results** in SPMT
2. Review the summary — items scanned, warnings, errors
3. Export the full report to CSV for review

> **Screenshot:** `screenshots/03-file-share/03_spmt_scan_report.png`
> *SPMT scan report showing item count, warnings, and errors*

### Common Scan Findings and Remediation

| Issue | Example | Remediation |
|---|---|---|
| Invalid characters | `Project: Alpha` (colon) | Rename to `Project - Alpha` before migration |
| Path too long | Deeply nested folder structure > 400 chars | Flatten folder hierarchy |
| Blocked file type | `.tmp`, `.ps1` in some configurations | Review and exclude or rename |
| File over 250 GB | Not expected in this environment | N/A |

> **Note:** SPMT can automatically handle some invalid character substitutions. The behaviour is controlled in SPMT settings → **Replace invalid characters with underscore**. For a clean migration, it is better to remediate at source.

> **Screenshot:** `screenshots/03-file-share/04_invalid_chars_remediated.png`
> *File Explorer showing renamed files before migration*

---

## Phase 2 — SharePoint Site and Library Preparation

Before SPMT runs, the destination libraries must exist in SharePoint Online. SPMT can create lists and libraries automatically, but pre-creating them allows the correct names, column structures, and settings to be configured in advance.

### Create the SharePoint Site

1. Navigate to **SharePoint Admin Center** → **Active sites** → **Create**
2. Select **Team site** (connected to Microsoft 365 group)
3. Site name: `QCB Homelab Consultants`
4. Site address: `qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`
5. Owners: `m365admin@qcbhomelab.online`
6. Privacy: **Private**

> **Screenshot:** `screenshots/03-file-share/05_sharepoint_site_created.png`
> *SharePoint Admin Center showing QCB Homelab Consultants site active*

### Create Document Libraries

For each library, navigate to the SharePoint site → **New** → **Document library**:

| Library Name | Purpose |
|---|---|
| Projects | Client project folders and deliverables |
| Technical Library | Internal technical reference documents |
| Templates | Company document templates |
| Administration | HR, finance, and operations records |

> **Screenshot:** `screenshots/03-file-share/06_sharepoint_libraries_created.png`
> *SharePoint site showing four document libraries created*

---

## Phase 3 — Live Migration

### SPMT Migration Task Configuration

With the scan clean and destination libraries ready, configure the live migration tasks. SPMT supports multiple source-to-destination mappings in a single migration batch.

1. In SPMT, click **Start your first migration** (or **Add a migration task**)
2. For each library, configure a task:

**Task 1 — Projects**
- Source: `\\QCBHC-DC01\Company\Projects`
- Destination: `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`
- Destination library: `Projects`

**Task 2 — Technical Library**
- Source: `\\QCBHC-DC01\Company\TechLibrary`
- Destination: `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`
- Destination library: `Technical Library`

**Task 3 — Templates**
- Source: `\\QCBHC-DC01\Company\Templates`
- Destination: `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`
- Destination library: `Templates`

**Task 4 — Administration**
- Source: `\\QCBHC-DC01\Company\Administration`
- Destination: `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`
- Destination library: `Administration`

3. Review all tasks in the SPMT task list
4. Click **Migrate** to begin

> **Screenshot:** `screenshots/03-file-share/07_spmt_tasks_configured.png`
> *SPMT showing all four migration tasks ready to run*

### Monitoring Migration Progress

SPMT shows real-time progress per task:

- Files scanned
- Files migrated
- Files skipped (with reasons)
- Files failed

> **Screenshot:** `screenshots/03-file-share/08_spmt_migration_progress.png`
> *SPMT progress view showing files migrating across all four tasks*

> **Screenshot:** `screenshots/03-file-share/09_spmt_migration_complete.png`
> *SPMT summary showing all tasks completed*

---

## Permission Migration Approach

### Key Decision: Recreate Permissions Manually Rather Than Migrating NTFS ACLs

SPMT can attempt to migrate NTFS permissions to SharePoint, but this approach has significant limitations:

- NTFS permissions use local or AD security groups — these must map to Entra ID groups in SharePoint
- SharePoint permission inheritance works differently from NTFS — unique permissions on every folder creates a management overhead
- Migrated NTFS permissions are often more complex than necessary in SharePoint

**Recommended approach for QCB Homelab Consultants:** Recreate permissions at the library level using SharePoint groups mapped to the Microsoft 365 / Entra ID security groups created in workstream 01d.

### Permission Matrix (Post-Migration)

| Library | Group | Permission Level |
|---|---|---|
| Projects | Projects-Staff | Contribute |
| Projects | Management | Full Control |
| Technical Library | All Staff | Read |
| Technical Library | Projects-Staff | Contribute |
| Templates | All Staff | Read |
| Templates | Management | Full Control |
| Administration | Admin-Staff | Contribute |
| Administration | Management | Full Control |

> **Note:** This mirrors the NTFS permission structure documented in `00-discovery-and-planning.md` but uses SharePoint permission levels rather than NTFS ACLs.

> **Screenshot:** `screenshots/03-file-share/10_sharepoint_permissions_configured.png`
> *SharePoint library permissions showing groups assigned to Projects library*

---

## Post-Migration File Validation

After migration completes, verify content at the destination:

1. Navigate to each SharePoint library and spot-check:
   - Folder structure preserved
   - File names correct (no garbled characters)
   - File opens correctly from SharePoint
2. Compare file counts between source and destination

### File Count Verification (PowerShell)

```powershell
# Count files in source share
(Get-ChildItem -Path '\\QCBHC-DC01\Company' -Recurse -File).Count

# Count files in SharePoint via PnP PowerShell
Connect-PnPOnline -Url "https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants" -Interactive
Get-PnPListItem -List "Projects" -PageSize 500 | Where-Object { $_.FileSystemObjectType -eq "File" } | Measure-Object
```

> **Screenshot:** `screenshots/03-file-share/11_sharepoint_files_verified.png`
> *SharePoint Projects library showing migrated folder structure*

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Pre-migration scan clean | SPMT scan report | Zero errors, warnings resolved |
| All four libraries populated | Browse SharePoint site | Files visible in each library |
| File counts match | PowerShell comparison | Source and destination counts match |
| Files open correctly | Open sample files from SharePoint | Files open without corruption |
| Permissions applied | Check library permissions | Groups assigned per matrix |
| Version history present | Check file version history | Migrated files show version 1.0 |
| Co-authoring works | Open same file from two accounts | Both users can edit simultaneously |

---

## Summary

This workstream delivered the following:

- **Pre-migration scan** completed — invalid characters and path issues identified and remediated before live migration
- **SharePoint site** created at `qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants` with four document libraries matching the source folder structure
- **SPMT migration** completed — all content from `\\QCBHC-DC01\Company` migrated into SharePoint Online across four tasks
- **Permissions** recreated at library level using Entra ID security groups

**What this enables next:**

- SharePoint document libraries can be connected to Microsoft Teams channels (workstream 06)
- The OneDrive migration (workstream 04) can proceed using the same SPMT tooling
- The SMB share on QCBHC-DC01 can be decommissioned once users confirm all content is accessible in SharePoint
- Staff can be redirected to SharePoint via the SharePoint app or Teams without VPN dependency
