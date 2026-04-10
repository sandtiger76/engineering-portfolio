# 02 — Conditional Access

## In Plain English

Imagine a security guard at a building entrance who doesn't just check a badge — they check who you are, what device you're carrying, where you've come from, and what you're trying to access. Based on all of that, they decide whether to let you in, ask for additional verification, or turn you away entirely.

Conditional Access works exactly the same way for Microsoft 365. Every time a user tries to sign in, Conditional Access evaluates a set of conditions in real time: who is this person, what device are they using, which network are they on, and what are they trying to access? Based on those conditions, it makes a decision — allow access, require MFA, require a compliant device, or block entirely.

For QCB Homelab Consultants — a company with staff working across three offices and from home — this is the control layer that ensures consistent security regardless of where someone is working from.

---

## Why This Matters

Security Defaults — Microsoft's out-of-the-box protection — enforces MFA for all users but treats everyone the same regardless of role, device, or location. It cannot distinguish between an executive who must always use a compliant device, and a field worker accessing email from a personal phone.

Conditional Access gives precise, auditable control. For QCB Homelab Consultants this means:

- All users must complete MFA on every sign-in — no exceptions
- Legacy authentication protocols that cannot support MFA are blocked entirely
- The executive has the strictest requirements — compliant device always, no location exceptions
- Access to Microsoft 365 apps requires either a managed compliant device or a MAM-protected app
- The three office locations are declared as known networks — providing context for sign-in monitoring

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Security Defaults disabled | Completed in workstream 01 |
| 5 staff users created and licensed | Completed in workstream 01 |
| Security groups created | GRP-Executives, GRP-AllStaff etc. — completed in workstream 01 |
| Break-glass account confirmed accessible | Must be excluded from all CA policies |
| Public IP for each office | Required for named location configuration |
| Intune compliance policy | Referenced in CA-04 — created in workstream 07 |

> **Note on CA-04:** CA-04 references Intune device compliance. Create it now in **Report-only** mode and switch to **On** after Intune is configured in workstream 07. This prevents accidental lockout before devices are enrolled.

---

## Phase 1 — Named Locations

Named locations declare known network IP ranges to the tenant. For QCB Homelab Consultants, one named location is created per office. These are used for sign-in context and reporting — they do not bypass any security controls.

### Why Named Locations Do Not Bypass MFA

A common misconfiguration in multi-site deployments is to use named locations to skip MFA when users are "in the office." This is a significant security risk — office networks are not always secure, and an attacker who gains physical or network access to the office could bypass MFA entirely.

In this deployment, named locations are used for context only. MFA is required on every sign-in regardless of network location.

### Step 1 — Create Three Named Locations

1. Navigate to **Microsoft Entra Admin Center** → **Protection** → **Conditional Access** → **Named locations**
2. For each office, click **+ IP ranges location**

**Central Office (HQ):**

| Field | Value |
|---|---|
| Name | LOC-CentralOffice |
| Mark as trusted location | Yes |
| IP ranges | [Central Office public IP]/32 |

**North Office (Regional):**

| Field | Value |
|---|---|
| Name | LOC-NorthOffice |
| Mark as trusted location | Yes |
| IP ranges | [North Office public IP]/32 |

**South Office (Regional):**

| Field | Value |
|---|---|
| Name | LOC-SouthOffice |
| Mark as trusted location | Yes |
| IP ranges | [South Office public IP]/32 |

3. Click **Create** for each location

> **Finding the public IP of each office:** From a device on the office network, navigate to `https://whatismyip.com`. The IP shown is the office's public IP. For this lab, use your home broadband public IP for one or more locations — they can share the same IP for lab purposes.

> **Why /32?** A /32 CIDR block represents a single IP address. Most small office internet connections have a single static or dynamic public IP. If the office uses a range of IPs, adjust the CIDR notation accordingly (e.g. /29 for 6 usable addresses).

### Verify Named Locations

After creating all three:
1. Navigate to **Conditional Access** → **Named locations**
2. Confirm all three locations are listed and marked as **Trusted**

---

## Phase 2 — The 4 Conditional Access Policies

Four policies are created in order. Each addresses a specific scenario and builds on the previous one.

---

### Policy CA-01 — Require MFA for All Users

**What it does:** Every user must complete MFA on every sign-in, regardless of location, device, or application.

**Why:** MFA is the single most effective control against account compromise. A stolen password alone is not sufficient — the attacker must also pass MFA. This policy is the baseline from which everything else is built.

**Step 2 — Create CA-01**

1. Navigate to **Conditional Access** → **Policies** → **+ New policy**
2. Name: `CA-01-Require-MFA-All-Users`

**Assignments — Users:**
- Include: **All users**
- Exclude: `qcb-az@[tenant].onmicrosoft.com`

**Assignments — Target resources:**
- Include: **All cloud apps**

**Conditions:** None — applies in all situations without exception.

**Access controls — Grant:**
- Grant access
- Require multifactor authentication

**Enable policy:** **On**

3. Click **Create**

---

### Policy CA-02 — Block Legacy Authentication

**What it does:** Blocks all sign-in attempts using legacy protocols — IMAP, POP3, SMTP AUTH, Basic Auth, and others that predate MFA.

**Why:** Legacy protocols cannot support MFA. An attacker with a stolen password can authenticate using a legacy protocol and bypass CA-01's MFA requirement entirely. This policy closes that gap. In Exchange Online, all mail clients use modern authentication — no legitimate use case for legacy auth remains.

**Step 3 — Create CA-02**

1. **+ New policy**
2. Name: `CA-02-Block-Legacy-Authentication`

**Assignments — Users:**
- Include: **All users**
- Exclude: `qcb-az@[tenant].onmicrosoft.com`

**Assignments — Target resources:**
- Include: **All cloud apps**

**Conditions — Client apps:**
- Client apps: **Yes**
- Check: **Exchange ActiveSync clients** and **Other clients**
- Uncheck: **Browser** and **Mobile apps and desktop clients**

**Access controls — Grant:**
- Block access

**Enable policy:** **On**

3. Click **Create**

---

### Policy CA-03 — Executive Strict Access

**What it does:** Requires Alex Carter to always complete MFA and use a compliant managed device — with no exceptions for any named location, including the Central Office where Alex works.

**Why:** Executives are the highest-value targets for attackers and the most commonly impersonated accounts in phishing campaigns. The decision to apply this policy without any named location exemption is deliberate — being in the Central Office does not make the sign-in inherently more trustworthy. Identity and device compliance must be verified on every access request, regardless of physical location.

**Step 4 — Create CA-03**

1. **+ New policy**
2. Name: `CA-03-Executive-Strict-Access`

**Assignments — Users:**
- Include: **Select users and groups** → **GRP-Executives**
- Exclude: `qcb-az@[tenant].onmicrosoft.com`

**Assignments — Target resources:**
- Include: **All cloud apps**

**Conditions:** None — applies everywhere without location exception.

**Access controls — Grant:**
- Grant access
- Require multifactor authentication
- Require device to be marked as compliant
- Require **all** the selected controls

**Enable policy:** **On**

3. Click **Create**

---

### Policy CA-04 — Require Compliant Device or MAM for M365 Apps

**What it does:** For all users accessing Exchange Online, SharePoint, and Teams — the device must either be Intune-compliant (corporate managed laptop) or the access must be via a MAM-protected application (Outlook or Teams on Casey's iPhone).

**Why:** This is the device pillar of Zero Trust. MFA proves who the user is — this policy proves the device they are using meets the company's security requirements. A corporate laptop must be enrolled, compliant, and meet the BitLocker and screen lock requirements. A personal iPhone must access data only through MAM-protected apps with a PIN and copy/paste restrictions enforced.

> **Create in Report-only mode first.** Switch to On after the Windows laptop is enrolled and compliant (workstream 07) and the iOS MAM policy is configured (workstream 08). Enabling this before Intune is configured will lock all users out of Microsoft 365.

**Step 5 — Create CA-04**

1. **+ New policy**
2. Name: `CA-04-Require-Compliant-Device-Or-MAM`

**Assignments — Users:**
- Include: **All users**
- Exclude: `qcb-az@[tenant].onmicrosoft.com`

**Assignments — Target resources:**
- Include: **Select apps**
  - Office 365 Exchange Online
  - Office 365 SharePoint Online
  - Microsoft Teams

**Conditions:** None.

**Access controls — Grant:**
- Grant access
- Require device to be marked as compliant
- Require app protection policy
- Require **one of** the selected controls (either compliant device OR app protection is sufficient)

**Enable policy:** **Report-only**

3. Click **Create**

---

## Validation

### Confirm All 4 Policies

1. Navigate to **Conditional Access** → **Policies**
2. Confirm all four policies with correct states:

| Policy | State |
|---|---|
| CA-01-Require-MFA-All-Users | On |
| CA-02-Block-Legacy-Authentication | On |
| CA-03-Executive-Strict-Access | On |
| CA-04-Require-Compliant-Device-Or-MAM | Report-only |

### Confirm Named Locations

1. Navigate to **Conditional Access** → **Named locations**
2. Confirm all three locations are listed as trusted:

| Location | Trusted |
|---|---|
| LOC-CentralOffice | Yes |
| LOC-NorthOffice | Yes |
| LOC-SouthOffice | Yes |

### Test MFA Is Firing

1. Open a private/incognito browser window
2. Navigate to `https://portal.office.com`
3. Sign in as `jordan.hayes@qcbhomelab.online`
4. Confirm an MFA prompt appears after the password
5. Complete MFA and confirm access is granted

### Test From a Named Location (Office Network)

1. Sign in as `morgan.blake@qcbhomelab.online` from the office network (or home network registered as a named location for lab purposes)
2. Confirm **MFA is still required** — being on a trusted named location does not bypass MFA
3. In **Entra Admin Center** → **Users** → **Sign-in logs**, review the sign-in event and confirm:
   - Authentication requirement: **Multifactor authentication**
   - Named location: **LOC-CentralOffice** (or whichever is registered)
   - CA policies applied: CA-01 listed as **Success**

### Use the What If Tool

The What If tool simulates a sign-in and shows which policies would apply.

1. Navigate to **Conditional Access** → **What If**
2. Set User to `alex.carter@qcbhomelab.online`
3. Set Cloud apps to **All cloud apps**
4. Set Named location to **LOC-CentralOffice**
5. Click **What If**
6. Confirm **both CA-01 and CA-03** appear — even from the trusted Central Office location, the executive policy applies and requires MFA + compliant device

---

## Summary

This workstream delivered:

- **LOC-CentralOffice, LOC-NorthOffice, LOC-SouthOffice** — three named locations declared as trusted, used for sign-in context and reporting, not for MFA exemption
- **CA-01** — MFA required for all users, all apps, all locations including all three offices and home
- **CA-02** — Legacy authentication blocked for all users
- **CA-03** — Executive always requires MFA + compliant device, no location exceptions
- **CA-04** — Compliant device or MAM required for M365 apps (Report-only until Intune is configured)
- **Break-glass account** excluded from all policies

The Conditional Access framework reflects the multi-site reality of QCB Homelab Consultants — three office locations are known and declared, but security is never relaxed because of location. MFA and device compliance are enforced consistently whether the user is in the Central Office, the North Office, the South Office, or working from home.

**Next:** [03 — MFA & SSPR](./03-mfa-and-sspr.md)
