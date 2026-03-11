# 06 — Microsoft Teams Setup

## In Plain English

QCB Homelab Consultants currently uses a third-party video conferencing tool that is entirely disconnected from their documents, calendar, and files. This workstream replaces it with Microsoft Teams — giving staff a single platform for video calls, instant messaging, file collaboration, and access to the SharePoint document libraries migrated in workstream 03. Everything is in one place, and it works from any device.

## Why This Matters

The disconnected nature of the existing video conferencing tool creates friction — links are shared via email, files are emailed back and forth, and there is no central record of what was discussed. Teams connects communication directly to documents: every team has its own file storage (backed by SharePoint), every meeting can be recorded, and every channel conversation is searchable. For a consultancy firm working across multiple client projects, this is a significant operational improvement.

## Prerequisites

- Microsoft 365 Business Premium licences assigned to all 15 staff (completed in `01d`)
- SharePoint site and document libraries migrated (completed in `03`)
- Users synced to Entra ID and signed in to Microsoft 365 (completed in `01a`/`01b`)
- Teams is included in Business Premium — no additional activation required
- Guest access decision made: **disabled** (client-confidential content, documented below)

---

## Teams Architecture for QCB Homelab Consultants

The Teams structure mirrors the department structure documented in Active Directory. Each department gets its own Team, with channels for logical work areas within that department.

```
QCB Homelab Consultants (Org-Wide Team)
├── General (default channel)
├── Announcements
└── IT & Infrastructure

Management Team
├── General
├── Strategy & Planning
└── Finance & Reporting

Design Team
├── General
├── Active Projects
└── Design Resources

Projects Team
├── General
├── Project: [Client A]
├── Project: [Client B]
└── Templates & Standards

Admin Team
├── General
├── HR & Onboarding
└── Operations
```

### Key Decision: Mirror Department Structure

Teams channels should reflect how work is actually organised, not how IT has always organised things. For QCB Homelab Consultants, the department structure (Management, Design, Projects, Admin) is already established in Active Directory and reflected in the SharePoint site structure. Using the same structure in Teams means:

- Staff know where to look for files, conversations, and meetings
- SharePoint libraries connect naturally to their corresponding Teams channels
- Access control is consistent across SharePoint and Teams (both use the same M365 groups)

---

## Phase 1 — Create Teams

### Step-by-Step: Create Teams via Teams Admin Center

1. Navigate to **Teams Admin Center** (`https://admin.teams.microsoft.com`) → **Teams** → **Manage teams**
2. Click **Add** to create each team

For each Team:

| Team Name | Type | Owner | Members |
|---|---|---|---|
| QCB Homelab Consultants | Org-wide | m365admin | All staff (auto-added) |
| Management | Private | Managing Director | Management group |
| Design | Private | Design Lead | Design group |
| Projects | Private | Projects Lead | Projects group |
| Admin | Private | Admin Lead | Admin group |

> **Note:** Org-wide teams automatically include all licensed users. Private teams require explicit membership.

> **Screenshot:** `screenshots/06-teams/01_teams_created.png`
> *Teams Admin Center showing all five teams created*

### Create Teams via PowerShell (Alternative)

```powershell
Connect-MicrosoftTeams

# Create org-wide team
New-Team -DisplayName "QCB Homelab Consultants" -Description "Company-wide team" -Visibility Public

# Create department teams
$departments = @("Management", "Design", "Projects", "Admin")
foreach ($dept in $departments) {
    New-Team -DisplayName $dept -Description "$dept department team" -Visibility Private
}
```

---

## Phase 2 — Create Channels

### Add Channels to Each Team

In the Teams client or Teams Admin Center, add channels to each team:

**QCB Homelab Consultants (Org-Wide)**
- General *(default — cannot be deleted)*
- Announcements *(configure as announcement channel: only owners can post)*
- IT & Infrastructure

**Management**
- General *(default)*
- Strategy & Planning
- Finance & Reporting

**Design**
- General *(default)*
- Active Projects
- Design Resources

**Projects**
- General *(default)*
- Templates & Standards
- *(Project-specific channels added as projects begin)*

**Admin**
- General *(default)*
- HR & Onboarding
- Operations

> **Screenshot:** `screenshots/06-teams/02_channels_configured.png`
> *Teams client showing Projects team with channels*

---

## Phase 3 — Connect Teams Channels to SharePoint Libraries

### How Teams and SharePoint Integrate

Every Team has a SharePoint site created automatically behind the scenes when the Team is created. The **Files** tab in each channel connects to a folder within that SharePoint site's default document library. This is separate from the SharePoint migration site created in workstream 03.

For QCB Homelab Consultants, the migrated content lives in the dedicated SharePoint site (`/sites/QCBHomelabConsultants`). The correct way to surface this in Teams is to add a **SharePoint** tab pointing to the relevant document library — this does not move or copy any files.

### Add SharePoint Tab to a Channel

1. In the Teams client, navigate to the **Projects** team → **General** channel
2. Click the **+** (Add a tab) button
3. Select **SharePoint**
4. Choose **SharePoint site** → navigate to `QCB Homelab Consultants`
5. Select the **Projects** document library
6. Name the tab: `Project Files`
7. Click **Save**

Repeat for each department team:

| Team | Channel | Library |
|---|---|---|
| Management | General | Administration |
| Design | General | Technical Library + Templates |
| Projects | General | Projects |
| Admin | General | Administration |

> **Screenshot:** `screenshots/06-teams/03_sharepoint_tab_added.png`
> *Teams channel showing SharePoint document library tab*

> **Screenshot:** `screenshots/06-teams/04_files_visible_in_teams.png`
> *Teams Files tab showing migrated SharePoint content*

---

## Phase 4 — Guest Access Policy

### Key Decision: Disable Guest Access

Guest access in Teams allows people outside the organisation to join Teams and access shared content. For a consultancy working with confidential client data, this creates unacceptable risk — a misconfigured share or accidental channel invitation could expose client data to unauthorised parties.

**Decision: Guest access is disabled at the tenant level.**

This is enforced in two places:

**Teams Admin Center:**
1. Navigate to **Teams Admin Center** → **Org-wide settings** → **Guest access**
2. Set **Allow guest access in Teams** → **Off**

**Azure / Entra ID:**
1. Navigate to **Entra ID** → **External Identities** → **External collaboration settings**
2. Set guest invitation restrictions to **No one in the organisation can invite guest users**

> **Screenshot:** `screenshots/06-teams/05_guest_access_disabled.png`
> *Teams Admin Center showing guest access disabled*

> **Note for real engagements:** Some consultancies require guest access for client collaboration. If this is the case, configure guest access at the individual Team level (not tenant-wide), require MFA for guests via Conditional Access, and implement sensitivity labels to prevent guests from accessing restricted content.

---

## Phase 5 — Teams Policies and Messaging Configuration

### Messaging Policies

Configure a messaging policy appropriate for a professional consultancy:

| Setting | Value | Reason |
|---|---|---|
| Delete sent messages | Off | Retain communication records |
| Edit sent messages | On (24 hour window) | Allow corrections |
| Read receipts | User controlled | Respect individual preference |
| Giphy in conversations | Off | Professional tone |
| Memes | Off | Professional tone |
| Immersive reader | On | Accessibility |

### Meeting Policies

| Setting | Value | Reason |
|---|---|---|
| Allow cloud recording | On (organiser only) | Client meetings may need recording |
| Automatically admit people | People in my organisation | Prevent uninvited joining |
| Allow external participants to bypass lobby | Off | Security |
| Live captions | On | Accessibility |

> **Screenshot:** `screenshots/06-teams/06_meeting_policy.png`
> *Teams Admin Center showing meeting policy configuration*

---

## User Adoption Guidance

A Teams rollout fails not from technical problems but from adoption gaps. For QCB Homelab Consultants, the following guidance would accompany the rollout:

### What Changes for Staff

| Before | After |
|---|---|
| Video calls via third-party tool (separate login) | Video calls via Teams (same M365 credentials) |
| Files emailed between colleagues | Files shared via Teams channels |
| H: drive for personal files | OneDrive, accessible from Teams |
| Company files via VPN | SharePoint via Teams Files tab |
| Meetings scheduled separately from files | Meeting notes saved directly to Teams channel |

### Quick Start for Staff

1. Sign in to Teams at `https://teams.microsoft.com` or download the desktop app
2. Find your department team in the left sidebar
3. Use **General** for day-to-day conversation
4. Click **Files** in any channel to access shared documents
5. Access your personal files via **OneDrive** in the left sidebar
6. Schedule meetings from **Calendar** — your Outlook calendar and Teams calendar are the same

### What the Third-Party Video Tool Did That Teams Does Differently

| Third-Party Feature | Teams Equivalent |
|---|---|
| Meeting rooms | Teams meetings — scheduled from Calendar |
| Personal meeting link | Teams personal meeting URL (under Calendar → Meet now) |
| Screen sharing | Built in — share screen or specific window |
| Chat during meeting | Teams meeting chat |
| Recording | Teams cloud recording (saved to OneDrive) |

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| All five teams created | Teams Admin Center → Manage teams | Five teams listed |
| Channels configured | Teams client | Each team shows correct channels |
| SharePoint tabs added | Click Files tab in each channel | Migrated library content visible |
| Guest access disabled | Teams Admin Center → Org-wide settings | Guest access: Off |
| Meeting scheduled and joined | Create test meeting | All participants can join |
| File accessed from Teams | Open file via Files tab | File opens in Teams/browser |
| Chat message sent | Post in General channel | Message visible to all team members |

---

## Summary

This workstream delivered the following:

- **Five Teams** created matching the QCB Homelab Consultants department structure
- **Channels** configured for each team's logical work areas
- **SharePoint document libraries** connected to Teams channels via tabs — migrated content accessible directly from Teams
- **Guest access** disabled at tenant level to protect client-confidential content
- **Messaging and meeting policies** configured for professional use
- **User adoption guidance** prepared for rollout communication

**What this enables next:**

- Third-party video conferencing subscription can be cancelled
- Staff have a single platform for communication, files, and meetings
- Teams channel meetings replace ad hoc video calls with a permanent record in the channel
- Future: sensitivity labels can be applied to Teams to classify confidential channels (documented in workstream 08)
