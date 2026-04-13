[← 08 — Intune: Windows](08-intune-windows.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [10 — Conditional Access & MFA →](10-conditional-access.md)

---

# 09 — Intune: iOS Mobile Application Management (MAM)

## Overview — What This Document Covers

Most people carry a smartphone, and most people use that smartphone to check work email or messages — whether the company officially supports it or not. The question for IT is not whether personal devices access company data, but how to make it safe when they do.

The challenge is that a personal phone is not a company device. The organisation cannot wipe it, cannot control what apps are installed, and cannot monitor what the user does with it. But it still needs to protect the company data on it — especially if the phone is lost or the person leaves.

Mobile Application Management (MAM) is the answer. Rather than managing the entire device, Intune manages only the specific work apps — Outlook, Teams, OneDrive — and the company data within them. The personal side of the phone is completely untouched. This document covers setting up that protection: the policies that control what users can do with company data in those apps, and how to remove company data remotely without affecting anything personal.

---

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

In the Assignments tab of the App Protection Policy, assign the policy to both `GRP-AllStaff` and `GRP-Contractors`.

Staff use personal iPhones alongside their corporate Windows laptops. Contractors use personal devices exclusively — iOS MAM is their only managed access point into company data, making this policy particularly important for that group.

All users in the assigned groups will have this policy applied to the targeted apps (Outlook, Teams, OneDrive) on any iOS device they use to sign in.

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

## Common Questions & Troubleshooting

**Q1: A user signed into Outlook on their personal iPhone but was never prompted to set a PIN. The MAM policy does not appear to have applied. What should I check?**

First confirm the App Protection Policy is assigned to a group that includes the user — check in Intune Admin Center under Apps → App protection policies → [Policy] → Assignments. Then confirm the user signed in with their work account (not a personal Microsoft account). MAM policies only apply when the user authenticates with an account that is targeted by the policy. If the assignment looks correct, ask the user to sign out of the Outlook app completely and sign back in — the policy is re-evaluated at sign-in. Check Apps → App protection status to see whether the policy is showing as applied for that user.

**Q2: Users are complaining they cannot attach files to emails from their personal iPhone. Is this a MAM policy effect or something else?**

This is expected behaviour if the MAM policy has "Save copies of org data" set to Block and "Send org data to other apps" set to Policy managed apps only. Users can attach files that are stored within managed apps (such as OneDrive) but cannot attach files from personal storage like the iOS Photos app or iCloud Drive. If this is causing significant friction, review the policy settings — some organisations allow attachments from personal storage while still blocking paste and copy operations. The trade-off is documented in the Data Protection tab of the App Protection Policy.

**Q3: The "Wipe only organisation data" option removed company email from the device but the user says their Teams messages are still visible. Is the wipe incomplete?**

Selective wipe removes the authentication token and locally cached data for managed apps, but some Teams content may persist briefly in cache before the app fully clears. Ask the user to open the Teams app — it should prompt them to sign in again, and once they do with a personal account (or cannot, because the work account is wiped), the company content will no longer be accessible. If Teams is still showing work content after the user confirms the app prompted for re-authentication, the wipe may need to be re-triggered from the Intune Admin Center.

**Q4: A user's personal iPhone was recently replaced. The MAM policy is assigned but it is not applying to the new device. What is needed?**

MAM policies apply at the app and account level, not at the device level — so there is no device registration required for MAM. The policy should apply automatically when the user signs into the managed apps (Outlook, Teams, OneDrive) on the new device with their work account. If it is not applying, ask the user to sign out and back in, and check Apps → App protection status in Intune to confirm the policy is being received. No IT action is typically required for a device replacement in a MAM-only environment.

**Q5: The organisation wants to allow users to use FaceID instead of a PIN for Outlook on iPhone, but the current policy requires a numeric PIN. How is this changed?**

In the App Protection Policy under the Access Requirements tab, the setting "Biometrics instead of PIN" can be set to Allow. When enabled, users can authenticate to managed apps using FaceID or TouchID instead of entering their PIN. The PIN remains as a fallback if biometrics fail or are unavailable. This change applies at next policy refresh — the user does not need to reinstall the app. Policy refresh happens at app launch and periodically based on the "Recheck access requirements after inactivity" setting.

---
