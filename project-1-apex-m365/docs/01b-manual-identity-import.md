# 01b — Manual Identity Import

> **This step is only required if Entra Cloud Sync could not be established.**
> If Cloud Sync is working and your AD users are syncing successfully, skip this page entirely and proceed to the next workstream.
> See [01a — Entra Cloud Sync](./01a-entra-cloud-sync.md) for context on why this path was taken in this lab.

---

## In Plain English

When Cloud Sync is working, user accounts flow automatically from Active Directory into Entra ID. When it cannot be established — due to network restrictions, ISP blocks, or lab constraints — the accounts need to be created in Entra ID directly. This page documents how to do that cleanly, using the existing AD as the source of truth for names, UPNs, and department data.

The result is identical from a Microsoft 365 perspective: 15 licensed users in Entra ID, with the correct UPNs, ready for email migration, SharePoint access, Intune enrolment, and Conditional Access policy.

The one difference from a synced environment is that these are **cloud-only identities** — they are not linked to the on-premises AD accounts. Password Hash Sync does not apply. Users will set a new password on first login.

---

## The End State

By the end of this workstream, the following will be in place:

| Component | State |
|---|---|
| Entra Connect | Installed on DC — agent registered, ISP restriction documented |
| 15 staff accounts | Created directly in Entra ID from AD export |
| UPNs | `firstname.lastname@qcbhomelab.online` — matching AD |
| Admin accounts | Two dedicated admin accounts — no named user doing admin |
| MFA | Enforced via Conditional Access for all users |
| Security defaults | Disabled — replaced by Conditional Access policies |
| Licences | Business Premium assigned to all 15 staff via group |

---

## Prerequisites

| Requirement | Detail |
|---|---|
| M365 tenant domain verified | `qcbhomelab.online` |
| Global Admin account | `m365admin@qcbhomelab.online` |
| Access to QCBHC-DC01 | To export AD user and group data |
| Microsoft Graph PowerShell module | Installed on DC or admin workstation |
| Business Premium licences | 15 available in the tenant |

---

## Overview

This workstream has three stages:

1. **Export** — Pull user and group data from Active Directory on QCBHC-DC01
2. **Import users** — Create the 15 accounts in Entra ID via the portal (bulk upload) and verify
3. **Import groups** — Recreate AD security groups in Entra ID and assign memberships via PowerShell

---

## Stage 1 — Export from Active Directory

Run the following on QCBHC-DC01 to export users and group memberships to CSV.

### Export Users

```powershell
Get-ADUser -Filter * -Properties DisplayName,EmailAddress,Department,Title,Office,MobilePhone |
Select-Object SamAccountName,DisplayName,EmailAddress,Department,Title,Office,MobilePhone |
Export-Csv C:\Users\Administrator\Desktop\ADUsers.csv -NoTypeInformation
```

### Export Groups and Members

```powershell
Get-ADGroup -Filter * | ForEach-Object {
    $group = $_.Name
    Get-ADGroupMember $_ | ForEach-Object {
        [PSCustomObject]@{
            Group  = $group
            Member = $_.SamAccountName
        }
    }
} | Export-Csv C:\Users\Administrator\Desktop\ADGroups.csv -NoTypeInformation
```

Review both files before proceeding. Check for:
- Any accounts with missing display names or UPNs
- System or service accounts that should not be imported (e.g. `krbtgt`, `ADToAADSyncServiceAccount`)
- Groups that are AD-internal and not needed in Entra ID (e.g. `Domain Admins`, `Schema Admins`)

---

## Stage 2 — Import Users into Entra ID

### Option A — Bulk Import via the Entra Portal (Recommended for Portfolio Evidence)

The Entra portal supports bulk user creation via a CSV template. This is the clearest method to document with screenshots.

#### Step 1 — Download the Microsoft Bulk Create Template

In the Entra portal ([https://entra.microsoft.com](https://entra.microsoft.com)), navigate to:

**Identity → Users → All Users → Bulk operations → Bulk create**

Download the CSV template provided on that screen.

> <img src="../screenshots/01b-manual-identity-import/01_bulk_create_template_download.png" width="75%" alt="Entra portal bulk create screen with template download" />
>
> Bulk create — download the CSV template

#### Step 2 — Populate the Template

The template requires specific column headers. Map your AD export to the template as follows:

| Template Column | Source |
|---|---|
| `Name [displayName]` | `DisplayName` from AD export |
| `User name [userPrincipalName]` | `firstname.lastname@qcbhomelab.online` |
| `Initial password` | Temporary password — users will be prompted to change on first login |
| `Block sign in` | `No` |
| `First name` | Derived from `DisplayName` |
| `Last name` | Derived from `DisplayName` |
| `Job title` | `Title` from AD export |
| `Department` | `Department` from AD export |
| `Usage location` | `GB` (or appropriate country code) |

> **Important:** The `Usage location` field is required before a licence can be assigned. Do not leave it blank.

Save the completed file as `bulk-create-users.csv`.

#### Step 3 — Upload and Run

Return to **Bulk create** in the portal and upload the completed CSV. The portal will validate the file before processing — fix any errors flagged before submitting.

> <img src="../screenshots/01b-manual-identity-import/02_bulk_create_upload.png" width="75%" alt="Bulk create CSV upload screen" />
>
> Uploading the completed user CSV

#### Step 4 — Monitor the Import

After submission, navigate to **Bulk operation results** to monitor progress. Each row will show as succeeded or failed with a reason.

> <img src="../screenshots/01b-manual-identity-import/03_bulk_create_results.png" width="75%" alt="Bulk operation results showing import status per user" />
>
> Bulk operation results

---

### Option B — PowerShell via Microsoft Graph

For environments where scripted creation is preferred, or where the portal bulk import has limitations, the Microsoft Graph PowerShell module can create users directly from the AD export CSV.

#### Install the Module

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

#### Connect to Graph

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"
```

#### Create Users from CSV

```powershell
$users = Import-Csv "C:\Users\Administrator\Desktop\ADUsers.csv"

foreach ($user in $users) {
    # Skip system accounts
    if ($user.SamAccountName -in @('krbtgt','Administrator','Guest','ADToAADSyncServiceAccount')) {
        Write-Host "Skipping: $($user.SamAccountName)"
        continue
    }

    # Build UPN from DisplayName
    $nameParts  = $user.DisplayName -split ' '
    $firstName  = $nameParts[0]
    $lastName   = $nameParts[-1]
    $upn        = "$($firstName.ToLower()).$($lastName.ToLower())@qcbhomelab.online"

    $params = @{
        DisplayName       = $user.DisplayName
        UserPrincipalName = $upn
        MailNickname      = "$($firstName.ToLower()).$($lastName.ToLower())"
        Department        = $user.Department
        JobTitle          = $user.Title
        UsageLocation     = "GB"
        AccountEnabled    = $true
        PasswordProfile   = @{
            ForceChangePasswordNextSignIn = $true
            Password                      = "TempP@ss2026!"
        }
    }

    try {
        New-MgUser @params
        Write-Host "Created: $upn"
    } catch {
        Write-Host "Failed: $upn — $($_.Exception.Message)"
    }
}
```

> **Note:** Change the temporary password to something appropriate for your environment. Users will be forced to change it on first sign-in.

---

## Stage 3 — Recreate Security Groups and Assign Members

### Create Groups in Entra ID

```powershell
$groups = Import-Csv "C:\Users\Administrator\Desktop\ADGroups.csv" |
    Select-Object -ExpandProperty Group -Unique |
    Where-Object { $_ -notin @('Domain Admins','Schema Admins','Enterprise Admins','Domain Users','Domain Computers') }

foreach ($groupName in $groups) {
    $params = @{
        DisplayName     = $groupName
        MailEnabled     = $false
        MailNickname    = ($groupName -replace '\s','')
        SecurityEnabled = $true
    }
    try {
        New-MgGroup @params
        Write-Host "Created group: $groupName"
    } catch {
        Write-Host "Failed group: $groupName — $($_.Exception.Message)"
    }
}
```

### Assign Group Memberships

```powershell
$memberships = Import-Csv "C:\Users\Administrator\Desktop\ADGroups.csv"

foreach ($entry in $memberships) {
    # Skip excluded groups
    if ($entry.Group -in @('Domain Admins','Schema Admins','Enterprise Admins','Domain Users','Domain Computers')) {
        continue
    }

    # Find the Entra group
    $group = Get-MgGroup -Filter "displayName eq '$($entry.Group)'" | Select-Object -First 1
    if (-not $group) {
        Write-Host "Group not found: $($entry.Group)"
        continue
    }

    # Find the Entra user — reconstruct UPN from SamAccountName
    $adUser = Get-ADUser -Identity $entry.Member -Properties DisplayName -ErrorAction SilentlyContinue
    if (-not $adUser) { continue }

    $nameParts = $adUser.DisplayName -split ' '
    $upn = "$($nameParts[0].ToLower()).$($nameParts[-1].ToLower())@qcbhomelab.online"

    $mgUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if (-not $mgUser) {
        Write-Host "User not found in Entra: $upn"
        continue
    }

    try {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $mgUser.Id
        Write-Host "Added $upn to $($entry.Group)"
    } catch {
        Write-Host "Failed: $upn → $($entry.Group) — $($_.Exception.Message)"
    }
}
```

---

## Stage 4 — Assign Licences

Licences are assigned via a group rather than per-user. This is the recommended approach — it is easier to manage and audit.

### Create a Licence Assignment Group

In the Entra portal, navigate to **Identity → Groups → New group** and create:

- **Group type:** Security
- **Group name:** `M365-BusinessPremium-Users`
- **Members:** Add all 15 staff accounts

> <img src="../screenshots/01b-manual-identity-import/04_licence_group_created.png" width="75%" alt="Licence assignment group created in Entra portal" />
>
> Licence assignment group

### Assign the Licence to the Group

Navigate to **Billing → Licences → Microsoft 365 Business Premium → Licensed groups → Assign**.

Select `M365-BusinessPremium-Users` and confirm. Entra ID will process licence assignments in the background — allow up to 5 minutes.

> <img src="../screenshots/01b-manual-identity-import/05_licence_assigned_to_group.png" width="75%" alt="Business Premium licence assigned to the group" />
>
> Licence assigned to group

---

## Validation

Confirm the following before proceeding to the next workstream:

```powershell
# Confirm all 15 users exist in Entra ID
Connect-MgGraph -Scopes "User.Read.All"
Get-MgUser -All | Where-Object { $_.UserPrincipalName -like "*@qcbhomelab.online" } |
    Select-Object DisplayName, UserPrincipalName, Department |
    Sort-Object DisplayName |
    Format-Table -AutoSize
```

```powershell
# Confirm group memberships
Get-MgGroup -All | Where-Object { $_.SecurityEnabled -eq $true } |
    ForEach-Object {
        $members = Get-MgGroupMember -GroupId $_.Id
        [PSCustomObject]@{
            Group       = $_.DisplayName
            MemberCount = $members.Count
        }
    } | Format-Table -AutoSize
```

Check the Entra portal for licence assignment status:

**Billing → Licences → Microsoft 365 Business Premium → Licensed users**

All 15 staff should appear with status **Active**.

> <img src="../screenshots/01b-manual-identity-import/06_users_licensed_confirmed.png" width="75%" alt="All 15 users showing as licensed in the portal" />
>
> All 15 users licensed and confirmed

---

## Notes for Real Engagements

- Cloud-only accounts created this way have no on-premises AD link. If Cloud Sync is later resolved, do not attempt to hard-match these accounts without careful planning — duplicate identities can result.
- The temporary password assigned during bulk creation should be communicated securely to each user. Consider enabling Self-Service Password Reset (SSPR) so users can set their own password before first login.
- `UsageLocation` must be set on every account before a licence can be assigned. This is a common bulk import failure point.
- System and built-in AD accounts (`krbtgt`, `Administrator`, `Guest`) must be excluded from the import. Review the AD export carefully before uploading.
- The `ADToAADSyncServiceAccount` created during Cloud Sync agent installation should also be excluded — it is a service account, not a staff identity.

---

## Summary

15 user accounts have been created in Entra ID directly from the Active Directory export, with UPNs matching the `qcbhomelab.online` tenant domain. Security groups have been recreated and memberships assigned. All 15 accounts have been licensed with Microsoft 365 Business Premium via group-based licensing.

This provides the same foundation as a Cloud Sync deployment for all downstream workstreams. The only functional difference is that these are cloud-only identities — password hash sync does not apply and users will set a new password on first login.

---

[← Back to README](../README.md)
