[← 03 — Azure Resource Setup](03-azure-setup.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [05 — Microsoft 365 & Exchange Online →](05-m365-exchange.md)

---

# 04 — Hybrid Identity

## Introduction

Hybrid identity is the bridge between an on-premises Active Directory and Microsoft's cloud identity service, Microsoft Entra ID (formerly Azure Active Directory). It is what allows the same username and password a user types at their office computer to also work when signing into Microsoft 365, Teams, or Azure from anywhere in the world.

Without hybrid identity, you would have two separate identity systems to manage — one on-premises and one in the cloud. Users would have different passwords for each, and the IT team would have to create and delete accounts in two places every time someone joined or left. Hybrid identity solves this by making Active Directory the single source of truth and synchronising it to the cloud automatically.

The tool that does this synchronisation is called Microsoft Entra Connect Sync. It runs as a service on a Windows server, checks for changes in Active Directory every 30 minutes, and pushes those changes to Entra ID. The authentication method used here is Password Hash Synchronisation (PHS), which means a hashed version of each user's password is also synchronised to the cloud. This allows users to sign in to cloud services even if the on-premises server is temporarily unavailable.

---

## What We Are Building

| Component | Decision |
|---|---|
| Sync tool | Microsoft Entra Connect Sync |
| Authentication method | Password Hash Synchronisation (PHS) |
| Sync server | Azure VM in RG-Identity (or the DC itself for lab purposes) |
| Admin accounts | Separate cloud-only accounts — never sync admin accounts |
| Legacy authentication | Disabled |

> In a production environment, Entra Connect Sync should run on a dedicated server, not the domain controller. For this lab, installing it on QCBHC-DC01 is acceptable to keep costs down.

---

## Implementation Steps

### Step 1 — Prepare Entra ID

Before installing Entra Connect, the Microsoft 365 tenant must be ready to receive synchronised objects.

Log in to the Microsoft 365 Admin Center at admin.microsoft.com using a Global Administrator account. Confirm that the domain qcbhomelab.online is verified (this was completed during the M365 setup in document 05 — if working in order, complete that first).

### Step 2 — Create a Cloud-Only Admin Account

Synchronised accounts should never be used for administrative tasks in the cloud. Create a dedicated cloud-only Global Administrator account that exists only in Entra ID:

1. Go to Microsoft Entra Admin Center — entra.microsoft.com
2. Navigate to Users and create a new user
3. Username: `sync-admin@qcbhomelab.online`
4. Assign the Global Administrator role
5. Set a strong password and store it securely

This account will be used during the Entra Connect installation.

### Step 3 — Download and Install Entra Connect Sync

On QCBHC-DC01 (or your dedicated sync server):

1. Open a browser and download Entra Connect Sync from: https://www.microsoft.com/en-us/download/details.aspx?id=47594
2. Run the installer as Administrator
3. Accept the licence terms and click Continue

### Step 4 — Configure Entra Connect

When the configuration wizard opens, select **Use express settings** if this is a single-forest, single-domain environment with Password Hash Synchronisation. This is correct for our setup.

The wizard will prompt for:

- **Entra ID credentials** — use the `sync-admin@qcbhomelab.online` account created in Step 2
- **AD DS credentials** — use `QCBHOMELAB\Administrator` or a dedicated service account with the minimum required permissions

When prompted to continue without matching all UPN suffixes, confirm and proceed — this is expected in a lab environment where the internal AD domain matches the public domain.

Click **Install** and allow the wizard to complete. The initial synchronisation will start automatically when the wizard finishes.

### Step 5 — Verify Synchronisation

On the sync server, open PowerShell and run a manual sync to confirm everything is working:

```powershell
# Trigger a manual delta sync
Start-ADSyncSyncCycle -PolicyType Delta

# Check for sync errors
Get-ADSyncConnectorRunStatus
```

In the Entra Admin Center, navigate to Users and confirm that the six user accounts from Active Directory are now visible with a sync icon indicating they are synchronised from on-premises.

### Step 6 — Verify Password Hash Sync

```powershell
# Confirm PHS is enabled
Get-ADSyncAADPasswordSyncConfiguration -SourceConnector "qcbhomelab.online"
```

The output should show that password synchronisation is enabled.

### Step 7 — Scope the Sync (Optional but Recommended)

By default, Entra Connect synchronises all users and groups. It is better practice to scope the sync to only the OUs you want in the cloud. In Entra Connect, open the Synchronisation Service Manager and configure the connector to filter to:

- `OU=Users,DC=qcbhomelab,DC=online`
- `OU=Groups,DC=qcbhomelab,DC=online`

This prevents service accounts and other internal objects from appearing in the cloud unnecessarily.

### Step 8 — Assign Licences

Once users are synchronised to Entra ID, they need Microsoft 365 licences before they can use any services.

Navigate to Entra Admin Center → Groups → find `GRP-License-M365BusinessPremium` → Licences → assign the Microsoft 365 Business Premium licence to this group.

All members of that group will automatically receive their licence within a few minutes. This group-based licensing approach means that when new users are added to the group, they receive a licence automatically without manual intervention.

---

## What to Expect

After completing these steps, users created in Active Directory will automatically appear in Microsoft 365, be able to sign in with their AD password, and have licences assigned through group membership. Changes made to users in AD — name changes, department updates, group membership — will synchronise to the cloud within 30 minutes or immediately after a manual sync cycle.

---

[← 03 — Azure Resource Setup](03-azure-setup.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [05 — Microsoft 365 & Exchange Online →](05-m365-exchange.md)
