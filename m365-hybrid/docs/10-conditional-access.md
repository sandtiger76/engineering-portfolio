[← 09 — Intune: iOS MAM](09-intune-ios.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [11 — Defender for Business →](11-defender.md)

---

# 10 — Conditional Access & MFA

## Overview — What This Document Covers

Passwords alone are no longer enough to protect access to company systems. A stolen password gives an attacker everything they need to sign in as a real employee — and in a cloud environment where systems are accessible from anywhere in the world, that is a significant risk.

This document covers two closely related protections. Multi-factor authentication (MFA) requires users to prove their identity with a second method — typically a notification on their phone — in addition to their password. Even if a password is stolen, the attacker cannot get in without also having the user's phone. Conditional Access is the policy engine that decides, for every single sign-in, whether to allow access, block it, or demand additional proof — based on who the user is, what device they are using, and whether the sign-in looks normal.

Together, these two controls form the core of a Zero Trust security model: no access is ever assumed to be safe just because the user knows the password. Every sign-in is evaluated, every time.

---

## Introduction

Traditional security worked like a castle and moat — once you were inside the network, you were trusted. Modern security has had to abandon that model entirely. Users now access company data from coffee shops, hotels, personal devices, and countries they were not in yesterday. The network boundary no longer means anything.

Zero Trust is the replacement model. Its core principle is simple: never trust, always verify. Every time a user tries to access a company resource, the system asks the same questions: who is this person, is their device healthy, and does this sign-in look normal? Only when those answers are satisfactory is access granted.

Conditional Access is how Microsoft 365 implements Zero Trust. It is a policy engine that sits between the user and the resource they are trying to reach. Before access is granted, the policy evaluates the user's identity, their device compliance status, their location, and the sensitivity of what they are trying to access — then decides whether to allow, block, or challenge with multi-factor authentication (MFA).

MFA means the user must prove their identity using at least two factors: something they know (their password) and something they have (their phone, showing a notification or a code). Even if someone steals a password, they cannot sign in without also having the user's phone.

---

## What We Are Building

| Policy | Purpose |
|---|---|
| CA01 — Require MFA for all users | No sign-in is trusted on password alone |
| CA02 — Block legacy authentication | Prevents older protocols that cannot support MFA |
| CA03 — Require compliant device for M365 apps | Blocks unmanaged devices from accessing company data |
| CA04 — Protect admin accounts | Stricter controls for any account with elevated permissions |

---

## Implementation Steps

### Step 1 — Enable Security Defaults or Move to Conditional Access

Microsoft 365 tenants come with Security Defaults enabled by default, which provides basic MFA for all users. However, Security Defaults cannot be customised. To implement the policies in this document, Security Defaults must be turned off and replaced with individual Conditional Access policies.

> Before disabling Security Defaults, make sure you have at least one Global Administrator account with MFA already set up. If you get locked out, recovery is possible but inconvenient.

In the Entra Admin Center, navigate to Properties → Manage security defaults and set Security defaults to Disabled. You will be asked to provide a reason — select the option for using Conditional Access policies.

### Step 2 — Register MFA Methods for All Users

Before creating policies that require MFA, ensure all users have registered an authentication method. Navigate to Entra Admin Center → Users → Per-user MFA (or use the Authentication methods policies).

For this lab, configure the Microsoft Authenticator app as the primary MFA method:

Navigate to Entra Admin Center → Protection → Authentication methods → Microsoft Authenticator and enable it for all users.

Each user will be prompted to register the Authenticator app the next time they sign in, provided the Conditional Access policy in Step 3 is in place.

### Step 3 — CA01: Require MFA for All Users

In the Entra Admin Center, navigate to Protection → Conditional Access → Create new policy.

Name: `CA01 — Require MFA — All Users`

| Section | Setting |
|---|---|
| Users | All users |
| Exclude | Your break-glass emergency admin account |
| Cloud apps | All cloud apps |
| Conditions | Any location, any device |
| Grant | Require multi-factor authentication |
| Session | Sign-in frequency: 8 hours |

Enable the policy and set it to On.

> A break-glass account is an emergency Global Administrator account that is excluded from all Conditional Access policies. It exists in case MFA becomes unavailable and you need to access the tenant to fix it. This account should have a very long random password, be stored securely offline, and never be used for day-to-day work.

### Step 4 — CA02: Block Legacy Authentication

Legacy authentication protocols (POP3, IMAP, SMTP AUTH, older Office clients) cannot perform MFA. Attackers frequently target these protocols specifically because they bypass modern authentication. This policy blocks them entirely.

Name: `CA02 — Block Legacy Authentication`

| Section | Setting |
|---|---|
| Users | All users |
| Cloud apps | All cloud apps |
| Conditions | Client apps: Exchange ActiveSync clients AND Other clients |
| Grant | Block access |

Enable the policy and set it to On.

### Step 5 — CA03: Require Compliant Device for M365

This policy ensures that only Intune-managed and compliant devices can access Microsoft 365 applications. A user signing in from a personal unmanaged laptop will be blocked from accessing Exchange, SharePoint, and Teams.

Name: `CA03 — Require Compliant Device — M365 Apps`

| Section | Setting |
|---|---|
| Users | All users |
| Exclude | Your break-glass account |
| Cloud apps | Office 365 |
| Conditions | Any location |
| Grant | Require device to be marked as compliant |

Enable the policy and set it to Report-only first. This allows you to see what would have been blocked before enforcing it. Review the sign-in logs for a day, confirm no legitimate access would be blocked, then switch to On.

### Step 6 — CA04: Protect Admin Accounts

Admin accounts are the highest-value target in any Microsoft 365 environment. This policy applies stricter controls to any account holding a privileged role.

Name: `CA04 — Admin Accounts — Require MFA Always`

| Section | Setting |
|---|---|
| Users | Directory roles: Global Administrator, User Administrator, Exchange Administrator, SharePoint Administrator, Intune Administrator |
| Cloud apps | All cloud apps |
| Conditions | Any location, any device |
| Grant | Require multi-factor authentication |
| Session | Sign-in frequency: every time (no persistent session) |

Enable the policy and set it to On.

### Step 7 — Verify the Policies

Sign in as a regular user (e.g. j.carter@qcbhomelab.online) from a browser. Confirm the MFA prompt appears. Complete MFA and confirm access is granted.

Check the Entra Admin Center sign-in logs (Identity → Monitoring → Sign-in logs) to see each sign-in attempt and which Conditional Access policies were evaluated and their result.

---

## What to Expect

Every sign-in to the environment now goes through the Conditional Access engine. Users will be prompted for MFA on their first sign-in and periodically thereafter. Attempts to sign in from unmanaged devices to Microsoft 365 applications will be blocked. Legacy authentication attempts will be blocked entirely. Admin accounts have no persistent sessions, meaning they must re-authenticate every time — the minor inconvenience is an acceptable trade-off for significantly improved security.

---

## Common Questions & Troubleshooting

**Q1: A Conditional Access policy was set to "On" and now a user is completely locked out — they cannot sign in at all. How do I recover access?**

This is why a break-glass account excluded from all Conditional Access policies is essential. Sign in with that account and either disable the policy or adjust the conditions to restore access for the affected user. If you do not have a break-glass account and are fully locked out, Microsoft support can assist but the process is slow. For future reference: always test new policies in Report-only mode first, and always confirm the break-glass account is excluded before enabling any policy. Never test Conditional Access changes using the account you are currently signed in with.

**Q2: MFA is required by policy but a user says they are never prompted for it — they sign straight in with their password. What is happening?**

The most likely cause is that the user has an active MFA session token that has not yet expired. Conditional Access evaluates sign-in frequency at the point of authentication, so if the user authenticated recently and the token is still valid, they will not be challenged again until the session expires. Check the sign-in logs in Entra Admin Center under Identity → Monitoring → Sign-in logs and look at the Conditional Access tab for that sign-in event to confirm which policies were evaluated and what the result was. If a policy shows as "Not applied", check whether the user falls into an exclusion group.

**Q3: CA03 (require compliant device) is blocking a user who is on a corporate Intune-enrolled laptop. Their device is enrolled but the policy is still blocking them. What should I investigate?**

Compliant device Conditional Access requires the device to be both enrolled in Intune AND meeting all compliance policy requirements. Enrolled does not automatically mean compliant. Check the device's compliance status in Intune Admin Center under Devices → [Device] → Device compliance and look for which specific compliance setting is failing. Common causes are BitLocker not yet completed, Defender reporting as inactive, or the OS version being below the minimum required. Once the device becomes compliant, access is restored at the next sign-in without any manual intervention.

**Q4: Legacy authentication blocking (CA02) is causing a shared service account or application to stop working. How should this be handled?**

Legacy authentication should be blocked for all human users, but some service accounts and older line-of-business applications use SMTP AUTH, POP3, or IMAP to connect to Exchange Online and cannot support modern authentication. Rather than exempting all legacy auth, identify the specific account or application and create a narrow exclusion — either by excluding the specific user account from CA02, or by migrating the application to use Microsoft Graph API and OAuth, which is the correct long-term solution. Document any exclusions clearly, as they represent ongoing security risk.

**Q5: The sign-in logs show a Conditional Access policy as "Failure" for a user, but the user says they can still access the resource. How is that possible?**

A "Failure" result in the CA evaluation log means the policy evaluated to a block or challenge condition, but it does not always mean the user was denied — if another policy evaluated to "Success" and granted access, the user may still have been allowed in. Conditional Access evaluates all applicable policies and grants access if any policy result permits it, unless an explicit block policy is in force. Review all policy results for that sign-in event together, not just the one showing failure. A "Block" result from a specific policy will only stop access if it is the controlling result after all policies are evaluated.

---
