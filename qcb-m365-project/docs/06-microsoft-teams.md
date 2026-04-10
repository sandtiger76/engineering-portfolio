# 06 — Microsoft Teams

## In Plain English

Microsoft Teams is the central hub where communication and collaboration come together. It combines instant messaging, video calls, meetings, and file sharing in one application — connected directly to the SharePoint document libraries configured in workstream 05.

Without Teams, a distributed team uses a patchwork of tools: one application for video calls, another for instant messaging, email for sharing files, and a shared drive that requires a VPN. Each tool has its own login, its own notification, and its own archive. Important information gets buried in email threads or lost when someone leaves.

Teams replaces all of that. Every conversation, every meeting, every document lives in the same place, searchable and accessible to the right people.

---

## Why This Matters

For QCB Homelab Consultants — a consultancy with staff working across multiple locations — fragmented communication tools create real operational risk. Decisions get made in conversations that are not recorded. Files get emailed between people and quickly fall out of sync. Onboarding a new staff member requires access to five different systems.

Teams solves these problems at the platform level. Channels provide a permanent, searchable record of team conversations. The Files tab in each channel connects directly to the SharePoint document library — the files are not copied or duplicated, they are accessed in place. Meetings are scheduled from the Teams calendar (the same as Outlook) and can be recorded and transcribed automatically.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| 5 staff users with Business Premium licences | Completed in workstream 01 |
| SharePoint team site and libraries created | Completed in workstream 05 |
| Security groups created | GRP-Executives, GRP-Managers, GRP-Staff, GRP-FieldWorkers, GRP-AllStaff |
| Teams Admin Center accessible | https://admin.teams.microsoft.com |

---

## The End State

| Component | State |
|---|---|
| Org-wide team | QCB Homelab Consultants — all staff |
| Department teams | Executives, Operations, Projects |
| SharePoint tabs | Document libraries connected to relevant channels |
| Guest access | Disabled at tenant level |
| Meeting policy | Professional settings — recording enabled for organisers |
| Messaging policy | Professional settings — immersive reader on, memes off |
| Teams creation | Restricted to administrators only |

---

## Teams Architecture

```
QCB Homelab Consultants (Org-Wide — all 5 staff)
├── General (announcements, company-wide)
└── IT & Admin

Executives (Private — Alex Carter only)
└── General

Operations (Private — Morgan Blake, Jordan Hayes, Riley Morgan)
├── General
└── Operations Files → SharePoint: Operations library

Projects (Private — all staff)
├── General
└── Project Files → SharePoint: Projects library
```

---

## Phase 1 — Org-Wide Settings

### Step 1 — Restrict Team Creation to Administrators

By default, any licensed user can create a new Team. This quickly creates an ungoverned proliferation of teams with duplicate content, no clear ownership, and no consistent access control.

Restricting team creation means only administrators can create Teams — ensuring every team is purposeful and properly configured.

1. Navigate to **Microsoft Entra Admin Center** → **Groups** → **General**
2. Under **Users can create Microsoft 365 groups in Azure portals, API or PowerShell**, select **No**
3. Click **Save**

> This setting prevents users from creating Microsoft 365 groups, which are the underlying structure for Teams. Administrators (m365admin) retain the ability to create teams.

### Step 2 — Disable Guest Access

Guest access allows people outside the organisation to join Teams and participate in channels. For a consultancy handling client-confidential information, this is a significant data exposure risk.

1. Navigate to **Teams Admin Center** at `https://admin.teams.microsoft.com`
2. Go to **Users** → **Guest access**
3. Set **Allow guest access in Teams** to **Off**
4. Click **Save**

Also configure the Entra ID external collaboration setting:

1. Navigate to **Entra Admin Center** → **External Identities** → **External collaboration settings**
2. Under **Guest invite settings**, select **No one in the organisation can invite guest users**
3. Click **Save**

---

## Phase 2 — Create Teams

### Step 3 — Create the Org-Wide Team

The org-wide team includes all licensed staff automatically. It is used for company-wide announcements and general communication.

1. In **Teams Admin Center** → **Teams** → **Manage teams** → **+ Add**
2. Configure:

| Field | Value |
|---|---|
| Name | QCB Homelab Consultants |
| Description | Company-wide team for all staff |
| Team owners | m365admin@qcbhomelab.online |
| Privacy | Public |
| Org-wide team | Yes |

3. Click **Apply**

> An org-wide team automatically includes all licensed users. No manual member management is required.

### Step 4 — Create Department Teams

For each department team, navigate to **Teams Admin Center** → **Teams** → **Manage teams** → **+ Add**

**Executives Team:**

| Field | Value |
|---|---|
| Name | Executives |
| Description | Executive leadership team |
| Privacy | Private |
| Owners | m365admin@qcbhomelab.online |
| Members | alex.carter@qcbhomelab.online |

**Operations Team:**

| Field | Value |
|---|---|
| Name | Operations |
| Description | Operations and administration |
| Privacy | Private |
| Owners | morgan.blake@qcbhomelab.online |
| Members | morgan.blake, jordan.hayes, riley.morgan |

**Projects Team:**

| Field | Value |
|---|---|
| Name | Projects |
| Description | Client projects and deliverables |
| Privacy | Private |
| Owners | morgan.blake@qcbhomelab.online |
| Members | All 5 users |

---

## Phase 3 — Create Channels

### Step 5 — Add Channels to Each Team

Default channels (General) are created automatically. Add the following additional channels:

**QCB Homelab Consultants (org-wide):**
- IT & Admin *(for IT announcements and system communications)*

**Operations team:**
- Operations Files *(will have SharePoint tab added)*

**Projects team:**
- Project Files *(will have SharePoint tab added)*

To add a channel:
1. In **Teams Admin Center** → **Teams** → click the team name → **Channels** tab → **Add**
2. Enter the channel name and description
3. Set type to **Standard**
4. Click **Apply**

---

## Phase 4 — Connect SharePoint Libraries to Teams

### Step 6 — Add SharePoint Document Library Tabs

Each relevant channel gets a SharePoint tab connecting it to the appropriate document library. This surfaces the migrated documents directly within Teams — staff do not need to navigate to SharePoint separately.

The SharePoint tab must be added from within the Teams client (not Teams Admin Center).

**For the Operations channel in the Operations team:**

1. Open the Teams client and navigate to the **Operations** team → **Operations Files** channel
2. Click **+** (Add a tab) at the top of the channel
3. Search for **SharePoint** → select it
4. Choose **SharePoint site** → select the QCB Homelab Consultants site
5. Select the **Operations** document library
6. Name the tab: `Operations Files`
7. Click **Save**

**For the Project Files channel in the Projects team:**

1. Navigate to the **Projects** team → **Project Files** channel
2. Click **+** → **SharePoint**
3. Select the **Projects** document library
4. Name the tab: `Project Files`
5. Click **Save**

> The SharePoint tab does not copy files into Teams — it connects to the existing SharePoint library. Files opened via the Teams tab are the same files that live in SharePoint. Changes made in one place are immediately reflected in the other.

---

## Phase 5 — Configure Policies

### Step 7 — Configure Meeting Policy

1. Navigate to **Teams Admin Center** → **Meetings** → **Meeting policies** → **Global (Org-wide default)**
2. Configure:

| Setting | Value | Reason |
|---|---|---|
| Allow cloud recording | On — organisers and co-organisers only | Client meetings may need recording |
| Automatically admit people | People in my organisation and trusted organisations | Prevents uninvited joining |
| Allow external participants to bypass the lobby | Off | Security — all external participants must be admitted |
| Live captions | On | Accessibility |
| Whiteboard | On | Collaboration |

3. Click **Save**

### Step 8 — Configure Messaging Policy

1. Navigate to **Teams Admin Center** → **Messaging policies** → **Global (Org-wide default)**
2. Configure:

| Setting | Value | Reason |
|---|---|---|
| Delete sent messages | Off | Retain communication records |
| Edit sent messages | On | Allow corrections |
| Read receipts | User controlled | Individual preference |
| Giphy in conversations | Off | Professional environment |
| Memes | Off | Professional environment |
| Immersive reader | On | Accessibility |
| Priority notifications | On | Urgent communications |

3. Click **Save**

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Org-wide team created | Teams Admin Center → Teams | QCB Homelab Consultants listed |
| All staff in org-wide team | Click team → Members | All 5 users listed |
| Department teams created | Teams Admin Center → Teams | Executives, Operations, Projects listed |
| Correct members in each team | Click each team → Members | Matches the team design above |
| Guest access disabled | Teams Admin Center → Guest access | Off |
| Team creation restricted | Sign in as jordan.hayes, attempt to create a team | Option not available or request must be made to admin |
| SharePoint tab working | Open Operations channel → Operations Files tab | SharePoint library content visible |
| Meeting policy active | Teams Admin Center → Meeting policies | Global policy shows updated settings |
| Video call test | Start a Teams meeting between two user accounts | Call connects, recording available to organiser |

---

## Summary

This workstream delivered:

- **Org-wide team** — all 5 staff in a single company-wide team for announcements and general communication
- **3 department teams** — Executives, Operations, Projects — private, with correct membership
- **SharePoint tabs** — Operations and Projects libraries connected to their respective Teams channels
- **Guest access disabled** — no accidental external exposure through Teams
- **Team creation restricted** — only administrators can create new Teams
- **Meeting policy** — recording available to organisers, lobby enforced for external participants
- **Messaging policy** — professional settings, immersive reader for accessibility

Staff now have a single platform for communication, file access, and meetings. The patchwork of separate tools — video conferencing, instant messaging, email-as-file-sharing — is replaced by Teams as the operational hub.

**Next:** [07 — Intune: Windows Device Management](./07-intune-windows.md)
