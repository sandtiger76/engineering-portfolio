# 03 — MFA & Self-Service Password Reset

## In Plain English

Multi-factor authentication (MFA) means proving your identity in more than one way. A password is one factor — something you know. MFA adds a second factor: something you have (a phone that receives a code) or something you are (a fingerprint). Even if someone steals your password, they cannot sign in without also having access to your phone.

Self-Service Password Reset (SSPR) lets users reset their own password without calling the IT helpdesk. If Casey Quinn forgets her password at 8pm before an early morning client meeting, she can reset it herself from the Microsoft 365 sign-in page — no support ticket, no waiting until Monday morning.

Together, MFA and SSPR are two of the most impactful security and productivity improvements in any Microsoft 365 deployment. MFA dramatically reduces the risk of account compromise. SSPR reduces helpdesk calls and eliminates the frustration of being locked out.

---

## Why This Matters

Password-only authentication is the single largest cause of account compromise in cloud environments. Attackers obtain passwords through phishing, credential stuffing from data breaches, and social engineering. Once they have a password, a single-factor environment gives them immediate access to email, files, and everything else.

MFA raises the bar substantially. According to Microsoft's own research, MFA blocks over 99% of automated account compromise attacks. It is not a perfect defence, but it is the most impactful single control available.

SSPR matters for a different reason: it removes a friction point that causes users to do the wrong thing. When resetting a password requires a helpdesk call, users choose weak passwords they are unlikely to forget, reuse passwords across systems, or write passwords down. When reset is self-service and instant, users are more willing to use strong, unique passwords.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Security Defaults disabled | Completed in workstream 01 |
| Conditional Access policies active | CA-01 enforcing MFA — completed in workstream 02 |
| 5 staff users created and licensed | Completed in workstream 01 |
| GRP-AllStaff group created | Completed in workstream 01 |
| Users have mobile phones available for MFA registration | Required for MFA setup |

---

## How MFA Works in This Deployment

MFA in this project is enforced through **Conditional Access Policy CA-01** — not through the legacy per-user MFA settings. This is an important distinction.

**Per-user MFA** (the older method) is configured per individual user account, applies to all authentications regardless of context, and cannot be targeted by condition or group.

**Conditional Access MFA** (the modern method) is a policy that evaluates conditions — who the user is, what they are accessing, what device they are using — before deciding whether to require MFA. It can be targeted at specific groups, excluded for specific accounts, and combined with other requirements like device compliance.

CA-01 has already been created in workstream 02 — it requires MFA for all users, all apps, with no conditions. This means every user must register for MFA before they can complete their first sign-in. No further MFA configuration is required beyond ensuring the authentication methods policy allows the right methods.

---

## Phase 1 — Authentication Methods Policy

### Step 1 — Configure Allowed Authentication Methods

Microsoft Entra ID allows administrators to control which MFA methods users can register. The recommended methods for QCB Homelab Consultants are:

- **Microsoft Authenticator** — the preferred method; push notification to the user's phone app
- **SMS** — text message code as a fallback; less secure than Authenticator but more accessible
- **Voice call** — telephone call with spoken code; for users without a smartphone

The least secure method — email OTP — is not enabled. FIDO2 security keys and Windows Hello for Business are not included in this deployment.

1. Navigate to **Microsoft Entra Admin Center** → **Protection** → **Authentication methods** → **Policies**
2. Select **Microsoft Authenticator** → **Enable** → set to **All users** → **Save**
3. Select **SMS** → **Enable** → set to **All users** → **Save**
4. Select **Voice call** → **Enable** → set to **All users** → **Save**

> **Microsoft Authenticator is the recommended method.** It provides push notification approval (tap Approve on the phone) rather than requiring the user to type a code, which is both more convenient and more secure. Users should be guided to install and register the Authenticator app as their primary method.

---

## Phase 2 — MFA Registration

When a user signs in for the first time after CA-01 is enabled, they will be prompted to register for MFA before they can access any Microsoft 365 service. This is called the MFA registration interrupt.

### Step 2 — Complete MFA Registration as a Test User

Complete this process as `jordan.hayes@qcbhomelab.online` to verify the experience works correctly:

1. Open a private/incognito browser window
2. Navigate to `https://portal.office.com`
3. Enter the username and temporary password
4. On the **More information required** screen — click **Next**
5. Follow the prompts to install **Microsoft Authenticator** on a phone and scan the QR code
6. Approve the test notification on the phone
7. Click **Done** — the user is now registered for MFA and can complete sign-in

> All 5 staff users must complete MFA registration before they can use Microsoft 365 services. In a production environment, a communication to staff before go-live explaining what to expect — and how to install the Authenticator app — significantly reduces confusion and support calls.

### Step 3 — Verify MFA Registration Status

After users register, confirm their registration status:

1. Navigate to **Microsoft Entra Admin Center** → **Protection** → **Authentication methods** → **User registration details**
2. Confirm each user shows **MFA capable: Yes** and at least one method registered

Alternatively, via PowerShell:

```powershell
Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All"

# Get MFA registration status for all users
Get-MgReportAuthenticationMethodUserRegistrationDetail |
    Select-Object UserDisplayName, IsMfaRegistered, IsMfaCapable |
    Format-Table
```

Expected output:
```
UserDisplayName    IsMfaRegistered    IsMfaCapable
---------------    ---------------    ------------
Alex Carter        True               True
Morgan Blake       True               True
Jordan Hayes       True               True
Riley Morgan       True               True
Casey Quinn        True               True
```

---

## Phase 3 — Self-Service Password Reset

### Step 4 — Enable SSPR

SSPR allows users to reset their own password from the Microsoft 365 sign-in page without contacting IT. It is enabled per group — GRP-AllStaff is the target.

1. Navigate to **Microsoft Entra Admin Center** → **Protection** → **Password reset**
2. Select **Properties** from the left menu
3. Set **Self service password reset enabled** to **Selected**
4. Click **Select group** → search for and select **GRP-AllStaff**
5. Click **Save**

### Step 5 — Configure SSPR Authentication Methods

SSPR requires users to verify their identity before resetting their password. Configure the methods and the number of methods required.

1. Navigate to **Password reset** → **Authentication methods**
2. Set **Number of methods required to reset** to **2**
3. Enable the following methods:
   - **Mobile app notification** (Microsoft Authenticator)
   - **Mobile app code** (time-based code from Authenticator)
   - **Mobile phone** (SMS to registered phone number)
   - **Email** (code to alternate email address)
4. Click **Save**

> Requiring 2 methods means a user must verify via two different channels before resetting their password. This prevents an attacker who has compromised one channel from resetting the password through SSPR.

### Step 6 — Configure SSPR Registration

SSPR registration can be combined with MFA registration using the combined security info registration experience. This means users register for both MFA and SSPR in a single session.

1. Navigate to **Password reset** → **Registration**
2. Set **Require users to register when signing in** to **Yes**
3. Set **Number of days before users are asked to re-confirm their authentication information** to **180**
4. Click **Save**

### Step 7 — Test SSPR

Test the SSPR experience as `riley.morgan@qcbhomelab.online`:

1. Navigate to `https://aka.ms/sspr` (the Microsoft SSPR portal)
2. Enter the username: `riley.morgan@qcbhomelab.online`
3. Complete the CAPTCHA
4. Verify identity using the registered methods
5. Enter and confirm a new password
6. Confirm sign-in with the new password succeeds

---

## Phase 4 — Monitor Authentication Activity

### Step 8 — Review Sign-In Logs

After MFA is in use, sign-in logs provide valuable visibility into authentication activity — which users are signing in, from where, and whether MFA was completed.

1. Navigate to **Microsoft Entra Admin Center** → **Users** → **Sign-in logs**
2. Review recent sign-in events
3. For each event, note:
   - **Authentication requirement** — Single-factor or Multifactor
   - **MFA result** — MFA requirement satisfied by claim in token, or MFA completed in Entra ID
   - **Conditional Access** — which policies applied and what was their result

> Regularly reviewing sign-in logs is an important operational habit. Unexpected sign-ins from unusual locations, failed MFA attempts, or sign-ins outside working hours may indicate a compromise.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| MFA required on sign-in | Sign in as any user in incognito browser | MFA prompt appears after password |
| Authenticator app registered | Entra → Authentication methods → User registration | All 5 users show IsMfaRegistered: True |
| SSPR enabled for GRP-AllStaff | Entra → Password reset → Properties | Selected — GRP-AllStaff |
| SSPR test successful | Navigate to aka.ms/sspr as riley.morgan | Password reset completes without IT involvement |
| Sign-in logs showing MFA | Entra → Users → Sign-in logs | Authentication requirement: Multifactor |

---

## Summary

This workstream delivered:

- **Authentication methods** configured — Microsoft Authenticator (primary), SMS and voice call (fallback)
- **MFA registration** completed for all 5 users via the registration interrupt flow
- **SSPR enabled** for GRP-AllStaff with 2-method verification requirement
- **SSPR tested** — password reset confirmed working without helpdesk involvement
- **Sign-in log review** — MFA confirmed firing on every sign-in

Every member of staff at QCB Homelab Consultants now signs in with MFA. Passwords alone are no longer sufficient to access company data. SSPR means password-related helpdesk calls are eliminated — users can recover their own accounts at any time.

**Next:** [04 — Exchange Online](./04-exchange-online.md)
