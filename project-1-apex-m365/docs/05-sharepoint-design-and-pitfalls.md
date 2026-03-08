# 05 — SharePoint Online: Design Decisions & Migration Pitfalls

## In Plain English

SharePoint Online is where the company's shared files live in Microsoft 365. Think of it as
a replacement for the shared network drive that staff currently access in the office — except
it works from anywhere, on any device, with no VPN required.

Before any files are moved across, decisions need to be made about how SharePoint is
structured. Getting this wrong is easy and expensive to fix after the fact — like building
the rooms in a house before deciding where the walls go. This page explains how to design
the structure correctly, documents the technical limits that catch organisations out, and
shares real-world migration problems and how to avoid them.

---

## Why This Matters

SharePoint Online has significant differences from a traditional file server that affect how
it should be designed and how data should be migrated into it. Organisations that treat it
as a direct replacement for a network drive — moving files across without any design
consideration — routinely encounter problems with file name restrictions, permission
complexity, view failures on large folders, and sync client behaviour that can overwrite
other users' work.

Understanding these constraints before migration begins is the difference between a smooth
cutover and a recovery exercise.

---

## Overview

SharePoint Online is not a file server. Treating it like one is the single most common cause of
migration problems, user frustration, and data incidents. Before a single file is moved, the
information architecture must be designed, the limits understood, and the risks identified.

This page covers three things:

1. SharePoint Online limits that directly affect migration planning
2. Real-world migration pitfalls — including how to identify and resolve them before they cause
   problems
3. Design decisions for the QCB Homelab Consultants migration, with rationale

The limits and pitfalls documented here are drawn from production migration experience. They apply
regardless of organisation size — an SME with 50GB of data can hit the same character limit
problems as an enterprise with 50TB.

---

## SharePoint Online Limits Reference

Understanding the platform limits before migration prevents the most common failure modes.
These limits are subject to change as Microsoft evolves the platform — always verify against
current Microsoft documentation before a production migration.

### Storage and Scale Limits

| Limit | Value | Notes |
|---|---|---|
| Site collection storage | 25 TB | Per site collection — effectively unlimited for SME |
| Items per library | 30 million | No practical limit for most organisations |
| Individual file size | 250 GB | Covers virtually all business file types |
| Sync limit | 300,000 items | Across all libraries synced to a single device |
| Single move/copy operation | 100 GB or 30,000 files | Whichever limit is hit first |

### The 5,000 Item View Threshold — The Most Commonly Hit Limit

The view threshold is the limit most likely to cause visible problems in a real migration, and
the one most commonly misunderstood.

**What it is:** SharePoint Online will not display more than 5,000 items in a single view without
proper indexing or filtering. This does not prevent storage — a library can hold 30 million items.
It prevents *display* of unfiltered views beyond 5,000 items.

**What it causes:**
- List views return an error rather than displaying results
- Search functionality within the library degrades
- Filtered views and indexed columns work correctly — but must be configured

**How to avoid it:**
- Design folder structures that keep individual folder contents below 5,000 items
- Add indexed columns to large libraries before they exceed the threshold
- Use filtered views rather than flat unfiltered views for large libraries
- Avoid flat library structures — use meaningful folder hierarchy

> **Production experience:** This limit was encountered during a large-scale migration where
> flat folder structures were migrated directly from SMB shares. Individual folders containing
> years of accumulated project files exceeded 5,000 items, causing view failures immediately
> after migration. Remediating after the fact required restructuring content that users were
> already accessing — far more disruptive than designing for it upfront.

### URL Path Length

| Limit | Value | Recommendation |
|---|---|---|
| Maximum decoded URL path | 400 characters | Hard limit — files exceeding this will fail to migrate |
| Recommended maximum | 260 characters | Avoids Windows path length limitations on synced devices |

**What the path includes:** Everything from the site name to the file name.

```
https://tenant.sharepoint.com/sites/company/Shared Documents/Projects/PROJ001/Correspondence/2026-01-05_Very_Long_Filename.docx
```

Every component — site name, library name, folder path, file name, file extension — contributes
to the total path length. Deep folder hierarchies combined with long file names are the most
common cause of path length failures.

**How to avoid it:**
- Audit file paths in the source environment before migration
- SPMT and ShareGate both include pre-migration scan functions that flag path length violations
- Shorten deep folder hierarchies where possible during the information architecture design phase
- Establish a file naming convention that avoids unnecessarily long file names

---

## Migration Pitfalls — Characters, Names, and Paths

### Invalid Characters

SharePoint Online and OneDrive do not permit the following characters in file or folder names:

```
~ # % & * { } \ : < > ? / | "
```

Additionally:
- Leading or trailing spaces in folder or file names are not permitted
- The characters `゛` and `ဧ` cannot be the first character of a folder name
- Temporary file prefixes such as `~$` are blocked

**Practical impact:** SMB file shares have far more permissive naming rules than SharePoint.
Files and folders that have existed on a file server for years — with names that were perfectly
valid on NTFS — will fail to migrate if they contain any of the above characters.

**How to handle it:**
- Run a pre-migration scan using SPMT or ShareGate before the live migration
- SPMT will automatically replace invalid characters with underscores during migration
- Review the scan report and communicate any automatic renames to affected users before migration
- Establish a file naming policy as part of the user adoption communication

### Reserved Names

The following names are blocked in SharePoint and cannot be used as file or folder names:

| Category | Reserved names |
|---|---|
| System folders | `_vti_` (any name containing this string) |
| SharePoint internals | `forms` |
| Windows reserved names | `CON`, `PRN`, `AUX`, `NUL` |
| COM ports | `COM0` through `COM9` |
| LPT ports | `LPT0` through `LPT9` |

These are Windows operating system reserved device names that carry over as restrictions into
SharePoint and OneDrive. They are rarely encountered but will cause migration failures when they
are.

---

## Permissions — The Hidden Complexity

### Unique Permissions Limit

| Limit | Value | Notes |
|---|---|---|
| Unique permission sets per library or list | 50,000 | Hard limit — cannot be bypassed |

**What this means in practice:** Every item that has permissions set differently from its parent
counts as a unique permission set. A library where individual files have been shared with specific
people — common in environments where users have managed their own sharing — can accumulate
thousands of unique permission sets.

**Why it matters for migration:** A like-for-like NTFS permission migration using SPMT will
attempt to recreate file-level permissions in SharePoint. In environments where NTFS permissions
have been applied at the file level rather than the folder level, this can rapidly approach or
exceed the 50,000 limit.

**Recommended approach:**
- Audit NTFS permissions before migration — identify where permissions are applied at file level
  rather than folder level
- Design SharePoint permissions at the library or folder level, not the file level
- Use SharePoint permission levels mapped to security groups rather than individual user
  permissions
- Accept that a like-for-like permission migration is rarely the right answer — use the migration
  as an opportunity to simplify the permissions model

### File-Level vs Folder-Level Permissions

SharePoint supports permissions at site, library, folder, and individual file level. Supporting
all four creates management complexity that compounds over time.

**Best practice:** Design permissions at library or folder level. Apply permissions via security
groups, not individual users. This mirrors the NTFS model that on-premises administrators are
familiar with, keeps the unique permissions count manageable, and makes ongoing administration
straightforward.

| Permission level | SharePoint equivalent | Applied via |
|---|---|---|
| Full Control | Full Control | Security group |
| Modify | Edit | Security group |
| Read & Execute | Read | Security group |
| No access | Remove from group / explicit deny (use sparingly) | Security group |

---

## The Sync Overwrite Problem

This is the most operationally dangerous issue in a SharePoint Online deployment and one that
is frequently underestimated.

### What Happens

A user syncs a SharePoint document library to their local PC via the OneDrive sync client.
They work offline — on a train, at a client site, with poor connectivity. During that time,
colleagues update files in the shared library. When the user reconnects, the sync client
attempts to reconcile local and cloud versions.

In the worst case scenario: a user has a local copy of the entire library from before major
changes were made. The sync client uploads their local versions, overwriting the current
cloud versions for every other user.

> **Production experience:** This scenario was encountered during a migration where a user had
> synced a large project library before going on annual leave. On return, the sync client
> uploaded several thousand files from a two-week-old local cache, overwriting current versions
> for the entire team. SharePoint version history allowed recovery — but the recovery process
> was time-consuming and caused significant disruption. The near-miss highlighted that version
> history and sync client behaviour must be communicated to users before go-live, not after.

### Why It Matters

- Affects all users sharing the library simultaneously
- Recovery is possible via version history — but time-consuming at scale
- Users are often unaware it has happened until colleagues report missing changes
- It does not require any malicious intent — it is a normal sync client behaviour

### How to Mitigate It

**Technical controls:**

| Control | How to implement | Effect |
|---|---|---|
| Version history | Enable on all libraries — minimum 500 major versions | Provides recovery point for overwritten files |
| Co-authoring | Office files support real-time co-authoring — encourage use | Reduces need for local copies |
| Sync client policies via Intune | Configure OneDrive sync client via Intune policy | Controls sync behaviour at fleet level |
| Files On-Demand | Enable via Intune/Group Policy | Files appear locally but are not downloaded until opened — reduces sync volume |
| Selective sync | Train users to sync only what they need | Reduces the volume of files at risk |

**OneDrive Files On-Demand** is the most effective technical control. Files appear in File
Explorer as if they are local — users can navigate and open them normally — but they are only
downloaded when accessed. This eliminates the stale local cache problem because there is no
full local copy to upload.

```powershell
# Enable Files On-Demand via registry (deploy via Intune or GPO)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" `
    -Name "FilesOnDemandEnabled" -Value 1 -Type DWord
```

**User communication controls:**

The technical controls reduce risk but cannot eliminate it entirely. Users must understand:

- SharePoint is not a personal file store — changes affect everyone
- Syncing large libraries to a laptop before travel requires awareness of the sync behaviour
  on return
- Version history exists and how to use it to recover previous versions
- Who to contact if they suspect a sync conflict has caused data loss

This should be covered in the user adoption communication before go-live — not discovered
through an incident afterwards.

---

## SharePoint Information Architecture — QCB Homelab Consultants

### Design Approach for an SME

For a 15-person organisation with a modest data volume, the information architecture should
prioritise simplicity and maintainability over elaborate structure. The goal is a design that
staff can navigate intuitively and that an administrator can manage without SharePoint expertise.

**Guiding principles:**
- One site collection for company content — no hub site complexity at this scale
- Document libraries map to business functions, not to the previous folder structure
- Permissions applied at library level via security groups — not at file level
- Metadata used sparingly — only where it adds genuine value over folder structure
- External sharing disabled at tenant level — re-enabled per library only when explicitly required

### Recommended Site Structure

```
SharePoint — QCB Homelab Consultants (Site Collection)
│
├── 📚 Projects (Document Library)
│   ├── PROJ001_Network_Infrastructure
│   │   ├── Diagrams
│   │   ├── Correspondence
│   │   └── Reports
│   └── PROJ002_Cloud_Migration
│       ├── Diagrams
│       ├── Correspondence
│       └── Reports
│
├── 📚 Technical Library (Document Library)
│   ├── Standard_Configs
│   └── Templates
│
├── 📚 Company Templates (Document Library)
│
└── 📚 Administration (Document Library)
    ├── HR
    └── Finance
```

**Why a single site collection:**
- 15 users with a single office and shared projects do not benefit from the complexity of
  hub sites or multiple site collections
- Simpler permission management — site-level groups cascade to all libraries
- Easier to administer and support
- Can always be expanded to hub site architecture if the organisation grows

### Permission Mapping — AD Groups to SharePoint

| SharePoint Library | AD Group | Permission Level |
|---|---|---|
| Projects | GRP-AllStaff | Read |
| Projects | GRP-Design | Edit |
| Projects | GRP-Projects | Edit |
| Technical Library | GRP-AllStaff | Read |
| Technical Library | GRP-CADUsers | Edit |
| Company Templates | GRP-AllStaff | Read |
| Company Templates | GRP-Management | Edit |
| Administration | GRP-Admin | Edit |
| Administration | GRP-Management | Read |
| Administration | GRP-AllStaff | No access |

> **Note:** Administration breaks inheritance — GRP-AllStaff explicitly has no access.
> This mirrors the NTFS permission design on the source SMB share.

### Versioning Configuration

Applied to all document libraries:

| Setting | Value | Reason |
|---|---|---|
| Version history | Enabled | Recovery from accidental overwrites |
| Major versions to retain | 500 | Sufficient history without excessive storage |
| Require check out | No | Unnecessary friction for SME — co-authoring handles concurrency |

### External Sharing

| Setting | Value |
|---|---|
| Tenant-level external sharing | Disabled |
| Per-library external sharing | Disabled on all libraries |

External sharing is disabled at tenant level and not enabled on any library. QCB Homelab
Consultants handles client-confidential documents — there is no legitimate use case for
anonymous or external sharing of company content. If a specific need arises, it is enabled
on a named library with an expiry date and owner accountability.

---

## Pre-Migration Checklist

Before SPMT runs against the source file shares, complete the following:

- [ ] Run SPMT pre-migration scan against `\\QCBHC-DC01\Company` — review scan report
- [ ] Identify and resolve any path length violations (files exceeding 400 characters)
- [ ] Identify any invalid characters in file or folder names — document planned replacements
- [ ] Identify any reserved name conflicts
- [ ] Confirm no individual folder contains more than 5,000 items
- [ ] Document current NTFS permission structure — confirm SharePoint permission mapping
- [ ] Confirm version history is enabled on all target libraries before migration runs
- [ ] Confirm Files On-Demand policy is configured via Intune before users begin syncing
- [ ] Brief users on sync client behaviour and version history recovery before go-live

---

*Previous: [04 — OneDrive & Home Folders →](./04-onedrive-home-folders.md)*
*Next: [06 — Microsoft Teams →](./06-teams-setup.md)*
