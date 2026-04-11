[← 08 — Intune: Windows](08-intune-windows.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [10 — Conditional Access & MFA →](10-conditional-access.md)

---

# 09 — Intune: iOS Mobile Application Management (MAM)

## Introduction

Not every device that accesses company data is owned by the company. In many organisations, employees use their personal smartphones to check email, access Teams, and read documents. This is called BYOD — Bring Your Own Device.

The challenge with BYOD is balance. The organisation needs to protect its data on those devices, but it cannot — and should not — take full control of a personal phone the way it would a corporate laptop. The employee has a right to privacy on their personal device, and they will not accept having IT wipe or control their entire phone.

Mobile Application Management (MAM) solves this. Rather than managing the whole device, Intune manages only the apps and the company data within them. The Outlook app, for example, can be configured to require a PIN, prevent copy-paste to personal apps, and allow remote wipe of company data — all without touching personal photos, messages, or other apps on the phone.

In this environment, iPhones are personal devices (BYOD). They are not enrolled in MDM (full device management). Instead, MAM policies are applied at the app layer only.

---

## What We Are Building

- App Protection Policy for iOS that governs Outlook, Teams, and OneDrive
- No device enrolment required — users simply install the apps and sign in
- Company data is isolated within managed apps and cannot be moved to personal apps
- Remote wipe capability for company data only, leaving personal data untouched

---

## Implementation Steps

### Step 1 — Add iOS Apps to Intune

Before applying policies, the apps need to be added to Intune so they can be targeted.

In the Intune Admin Center, navigate to Apps → iOS/iPadOS → Add.

Select App type: iOS store app and add the following apps by searching the App Store:

- Microsoft Outlook
- Microsoft Teams
- Microsoft OneDrive

For each app, set the minimum OS version to iOS 16 and publish to all users.

> These apps do not get pushed automatically to personal devices — they are simply registered in Intune so policies can target them. Users install the apps themselves from the App Store.

### Step 2 — Create an App Protection Policy

Navigate to Apps → App protection policies → Create policy → iOS/iPadOS.

Name the policy `APP-iOS-BYOD-Protection` and configure the following:

**Data Protection tab:**

| Setting | Value |
|---|---|
| Backup org data to iTunes and iCloud backups | Block |
| Send org data to other apps | Policy managed apps only |
| Receive data from other apps | Policy managed apps only |
| Restrict cut, copy, and paste between other apps | Policy managed apps only |
| Save copies of org data | Block |
| Allow user to save copies to selected services | OneDrive for Business only |
| Open data into org documents | Block |
| Org data notifications | Block org data in notifications |

**Access Requirements tab:**

| Setting | Value |
|---|---|
| PIN for access | Required |
| PIN type | Numeric |
| Simple PIN | Block |
| Minimum PIN length | 6 |
| Biometrics instead of PIN | Allow |
| Recheck access requirements after inactivity | 30 minutes |

**Conditional launch tab:**

| Condition | Value | Action |
|---|---|---|
| Offline grace period | 720 hours (30 days) | Wipe data |
| Jailbroken/rooted devices | N/A | Block access |
| Min OS version | 16.0 | Block access |

### Step 3 — Assign the Policy

In the Assignments tab of the App Protection Policy, assign the policy to the GRP-AllStaff group (or GRP-Devices-iOS once that group has been populated).

All users in the assigned group will have this policy applied to the targeted apps (Outlook, Teams, OneDrive) on any iOS device they use to sign in.

### Step 4 — Test the MAM Policy

On a personal iPhone, install Microsoft Outlook from the App Store. Sign in with a user account, for example j.carter@qcbhomelab.online.

During sign-in, the user will be prompted to set a PIN for the app — this is the MAM policy taking effect. Once signed in, test the following to confirm the policy is working:

- Try to copy an email body and paste it into the Notes app — this should be blocked
- Try to save an email attachment to Files — this should be blocked or limited to OneDrive only
- Try to forward an email to a personal Gmail account — the send should work but attachment saving will be restricted

In the Intune Admin Center, navigate to Apps → App protection status and confirm the policy shows as applied for the test user.

### Step 5 — Remote Wipe Company Data

If a user loses their phone or leaves the organisation, IT can wipe all company data from the managed apps without touching any personal data.

In the Intune Admin Center, navigate to Users → find the user → Devices. Select the relevant iOS device and choose Wipe from the action menu, then select Wipe only organisation data.

This removes all company email, files, and Teams data from the device. The user's personal apps, photos, and data are completely unaffected.

---

## What to Expect

Users experience minimal friction — they install familiar apps from the App Store, sign in with their work account, set a short PIN, and everything works. They will notice they cannot paste company content into personal apps, which is the intended behaviour. The IT team retains the ability to protect and wipe company data without ever having visibility of or control over the personal side of the device.

---

[← 08 — Intune: Windows](08-intune-windows.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [10 — Conditional Access & MFA →](10-conditional-access.md)
