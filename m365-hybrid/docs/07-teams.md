[← 06 — SharePoint & OneDrive](06-sharepoint-onedrive.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [08 — Intune: Windows →](08-intune-windows.md)

---

# 07 — Microsoft Teams

## Introduction

Microsoft Teams is the communication and collaboration hub in Microsoft 365. It brings together chat, video meetings, file sharing, and app integrations into a single interface. For an organisation spread across London, New York, Hong Kong, and remote locations, Teams is the tool that makes it feel like everyone is working from the same building.

Teams is built on top of Microsoft 365 Groups and SharePoint. When you create a Team, Microsoft automatically creates a Microsoft 365 Group (for membership), a SharePoint site (for file storage), a shared mailbox, and a shared calendar in the background. This means Teams is not a standalone product — it is the front end for several integrated services working together.

Governance matters from day one. Without controls in place, users can create as many Teams as they like, leading to sprawl — dozens of abandoned or duplicate teams with no clear ownership. In this project, Team creation is restricted to administrators only.

---

## What We Are Building

| Team | Members | Purpose |
|---|---|---|
| QCB — London | j.carter, o.brown | London office collaboration |
| QCB — New York | m.reed, s.miller | New York office collaboration |
| QCB — Hong Kong | d.wong, e.chan | Hong Kong office collaboration |
| QCB — All Staff | All users | Company-wide announcements |

---

## Implementation Steps

### Step 1 — Restrict Team Creation

By default, any Microsoft 365 user can create a new Team. To prevent sprawl, restrict this so only members of a specific security group can create Teams.

This is done by restricting Microsoft 365 Group creation, which controls Team creation at the source.

Open the Microsoft Teams Admin Center at admin.teams.microsoft.com. Then run the following PowerShell to restrict group creation to administrators only:

```powershell
# Connect to Entra ID
Connect-AzureAD

# Get the tenant settings
$settingsObjectID = (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).Id

if (!$settingsObjectID) {
    $template = Get-AzureADDirectorySettingTemplate | Where-Object { $_.DisplayName -eq "Group.Unified" }
    $settings = $template.CreateDirectorySetting()
    New-AzureADDirectorySetting -DirectorySetting $settings
    $settingsObjectID = (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).Id
}

$settings = Get-AzureADDirectorySetting -Id $settingsObjectID
$settings["EnableGroupCreation"] = $false
Set-AzureADDirectorySetting -Id $settingsObjectID -DirectorySetting $settings
```

### Step 2 — Configure Teams Policies in the Admin Center

In the Microsoft Teams Admin Center:

Navigate to Teams → Teams policies and confirm or create a policy that:
- Allows users to create private channels: Yes
- Allows users to create shared channels: No (for simplicity in this lab)

Navigate to Meetings → Meeting policies and confirm the Global policy allows standard meeting features including video, screen sharing, and recording.

Navigate to Messaging policies and confirm users can delete their own messages and use rich text formatting.

### Step 3 — Create the Teams

Create each Team from the Teams Admin Center or from the Teams client while signed in as a Global Administrator.

In the Teams client:
1. Click Teams in the left sidebar
2. Click Join or create a team → Create a team
3. Select From scratch → Private
4. Name the team and add the relevant members

Create the four teams listed in the table above. For QCB — All Staff, set the team type to Org-wide if prompted — this automatically includes all users in the organisation.

### Step 4 — Configure the All Staff Team

The All Staff team should be used for announcements only. Restrict posting so that only owners can post in the General channel:

1. Open the QCB — All Staff team
2. Click the three dots next to the General channel → Manage channel
3. Under Channel moderation, turn on moderation
4. Set Who can post messages to Only owners and moderators

### Step 5 — Add Channels to Location Teams

Add relevant channels to each location team to organise conversations by topic:

For each location team, add channels for:
- General (created by default)
- Projects
- IT Support

### Step 6 — Verify Teams is Working

Sign in to each user account via the Teams web client at teams.microsoft.com and confirm:
- The user can see their location team
- The user can see the All Staff team
- Messaging works between users
- The user cannot create a new team (due to the restriction applied in Step 1)

---

## What to Expect

Teams is ready to use across all locations. Files shared in Teams are stored in the corresponding SharePoint site, meaning they are accessible from SharePoint and OneDrive as well. The governance controls ensure the environment stays clean and manageable as the organisation grows.

---

[← 06 — SharePoint & OneDrive](06-sharepoint-onedrive.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [08 — Intune: Windows →](08-intune-windows.md)
