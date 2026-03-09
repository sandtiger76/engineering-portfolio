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
| UPNs | `samaccountname@qcbhomelab.online` — matching AD |
| Security groups | 6 custom groups recreated with correct memberships |
| Licences | Business Premium assigned to all 15 staff via group |

---

## Prerequisites

| Requirement | Detail |
|---|---|
| M365 tenant domain verified | `qcbhomelab.online` |
| Global Admin account | `m365admin@qcbhomelab.online` |
| Microsoft Graph PowerShell module | Installed on DC or admin workstation |
| Business Premium licences | 15 available in the tenant |

---

## Source Data

The following was exported from Active Directory on QCBHC-DC01 and forms the source of truth for this import.

### Staff Accounts

| SAM Account | Display Name | Department | Title |
|---|---|---|---|
| `j.hartley` | James Hartley | Management | Managing Director |
| `s.mitchell` | Sarah Mitchell | Design | Senior IT Consultant |
| `t.bradley` | Tom Bradley | Design | Systems Engineer |
| `l.simmons` | Laura Simmons | Design | IT Consultant |
| `d.fletcher` | Daniel Fletcher | Design | Network Engineer |
| `r.wong` | Rachel Wong | Design | IT Consultant |
| `e.clarke` | Emma Clarke | Projects | Project Manager |
| `m.reid` | Marcus Reid | Projects | Project Manager |
| `s.turner` | Sophie Turner | Projects | Project Coordinator |
| `o.nash` | Oliver Nash | Projects | Project Coordinator |
| `p.sharma` | Priya Sharma | Projects | Project Support Analyst |
| `d.owen` | David Owen | Admin | Office Administrator |
| `c.morton` | Claire Morton | Admin | Finance Administrator |
| `b.ashworth` | Ben Ashworth | Admin | HR Coordinator |
| `k.doyle` | Karen Doyle | Admin | Receptionist |

### Security Groups

| Group | Members |
|---|---|
| `GRP-Management` | `j.hartley` |
| `GRP-Design` | `s.mitchell`, `t.bradley`, `l.simmons`, `d.fletcher`, `r.wong` |
| `GRP-Projects` | `e.clarke`, `m.reid`, `s.turner`, `o.nash`, `p.sharma` |
| `GRP-Admin` | `d.owen`, `c.morton`, `b.ashworth`, `k.doyle` |
| `GRP-AllStaff` | All 15 staff |
| `GRP-CADUsers` | `s.mitchell`, `t.bradley`, `l.simmons`, `d.fletcher`, `r.wong` |

---

## Stage 1 — Import Users

### Option A — Bulk Import via the Entra Portal

The Entra portal supports bulk user creation via CSV. This is the most straightforward method and produces clear screenshot evidence.

#### Step 1 — Download the Bulk Create Template

In the Entra portal ([https://entra.microsoft.com](https://entra.microsoft.com)), navigate to:

**Identity → Users → All Users → Bulk operations → Bulk create**

Download the CSV template provided on that screen.

> <img src="../screenshots/01b-manual-identity-import/01_bulk_create_template_download.png" width="75%" alt="Entra portal bulk create screen with template download" />
>
> Bulk create — download the CSV template

#### Step 2 — Populate the Template

The `EmailAddress` field is not populated in AD for these accounts. UPNs are constructed directly from the SAM account name in the format `samaccount@qcbhomelab.online`.

Populate one row per user as follows:

| displayName | userPrincipalName | initialPassword | blockSignIn | firstName | lastName | jobTitle | department | usageLocation |
|---|---|---|---|---|---|---|---|---|
| James Hartley | j.hartley@qcbhomelab.online | TempP@ss2026! | No | James | Hartley | Managing Director | Management | GB |
| Sarah Mitchell | s.mitchell@qcbhomelab.online | TempP@ss2026! | No | Sarah | Mitchell | Senior IT Consultant | Design | GB |
| Tom Bradley | t.bradley@qcbhomelab.online | TempP@ss2026! | No | Tom | Bradley | Systems Engineer | Design | GB |
| Laura Simmons | l.simmons@qcbhomelab.online | TempP@ss2026! | No | Laura | Simmons | IT Consultant | Design | GB |
| Daniel Fletcher | d.fletcher@qcbhomelab.online | TempP@ss2026! | No | Daniel | Fletcher | Network Engineer | Design | GB |
| Rachel Wong | r.wong@qcbhomelab.online | TempP@ss2026! | No | Rachel | Wong | IT Consultant | Design | GB |
| Emma Clarke | e.clarke@qcbhomelab.online | TempP@ss2026! | No | Emma | Clarke | Project Manager | Projects | GB |
| Marcus Reid | m.reid@qcbhomelab.online | TempP@ss2026! | No | Marcus | Reid | Project Manager | Projects | GB |
| Sophie Turner | s.turner@qcbhomelab.online | TempP@ss2026! | No | Sophie | Turner | Project Coordinator | Projects | GB |
| Oliver Nash | o.nash@qcbhomelab.online | TempP@ss2026! | No | Oliver | Nash | Project Coordinator | Projects | GB |
| Priya Sharma | p.sharma@qcbhomelab.online | TempP@ss2026! | No | Priya | Sharma | Project Support Analyst | Projects | GB |
| David Owen | d.owen@qcbhomelab.online | TempP@ss2026! | No | David | Owen | Office Administrator | Admin | GB |
| Claire Morton | c.morton@qcbhomelab.online | TempP@ss2026! | No | Claire | Morton | Finance Administrator | Admin | GB |
| Ben Ashworth | b.ashworth@qcbhomelab.online | TempP@ss2026! | No | Ben | Ashworth | HR Coordinator | Admin | GB |
| Karen Doyle | k.doyle@qcbhomelab.online | TempP@ss2026! | No | Karen | Doyle | Receptionist | Admin | GB |

> **Important:** `usageLocation` must be populated on every row — Entra ID will not assign a licence to any account where this field is blank.

Save as `bulk-create-users.csv` and upload via the **Bulk create** screen.

> <img src="../screenshots/01b-manual-identity-import/02_bulk_create_upload.png" width="75%" alt="Bulk create CSV upload screen" />
>
> Uploading the completed user CSV

#### Step 3 — Monitor Results

Navigate to **Bulk operation results** to confirm all 15 rows succeeded.

> <img src="../screenshots/01b-manual-identity-import/03_bulk_create_results.png" width="75%" alt="Bulk operation results showing all 15 users imported" />
>
> Bulk operation results — all 15 succeeded

---

### Option B — PowerShell via Microsoft Graph

For a fully scripted approach, the following creates all 15 users directly from the source data.

```powershell
# Install and connect
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Connect-MgGraph -Scopes "User.ReadWrite.All"

$users = @(
    @{ SAM="j.hartley";  Display="James Hartley";   First="James";   Last="Hartley";   Dept="Management"; Title="Managing Director" },
    @{ SAM="s.mitchell"; Display="Sarah Mitchell";  First="Sarah";   Last="Mitchell";  Dept="Design";     Title="Senior IT Consultant" },
    @{ SAM="t.bradley";  Display="Tom Bradley";     First="Tom";     Last="Bradley";   Dept="Design";     Title="Systems Engineer" },
    @{ SAM="l.simmons";  Display="Laura Simmons";   First="Laura";   Last="Simmons";   Dept="Design";     Title="IT Consultant" },
    @{ SAM="d.fletcher"; Display="Daniel Fletcher"; First="Daniel";  Last="Fletcher";  Dept="Design";     Title="Network Engineer" },
    @{ SAM="r.wong";     Display="Rachel Wong";     First="Rachel";  Last="Wong";      Dept="Design";     Title="IT Consultant" },
    @{ SAM="e.clarke";   Display="Emma Clarke";     First="Emma";    Last="Clarke";    Dept="Projects";   Title="Project Manager" },
    @{ SAM="m.reid";     Display="Marcus Reid";     First="Marcus";  Last="Reid";      Dept="Projects";   Title="Project Manager" },
    @{ SAM="s.turner";   Display="Sophie Turner";   First="Sophie";  Last="Turner";    Dept="Projects";   Title="Project Coordinator" },
    @{ SAM="o.nash";     Display="Oliver Nash";     First="Oliver";  Last="Nash";      Dept="Projects";   Title="Project Coordinator" },
    @{ SAM="p.sharma";   Display="Priya Sharma";    First="Priya";   Last="Sharma";    Dept="Projects";   Title="Project Support Analyst" },
    @{ SAM="d.owen";     Display="David Owen";      First="David";   Last="Owen";      Dept="Admin";      Title="Office Administrator" },
    @{ SAM="c.morton";   Display="Claire Morton";   First="Claire";  Last="Morton";    Dept="Admin";      Title="Finance Administrator" },
    @{ SAM="b.ashworth"; Display="Ben Ashworth";    First="Ben";     Last="Ashworth";  Dept="Admin";      Title="HR Coordinator" },
    @{ SAM="k.doyle";    Display="Karen Doyle";     First="Karen";   Last="Doyle";     Dept="Admin";      Title="Receptionist" }
)

foreach ($user in $users) {
    $upn = "$($user.SAM)@qcbhomelab.online"
    $params = @{
        DisplayName       = $user.Display
        GivenName         = $user.First
        Surname           = $user.Last
        UserPrincipalName = $upn
        MailNickname      = $user.SAM
        Department        = $user.Dept
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

---

## Stage 2 — Recreate Security Groups

### Create the Groups

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All"

$groups = @("GRP-Management","GRP-Design","GRP-Projects","GRP-Admin","GRP-AllStaff","GRP-CADUsers")

foreach ($groupName in $groups) {
    $params = @{
        DisplayName     = $groupName
        MailEnabled     = $false
        MailNickname    = $groupName
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
$groupMemberships = @{
    "GRP-Management" = @("j.hartley")
    "GRP-Design"     = @("s.mitchell","t.bradley","l.simmons","d.fletcher","r.wong")
    "GRP-Projects"   = @("e.clarke","m.reid","s.turner","o.nash","p.sharma")
    "GRP-Admin"      = @("d.owen","c.morton","b.ashworth","k.doyle")
    "GRP-AllStaff"   = @("j.hartley","s.mitchell","t.bradley","l.simmons","d.fletcher",
                         "r.wong","e.clarke","m.reid","s.turner","o.nash","p.sharma",
                         "d.owen","c.morton","b.ashworth","k.doyle")
    "GRP-CADUsers"   = @("s.mitchell","t.bradley","l.simmons","d.fletcher","r.wong")
}

foreach ($groupName in $groupMemberships.Keys) {
    $group = Get-MgGroup -Filter "displayName eq '$groupName'" | Select-Object -First 1
    if (-not $group) {
        Write-Host "Group not found: $groupName"
        continue
    }
    foreach ($sam in $groupMemberships[$groupName]) {
        $upn = "$sam@qcbhomelab.online"
        $mgUser = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
        if (-not $mgUser) {
            Write-Host "User not found: $upn"
            continue
        }
        try {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $mgUser.Id
            Write-Host "Added $upn to $groupName"
        } catch {
            Write-Host "Failed: $upn → $groupName — $($_.Exception.Message)"
        }
    }
}
```

---

## Stage 3 — Assign Licences

Licences are assigned via a group rather than per-user. This is the recommended approach — easier to manage and audit.

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

Select `M365-BusinessPremium-Users` and confirm. Allow up to 5 minutes for Entra ID to process assignments.

> <img src="../screenshots/01b-manual-identity-import/05_licence_assigned_to_group.png" width="75%" alt="Business Premium licence assigned to the group" />
>
> Licence assigned to group

---

## Validation

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
Get-MgGroup -All | Where-Object { $_.DisplayName -like "GRP-*" } |
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

- Cloud-only accounts have no on-premises AD link. If Cloud Sync is later resolved, do not attempt to hard-match these accounts without careful planning — duplicate identities can result.
- The temporary password should be communicated securely to each user. Consider enabling Self-Service Password Reset (SSPR) so users can set their own password before first login.
- `UsageLocation` must be set on every account before a licence can be assigned — this is the most common bulk import failure point.
- System accounts (`krbtgt`, `Administrator`, `Guest`) and service accounts (`ADToAADSyncServiceAccount`, `pGMSA_xxxxxxxx$`) must be excluded from the import.
- Built-in AD groups (`Domain Admins`, `Domain Users`, `Schema Admins` etc.) should not be recreated in Entra ID — only the 6 custom `GRP-` groups are relevant.

---

## Summary

15 user accounts have been created in Entra ID directly from the Active Directory export, with UPNs in the format `samaccount@qcbhomelab.online`. The 6 custom security groups have been recreated with correct memberships. All 15 accounts have been licensed with Microsoft 365 Business Premium via group-based licensing.

This provides the same foundation as a Cloud Sync deployment for all downstream workstreams. The only functional difference is that these are cloud-only identities — password hash sync does not apply and users will set a new password on first login.

---

[← Back to README](../README.md)
