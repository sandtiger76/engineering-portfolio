[← 03 — Azure Resource Setup](03-azure-setup.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [05 — Microsoft 365 & Exchange Online →](05-m365-exchange.md)

---

# 04 — Hybrid Identity

## Overview — What This Document Covers

Most organisations that move to Microsoft 365 do not start from scratch — they already have years of user accounts stored on a local server. The challenge is connecting those existing accounts to the cloud without forcing everyone to manage two separate sets of credentials.

Hybrid identity is the solution. It creates a live connection between the organisation's on-premises directory and Microsoft's cloud, so that when someone's account is created, changed, or disabled on the local server, that change is automatically reflected in Microsoft 365 within minutes. Users get a single username and password that works everywhere — on their office computer, in the browser, on their phone.

This document covers setting up that connection: installing the synchronisation agent, choosing the right synchronisation method, and verifying that accounts are flowing correctly from on-premises into the cloud.

---

## Introduction

Hybrid identity is the bridge between an on-premises Active Directory and Microsoft's cloud identity service, Microsoft Entra ID. It is what allows the same username and password a user types at their office computer to also work when signing into Microsoft 365, Teams, or Azure from anywhere in the world.

Without hybrid identity, you would have two separate identity systems to manage — one on-premises and one in the cloud. Users would have different passwords for each, and the IT team would have to create and delete accounts in two places every time someone joined or left. Hybrid identity solves this by making Active Directory the single source of truth and synchronising it to the cloud automatically.

### The Tool: Microsoft Entra Cloud Sync

Microsoft offers two tools for hybrid identity synchronisation:

| Tool | Architecture | Best For |
|---|---|---|
| Microsoft Entra Connect Sync | Full sync engine installed on-premises, local SQL database | Complex environments, multiple forests, Pass-Through Authentication, device writeback |
| Microsoft Entra Cloud Sync | Lightweight agent on-premises, sync engine runs in Microsoft's cloud | Most SMB and modern environments — simpler, lower overhead, Microsoft's recommended direction |

This project uses **Microsoft Entra Cloud Sync**. It is Microsoft's strategic direction for hybrid identity — new features are being developed here first, and it is the recommended choice for environments with a single forest and fewer than 150,000 objects. Rather than running a heavy sync engine locally, a lightweight provisioning agent is installed on DC01. The agent relays directory data to Microsoft's cloud-based provisioning service, which handles all the sync logic.

### Authentication Method: Password Hash Sync

The authentication method used is Password Hash Synchronisation (PHS). A hashed representation of each user's password is synchronised to Entra ID, allowing users to sign in to cloud services using the same password as their AD account — even if the on-premises server is temporarily unavailable.

### What Syncs and What Does Not

This is an important distinction worth understanding clearly:

| Object | Syncs to Entra ID? | Notes |
|---|---|---|
| User accounts | ✅ Yes | From scoped OUs only |
| Security groups | ✅ Yes | From scoped OUs only |
| Password hashes | ✅ Yes | Enables cloud sign-in |
| Organisational Units | ❌ No | OU structure stays in AD — Entra uses groups instead |
| Devices (workstations) | ❌ No | Corporate laptops join Entra ID directly during setup |
| Service accounts | ❌ No | Excluded by OU scoping |

### A Note on Device Identity

Devices do not need to be synced from AD. In this environment:

- **Office workstations** — AD joined, managed by Group Policy on the local network
- **Corporate laptops** — join Entra ID directly during Windows setup (OOBE), managed by Intune over the internet. No VPN or domain controller contact required for authentication — the laptop authenticates directly to Entra ID from anywhere in the world
- **Personal iPhones** — BYOD, managed by Intune MAM at the app layer only

Intune is effectively the cloud replacement for Group Policy — it applies the same kind of security baselines, software configuration, and compliance enforcement, but does so over the internet without requiring network connectivity to a domain controller. This is covered in detail in documents 08 and 09.

---

## What We Are Building

| Component | Decision |
|---|---|
| Sync tool | Microsoft Entra Cloud Sync (Provisioning Agent) |
| Authentication method | Password Hash Synchronisation |
| Agent location | QCBHC-DC01 (on-premises domain controller) |
| Service account | Group Managed Service Account (gMSA) — auto-created |
| Sync scope | OU=Accounts and OU=Groups only |
| Sync frequency | Every 2 minutes (Cloud Sync default) |
| Admin accounts | Separate cloud-only account — never synced from AD |

---

## Prerequisites

Before starting, ensure the following are in place:

- QCBHC-DC01 is running and AD DS is configured with users and groups (documents 01 and 02)
- The domain `qcbhomelab.online` is verified in Microsoft 365 (document 05 — if working in order, complete that first or verify the domain before proceeding)
- Outbound internet access from DC01 to Microsoft endpoints (TLS 1.2 required)
- A cloud-only Global Administrator account exists in Entra ID for the installation

### Cloud-Only Admin Account

A dedicated cloud-only account must be used for the Entra Cloud Sync installation. This account must exist only in Entra ID — it must never be a synchronised account from AD, and it must never be used for day-to-day administration.

| Setting | Value |
|---|---|
| Display name | AD Domain Sync Account |
| Username | sync-admin@qcbhomelab.online |
| Role | Global Administrator (Entra ID Role — not Azure RBAC) |
| Password | Static, never expires, no forced change at next sign-in |
| Account type | Cloud-only — created directly in Entra ID |

> **Entra ID Roles vs Azure RBAC Roles:** These are two separate permission systems. Entra ID Roles (Global Administrator, User Administrator etc.) control permissions within Entra ID and Microsoft 365. Azure RBAC Roles (Owner, Contributor, Reader) control permissions over Azure infrastructure resources like VMs and storage accounts. The sync account needs a Global Administrator *Entra ID Role* — not an Azure RBAC role.

> **Why Global Administrator for installation?** The provisioning agent wizard needs elevated permissions to configure the synchronisation service, create the gMSA in AD, and register the agent with Entra ID. This is a one-time requirement. After setup, the agent runs as the gMSA and the sync-admin account is not used day-to-day. Treat it as a break-glass account — strong password, stored securely, monitored for sign-in activity.

Create this account in the Entra Admin Center before proceeding:

1. Go to **entra.microsoft.com → Users → New user**
2. Set the display name, username, and a strong static password
3. Set **Require change password at next sign-in** to **No**
4. Assign the **Global Administrator** role
5. Save

---

## Implementation Steps

### Step 1 — Download the Provisioning Agent

On QCBHC-DC01, open a browser and navigate to the Entra Admin Center:

**entra.microsoft.com → Identity → Hybrid management → Microsoft Entra Connect → Cloud Sync → Agents → Download on-premises agent**

Download and run the installer as Administrator. Accept the licence terms and complete the installation. Reboot DC01 before proceeding to configuration — this prevents silent authentication failures during the setup wizard.

### Step 2 — Configure the Provisioning Agent on DC01

After rebooting, open the **Microsoft Entra Provisioning Agent** configuration wizard from the Start menu.

**Welcome screen** — click Next.

**Connect Microsoft Entra ID:**
- Sign in with `sync-admin@qcbhomelab.online`
- Complete the sign-in — no MFA prompt should appear if the account is configured correctly (see Troubleshooting section)

**Configure Service Account:**
- Select **Create gMSA**
- A Group Managed Service Account (gMSA) is a special AD account with an automatically managed, rotating password. It cannot be used interactively and is purpose-built for services like this — it is more secure than a standard service account
- Enter your domain admin credentials to allow the wizard to create the gMSA:
  - Username: `QCBHOMELAB\Administrator`
  - Password: your DC01 Administrator password
- These credentials are used once to create the gMSA and are not stored

**Connect Active Directory:**
- The domain `qcbhomelab.online` should appear automatically
- Click **Add Directory** if it does not appear
- Confirm `qcbhomelab.online` appears under Configured Domains
- Click Next

**Confirm screen** — verify the settings:

| Setting | Expected Value |
|---|---|
| Active Directory domain | qcbhomelab.online |
| Service account | qcbhomelab.online\provAgentgMSA |
| Entra ID account | sync-admin@qcbhomelab.online |

Click **Confirm** and wait for registration to complete — this typically takes one to two minutes. Click **Exit** when done.

### Step 3 — Verify the Agent in Entra Admin Center

In the Entra Admin Center, navigate to:

**Identity → Hybrid management → Microsoft Entra Connect → Cloud Sync → Agents**

Confirm the agent appears as:

| Machine Name | Status |
|---|---|
| QCBHC-DC01.qcbhomelab.online | 🟢 active |

### Step 4 — Create the Cloud Sync Configuration

Navigate to **Cloud Sync → Configurations → New configuration → AD to Microsoft Entra ID sync**.

Select `qcbhomelab.online` from the domain dropdown — it will appear now that an active agent is registered against it.

Confirm **Enable password hash sync** is checked.

Click **Create**. You will be taken to the configuration overview page.

### Step 5 — Configure Scoping Filters

By default, Cloud Sync will attempt to sync every object in Active Directory including built-in accounts, system objects, and service accounts. Scoping filters restrict the sync to only the OUs you want in Entra ID.

Navigate to **Scoping filters** in the left panel.

Select **Selected organizational units** and add the following two OUs:

| Distinguished Name | Purpose |
|---|---|
| `OU=Accounts,DC=qcbhomelab,DC=online` | All staff and contractor user accounts |
| `OU=Groups,DC=qcbhomelab,DC=online` | All security and licence groups |

Click **Save**.

This ensures only your user accounts and groups appear in Entra ID. Built-in AD objects, the Administrator account, and any service accounts outside these OUs will not be synchronised.

### Step 6 — Test with Provision on Demand

Before enabling sync for all users, test against a single user to confirm the configuration is working correctly.

Navigate to **Provision on demand** in the left panel.

Enter the full distinguished name of a user — not just the username. The full DN is required:

```
CN=James Carter,OU=London,OU=Staff,OU=Accounts,DC=qcbhomelab,DC=online
```

Click **Provision**. All four steps should show green:

| Step | Expected Result |
|---|---|
| Import user | Successfully imported user |
| Determine if user is in scope | User is in scope |
| Match user between source and target | Successfully matched user |
| Perform action | Successfully created user in Microsoft Entra ID |

The Export details panel on the right will show all the attributes that were written to Entra ID, including DisplayName, Department, DnsDomainName, and UPN.

### Step 7 — Enable the Configuration

Navigate back to **Overview** and click **Review and enable**.

Review the configuration summary:

| Setting | Value |
|---|---|
| Domain | qcbhomelab.online |
| Password hash sync | Enabled |
| Prevent accidental deletion | Enabled |
| Accidental deletion threshold | 500 |
| Object scope filters | Organizational units |

Click **Enable configuration**. Once enabled, sync runs every 2 minutes automatically.

### Step 8 — Assign Licences

Once users are synchronised to Entra ID, they need Microsoft 365 licences before they can use any services. Licences are assigned through group membership — no manual per-user assignment is needed.

Navigate to **Entra Admin Center → Groups** and find `GRP-License-M365BusinessPremium`. Go to **Licences** and assign the Microsoft 365 Business Premium licence. This covers all six staff members.

Then find `GRP-License-M365Basic` and assign the Microsoft 365 Business Basic licence. This covers the two contractors, giving them access to web apps and Teams without the full desktop Office suite or Intune MDM.

All members of each group will automatically receive their licence within a few minutes. When new users are added to either group in AD, they will sync to Entra ID and receive the appropriate licence automatically.

---

## Verify Synchronisation

Navigate to **Entra Admin Center → Users → All users** and confirm all eight AD accounts are visible with **On-premises sync = Yes**:

| User | UPN | On-premises sync |
|---|---|---|
| James Carter | j.carter@qcbhomelab.online | Yes |
| Olivia Brown | o.brown@qcbhomelab.online | Yes |
| Michael Reed | m.reed@qcbhomelab.online | Yes |
| Sophia Miller | s.miller@qcbhomelab.online | Yes |
| Daniel Wong | d.wong@qcbhomelab.online | Yes |
| Emily Chan | e.chan@qcbhomelab.online | Yes |
| Amir Hassan | a.hassan@qcbhomelab.online | Yes |
| Petra Novak | p.novak@qcbhomelab.online | Yes |

You will also see an **On-Premises Directory Synchronisation** service account (`ADToAADSyncSer...`) — this is created automatically by Cloud Sync and is expected.

The three cloud-only accounts (sync-admin, m365admin, and your personal Microsoft account) will show **On-premises sync = No** — this is correct. These accounts must never be synchronised from AD.

---

## Troubleshooting

### "Let's keep your account secure" prompt during agent configuration

**Symptom:** The agent wizard sign-in is interrupted by a Microsoft Authenticator registration prompt.

**Cause:** This is caused by Security Defaults or Microsoft-managed Conditional Access policies enforcing MFA registration. As of late 2024/early 2025, Security Defaults ignore all group exclusions and Authentication Methods Policy exclusions — they enforce MFA registration tenant-wide and cannot be overridden by Conditional Access or Graph API calls.

**Fix:** In the Entra Admin Center, navigate to **Protection → Conditional Access → Policies** and temporarily disable the **MFA for all users** policy. Re-enable it immediately after the agent is successfully configured.

The recommended policy state during agent configuration:

| Policy | Temporary State |
|---|---|
| Block legacy authentication | ✅ On — leave enabled |
| MFA for admins | ✅ On — leave enabled |
| MFA for Azure management | ❌ Off |
| MFA for all users | ❌ Off — temporarily |

Re-enable MFA for all users immediately after the agent wizard completes. The provisioning agent runs as a gMSA service account and is not affected by MFA policies — it authenticates non-interactively as a service.

### "Require change password at next sign-in" blocks the wizard

**Symptom:** The wizard prompts to change the sync-admin password and cannot proceed.

**Fix:** In Entra Admin Center, go to **Users → sync-admin → Edit properties** and set **Require change password at next sign-in** to **No**. Retry the wizard.

### Domain dropdown only shows a stale domain

**Symptom:** The new configuration dropdown shows an old domain (e.g. `apex.local`) instead of `qcbhomelab.online`.

**Cause:** A stale agent registration from a previous lab exists in the tenant. The portal shows domains associated with registered agents.

**Fix:** The stale domain entry may not be directly deletable from the portal. A working workaround is to create a dummy configuration for the stale domain first — this clears the dropdown state — then create the correct configuration for `qcbhomelab.online`. Delete the dummy configuration afterwards.

### Provision on demand returns ResourceNotFound

**Symptom:** Testing a user in Provision on demand returns "The provisioning service was not able to find the input user."

**Cause:** The field requires the full Active Directory Distinguished Name, not just the username or SAM account name.

**Fix:** Use the full DN format:
```
CN=James Carter,OU=London,OU=Staff,OU=Accounts,DC=qcbhomelab,DC=online
```

To find the DN for any user, run this on DC01:
```powershell
Get-ADUser -Filter * -SearchBase "OU=Accounts,DC=qcbhomelab,DC=online" | Select-Object Name, DistinguishedName
```

---

## What to Expect

After completing these steps, users created in Active Directory will automatically appear in Microsoft 365 within 2 minutes of any change. Users can sign in to cloud services using their AD password. Licences are assigned automatically through group membership. Changes made in AD — name changes, department updates, group membership — will synchronise to the cloud within the next sync cycle.

The three cloud-only admin accounts will remain separate from the sync process and will never be overwritten by AD data.

---

## Common Questions & Troubleshooting

**Q1: Users are not appearing in Entra ID after sync. The agent shows as healthy but nothing is synchronising. What should I check first?**

Start with the scoping filter. Cloud Sync only synchronises objects within the configured OU scope — if users are in an OU that is not included in the sync scope, they will not appear in Entra ID regardless of agent health. In the Entra Admin Center, go to the Cloud Sync configuration and verify the OUs listed under scope match where your user accounts actually live. A common mistake is scoping to `OU=Staff` but having contractor accounts in `OU=Contractors` which is outside the scope.

**Q2: A user's password change on-premises is not reflecting in the cloud. They can still sign in using their old password. Why?**

Password Hash Synchronisation runs on its own cycle, separate from the attribute sync cycle. After a password change, it can take up to 2 minutes for the new hash to synchronise. If it is taking longer, check that the Password Hash Sync option is enabled in the Cloud Sync configuration and that the agent on DC01 is running and healthy. Also confirm the user's account is within the sync scope — if the account is out of scope, password hashes will not synchronise even if other attributes did previously.

**Q3: A synced user account is showing in Entra ID but cannot be assigned a Microsoft 365 licence. What is the problem?**

The most common cause is a missing usage location. Microsoft requires a usage location to be set on every user account before a licence can be assigned — it is a compliance requirement related to data residency. Synced accounts do not inherit this from AD automatically. Set it via PowerShell: `Update-MgUser -UserId <UPN> -UsageLocation "GB"` (or the appropriate country code). After setting the usage location, licence assignment should succeed immediately.

**Q4: A user was deleted from Active Directory but their account is still visible and active in Entra ID. Why has it not been removed?**

Deletion synchronisation follows the same cycle as creation, but there is an additional safety mechanism — Entra ID moves deleted accounts to a soft-delete state (the Entra ID Recycle Bin) rather than removing them immediately. This gives a 30-day recovery window. If you need to confirm a deletion has synchronised, check the Entra Admin Center under Deleted users — the account should appear there within a few minutes of the next sync cycle after deletion in AD.

**Q5: The Cloud Sync agent was installed but the Entra Admin Center shows it as disconnected or inactive. How do I get it back online?**

First check the Windows Service on DC01 — open Services and look for the Microsoft Entra Connect Provisioning Agent. If it is stopped, start it and check whether it stays running. If it crashes immediately, check the Windows Event Log under Applications and Services Logs > Microsoft > Azure AD Connect Provisioning Agent. The most common causes are: the service account password has changed, the agent's registration with Entra ID has expired (re-register via the agent installer), or a network change is blocking outbound HTTPS to Microsoft's endpoints.

---
