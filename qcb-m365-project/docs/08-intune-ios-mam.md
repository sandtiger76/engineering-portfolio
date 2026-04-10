# 08 — Intune: iOS Mobile Application Management (MAM)

## In Plain English

Casey Quinn is the field worker at QCB Homelab Consultants. She works from client sites and does not use a company-issued laptop — she accesses company email and files from her personal iPhone.

There is a meaningful difference between managing a company laptop and managing someone's personal phone. A company laptop belongs to the organisation — it is reasonable to manage it fully, wipe it remotely, and control what software is installed. A personal phone is different. It contains personal photos, private messages, banking apps, and everything else in someone's personal life. Enrolling it in full MDM (Mobile Device Management) gives the company the ability to remotely wipe the entire device. That is unreasonable, and in some jurisdictions it raises legal questions about employer overreach.

MAM without enrolment is the solution. Instead of managing the device, the company manages only the applications — specifically, Outlook and Teams. Within those applications, corporate data is protected by policy. Outside those applications, the device is untouched.

---

## Why This Matters

Without any protection on Casey's personal iPhone:
- Company email and files are accessible to anyone who picks up the phone (no PIN on the apps)
- Casey could copy a sensitive client document from Outlook into a personal notes app, a personal cloud storage service, or send it to a personal email address
- If Casey leaves the company, company data remains on her personal device indefinitely

With MAM app protection:
- Outlook and Teams require a PIN to open, separate from the phone's own PIN
- Data cannot be copied from Outlook into an unmanaged app (no copy/paste to Notes, Gmail, WhatsApp)
- When Casey leaves, the company data inside Outlook and Teams can be wiped remotely — without touching any personal data on the device
- The rest of the iPhone remains entirely under Casey's control

This is the correct, proportionate, and legally defensible approach to BYOD.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Microsoft 365 Business Premium licence assigned to Casey Quinn | Completed in workstream 01 |
| casey.quinn added to GRP-FieldWorkers | Completed in workstream 01 |
| Intune Admin Center accessible | https://intune.microsoft.com |
| iPhone with Outlook and Teams installed | The Authenticator app should also be installed |
| CA-04 in Report-only or On mode | References app protection policy as an access condition |

---

## The End State

| Component | State |
|---|---|
| iOS App Protection Policy | MAM-iOS-FieldWorker applied to GRP-FieldWorkers |
| Apps protected | Microsoft Outlook, Microsoft Teams |
| PIN requirement | 6-digit PIN required to open each app |
| Copy/paste | Blocked to unmanaged apps |
| Data backup | Corporate data backup to personal iCloud blocked |
| Screen capture | Blocked within protected apps |
| Conditional launch | Block access if device is jailbroken |
| Remote wipe | Corporate data can be wiped without device wipe |

---

## Understanding MAM Without Enrolment

Before configuring the policy, it is important to understand what MAM without enrolment does and does not do.

**What it does:**
- Applies a PIN requirement to Outlook and Teams on the personal device
- Prevents corporate data from being copied out of protected apps into unmanaged apps
- Prevents corporate data from being backed up to personal iCloud
- Prevents screenshots within protected apps (where the OS allows enforcement)
- Blocks access if the device is detected as jailbroken
- Allows corporate data inside Outlook and Teams to be remotely wiped (selective wipe) without touching personal data

**What it does not do:**
- It does not enrol the device in Intune MDM
- It does not allow the company to see the device in Intune as a managed device
- It does not allow full remote wipe of the device
- It does not control any personal apps or settings outside Outlook and Teams
- It does not prevent Casey from using personal apps on the same device

**How it works technically:**
When Casey opens Outlook on her iPhone after the policy is applied, she is prompted to sign in with her Microsoft 365 account. At that point, the app checks with Intune whether an App Protection Policy applies to her account. If it does, the policy is downloaded and applied to the app — all without enrolling the device. The device itself never registers in Intune.

---

## Phase 1 — Create the iOS App Protection Policy

### Step 1 — Create the Policy

1. Navigate to **Intune Admin Center** at `https://intune.microsoft.com`
2. Go to **Apps** → **App protection policies** → **+ Create policy**
3. Platform: **iOS/iPadOS** → **Create**
4. Name: `MAM-iOS-FieldWorker`
5. Description: `App protection policy for field workers accessing Microsoft 365 on personal iOS devices`
6. Click **Next**

### Step 2 — Configure Apps

1. On the **Apps** tab, click **+ Select public apps**
2. Search for and add:
   - **Microsoft Outlook**
   - **Microsoft Teams**
3. Click **Next**

> These are the two applications through which company data is accessed on a personal device. Edge for iOS can be added if web browsing to internal resources is required.

### Step 3 — Configure Data Protection Settings

On the **Data protection** tab, configure:

**Data Transfer:**

| Setting | Value | Reason |
|---|---|---|
| Backup org data to iTunes and iCloud backups | Block | Corporate data must not be backed up to personal iCloud |
| Send org data to other apps | Policy managed apps only | Data can only be sent to other MAM-protected Microsoft apps |
| Receive data from other apps | Policy managed apps only | Data can only be received from MAM-protected apps |
| Save copies of org data | Block | Users cannot save attachments to personal storage (Photos, iCloud Drive) |
| Allow user to save copies to selected services | None selected | No personal storage services permitted |
| Restrict cut, copy, and paste between other apps | Policy managed apps with paste in | Copy/paste blocked to unmanaged apps |
| Screen capture and Google Assistant | Block | Prevents screenshotting of corporate content |

**Encryption:**

| Setting | Value |
|---|---|
| Encrypt org data | Require |

**Functionality:**

| Setting | Value |
|---|---|
| Sync app with native contacts app | Block |
| Printing org data | Block |

### Step 4 — Configure Access Requirements

On the **Access requirements** tab:

| Setting | Value | Reason |
|---|---|---|
| PIN for access | Require | Separate PIN for apps, independent of device passcode |
| PIN type | Numeric | Simpler than alphanumeric while still providing protection |
| Minimum PIN length | 6 | Standard minimum |
| Allow biometrics instead of PIN | Allow | Fingerprint / Face ID is acceptable — still proves physical possession |
| Override biometrics with PIN after timeout | Require | PIN required after 30 minutes of inactivity |
| PIN reset after number of days | 90 | PIN must be changed every 90 days |
| Simple PIN | Block | Sequential or repeated numbers not allowed |
| Work or school account credentials for access | Not required | PIN is sufficient |

### Step 5 — Configure Conditional Launch

Conditional launch defines conditions under which access is blocked regardless of PIN.

On the **Conditional launch** tab, add the following conditions:

| Condition | Value | Action |
|---|---|---|
| Jailbroken/rooted devices | — | Block access |
| Max PIN attempts | 5 | Reset PIN |
| Offline grace period | 720 minutes (12 hours) | Wipe data |
| Min OS version | 16.0 | Warn |

> **Jailbroken devices:** A jailbroken iPhone has had its operating system security controls removed. It is significantly more vulnerable to attack and cannot be trusted to enforce the app protection policy effectively. Blocking jailbroken devices is the correct and standard response.

> **Offline grace period:** If the device has not checked in with Intune for 12 hours, corporate data is wiped from the protected apps. This ensures that if someone leaves the company and the Intune licence is removed, data is not retained on the device indefinitely.

### Step 6 — Assign the Policy

1. On the **Assignments** tab → **+ Add groups** → select **GRP-FieldWorkers**
2. Click **Review + create** → **Create**

---

## Phase 2 — Register the iPhone

Casey's iPhone does not need to be enrolled in Intune MDM. The App Protection Policy is applied automatically when she signs into Outlook with her Microsoft 365 account. However, for Conditional Access Policy CA-04 to recognise the device as using an app protection policy, the Authenticator app must be installed and registered.

### Step 7 — Install Required Apps on iPhone

On Casey's iPhone, install the following from the App Store:
- **Microsoft Authenticator**
- **Microsoft Outlook**
- **Microsoft Teams**

### Step 8 — Register with Authenticator

1. Open **Microsoft Authenticator** on the iPhone
2. Sign in with `casey.quinn@qcbhomelab.online`
3. Complete MFA registration if not already done
4. The device is now registered with Entra ID — not MDM enrolled, but identity registered

### Step 9 — Sign Into Outlook on iPhone

1. Open **Outlook** on the iPhone
2. Sign in with `casey.quinn@qcbhomelab.online`
3. Complete MFA
4. After sign-in, Outlook checks for an App Protection Policy — the `MAM-iOS-FieldWorker` policy is downloaded and applied
5. Casey is prompted to create a 6-digit PIN for Outlook

Verify the policy is applied:
1. In **Intune Admin Center** → **Apps** → **App protection policies** → **MAM-iOS-FieldWorker**
2. Click **App protection status** → **iOS/iPadOS**
3. Casey Quinn's account should appear as a protected user

### Step 10 — Test Policy Enforcement

Test that the policy is working as expected:

1. Open **Outlook** on the iPhone → receive or open an email with an attachment
2. Attempt to save the attachment to **Files** (personal iCloud) — confirm this is blocked
3. Open an email → copy a paragraph of text → switch to **Notes** (personal app) → attempt to paste — confirm paste is blocked
4. Open **Outlook** → hold the home button to multitask → confirm a grey screen or blurred view appears (screenshot prevention)
5. Close Outlook → wait 5 minutes → reopen → confirm the PIN prompt appears

---

## Selective Wipe (Offboarding Procedure)

When Casey Quinn leaves the company, the following process removes company data from her personal device without affecting any personal data:

1. Navigate to **Intune Admin Center** → **Apps** → **App protection policies** → **MAM-iOS-FieldWorker**
2. Click **App protection status** → find Casey Quinn's device
3. Click the device → **Wipe**

This removes all company data from Outlook and Teams — emails, attachments, Teams messages, and cached files. The rest of the iPhone (personal photos, messages, apps) is completely untouched.

Alternatively, removing the Microsoft 365 licence from Casey's account in Entra ID achieves the same result — the offline grace period (12 hours) triggers and data is wiped automatically.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Policy created | Intune → App protection policies | MAM-iOS-FieldWorker listed |
| Policy assigned to GRP-FieldWorkers | Policy → Assignments | GRP-FieldWorkers listed |
| Policy applied to casey.quinn | Policy → App protection status | casey.quinn appears as protected user |
| PIN required on Outlook | Open Outlook on iPhone | 6-digit PIN prompt appears |
| Copy/paste blocked | Copy email text, paste to Notes | Paste blocked — no content transferred |
| Save attachment blocked | Attempt to save attachment to Files | Action blocked by policy |
| Jailbreak check active | Policy → Conditional launch | Jailbroken/rooted devices: Block access |

---

## Summary

This workstream delivered:

- **iOS App Protection Policy** `MAM-iOS-FieldWorker` created and assigned to GRP-FieldWorkers
- **Outlook and Teams** on Casey's iPhone protected — PIN required, copy/paste restricted, iCloud backup blocked
- **No MDM enrolment** — the device remains entirely personal; only app data is governed
- **Selective wipe capability** — company data can be removed remotely without touching personal data
- **Conditional launch** — jailbroken devices blocked, offline grace period enforced
- **CA-04** recognises the MAM-protected app as satisfying the app protection condition

Casey Quinn can now access company email and files from her personal iPhone with corporate data properly protected. The company has no visibility into or control over the device itself — only the data within the managed applications.

**Next:** [09 — Defender for Business](./09-defender-for-business.md)
