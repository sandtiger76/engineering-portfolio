[← 07 — Microsoft Teams](07-teams.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [09 — Intune: iOS MAM →](09-intune-ios.md)

---

# 08 — Intune: Windows Device Management & Patching

## Introduction

Microsoft Intune is the cloud-based device management service included in Microsoft 365 Business Premium. It allows IT to manage Windows laptops and desktops without needing a traditional on-premises tool like SCCM (System Centre Configuration Manager). Through Intune, you can enrol devices, enforce security policies, deploy applications, configure settings, and control Windows Update — all from a single web console, from anywhere.

For the users in this environment, every corporate Windows device is managed through Intune. This means the moment a device is enrolled, it receives the correct security baseline, compliance settings, and software configuration automatically — without the IT team needing to physically touch the machine.

Patching is managed through Windows Update for Business, which is configured via Intune Update Rings. An Update Ring is a policy that controls when and how Windows updates are installed. Rather than letting every device update unpredictably, Update Rings allow you to stage updates — testing them on a small group first before rolling them out to everyone else.

---

## What We Are Building

- Intune MDM authority configured for Windows
- Enrolment configured via Entra ID join
- Compliance policy defining what a healthy device looks like
- Configuration profile applying security settings
- Windows Update Ring for controlled patching
- OneDrive Known Folder Move policy to silently redirect Desktop, Documents, and Pictures to OneDrive

---

## Implementation Steps

### Step 1 — Confirm Intune is Active

Log in to the Microsoft Intune Admin Center at intune.microsoft.com. With Microsoft 365 Business Premium, Intune is already included and active. Confirm you can see the Devices and Policy sections in the left navigation.

### Step 2 — Configure Automatic Enrolment

Automatic enrolment ensures that when a user joins a Windows device to Entra ID (which happens during Windows setup or via Settings), the device is automatically enrolled in Intune without any additional steps.

In the Intune Admin Center, navigate to Devices → Windows → Windows Enrolment → Automatic Enrolment. Set the MDM User Scope to All. This ensures every Entra ID user who joins a device will trigger automatic Intune enrolment.

### Step 3 — Create a Compliance Policy

A compliance policy defines the minimum security requirements a device must meet. Devices that do not meet these requirements are marked non-compliant, and Conditional Access policies (document 10) can block their access to company data.

In the Intune Admin Center, navigate to Devices → Compliance → Create policy → Windows 10 and later.

Name the policy `POL-Compliance-Windows` and configure the following settings:

| Setting | Value |
|---|---|
| Require BitLocker | Required |
| Require Secure Boot | Required |
| Require code integrity | Required |
| Minimum OS version | 10.0.19041 (Windows 10 2004 minimum) |
| Password required | Yes |
| Minimum password length | 8 |
| Password complexity | Require digits, lowercase, uppercase |
| Maximum minutes of inactivity before password required | 15 |
| Firewall | Required |
| Antivirus | Required |

Assign the policy to all devices (or to the GRP-Devices-Windows group once devices are enrolled).

### Step 4 — Create a Security Configuration Profile

Configuration profiles push specific settings to devices. This profile applies the security baseline appropriate for a business environment.

Navigate to Devices → Configuration → Create → New policy → Windows 10 and later → Settings catalog.

Name the profile `PROF-Security-Baseline-Windows` and add the following settings:

Under Microsoft Defender Antivirus:
- Turn off Microsoft Defender Antivirus: Disabled (keeps Defender on)
- Real-time protection: Enabled

Under Windows Security:
- Allow Windows Security App: Allowed

Under BitLocker:
- Require device encryption: Enabled
- Allow standard user encryption: Enabled

Under Experience:
- Allow Cortana above lock: Not allowed

Assign the profile to all Windows devices.

### Step 5 — Configure OneDrive Known Folder Move

Known Folder Move silently redirects a user's Desktop, Documents, and Pictures folders to their OneDrive, ensuring files are always backed up to the cloud without requiring the user to do anything.

In the Configuration profile, add the following settings under OneDrive:

| Setting | Value |
|---|---|
| Silently move Windows known folders to OneDrive | Enabled |
| Tenant ID | 61ac0281-e32d-4a6f-a7d1-754f9ac66f5c |
| Show notification to users after folders have been redirected | Yes |
| Prevent users from redirecting their known folders back to their PC | Enabled |

### Step 6 — Create Windows Update Rings

Update Rings control when devices receive Windows feature updates and quality updates. Using rings prevents all devices from updating simultaneously and gives you time to catch any issues before they affect everyone.

Navigate to Devices → Windows → Update rings for Windows 10 and later → Create profile.

Create two rings:

**Ring 1 — Pilot (applied to IT / admin accounts first)**

| Setting | Value |
|---|---|
| Name | RING-Windows-Pilot |
| Quality update deferral | 0 days |
| Feature update deferral | 0 days |
| Active hours start | 8 AM |
| Active hours end | 6 PM |
| Restart grace period | 2 days |

**Ring 2 — Production (applied to all other users)**

| Setting | Value |
|---|---|
| Name | RING-Windows-Production |
| Quality update deferral | 7 days |
| Feature update deferral | 30 days |
| Active hours start | 8 AM |
| Active hours end | 6 PM |
| Restart grace period | 5 days |

Assign the Pilot ring to a test user or admin account. Assign the Production ring to GRP-AllStaff.

This means security patches reach production devices 7 days after release, and feature updates (major Windows versions) are held for 30 days — giving Microsoft time to pull any problematic updates before they reach the wider user base.

### Step 7 — Enrol a Test Device

To test the enrolment flow, on a Windows 10 or 11 device:

1. Go to Settings → Accounts → Access work or school → Connect
2. Sign in with a user account (e.g. j.carter@qcbhomelab.online)
3. Select Join this device to Azure Active Directory
4. Complete sign-in — the device will join Entra ID and enrol in Intune automatically

In the Intune Admin Center, navigate to Devices → All devices and confirm the device appears and shows as compliant after policies are applied (this may take 15 to 30 minutes).

---

## What to Expect

Once enrolled, devices receive all configuration profiles and compliance policies automatically. The IT team can see every managed device from the Intune portal, check compliance status, remotely wipe a lost device, and confirm patch status — all without needing physical access to the machine.

---

[← 07 — Microsoft Teams](07-teams.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [09 — Intune: iOS MAM →](09-intune-ios.md)
