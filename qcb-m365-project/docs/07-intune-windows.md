# 07 — Intune: Windows Device Management

## In Plain English

When a member of staff uses their laptop to access company email and files, the company has an interest in whether that laptop is secure. Is the hard drive encrypted? Is the screen locked when unattended? Is the operating system up to date with security patches? On a file server model, Group Policy controlled these things — but Group Policy requires an on-premises domain controller and only works when the machine is on the corporate network.

Microsoft Intune replaces Group Policy for cloud-managed devices. It delivers security settings, compliance requirements, and configuration policies directly over the internet — no domain controller required, no VPN needed. A laptop in a home office or a coffee shop receives the same policies as one sitting in the office.

Intune does two distinct things: it checks whether a device meets the company's security requirements (compliance), and it configures devices to specific settings (configuration profiles). Both are used in this project.

---

## Why This Matters

A managed, compliant device is the second pillar of the Zero Trust model implemented in this project. MFA proved who the user is. Device compliance proves that the device they are using meets the company's security standards.

Without device management:
- There is no way to know if a company laptop has disk encryption enabled
- A lost or stolen device with no screen lock gives an attacker immediate access to everything
- An unpatched operating system is vulnerable to known exploits
- If someone leaves the company, their access to corporate data cannot be revoked at the device level

With Intune:
- Every managed device is required to meet compliance standards before accessing Microsoft 365
- Devices that fall out of compliance are automatically blocked from accessing company data
- Configuration policies push security settings consistently across all devices
- Corporate data can be remotely wiped from a lost or stolen device

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Microsoft 365 Business Premium licences assigned | Intune Plan 1 is included |
| GRP-ManagedDevices security group created | Created in workstream 01 |
| Cloudflare DNS access | For Intune CNAME records |
| Windows laptop available | QCB-LAPTOP-01 — the physical device to enrol |
| CA-04 in Report-only mode | Enables compliant device requirement without risk of lockout |

---

## The End State

| Component | State |
|---|---|
| Intune tenant | Active — Microsoft 365 Business Premium includes Intune Plan 1 |
| DNS CNAMEs | enterpriseenrollment and enterpriseregistration added to Cloudflare |
| Windows compliance policy | COMP-WIN-Corporate-Standard — BitLocker, screen lock, OS version, firewall |
| Security baseline profile | Microsoft Windows 10/11 security baseline applied |
| Update rings | Pilot (0 day deferral) and Production (7 day deferral) |
| OneDrive configuration profile | Files On-Demand enabled, silent sign-in configured |
| QCB-LAPTOP-01 | Entra joined, Intune enrolled, compliant |
| CA-04 | Switched from Report-only to On after laptop is compliant |

---

## Phase 1 — Intune DNS Configuration

### Step 1 — Add Intune Enrolment CNAME Records to Cloudflare

These DNS records allow Windows devices to automatically discover the Intune enrolment service when a user signs in with their work account. Without them, enrolment requires manual configuration.

Add the following CNAME records to Cloudflare DNS for `qcbhomelab.online`:

| Type | Name | Value |
|---|---|---|
| CNAME | enterpriseenrollment | enterpriseenrollment-s.manage.microsoft.com |
| CNAME | enterpriseregistration | enterpriseregistration.windows.net |

After adding:
1. Wait 5–10 minutes for DNS propagation
2. Verify via PowerShell:

```powershell
Resolve-DnsName -Name "enterpriseenrollment.qcbhomelab.online" -Type CNAME
Resolve-DnsName -Name "enterpriseregistration.qcbhomelab.online" -Type CNAME
```

Both should return the Microsoft target values.

### Step 2 — Confirm Intune Is Active

1. Navigate to **Microsoft Intune Admin Center** at `https://intune.microsoft.com`
2. Sign in as `m365admin@qcbhomelab.online`
3. Go to **Devices** → **Overview**
4. Confirm the tenant shows as licensed for Intune

---

## Phase 2 — Windows Compliance Policy

### Step 3 — Create the Windows Compliance Policy

The compliance policy defines what a "compliant device" means for QCB Homelab Consultants. This policy is referenced by Conditional Access Policy CA-04 — a device that does not meet these requirements is blocked from accessing Microsoft 365 applications.

1. Navigate to **Intune Admin Center** → **Devices** → **Compliance** → **+ Create policy**
2. Platform: **Windows 10 and later** → **Create**
3. Name: `COMP-WIN-Corporate-Standard`
4. Description: `Corporate standard compliance requirements for QCB Homelab Consultants Windows devices`

Configure the following settings:

**Device Health:**
| Setting | Value |
|---|---|
| Require BitLocker | Require |
| Require Secure Boot to be enabled on the device | Require |
| Require code integrity | Require |

**Device Properties:**
| Setting | Value |
|---|---|
| Minimum OS version | 10.0.19045 (Windows 10 22H2) |
| Maximum OS version | Not configured |

**System Security:**
| Setting | Value |
|---|---|
| Require a password to unlock mobile devices | Require |
| Simple passwords | Block |
| Password type | Alphanumeric |
| Minimum password length | 8 |
| Maximum minutes of inactivity before password is required | 5 |
| Firewall | Require |
| Antivirus | Require |
| Anti-spyware | Require |

5. **Assignments** → **Add groups** → select **GRP-ManagedDevices** (add the enrolled device to this group after enrolment in Phase 4)
6. Alternatively, assign to **All devices** for simplicity in this lab
7. **Actions for noncompliance:**
   - Mark device noncompliant: **Immediately**
   - Send email to end user: **1 day after noncompliance**
8. Click **Review + create** → **Create**

---

## Phase 3 — Configuration Profiles

### Step 4 — Apply Windows Security Baseline

The Microsoft Windows security baseline is a collection of 150+ settings recommended by Microsoft's security team, based on feedback from enterprise customers and government agencies. Applying a security baseline is significantly faster than configuring individual settings and ensures nothing is missed.

1. Navigate to **Intune Admin Center** → **Endpoint security** → **Security baselines**
2. Select **Microsoft Security Baseline for Windows 10 and later**
3. Click **+ Create profile**
4. Name: `CFG-WIN-Security-Baseline`
5. Review the default settings — accept all defaults for this deployment
6. **Assignments** → assign to **All devices** (or GRP-ManagedDevices)
7. Click **Review + create** → **Create**

> The security baseline includes settings for BitLocker, Windows Defender, account lockout, network security, and many others. It does not conflict with the compliance policy — the compliance policy checks requirements; the baseline enforces specific settings.

### Step 5 — Create OneDrive Configuration Profile

The OneDrive configuration profile enables Files On-Demand and configures silent sign-in — meaning users are automatically signed into the OneDrive sync client using their Windows credentials without being prompted.

1. Navigate to **Intune Admin Center** → **Devices** → **Configuration** → **+ Create** → **New policy**
2. Platform: **Windows 10 and later** → Profile type: **Settings catalog** → **Create**
3. Name: `CFG-WIN-OneDrive-Settings`
4. Click **+ Add settings** and search for each setting:

| Category | Setting | Value |
|---|---|---|
| OneDrive | Use OneDrive Files On-Demand | Enabled |
| OneDrive | Silently sign in users to the OneDrive sync client with their Windows credentials | Enabled |
| OneDrive | Set the sync client update ring | Production |
| OneDrive | Prevent users from syncing libraries and folders they do not own | Enabled |

5. **Assignments** → assign to **All devices**
6. Click **Review + create** → **Create**

### Step 6 — Create Windows Update Rings

Windows Update rings control when devices receive Windows updates. Two rings are created: a Pilot ring for early testing, and a Production ring for all other devices.

**Create the Pilot ring:**

1. Navigate to **Intune Admin Center** → **Devices** → **Update rings for Windows 10 and later** → **+ Create**
2. Name: `UPD-WIN-Pilot`
3. Configure:

| Setting | Value |
|---|---|
| Servicing channel | General Availability Channel |
| Feature update deferral period | 0 days |
| Quality update deferral period | 0 days |
| Automatic update behavior | Auto install and restart at scheduled time |

4. Assignments: assign `casey.quinn@qcbhomelab.online` (field worker as pilot tester)
5. Click **Review + create** → **Create**

**Create the Production ring:**

1. Click **+ Create** again
2. Name: `UPD-WIN-Production`
3. Configure:

| Setting | Value |
|---|---|
| Servicing channel | General Availability Channel |
| Feature update deferral period | 7 days |
| Quality update deferral period | 7 days |
| Automatic update behavior | Auto install and restart at scheduled time |

4. Assignments: assign **All devices**
5. Click **Review + create** → **Create**

> The Pilot ring receives updates with no deferral — it is the first to receive any update and allows issues to be identified before the wider rollout. The Production ring defers updates by 7 days, providing a window to catch problems. In a larger organisation, deferral periods of 14–30 days are common.

---

## Phase 4 — Enrol the Windows Laptop

### Step 7 — Enrol QCB-LAPTOP-01

The Windows laptop is enrolled by joining it to Microsoft Entra ID. Once joined, Intune enrolment happens automatically.

> **Before starting:** Confirm the laptop is running Windows 10 (version 22H2 or later) or Windows 11. Confirm it is connected to the internet and signed in with a local administrator account. Confirm it is **not** currently joined to any domain or Azure AD.

1. On QCB-LAPTOP-01, open **Settings** → **Accounts** → **Access work or school**
2. Click **Connect** → **Join this device to Azure Active Directory**
3. Enter the username: `jordan.hayes@qcbhomelab.online`
4. Enter the password and complete MFA
5. Confirm the organisation name: **QCB Homelab Consultants**
6. Click **Join** → **Done**
7. **Restart the device**
8. On the sign-in screen, select **Other user** → sign in as `jordan.hayes@qcbhomelab.online`
9. The device is now Entra joined — Intune enrolment begins automatically in the background

### Step 8 — Verify Device in Intune

After sign-in, Intune enrolment takes approximately 5–15 minutes.

1. Navigate to **Intune Admin Center** → **Devices** → **All devices**
2. The laptop should appear within 15 minutes with device name `QCB-LAPTOP-01` (or the computer's hostname)
3. Click the device → review:
   - **Compliance state:** Will initially show as **Not evaluated** → progresses to **Compliant** or **Not compliant**
   - **Device configuration:** Profiles applied
   - **Last check-in:** Confirms device is communicating with Intune

4. Add the device to **GRP-ManagedDevices** group:
   - Navigate to **Entra Admin Center** → **Groups** → **GRP-ManagedDevices** → **Members** → **+ Add members**
   - Search for the device by name → add it

Via PowerShell:

```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

Get-MgDeviceManagementManagedDevice |
    Select-Object DeviceName, ComplianceState, OperatingSystem, LastSyncDateTime |
    Format-Table
```

### Step 9 — Verify Compliance

1. In **Intune Admin Center** → **Devices** → click the enrolled device → **Device compliance**
2. Review each compliance setting:
   - If BitLocker is not yet enabled on the laptop, the device will show as **Not compliant**
   - Enable BitLocker: **Settings** → **Update & Security** → **Device encryption** → **Turn on**
   - Allow 15–30 minutes for Intune to re-evaluate after BitLocker is enabled

> A device that is not compliant will be blocked from Microsoft 365 once CA-04 is switched to On. Ensure compliance is achieved before that step.

---

## Phase 5 — Enable CA-04

### Step 10 — Switch CA-04 from Report-Only to On

Once QCB-LAPTOP-01 is enrolled and shows as **Compliant** in Intune, and the iPhone MAM policy is configured (workstream 08), CA-04 can be switched to enforcement mode.

1. Navigate to **Entra Admin Center** → **Protection** → **Conditional Access** → **Policies**
2. Click **CA-04-Require-Compliant-Device-Or-MAM**
3. Set **Enable policy** to **On**
4. Click **Save**

Test immediately:
1. Sign in to `https://portal.office.com` as `jordan.hayes@qcbhomelab.online` from the enrolled, compliant laptop → confirm access is granted
2. Attempt to sign in from an unmanaged device (a personal computer or browser without MAM) → confirm access is blocked or restricted

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| DNS CNAMEs in place | Resolve-DnsName for both CNAMEs | Returns Microsoft target values |
| Compliance policy created | Intune → Compliance | COMP-WIN-Corporate-Standard listed |
| Security baseline applied | Intune → Endpoint security → Security baselines | CFG-WIN-Security-Baseline applied to device |
| OneDrive profile applied | Intune → Devices → Config profiles | CFG-WIN-OneDrive-Settings applied |
| Update rings created | Intune → Update rings | UPD-WIN-Pilot and UPD-WIN-Production listed |
| Laptop enrolled | Intune → All devices | QCB-LAPTOP-01 listed |
| Laptop compliant | Intune → device → Compliance | Compliant |
| OneDrive sync client configured | Check OneDrive in system tray on laptop | Cloud icons (Files On-Demand), signed in automatically |
| CA-04 enforcing | Sign in from enrolled device | Access granted |

---

## Summary

This workstream delivered:

- **Intune DNS CNAMEs** added to Cloudflare — automatic enrolment discovery enabled
- **Windows compliance policy** `COMP-WIN-Corporate-Standard` — BitLocker, screen lock, OS version, firewall required
- **Security baseline** applied — 150+ hardened settings from Microsoft's security recommendations
- **OneDrive configuration profile** — Files On-Demand and silent sign-in configured
- **Windows Update rings** — Pilot (immediate) and Production (7-day deferral)
- **QCB-LAPTOP-01** enrolled in Intune via Entra ID join — compliant
- **CA-04** switched to enforcement — compliant device or MAM required for M365 access

The device pillar of the Zero Trust model is now active. Every access to Microsoft 365 from a Windows device requires that device to be enrolled in Intune and meeting the compliance policy.

**Next:** [08 — Intune: iOS MAM](./08-intune-ios-mam.md)
