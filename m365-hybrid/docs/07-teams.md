[← 06 — SharePoint & OneDrive](06-sharepoint-onedrive.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [08 — Intune: Windows →](08-intune-windows.md)

---

# 07 — Microsoft Teams

## Introduction

Microsoft Teams is the communication and collaboration hub in Microsoft 365. It brings together chat, video meetings, file sharing, and app integrations into a single interface. For an organisation spread across London, New York, Hong Kong, and remote locations, Teams is the tool that makes it feel like everyone is working from the same building.

Teams is built on top of Microsoft 365 Groups and SharePoint. When you create a Team, Microsoft automatically creates a Microsoft 365 Group (for membership), a SharePoint site (for file storage), a shared mailbox, and a shared calendar in the background. This means Teams is not a standalone product — it is the front end for several integrated services working together.

Governance matters from day one. Without controls in place, users can create as many Teams as they like, leading to sprawl — dozens of abandoned or duplicate teams with no clear ownership. In this project, Team creation is restricted to administrators only.

---

## What We Are Building

| Team | Owner | Purpose |
|---|---|---|
| QCB — London | j.carter | London office collaboration |
| QCB — New York | m.reed | New York office collaboration |
| QCB — Hong Kong | d.wong | Hong Kong office collaboration |
| QCB Homelab Consultants *(auto-created by Microsoft)* | j.carter | Company-wide announcements |

Each location team has three channels: General (default), Projects, and IT Support.

---

## Prerequisites

- Microsoft 365 Business Premium licences assigned to all users (document 05)
- Users synced from Active Directory and visible in Entra ID (document 04)
- Microsoft Graph PowerShell Beta module installed (`Install-Module Microsoft.Graph.Beta`)

---

## Implementation Steps

### Step 1 — Restrict Team Creation

By default, any Microsoft 365 user can create a new Team. To prevent sprawl, this is locked down so only administrators can create Teams. This is controlled at the Microsoft 365 Group level — restricting group creation also restricts team creation.

Connect to Microsoft Graph and check whether a Group.Unified settings object already exists in the tenant:

```powershell
Connect-MgGraph -Scopes "Directory.ReadWrite.All"
Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Group.Unified" }
```

This will return either an object with an ID, or nothing. If the object does not exist, it needs to be created from the template first:

```powershell
$template = Get-MgBetaDirectorySettingTemplate | Where-Object { $_.DisplayName -eq "Group.Unified" }
$settings = @{ TemplateId = $template.Id; Values = $template.Values }
New-MgBetaDirectorySetting -BodyParameter $settings
```

Once the object exists, retrieve its ID and update the EnableGroupCreation value to false:

```powershell
$settingId = (Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq "Group.Unified" }).Id

$setting = Get-MgBetaDirectorySetting -DirectorySettingId $settingId

$params = @{
    Values = $setting.Values | ForEach-Object {
        if ($_.Name -eq "EnableGroupCreation") {
            @{ Name = "EnableGroupCreation"; Value = "false" }
        } else {
            @{ Name = $_.Name; Value = $_.Value }
        }
    }
}

Update-MgBetaDirectorySetting -DirectorySettingId $settingId -BodyParameter $params
```

Verify the change took effect:

```powershell
(Get-MgBetaDirectorySetting -DirectorySettingId $settingId).Values | Where-Object { $_.Name -eq "EnableGroupCreation" }
```

The output should show `EnableGroupCreation = false`.

> **Note:** The older `AzureAD` PowerShell module and its `Get-AzureADDirectorySetting` cmdlet are deprecated. The `Get-MgBetaDirectorySetting` cmdlet is in the `Microsoft.Graph.Beta` module, which must be installed separately from the standard Graph module: `Install-Module Microsoft.Graph.Beta`.

### Step 2 — Configure Teams Policies

**Teams policies**

Navigate to the Teams Admin Center at **admin.teams.microsoft.com → Teams → Teams policies** and click on **Global (Org-wide default)**. A settings panel opens on the right. Confirm or set the following:

| Setting | Value |
|---|---|
| Create private channels | On |
| Create shared channels | Off |

Click **Apply**.

**Meeting policies**

Navigate to **Meetings → Meeting policies → Global (Org-wide default)**. Scroll through and confirm the following are enabled — no changes should be needed on a fresh tenant:

| Setting | Value |
|---|---|
| Video conferencing | On |
| Screen sharing | Entire screen |
| Channel meeting scheduling | On |

**Messaging policies**

Navigate to **Messaging → Messaging policies → Global (Org-wide default)**. Confirm:

| Setting | Value |
|---|---|
| Delete sent messages | On |
| Edit sent messages | On |
| Chat | On |

No changes should be needed on a fresh tenant.

### Step 3 — Create the Location Teams

Teams are created from the Teams Admin Center, not the Teams client. The admin account does not require a Teams licence to create teams here.

Navigate to **Teams → Manage teams → Add**. A panel opens on the right. Create the three location teams:

**QCB — London**
- Name: `QCB — London`
- Description: `London office collaboration`
- Privacy: Private
- Owner: your admin account (j.carter will be added as owner separately)

**QCB — New York**
- Name: `QCB — New York`
- Description: `New York office collaboration`
- Privacy: Private

**QCB — Hong Kong**
- Name: `QCB — Hong Kong`
- Description: `Hong Kong office collaboration`
- Privacy: Private

After creating all three, click on each team in the list and navigate to the **Members** tab. Add the relevant location owner and set their role to Owner:

| Team | Owner |
|---|---|
| QCB — London | j.carter |
| QCB — New York | m.reed |
| QCB — Hong Kong | d.wong |

> **Note on the All Staff team:** Microsoft 365 automatically creates an org-wide team when a new tenant is set up, using the organisation name — in this environment that is **QCB Homelab Consultants**. This team includes all users automatically and does not need to be created manually. Add j.carter as an owner via the Members tab.

### Step 4 — Configure the All Staff Team for Announcements

The QCB Homelab Consultants team is used for company-wide announcements. To prevent general chat and keep it focused, restrict posting so that only owners can post in the General channel.

This is done from the Teams client, not the Admin Center. The admin account does not have a Teams licence, so sign in to the Teams client at **teams.cloud.microsoft** as a licensed user who is an owner of the team — in this environment, j.carter.

In the left panel, hover over **QCB Homelab Consultants**, click the **three dots (...)** next to the General channel, and select **Manage channel**. Under the **Moderation** section, select **Only owners can post messages**.

> **Note:** The Teams client URL has changed from teams.microsoft.com to **teams.cloud.microsoft**. Both work but the new URL is the current standard.

> **Note:** Channel moderation is now configured via **Manage channel → Settings → Moderation** using a simple radio button selection. The older interface had a separate moderation toggle — this has been replaced in the current Teams client.

### Step 5 — Add Channels to Location Teams

Each location team needs two additional channels beyond the default General channel. This is done from the Teams client as the team owner for each location.

Signed in as j.carter at teams.cloud.microsoft, hover over the team name in the left panel, click the **three dots (...)** next to the team name (not the channel), and select **Add channel**.

For each channel, set the channel type to **Standard** and the layout to **Threads**.

Add the following channels to each location team:

| Team | Channels |
|---|---|
| QCB — London | Projects, IT Support |
| QCB — New York | Projects, IT Support |
| QCB — Hong Kong | Projects, IT Support |

> For QCB — New York and QCB — Hong Kong, sign in as the respective team owner (m.reed and d.wong) to add channels, or add the channels from the Teams Admin Center under **Teams → Manage teams → [Team] → Channels → Add**.

### Step 6 — Verify Teams is Working

Sign in to the Teams client at **teams.cloud.microsoft** as a regular user and confirm:

- The user can see their location team and all its channels in the left panel
- The user can see the QCB Homelab Consultants team
- Posting a message in a location team channel works correctly
- The **Create team** option in the Teams client shows only **From group** — the **From scratch** and **From template** options are greyed out, confirming the group creation restriction is in effect

---

## What to Expect

Teams is ready to use across all locations. All users are automatically members of QCB Homelab Consultants and will see it in their Teams client immediately. Location team members see only their own location team by default. Files shared in Teams channels are stored in the corresponding SharePoint site, meaning they are also accessible from SharePoint and OneDrive. The governance controls ensure the environment stays clean and manageable as the organisation grows.

---

## Troubleshooting

**`Get-MgBetaDirectorySetting` is not recognised**
The Microsoft.Graph.Beta module is not installed. Run `Install-Module Microsoft.Graph.Beta -Scope CurrentUser -Force` before retrying.

**Admin account cannot access the Teams client**
The Global Admin account does not have a Teams licence assigned. Use a licensed user account (such as j.carter) to access the Teams client for tasks that require it, such as channel moderation and adding channels.

**Create team shows only "From group" option**
This is the expected behaviour after applying the group creation restriction — it confirms the policy is working correctly. Only administrators can create new Teams.

**Channel moderation option not visible**
Moderation settings are only visible to team owners. If the option is missing, confirm the signed-in user is an owner of the team, not just a member.

---

[← 06 — SharePoint & OneDrive](06-sharepoint-onedrive.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [08 — Intune: Windows →](08-intune-windows.md)
