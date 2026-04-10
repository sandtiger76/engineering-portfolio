# Runbook: User Onboarding

## Purpose

This runbook defines the exact steps to onboard a new member of staff at QCB Homelab Consultants. It is designed to be followed without requiring any Microsoft 365 knowledge beyond basic portal navigation. Every step must be completed in the order listed — steps have dependencies.

Estimated time: 30–45 minutes per user (excluding device procurement and physical setup).

---

## Before You Start

Gather the following information before beginning:

| Item | Detail |
|---|---|
| New starter's full name | e.g. Sam Taylor |
| Role | Executive / Manager / Staff / Field Worker |
| Start date | The date on which the account should be active |
| Device type | Corporate Windows laptop / Personal iPhone (BYOD) / Both |
| Line manager | For group membership confirmation |
| Temporary password | Generate a strong temporary password — do not reuse |

---

## Step 1 — Create the User Account

**Portal:** Microsoft Entra Admin Center — `https://entra.microsoft.com`

1. Go to **Users** → **All users** → **New user** → **Create new user**
2. Fill in the following fields:

| Field | Value |
|---|---|
| User principal name | firstname.lastname@qcbhomelab.online |
| Display name | First Last (e.g. Sam Taylor) |
| First name | Sam |
| Last name | Taylor |
| Job title | (role from onboarding information) |
| Usage location | United Kingdom |
| Password | Set manually — record securely |
| Require password change on first sign-in | Yes |

3. Click **Review + create** → **Create**

---

## Step 2 — Assign to Security Groups

**Portal:** Microsoft Entra Admin Center

Based on the user's role, add them to the following groups:

| Role | Groups to Add |
|---|---|
| Executive | GRP-Executives, GRP-AllStaff |
| Manager | GRP-Managers, GRP-AllStaff |
| Staff | GRP-Staff, GRP-AllStaff |
| Field Worker | GRP-FieldWorkers, GRP-AllStaff |

For each group:
1. Go to **Groups** → **All groups** → search for the group name
2. Click **Members** → **+ Add members** → search for the new user → **Select**

> Adding to GRP-AllStaff triggers automatic licence assignment — Microsoft 365 Business Premium is assigned via group-based licensing.

---

## Step 3 — Verify Licence Assignment

**Portal:** Microsoft Entra Admin Center → Users → [new user] → Licences

Wait 2–3 minutes after adding to GRP-AllStaff, then confirm:

- Microsoft 365 Business Premium shows as **Assigned** (via group)
- Exchange Online, SharePoint Online, Teams, and Intune show as active services

If the licence has not appeared after 5 minutes, manually trigger the group-based licensing check:
1. Go to **Groups** → **GRP-AllStaff** → **Licences** → **Reprocess**

---

## Step 4 — Confirm Mailbox Is Provisioned

**Portal:** Exchange Admin Center — `https://admin.exchange.microsoft.com`

1. Go to **Recipients** → **Mailboxes**
2. Search for the new user's name
3. Confirm the mailbox is listed as **Active** with the primary SMTP address matching their UPN

Mailbox provisioning typically completes within 5 minutes of licence assignment.

---

## Step 5 — Add to Relevant Teams and SharePoint

**Portal:** Microsoft Teams Admin Center — `https://admin.teams.microsoft.com`

Based on the user's role:

| Role | Teams to Add |
|---|---|
| Executive | QCB Homelab Consultants (org-wide — auto), Executives |
| Manager | QCB Homelab Consultants (org-wide — auto), Operations, Projects |
| Staff | QCB Homelab Consultants (org-wide — auto), Operations or Projects (as appropriate) |
| Field Worker | QCB Homelab Consultants (org-wide — auto), Projects |

For each team (other than the org-wide team, which adds users automatically):
1. Go to **Teams** → **Manage teams** → click the team
2. **Members** tab → **+ Add member** → search for the user → **Add**

SharePoint permissions are inherited from security group membership — no additional SharePoint configuration is required if group membership was correctly assigned in Step 2.

---

## Step 6 — MFA Registration (User Action)

The new user must register for MFA before they can access any Microsoft 365 service. Send the user the following instructions:

> **Welcome to QCB Homelab Consultants Microsoft 365**
>
> Before you can sign in, you need to set up multi-factor authentication (MFA). This is a security requirement for all staff.
>
> **Step 1:** Download **Microsoft Authenticator** from the App Store or Google Play on your mobile phone.
>
> **Step 2:** Go to `https://portal.office.com` on your computer and sign in with:
> - Username: `firstname.lastname@qcbhomelab.online`
> - Password: (your temporary password — you will be asked to change it)
>
> **Step 3:** When prompted with "More information required", click **Next** and follow the steps to set up the Authenticator app.
>
> **Step 4:** Once registered, you can access all Microsoft 365 services — email, Teams, OneDrive, and SharePoint.
>
> If you have any problems, contact the IT team.

---

## Step 7 — Device Setup (Corporate Windows Laptop)

*Complete this step only if the user has a corporate Windows laptop.*

**On the Windows laptop, signed in as a local administrator:**

1. Go to **Settings** → **Accounts** → **Access work or school** → **Connect**
2. Select **Join this device to Azure Active Directory**
3. Enter the new user's credentials: `firstname.lastname@qcbhomelab.online`
4. Complete MFA
5. Confirm the organisation: **QCB Homelab Consultants** → **Join** → **Done**
6. Restart the laptop
7. Sign in as the new user using their Microsoft 365 credentials

After sign-in:
1. Intune enrolment begins automatically — wait 15–20 minutes
2. Verify in **Intune Admin Center** → **Devices** → **All devices** — the laptop appears
3. Confirm compliance status reaches **Compliant** (BitLocker must be enabled — see workstream 07)
4. Add the device to **GRP-ManagedDevices** in Entra ID

---

## Step 8 — Device Setup (iPhone — BYOD)

*Complete this step only for field workers using a personal iPhone.*

Send the user the following instructions:

> **Setting up your iPhone for work**
>
> You do not need to enrol your phone in any management system. Instead, you will install the Microsoft apps and sign in — your personal data will not be affected.
>
> **Step 1:** Install the following apps from the App Store:
> - Microsoft Authenticator
> - Microsoft Outlook
> - Microsoft Teams
>
> **Step 2:** Open **Microsoft Authenticator** and sign in with your work account.
>
> **Step 3:** Open **Outlook** and sign in with `firstname.lastname@qcbhomelab.online`. You will be prompted to create a PIN for Outlook — this is separate from your phone's passcode and is a security requirement.
>
> **Step 4:** Open **Teams** and sign in with the same work account.
>
> **What the PIN means:** The PIN protects your work email and Teams on this device. You will be asked for it each time you open Outlook or Teams. You can use Face ID or Touch ID instead if you prefer.

---

## Step 9 — SSPR Registration

After MFA registration, prompt the user to complete SSPR registration so they can reset their own password in future without IT involvement.

1. Ask the user to navigate to `https://aka.ms/mysecurityinfo`
2. Sign in with their Microsoft 365 credentials
3. Confirm they have registered at least 2 authentication methods (Authenticator + phone number or alternate email)

---

## Step 10 — Verification Checklist

Before marking onboarding as complete, confirm the following:

| Check | Method | Status |
|---|---|---|
| User account created | Entra Admin Center → Users | ☐ |
| Correct security groups assigned | Entra → Groups | ☐ |
| Business Premium licence assigned | Entra → Users → Licences | ☐ |
| Mailbox active | Exchange Admin Center → Mailboxes | ☐ |
| Teams membership correct | Teams Admin Center → Teams → Members | ☐ |
| MFA registered | Entra → Authentication methods → User registration | ☐ |
| SSPR registered | myaccess.microsoft.com / security info | ☐ |
| Device enrolled (if applicable) | Intune → All devices | ☐ |
| Device compliant (if applicable) | Intune → Device → Compliance | ☐ |
| MAM policy applied (if BYOD) | Intune → App protection status | ☐ |

---

## Notes

**Password:** Record the temporary password securely and communicate it to the user via a method separate from their work email (which they cannot access yet). Use a phone call, in-person handover, or a password manager shared link.

**Timing:** Create the account on the working day before the start date. Licence provisioning, mailbox creation, and Intune policy delivery all take time — starting the account 24 hours before avoids the new starter sitting idle on day one.

**Group membership:** If the user's role is unclear, default to GRP-Staff. Adding to a more privileged group can be done at any time — it is better to start with less access and grant more than to start with more and restrict later.
