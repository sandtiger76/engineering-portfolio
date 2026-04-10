# 05 — SharePoint Online & OneDrive for Business

## In Plain English

Every organisation needs somewhere to store its documents. In a traditional office, that meant a file server in a server room — a physical computer that held all the company's files. Staff accessed it over the office network, and remote workers needed a VPN to connect. If the server failed, everyone lost access to their files.

SharePoint Online replaces the file server entirely. Company documents — project files, templates, operational records — live in SharePoint, accessible from any device, from anywhere, with no VPN. Files have version history (accidentally overwrote something? Restore it), a recycle bin (accidentally deleted something? Recover it), and co-authoring (two people can edit the same document at the same time without conflicts).

OneDrive for Business is the personal equivalent. Every member of staff has their own cloud storage — like a personal drive that follows them to any device they sign in on.

---

## Why This Matters

A file server that only works on the office network is a bottleneck for distributed teams. Field workers either cannot access files, or they maintain local copies that quickly become out of sync. Email becomes a document delivery system, creating multiple conflicting versions of the same file.

SharePoint solves all of this. One copy of every document exists in one place. Everyone — in the office, at home, at a client site — accesses the same file. Changes are tracked, versions are preserved, and nothing is lost.

For QCB Homelab Consultants — a consultancy with distributed staff — this is not a nice-to-have. It is the operational foundation.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| 5 staff users with Business Premium licences | Completed in workstream 01 |
| Security groups created | GRP-Executives, GRP-Managers, GRP-Staff, GRP-AllStaff |
| SharePoint Admin role | m365admin holds Global Administrator — full SharePoint admin access included |
| SharePoint Admin Center accessible | https://admin.sharepoint.com |

---

## The End State

| Component | State |
|---|---|
| SharePoint team site | QCB Homelab Consultants — /sites/QCBHomelabConsultants |
| Document libraries | Projects, Operations, Templates, Executive |
| Permissions | Library-level, via Entra ID security groups |
| External sharing | Disabled at tenant level |
| OneDrive | Provisioned for all 5 users |
| Files On-Demand | Configured via policy — files available without bulk download |

---

## Phase 1 — Tenant-Level SharePoint Settings

Before creating any sites, configure the tenant-level settings that apply to all SharePoint sites and OneDrive accounts.

### Step 1 — Disable External Sharing

By default, SharePoint allows authenticated external users to be invited to view and edit documents. For QCB Homelab Consultants — a consultancy handling client-confidential information — this risk is unacceptable.

1. Navigate to **SharePoint Admin Center** at `https://admin.sharepoint.com`
2. Go to **Policies** → **Sharing**
3. Under **External sharing**, set both sliders to **Only people in your organisation**:
   - SharePoint: Only people in your organisation
   - OneDrive: Only people in your organisation
4. Click **Save**

This means no document or site can be shared with an email address outside `qcbhomelab.online`. "Share" links that work for anyone or for specific external guests are disabled.

> **For real engagements where external sharing is required:** Enable sharing for specific sites only (not the whole tenant), require external users to authenticate with a Microsoft account (not anonymous links), and set expiration dates on all external shares. Never enable "Anyone with the link" for a company handling client-confidential data.

---

## Phase 2 — Create the SharePoint Site

### Step 2 — Create the QCB Homelab Consultants Team Site

1. In **SharePoint Admin Center** → **Sites** → **Active sites** → **+ Create**
2. Select **Team site** (connected to a Microsoft 365 group)
3. Configure:

| Field | Value |
|---|---|
| Site name | QCB Homelab Consultants |
| Site address | /sites/QCBHomelabConsultants |
| Group owner | m365admin@qcbhomelab.online |
| Privacy | Private |
| Select a language | English (United Kingdom) |

4. Click **Finish**
5. Note the full site URL: `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`

---

## Phase 3 — Create Document Libraries

Four document libraries are created, each serving a distinct purpose and with distinct access permissions.

### Step 3 — Create the Libraries

Navigate to the SharePoint site at `https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants`

For each library:
1. Click **+ New** → **Document library**
2. Enter the library name
3. Click **Create**

| Library Name | Purpose |
|---|---|
| Projects | Client engagement files, deliverables, project documentation |
| Operations | Internal operational documents, processes, procedures |
| Templates | Company document templates — all staff read, management maintain |
| Executive | Board papers, financial summaries, executive-only documents |

---

## Phase 4 — Configure Permissions

### Key Decision: Library-Level Permissions via Security Groups

SharePoint permissions are applied at the library level using the Entra ID security groups created in workstream 01. This means:

- Adding a new staff member to the right group automatically grants them correct SharePoint access
- Removing a user from a group immediately revokes their SharePoint access
- Permissions are consistent and auditable — no ad-hoc individual assignments

### Step 4 — Break Permission Inheritance

By default, all libraries inherit permissions from the parent site. Break this inheritance on each library so permissions can be set independently.

For each library:
1. Open the library → **Settings** (gear icon) → **Library settings**
2. Click **Permissions for this document library**
3. Click **Stop Inheriting Permissions** → confirm
4. Remove all inherited permissions that do not apply to this library

### Step 5 — Apply Permission Matrix

Configure the following permissions for each library:

| Library | Group | Permission Level |
|---|---|---|
| Projects | GRP-AllStaff | Contribute (read, create, edit, delete own files) |
| Projects | GRP-Managers | Edit (contribute + manage lists) |
| Operations | GRP-AllStaff | Read |
| Operations | GRP-Managers | Contribute |
| Templates | GRP-AllStaff | Read |
| Templates | GRP-Managers | Contribute |
| Executive | GRP-Executives | Full Control |
| Executive | GRP-Managers | Read |

**For each library and group assignment:**
1. Go to library permissions
2. Click **Grant Permissions**
3. Search for the security group name
4. Select the permission level
5. Uncheck **Send an email invitation**
6. Click **Share**

> **Important:** The Executive library should not be accessible to GRP-Staff or GRP-FieldWorkers. After breaking inheritance, ensure only GRP-Executives and GRP-Managers are listed in the permissions for that library.

---

## Phase 5 — OneDrive for Business

### Step 6 — Pre-Provision OneDrive for All Users

OneDrive for Business is provisioned automatically when a user signs in for the first time. To ensure all accounts exist before staff are onboarded, pre-provision them via PowerShell.

```powershell
Connect-SPOService -Url https://qcbhomelab-admin.sharepoint.com

$users = @(
    "alex.carter@qcbhomelab.online",
    "morgan.blake@qcbhomelab.online",
    "jordan.hayes@qcbhomelab.online",
    "riley.morgan@qcbhomelab.online",
    "casey.quinn@qcbhomelab.online"
)

Request-SPOPersonalSite -UserEmails $users -NoWait
```

Wait 15–30 minutes, then verify:

1. Navigate to **SharePoint Admin Center** → **Sites** → **Active sites**
2. Filter by site template: **OneDrive**
3. Confirm 5 personal OneDrive sites are listed — one per user

### Step 7 — Configure Files On-Demand Policy

Files On-Demand allows users to see all their OneDrive files in File Explorer without downloading them all locally. Files are downloaded only when opened. This is configured via Intune in workstream 07 — the Intune configuration profile includes the OneDrive Files On-Demand setting.

> The Files On-Demand policy must be applied before users sign into the OneDrive sync client on their devices. If users sync before the policy is applied, they may download all files locally on first sync — consuming storage and potentially overwriting cloud content with stale local copies.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| External sharing disabled | SharePoint Admin Center → Sharing | Only people in your organisation |
| Team site created | SharePoint Admin Center → Active sites | QCBHomelabConsultants listed |
| 4 libraries created | Browse the SharePoint site | Projects, Operations, Templates, Executive visible |
| Permissions applied | Library → Settings → Permissions | Correct groups at correct levels |
| Staff cannot access Executive library | Sign in as jordan.hayes, navigate to Executive library | Access denied |
| Managers can access Executive library | Sign in as morgan.blake, navigate to Executive library | Read access confirmed |
| OneDrive provisioned | SharePoint Admin Center → Sites → OneDrive filter | 5 personal sites listed |
| User can access their OneDrive | Sign in as riley.morgan, navigate to OneDrive | Personal storage accessible |

### PowerShell Verification

```powershell
Connect-PnPOnline -Url "https://qcbhomelab.sharepoint.com/sites/QCBHomelabConsultants" -Interactive

# List all document libraries on the site
Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 } |
    Select-Object Title, DefaultViewUrl |
    Format-Table
```

---

## Summary

This workstream delivered:

- **External sharing disabled** at tenant level — no accidental exposure of client-confidential documents
- **SharePoint team site** created at `/sites/QCBHomelabConsultants`
- **4 document libraries** — Projects, Operations, Templates, Executive
- **Permissions configured** at library level via Entra ID security groups — consistent and maintainable
- **Executive library restricted** — only accessible to executives and managers
- **OneDrive pre-provisioned** for all 5 staff
- **Files On-Demand policy** to be applied via Intune in workstream 07

Staff can now access company documents from any device, anywhere. There is no file server dependency, no VPN required, and no risk of local-only copies going out of sync.

**Next:** [06 — Microsoft Teams](./06-microsoft-teams.md)
