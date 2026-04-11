[← 05 — Microsoft 365 & Exchange Online](05-m365-exchange.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [07 — Microsoft Teams →](07-teams.md)

---

# 06 — SharePoint & OneDrive

## Introduction

When organisations move to Microsoft 365, one of the most significant changes is what happens to file storage. Traditionally, files lived on a file server in the office — a physical or virtual server with shared folders that users mapped as network drives. Microsoft 365 replaces this with two cloud services: OneDrive for personal files and SharePoint for shared team files.

OneDrive is each user's personal file storage in the cloud. Think of it as a My Documents folder that follows the user anywhere, syncs to their devices, and is protected by Microsoft's infrastructure rather than a server in a cupboard.

SharePoint is the shared collaboration layer. Each team or office location gets its own SharePoint site with a document library that all members can access and collaborate on. Files stored there are available from any device, with built-in versioning, access control, and co-authoring.

In this project, the migration path is straightforward: user home folders move to OneDrive, and shared location folders move to SharePoint team sites.

---

## What We Are Building

| Source (Legacy) | Destination |
|---|---|
| C:\Data\Home\j.carter | OneDrive for Business — James Carter |
| C:\Data\Home\o.brown | OneDrive for Business — Olivia Brown |
| C:\Data\Group\London | SharePoint — London Team Site |
| C:\Data\Group\NewYork | SharePoint — New York Team Site |
| C:\Data\Group\HongKong | SharePoint — Hong Kong Team Site |

---

## Implementation Steps

### Step 1 — Access the SharePoint Admin Center

Log in to the Microsoft 365 Admin Center at admin.microsoft.com and navigate to SharePoint under the Admin Centers section. This opens the SharePoint Admin Center where you manage all sites.

### Step 2 — Create Team Sites

Create a SharePoint Team Site for each office location. A Team Site includes a document library, a SharePoint page, and an associated Microsoft 365 Group that controls membership.

In the SharePoint Admin Center:

1. Go to Sites → Active sites → Create
2. Select Team site
3. Create the following three sites:

| Site name | Site address | Owner |
|---|---|---|
| QCB London | london.sharepoint.com/sites/qcb-london | j.carter |
| QCB New York | sharepoint.com/sites/qcb-newyork | m.reed |
| QCB Hong Kong | sharepoint.com/sites/qcb-hongkong | d.wong |

Add the relevant users as members of each site after creation.

### Step 3 — Configure SharePoint Sharing Settings

By default, SharePoint may allow external sharing. For this environment, external sharing should be restricted to prevent company data being shared with personal accounts.

In the SharePoint Admin Center, go to Policies → Sharing and set:

- SharePoint sharing level: Only people in your organisation
- OneDrive sharing level: Only people in your organisation

This can be relaxed later on a per-site basis if specific external collaboration is needed.

### Step 4 — Create Dummy Data to Migrate

On QCBHC-DC01, create a realistic folder structure that represents what a file server would contain. This gives us something meaningful to migrate.

```powershell
# 06-Create-FileServerData.ps1
# Creates a simulated legacy file server structure on the DC

$users = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan")
$locations = @("London","NewYork","HongKong")

# Create user home folders
foreach ($user in $users) {
    $path = "C:\Data\Home\$user"
    New-Item -ItemType Directory -Path $path -Force | Out-Null

    # Create some dummy files
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

### Step 5 — Migrate Files Using SharePoint Migration Tool

Microsoft provides a free tool called the SharePoint Migration Tool (SPMT) for moving files from file servers and local folders to SharePoint and OneDrive.

Download SPMT from: https://www.microsoft.com/en-us/download/details.aspx?id=103627

Install it on QCBHC-DC01 and run it. Sign in with a Global Administrator account.

For each user's home folder:
1. Select File share as the source
2. Browse to `C:\Data\Home\<username>`
3. Set the destination to that user's OneDrive for Business
4. Run the migration

For each shared location folder:
1. Select File share as the source
2. Browse to `C:\Data\Group\<Location>`
3. Set the destination to the corresponding SharePoint team site document library
4. Run the migration

### Step 6 — Verify the Migration

Log in to Outlook on the web as one of the users. Click the waffle menu (9 dots) in the top left and select OneDrive. Confirm the migrated files are visible.

Navigate to one of the SharePoint team sites and confirm the shared files appear in the Documents library.

### Step 7 — Configure OneDrive Sync on Client Devices

On each Windows device, the OneDrive sync client should be configured to sync the user's OneDrive and any SharePoint libraries they need offline access to.

This is handled through Intune policy in document 08, which silently configures OneDrive sync as part of device enrolment.

---

[← 05 — Microsoft 365 & Exchange Online](05-m365-exchange.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [07 — Microsoft Teams →](07-teams.md)
