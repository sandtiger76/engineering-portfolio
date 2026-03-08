# 01a — Entra Connect Installation

## In Plain English

Entra Connect is a small piece of software installed on the on-premises server that acts as a bridge between the local Active Directory and Microsoft 365. Once it is running, every user account in Active Directory is automatically mirrored into the cloud — staff can log in to Microsoft 365 with the same username and password they already use at work. Without this, every account would need to be created in the cloud by hand, one at a time.

## Why This Matters

QCB Homelab Consultants has 15 user accounts already defined in Active Directory on QCBHC-DC01. Recreating them manually in Entra ID would introduce inconsistencies, waste time, and leave no repeatable process for future starters. Entra Connect solves all three problems: it reads the existing accounts from `apex.local`, creates matching cloud identities in the `qcbhomelab.online` tenant, and keeps them in sync automatically thereafter. This is the foundation on which every subsequent workstream — email, file migration, device management, and security policy — depends.

## Prerequisites

| Requirement | Status |
|---|---|
| QCBHC-DC01 running Windows Server 2022 | ✅ Confirmed |
| Active Directory domain: `apex.local` | ✅ Confirmed |
| 15 user accounts with UPN suffix `@qcbhomelab.online` | ✅ Confirmed |
| M365 tenant `qcbhomelab.online` verified as default domain | ✅ Confirmed |
| Working admin account: `m365admin@qcbhomelab.online` | ✅ Confirmed |
| Entra Connect installer downloaded from Microsoft | ✅ Required before starting |
| Domain Controller not running AD FS or existing sync tool | ✅ Confirmed — clean install |

> **Note:** Entra Connect must be installed on a domain-joined machine with line-of-sight to a Domain Controller. In this lab, it is installed directly on QCBHC-DC01.

---

## Key Decision: Express vs Custom Settings

Entra Connect offers two installation paths. The choice matters and should be documented for any real engagement.

### Express Settings

- Single Active Directory forest
- Single domain
- Password hash synchronisation (PHS) — the recommended and most resilient sign-in method
- Automatic sync every 30 minutes
- No federation, no pass-through authentication, no staging mode

### Custom Settings

Required when the environment has multiple forests or domains, uses AD FS or pass-through authentication, needs attribute filtering, runs a hybrid Exchange deployment, or requires a custom sync schedule.

### Decision for This Deployment

**Express Settings were selected.** QCB Homelab Consultants has a single forest (`apex.local`), a single domain, and no existing Microsoft Online Services directory. There is no Exchange on-premises, no AD FS, and no requirement for custom attribute filtering. Express is the correct and supportable choice. It also reflects real-world best practice for SME engagements at this scale — introducing unnecessary complexity into a straightforward single-domain deployment would be a consulting anti-pattern.

> For any engagement where the environment deviates from single-forest/single-domain, revisit this decision before installation. Custom settings cannot be retrofitted without reinstalling the tool.

---

## Installation Procedure

### Step 1 — Download Entra Connect

Download the installer from Microsoft's official page:

```
https://www.microsoft.com/en-us/download/details.aspx?id=47594
```

File: `AzureADConnect.msi`

Save to the domain controller QCBHC-DC01 and verify the file before running.

> **Screenshot:** `01_download_entra_connect.png` — Microsoft download page confirming the installer

---

### Step 2 — Launch the Installer

Run `AzureADConnect.msi` on QCBHC-DC01. Accept the licence agreement on the welcome screen and proceed.

> **Screenshot:** `02_installer_welcome.png` — Welcome screen with licence agreement checkbox

---

### Step 3 — Select Express Settings

On the installation method screen, select **Use express settings**.

The screen confirms the actions Express Settings will perform:
- Synchronise identity data from `apex.local`
- Enable Password Hash Synchronisation
- Synchronise all users and devices
- Enable auto-upgrade

> **Screenshot:** `03_express_settings_selected.png` — Express settings selection screen

---

### Step 4 — Connect to Microsoft Entra ID

Enter the M365 Global Administrator credentials:

- **Username:** `m365admin@qcbhomelab.online`
- **Password:** *(credentials not recorded in documentation)*

The installer verifies connectivity to the Entra ID tenant. This step fails if the account does not have Global Administrator privileges or if MFA interrupts the flow.

> **Screenshot:** `04_entra_credentials.png` — Entra ID credentials entry screen  
> **Screenshot:** `05_entra_credentials_verified.png` — Credential verification confirmed

---

### Step 5 — Connect to Active Directory

Enter the AD DS Connector credentials. The installer requires an account with **Enterprise Admin** privileges in `apex.local`.

- **Username:** `APEX\Administrator` (or `Administrator@apex.local`)
- **Password:** *(credentials not recorded in documentation)*

The installer validates the AD DS account and identifies the `apex.local` forest.

> **Screenshot:** `06_ad_credentials.png` — AD DS credentials entry screen  
> **Screenshot:** `07_ad_forest_verified.png` — apex.local forest identified and validated

---

### Step 6 — UPN and Domain Verification

The installer inspects the UPN suffixes configured in Active Directory and compares them against verified domains in the Entra ID tenant.

Expected result: `@qcbhomelab.online` is listed as a **Verified** suffix. This was set in advance — all 15 user accounts in AD have their UPN suffix set to `@qcbhomelab.online`, and that domain is confirmed as the default in the M365 tenant.

> **Screenshot:** `08_upn_verification.png` — UPN suffix table showing @qcbhomelab.online as Verified

> **What to do if the UPN shows as Not Verified:** This means the domain has not been added and verified in the M365 admin centre. Do not proceed — return to the tenant configuration and complete domain verification first.

---

### Step 7 — Review Configuration and Install

The installer presents a summary screen listing all selected options before making any changes:

- Entra ID tenant: `qcbhomelab.online`
- AD forest: `apex.local`
- Sign-in method: Password Hash Synchronisation
- Sync scope: All users and devices
- Start synchronisation when configuration completes: **checked**

Review the summary. Click **Install**.

> **Screenshot:** `09_ready_to_configure.png` — Configuration summary before installation

---

### Step 8 — Installation Complete

The installation runs and completes. The final screen confirms:

- Configuration complete
- Synchronisation has started
- The Entra Connect service is running

> **Screenshot:** `10_installation_complete.png` — Installation complete confirmation screen

---

## Post-Installation Checks

### Check the Sync Service is Running

On QCBHC-DC01, open **Services** (`services.msc`) and confirm:

| Service | Expected State |
|---|---|
| Microsoft Azure AD Sync | Running |

```powershell
# PowerShell alternative
Get-Service -Name "ADSync"
```

> **Screenshot:** `11_adsync_service_running.png` — Services console showing ADSync as Running

---

### Trigger a Manual Sync (Optional Verification Step)

The installer starts an initial sync automatically, but a manual delta sync can be triggered immediately to confirm the service is responsive:

```powershell
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
```

> **Screenshot:** `12_manual_sync_triggered.png` — PowerShell output confirming sync cycle started

---

### Check the Entra Connect Health Dashboard (Optional)

In the Microsoft Entra admin centre, navigate to:

**Identity → Hybrid management → Microsoft Entra Connect**

This dashboard confirms the sync tool is registered, shows the last sync time, and flags any errors.

> Full sync verification — confirming that all 15 users have appeared in Entra ID with correct attributes and assigned licences — is covered in the next page: **01b — Entra Connect Sync Verification**.

---

## Validation

| Check | Expected Result |
|---|---|
| ADSync service running on QCBHC-DC01 | ✅ Service status: Running |
| Entra Connect registered in Entra admin centre | ✅ Shown as connected |
| Initial sync completed without errors | ✅ Confirmed in sync log |
| UPN suffix `@qcbhomelab.online` verified during install | ✅ No UPN mismatch warnings |

---

## Summary

Entra Connect has been installed on QCBHC-DC01 using Express Settings. The tool is configured to synchronise the `apex.local` forest to the `qcbhomelab.online` Entra ID tenant using Password Hash Synchronisation, with an automatic sync cycle every 30 minutes. The initial synchronisation cycle has started.

Express Settings were chosen deliberately — this is a single-forest, single-domain SME environment with no federation, no hybrid Exchange, and no requirement for custom attribute filtering. The decision is documented and repeatable.

**This enables:** Sync verification (01b), group creation and licence assignment (01d), and all downstream workstreams that require cloud identities to exist before proceeding.

**Next page:** [01b — Entra Connect Sync Verification](./01b-entra-connect-sync-verification.md)
