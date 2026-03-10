# 07 — Intune Device Management

## In Plain English

QCB Homelab Consultants has no way of knowing whether the laptops staff use to access company data are secure. There is no encryption requirement, no screen lock enforcement, and no way to remotely wipe a device if it is lost or stolen. This workstream deploys Microsoft Intune to manage company devices — enforcing encryption, screen lock, and operating system currency — and replaces the third-party VPN with a policy-driven model where only compliant, managed devices can access company resources.

## Why This Matters

The existing VPN-based remote access model gives equal access to any device that can authenticate, regardless of whether that device has disk encryption enabled, current security patches, or a screen lock. A lost laptop with access credentials stored is a significant data breach risk. Intune solves this by making device compliance a prerequisite for access — if a device is not managed and not compliant, it cannot reach company data, regardless of whether the user has valid credentials. This is the device pillar of the Zero Trust model implemented across this project.

## Prerequisites

- Microsoft 365 Business Premium licences assigned to all staff — Intune is included (completed in `01d`)
- Conditional Access policy from `01f` referencing compliant device requirement
- Entra ID users in place (workstream `01a`/`01b`)
- `enterpriseenrollment.qcbhomelab.online` CNAME added to Cloudflare DNS — enables automatic enrolment discovery
- `enterpriseregistration.qcbhomelab.online` CNAME added to Cloudflare DNS — enables device registration
- Windows 10/11 device available for lab enrolment

---

## Intune Architecture for QCB Homelab Consultants

```
Intune (Device Management)
├── Compliance Policies
│   └── Windows Compliance Policy
│       ├── BitLocker: Required
│       ├── Screen lock: Required (5 min timeout)
│       ├── Min OS: Windows 10 22H2 / Windows 11 22H2
│       └── Firewall: Required
├── Configuration Profiles
│   └── OneDrive Settings (Files On-Demand, silent sign-in)
├── Enrolment
│   └── Azure AD Join (lab method)
│   └── Autopilot (production method — documented below)
└── Conditional Access (enforced in Entra ID)
    └── Require compliant device → references Intune compliance result
```

---

## Phase 1 — Intune Configuration Baseline

### Access Intune Admin Center

1. Navigate to `https://intune.microsoft.com`
2. Sign in as `m365admin@qcbhomelab.online`
3. Confirm the Intune service plan is active: **Devices** → **Overview** — tenant should show as licensed

> **Screenshot:** `screenshots/07-intune/01_intune_overview.png`
> *Intune Admin Center overview showing tenant licensed and ready*

---

## Phase 2 — Compliance Policy

### Key Decision: Compliance Policy Drives Conditional Access

The Intune compliance policy defines what a "compliant device" means. This matters because the Conditional Access policy (workstream `01f`) requires device compliance as a condition for accessing Microsoft 365 resources. The two work together:

- Intune evaluates the device and assigns a compliance status
- Conditional Access checks that status before granting access
- A non-compliant device is blocked, regardless of user credentials

### Create Windows Compliance Policy

1. Navigate to **Intune Admin Center** → **Devices** → **Compliance**
2. Click **Create policy** → **Windows 10 and later**
3. Name the policy: `QCB-Windows-Compliance`

Configure the following settings:

**Device Health:**
| Setting | Value |
|---|---|
| Require BitLocker | Required |
| Require Secure Boot | Required |
| Require code integrity | Required |

**Device Properties:**
| Setting | Value |
|---|---|
| Minimum OS version | `10.0.19045` (Windows 10 22H2) |
| Maximum OS version | Not configured |

**System Security:**
| Setting | Value |
|---|---|
| Require a password to unlock mobile devices | Required |
| Simple passwords | Block |
| Password type | Alphanumeric |
| Minimum password length | 8 |
| Maximum minutes of inactivity before password is required | 5 |
| Password expiration | 90 days |
| Firewall | Required |
| Antivirus | Required |
| Anti-spyware | Required |

4. **Assignments:** Assign to **All Devices** (or to a device group if phased rollout preferred)
5. **Actions for noncompliance:** Mark device non-compliant immediately; notify user via email after 1 day
6. Click **Review + create** → **Create**

> **Screenshot:** `screenshots/07-intune/02_compliance_policy_created.png`
> *Intune compliance policy showing all settings configured*

---

## Phase 3 — Configuration Profile (OneDrive Settings)

As documented in workstream `04`, the OneDrive Files On-Demand policy should be deployed via Intune before users sign into the sync client.

### Create OneDrive Configuration Profile

1. Navigate to **Devices** → **Configuration** → **Create** → **New policy**
2. Platform: **Windows 10 and later**
3. Profile type: **Settings catalog**
4. Name: `QCB-OneDrive-Settings`

Add the following settings from the Settings Catalog:

| Category | Setting | Value |
|---|---|---|
| OneDrive | Use OneDrive Files On-Demand | Enabled |
| OneDrive | Silently sign in users to the OneDrive sync client with their Windows credentials | Enabled |
| OneDrive | Set the sync client update ring | Production |
| OneDrive | Prevent users from syncing libraries and folders they do not own | Enabled |

5. Assign to **All Devices**
6. Click **Review + create** → **Create**

> **Screenshot:** `screenshots/07-intune/03_onedrive_config_profile.png`
> *Intune configuration profile showing OneDrive settings*

---

## Phase 4 — Device Enrolment (Lab Method: Manual Azure AD Join)

### Lab Enrolment Method: Manual Azure AD Join

In the lab environment, devices are enrolled by manually joining them to Azure AD (Entra ID). This is not the recommended production method but is appropriate for demonstrating the enrolment process.

**Enrolment steps on the Windows device:**

1. Open **Settings** → **Accounts** → **Access work or school**
2. Click **Connect** → **Join this device to Azure Active Directory**
3. Sign in with a staff account: `alice.martin@qcbhomelab.online`
4. Confirm the organisation name: **QCB Homelab Consultants**
5. Click **Join**
6. Restart the device

After restart, sign in with the Entra ID account. The device is now Entra joined.

> **Screenshot:** `screenshots/07-intune/04_aad_join_complete.png`
> *Windows Settings showing device joined to Azure AD - QCB Homelab Consultants*

### Verify Enrolment in Intune

1. In **Intune Admin Center** → **Devices** → **All devices**
2. The enrolled device should appear within 5–15 minutes
3. Click the device → verify **Compliance state** (will initially show as **Not evaluated** → progresses to **Compliant** or **Not compliant**)

> **Screenshot:** `screenshots/07-intune/05_device_enrolled_intune.png`
> *Intune All devices showing the enrolled Windows device*

> **Screenshot:** `screenshots/07-intune/06_device_compliance_status.png`
> *Intune device detail showing compliance status and applied policies*

---

## Phase 5 — GPO to Intune Mapping

### Key Decision: Intune Replaces Group Policy for Cloud-Managed Devices

The Windows Server DC (QCBHC-DC01) currently applies Group Policy to domain-joined machines. Once devices are Entra-joined and managed by Intune, Group Policy no longer applies — Intune configuration profiles and compliance policies replace GPO entirely.

This mapping table documents the equivalent for each significant GPO setting:

| Group Policy Setting | GPO Path | Intune Equivalent |
|---|---|---|
| BitLocker encryption required | `Computer Config → Windows Settings → Security Settings → BitLocker` | Compliance policy → BitLocker: Required |
| Screen lock after 5 minutes | `Computer Config → Admin Templates → Control Panel → Personalization` | Compliance policy → Max inactivity: 5 min |
| Windows Firewall enabled | `Computer Config → Windows Settings → Security Settings → Windows Firewall` | Compliance policy → Firewall: Required |
| Password complexity | `Computer Config → Windows Settings → Security Settings → Account Policies` | Compliance policy → Password type: Alphanumeric |
| Windows Update settings | `Computer Config → Admin Templates → Windows Update` | Windows Update for Business profile in Intune |
| OneDrive Files On-Demand | `Computer Config → Admin Templates → OneDrive` | Configuration profile → Settings Catalog → OneDrive |
| Software restriction | `Computer Config → Windows Settings → Security Settings → Software Restriction` | Intune → Apps → App protection policies |
| Drive mapping (H: drive) | `User Config → Windows Settings → Drive Maps` | **Replaced** — OneDrive sync client (workstream 04) |

> **Note:** Not all GPO settings have direct Intune equivalents. Complex GPO configurations may require Intune ADMX templates, PowerShell scripts deployed via Intune, or re-evaluation of whether the setting is still needed.

---

## Why Intune Replaces the VPN

The third-party VPN was used for two purposes:

1. **Remote access to file shares** — `\\QCBHC-DC01\Company` and `\\QCBHC-DC01\Home`
2. **Remote access to AD-joined resources**

Both of these dependencies are eliminated by this project:

| Old Requirement | Replacement |
|---|---|
| VPN to access Company share | SharePoint Online (workstream 03) — accessible from any browser |
| VPN to access H: drive | OneDrive for Business (workstream 04) — synced locally |
| VPN for AD authentication | Entra ID — authentication happens in the cloud |
| VPN for Group Policy | Intune — policy delivered over internet |

Conditional Access (workstream `01f`) enforces that only compliant, Intune-managed devices can access Microsoft 365 resources. This achieves the same access control as a VPN — but without requiring a VPN connection, and with real-time compliance checking rather than network perimeter trust.

---

## Autopilot: The Production Enrolment Method

### Key Decision: Document Autopilot as the Production Standard

Manual Azure AD Join is acceptable for a lab. In a production engagement, new devices should be enrolled via Windows Autopilot — a zero-touch provisioning service that configures a new device out of the box without IT intervention.

**How Autopilot works:**

1. Hardware vendor (Dell, HP, Lenovo etc.) or the IT team uploads device hardware hashes to the Microsoft 365 tenant
2. When a new device is powered on and connected to the internet, it checks against the Autopilot service
3. The device is automatically Entra joined, Intune enrolled, and all configuration profiles applied — without the user or IT touching a management image
4. The user signs in with their Microsoft 365 credentials and the device is ready

**Autopilot advantages over manual enrolment:**

| Advantage | Detail |
|---|---|
| Zero-touch | IT does not need to handle the device before deployment |
| Consistent | Every device receives the same policy — no variation |
| Scalable | Works for 1 device or 1,000 |
| Remote deployment | Works even if IT and user are in different locations |
| Replacement | If a device is lost, a replacement is shipped and configured automatically |

**What would be required to implement Autopilot for QCB Homelab Consultants:**

1. Purchase new devices from an Autopilot-capable vendor (most major OEMs)
2. Request vendor to upload hardware hashes to the tenant at time of purchase
3. Create an Autopilot deployment profile in Intune (join type: Entra joined, user-driven)
4. Assign the profile to the device group
5. Ship device to user — user powers on, signs in, device configures itself

> **Screenshot:** `screenshots/07-intune/07_autopilot_profile.png`
> *Intune Autopilot deployment profile — documented as the production standard*

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Compliance policy created | Intune → Compliance | QCB-Windows-Compliance listed |
| OneDrive profile created | Intune → Configuration | QCB-OneDrive-Settings listed |
| Device enrolled | Intune → All devices | Test device appears |
| Compliance evaluated | Device detail | Compliant (if BitLocker enabled) or Not compliant with reason |
| Policies applied to device | Device detail → Device configuration | Both profiles show Applied |
| Conditional Access enforced | Attempt access from non-compliant device | Access blocked |
| OneDrive Files On-Demand | Check OneDrive sync client on device | Cloud icons visible, not all files downloaded |

### Verify Compliance via PowerShell

```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Get all managed devices and compliance state
Get-MgDeviceManagementManagedDevice | Select-Object DeviceName, ComplianceState, OperatingSystem, LastSyncDateTime
```

---

## Summary

This workstream delivered the following:

- **Intune compliance policy** created — BitLocker, screen lock, firewall, minimum OS version enforced
- **OneDrive configuration profile** deployed — Files On-Demand and silent sign-in configured before user sync
- **Windows device enrolled** via manual Azure AD Join — demonstrates the enrolment process
- **GPO to Intune mapping** documented — every significant Group Policy setting mapped to its Intune equivalent
- **VPN dependency eliminated** — SharePoint, OneDrive, and Conditional Access replace the function of the VPN
- **Autopilot** documented as the production standard for zero-touch device provisioning

**What this enables next:**

- Conditional Access policy (workstream `01f`) can now enforce device compliance as a condition of access
- Enrolled devices automatically receive the OneDrive policy before sync — preventing overwrite issues
- The VPN subscription can be cancelled once all staff devices are enrolled and compliant
- Decommission of QCBHC-DC01 (workstream 09) removes the last dependency on on-premises Group Policy
