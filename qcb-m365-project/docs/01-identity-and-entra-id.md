# 01 — Identity & Microsoft Entra ID

## In Plain English

Every person who uses technology at work needs an identity — a username and password that proves who they are and grants them access to the tools they need. In a traditional office environment, that identity lived on a physical server in a server room. If the server went down, nobody could log in.

Microsoft Entra ID is Microsoft's cloud identity platform. It replaces the physical server entirely. It holds the list of who works at QCB Homelab Consultants, what they are allowed to access, and how they prove who they are. Because it lives in the cloud, it works from anywhere — the office, home, a client site, or a coffee shop — without a VPN, without a server room, and without the maintenance overhead of on-premises hardware.

Everything in Microsoft 365 — email, files, Teams, device management, security — depends on identity. Entra ID is the foundation. It must be configured correctly before anything else.

---

## Why This Matters

Without a properly configured identity platform:

- Users cannot be assigned licences for Microsoft 365 services
- Conditional Access policies cannot be applied
- Devices cannot be enrolled in Intune
- There is no audit trail of who did what and when
- There is no way to enforce consistent security policy across a distributed workforce

Getting identity right at the start means everything built on top of it is stable, secure, and maintainable.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Microsoft 365 Business Premium trial active | 25 licences available |
| qcbhomelab.online verified as default domain | Pre-configured — domain verified before this project began |
| Access to Microsoft 365 Admin Center | https://admin.microsoft.com |
| Access to Microsoft Entra Admin Center | https://entra.microsoft.com |

---

## The End State

By the end of this workstream, the following will be in place:

| Component | State |
|---|---|
| Tenant display name | QCB Homelab Consultants |
| Default domain | qcbhomelab.online |
| Break-glass admin account | qcb-az@[tenant].onmicrosoft.com — Global Admin, no licence |
| Working admin account | m365admin@qcbhomelab.online — Global Admin, no licence |
| Staff users | 5 users created, Business Premium assigned |
| Security groups | 6 groups created, members assigned |
| Security Defaults | Disabled — replaced by Conditional Access in workstream 02 |

---

## Phase 1 — Tenant Configuration

### Step 1 — Verify the Tenant Display Name

The tenant display name is what staff see when they sign in. It should match the company name.

1. Navigate to the **Azure Portal** at `https://portal.azure.com`
2. Sign in with the break-glass account: `qcb-az@[tenant].onmicrosoft.com`
3. Search for **Microsoft Entra ID** in the top search bar
4. Select **Properties** from the left-hand menu
5. Confirm the **Name** field shows `QCB Homelab Consultants`
6. If it does not, update it and click **Save**

Confirm via PowerShell:

```powershell
# Install the Microsoft Graph module if not already installed
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force

# Connect to the tenant
Connect-MgGraph -Scopes "Organization.Read.All"

# Confirm tenant display name
Get-MgOrganization | Select-Object DisplayName
```

Expected output:
```
DisplayName
-----------
QCB Homelab Consultants
```

---

## Phase 2 — Admin Account Separation

### Why Two Admin Accounts

Using a personal named account for administration is a common and dangerous mistake. If that account is compromised, an attacker gains Global Administrator access to the entire tenant. If the user leaves, their admin access must be carefully managed. Personal accounts also accumulate email, files, and Teams activity — mixing user data with admin privileges in a single account.

Two dedicated admin accounts are maintained. Neither holds a Microsoft 365 licence — admin roles do not require licences. All 25 Business Premium licences remain available for staff.

### Step 2 — Confirm the Break-Glass Account

The break-glass account was created when the Microsoft 365 tenant was first activated. It exists on the `onmicrosoft.com` domain — Microsoft's permanent initial domain that cannot be removed or misconfigured. It is the account of last resort: used only if the working admin account is ever locked out, compromised, or otherwise unavailable.

1. Navigate to **Microsoft 365 Admin Center** at `https://admin.microsoft.com`
2. Go to **Users** → **Active users**
3. Confirm `qcb-az@[tenant].onmicrosoft.com` exists
4. Click the account → confirm **Roles** shows **Global Administrator**
5. Click **Licences and apps** → confirm **no licence is assigned**

> The break-glass account must never be used for routine administration. Its sign-in activity should be treated as an alert — any use indicates either an emergency or a compromise.

### Step 3 — Create the Working Admin Account

The working admin account is used for all day-to-day administration. It lives on the custom domain so it is easily identifiable in audit logs.

1. In **Microsoft 365 Admin Center** → **Users** → **Active users** → **Add a user**
2. Configure as follows:

| Field | Value |
|---|---|
| First name | M365 |
| Last name | Admin |
| Display name | M365 Admin |
| Username | m365admin@qcbhomelab.online |
| Automatically create password | No — set a strong password manually |
| Require password change on first sign-in | No |

3. On the **Licences** tab — select **Create user without product licence**
4. On the **Optional settings** tab → **Roles** → **Admin centre access** → **Global Administrator**
5. Click **Finish adding**

Confirm the account has no licence and holds the Global Administrator role before proceeding.

> All remaining steps in this project are performed as `m365admin@qcbhomelab.online`. Sign in to the Microsoft 365 Admin Center with this account now.

---

## Phase 3 — Disable Security Defaults

Security Defaults are Microsoft's basic protection settings — enabled by default on all new tenants. They enforce MFA for all users but offer no granularity. This project replaces them with Conditional Access policies (workstream 02), which provide precise control.

Security Defaults and Conditional Access cannot coexist — disabling Security Defaults is required before Conditional Access policies can be created.

> **Important:** Do not disable Security Defaults until the break-glass account is confirmed working and accessible. If you are locked out before Conditional Access is configured, the break-glass account is your recovery path.

1. Navigate to **Microsoft Entra Admin Center** at `https://entra.microsoft.com`
2. Go to **Identity** → **Overview** → **Properties**
3. Scroll to the bottom and click **Manage Security defaults**
4. Set **Security defaults** to **Disabled**
5. Select the reason: **My organisation is using Conditional Access**
6. Click **Save**

> Conditional Access policies will be created in workstream 02 immediately after this step. Do not leave Security Defaults disabled without Conditional Access in place.

---

## Phase 4 — Create Staff Users

Five staff users are created directly in Entra ID. There is no on-premises Active Directory to sync from — users are cloud-native.

### Step 4 — Create Each User

For each user, follow these steps:

1. Navigate to **Microsoft Entra Admin Center** → **Users** → **All users** → **New user** → **Create new user**
2. Configure the fields as specified in the table below
3. Set a temporary password — users will be prompted to change it on first sign-in
4. Click **Review + create** → **Create**

| Display Name | User Principal Name | Job Title | Usage Location |
|---|---|---|---|
| Alex Carter | alex.carter@qcbhomelab.online | Executive | United Kingdom |
| Morgan Blake | morgan.blake@qcbhomelab.online | Manager | United Kingdom |
| Jordan Hayes | jordan.hayes@qcbhomelab.online | Staff | United Kingdom |
| Riley Morgan | riley.morgan@qcbhomelab.online | Staff | United Kingdom |
| Casey Quinn | casey.quinn@qcbhomelab.online | Field Worker | United Kingdom |

> **Usage Location must be set.** Microsoft 365 licences require a usage location to be assigned before a licence can be applied to a user. Set this to the appropriate country for each user at creation time.

### Step 5 — Assign Licences

Licences are assigned via the GRP-AllStaff security group (created in Phase 5). However, to confirm provisioning works correctly, assign a licence to one user manually first, then switch to group-based assignment.

1. Navigate to **Microsoft Entra Admin Center** → **Users** → select **Alex Carter**
2. Go to **Licences** → **Assignments** → **+ Add assignments**
3. Select **Microsoft 365 Business Premium** → **Save**
4. Wait 2–3 minutes → return to the user's licences and confirm **Exchange Online**, **SharePoint Online**, **Teams**, and **Intune** all show as assigned services

This confirms the licence is working. Proceed to create security groups — group-based licensing will handle the remaining 4 users.

---

## Phase 5 — Create Security Groups

Security groups are the building blocks of access control in this deployment. Policies, licences, and permissions are assigned to groups rather than individual users. This makes ongoing management significantly easier.

### Step 6 — Create Each Group

1. Navigate to **Microsoft Entra Admin Center** → **Groups** → **All groups** → **New group**
2. For each group, configure as follows — **Group type: Security**, **Membership type: Assigned**

| Group Name | Description | Members |
|---|---|---|
| GRP-Executives | Executive users — strict CA policy | Alex Carter |
| GRP-Managers | Manager users — standard CA policy | Morgan Blake |
| GRP-Staff | Standard office staff | Jordan Hayes, Riley Morgan |
| GRP-FieldWorkers | Field and remote workers — MAM policy | Casey Quinn |
| GRP-AllStaff | All licensed staff | All 5 users |
| GRP-ManagedDevices | Corporate-managed devices | (assigned to devices after Intune enrolment) |

3. After creating each group, assign the members listed above

### Step 7 — Enable Group-Based Licensing

Rather than assigning licences to each user individually, assign the Microsoft 365 Business Premium licence to GRP-AllStaff. All current and future members of this group receive the licence automatically.

1. Navigate to **Microsoft Entra Admin Center** → **Groups** → **GRP-AllStaff**
2. Select **Licences** from the left menu → **Assignments** → **+ Add assignments**
3. Select **Microsoft 365 Business Premium**
4. Confirm all service plans are enabled → **Save**
5. Wait 5 minutes → navigate to each user and confirm licences show as assigned via group

> If Alex Carter was manually assigned a licence in Step 5, remove the direct assignment now. Group-based and direct assignments can coexist, but group-based alone is cleaner and easier to manage.

---

## Validation

Run the following checks before proceeding to workstream 02:

| Check | Method | Expected Result |
|---|---|---|
| Tenant display name correct | Entra Admin Center → Overview | QCB Homelab Consultants |
| Break-glass account exists, no licence | Admin Center → Users | Global Admin role, no licence shown |
| Working admin account exists, no licence | Admin Center → Users | Global Admin role, no licence shown |
| Security Defaults disabled | Entra → Properties → Security defaults | Disabled |
| 5 staff users created | Entra → Users → All users | 5 users listed with correct UPNs |
| All users have licences | Entra → Users → each user → Licences | Microsoft 365 Business Premium assigned |
| 6 security groups created | Entra → Groups | All 6 groups listed with correct members |

### PowerShell Verification

```powershell
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"

# List all users and their UPNs
Get-MgUser -All | Select-Object DisplayName, UserPrincipalName | Format-Table

# List all security groups
Get-MgGroup -All | Where-Object { $_.SecurityEnabled -eq $true } |
    Select-Object DisplayName, Description | Format-Table
```

---

## Summary

This workstream delivered:

- **Tenant** named as QCB Homelab Consultants with qcbhomelab.online as the default domain
- **Break-glass account** confirmed — Global Administrator on onmicrosoft.com, no licence
- **Working admin account** created — m365admin@qcbhomelab.online, Global Administrator, no licence
- **Security Defaults** disabled — replaced by Conditional Access in the next workstream
- **5 staff users** created in Entra ID with correct UPNs, job titles, and usage locations
- **Microsoft 365 Business Premium** licences assigned via GRP-AllStaff group
- **6 security groups** created and populated — the foundation for CA policies, Intune, and SharePoint permissions

**What this enables next:** With users and groups in place, Conditional Access policies can be created and targeted precisely. Licences being assigned means Exchange Online, SharePoint, Teams, and Intune are all provisioned and ready to configure.

**Next:** [02 — Conditional Access](./02-conditional-access.md)
