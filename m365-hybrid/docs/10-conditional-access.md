[← 09 — Intune: iOS MAM](09-intune-ios.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [11 — Defender for Business →](11-defender.md)

---

# 10 — Conditional Access & MFA

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

[← 09 — Intune: iOS MAM](09-intune-ios.md) &nbsp;|&nbsp; [🏠 README](README.md) &nbsp;|&nbsp; [11 — Defender for Business →](11-defender.md)
