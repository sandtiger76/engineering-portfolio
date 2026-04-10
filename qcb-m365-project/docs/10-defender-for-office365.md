# 10 — Microsoft Defender for Office 365

## In Plain English

Exchange Online Protection (EOP) — active by default for all Exchange Online mailboxes — filters out spam and known malware. It is a useful baseline, but it has limits. It checks email against known bad signatures. It does not open links to see where they lead. It does not detonate attachments in a safe environment to see what they do. It does not check whether an email is impersonating the company's own executives.

Microsoft Defender for Office 365 Plan 1 is included in Microsoft 365 Business Premium and addresses these gaps. It adds three key capabilities: Safe Links, Safe Attachments, and anti-phishing with impersonation protection.

Together they address the most common ways attackers use email to compromise organisations: malicious links, weaponised attachments, and impersonation of trusted people.

---

## Why This Matters

Email is the most common entry point for cyberattacks. Phishing emails that impersonate trusted senders, attachments containing malware, and links that redirect to credential-harvesting pages account for the majority of successful breaches.

EOP catches the known threats — the malware with recognised signatures, the domains on blocklists. Defender for Office 365 catches the unknown threats — the new malware that has never been seen before, the malicious link that was registered yesterday and is not yet on any blocklist, and the email that appears to come from Alex Carter but was actually sent by an attacker.

For QCB Homelab Consultants — a consultancy where a convincing impersonation of the Managing Director could authorise a fraudulent payment — impersonation protection is particularly important.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Microsoft 365 Business Premium licences assigned | Defender for Office 365 Plan 1 is included |
| DKIM and SPF active | Completed in workstream 04 — required for Defender to function correctly |
| Exchange Online mailboxes active | Completed in workstream 04 |
| Microsoft Defender portal accessible | https://security.microsoft.com |

---

## The End State

| Component | State |
|---|---|
| Safe Links | Enabled — all email and Office apps |
| Safe Attachments | Enabled — Dynamic Delivery mode |
| Anti-phishing | Enabled — impersonation protection for executive |
| Quarantine | Active — review weekly |

---

## Phase 1 — Safe Links

Safe Links rewrites every URL in incoming email. When a user clicks a link, it is first checked against Microsoft's threat intelligence in real time. If the link leads to a known malicious site, the click is blocked and the user sees a warning. If the destination has changed since the email was sent — a common technique called link aging, where a link is safe at delivery but malicious by the time the user clicks — Safe Links catches this too.

### Step 1 — Configure the Safe Links Policy

1. Navigate to `https://security.microsoft.com`
2. Go to **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Safe Links**
3. Click **+ Create** to create a new policy
4. Name: `SafeLinks-AllUsers`
5. Click **Next**

**Users and domains:**
- Domains: add `qcbhomelab.online`
- This applies the policy to all email sent to the company's domain

**URL & click protection settings:**

| Setting | Value | Reason |
|---|---|---|
| On: Safe Links checks a list of known, malicious links when users click links in email | On | Core Safe Links protection |
| Apply Safe Links to email messages sent within the organisation | On | Internal phishing can happen — compromised accounts can send malicious links internally |
| Apply real-time URL scanning for suspicious links and links that point to files | On | Detonates suspicious links before allowing the click |
| Wait for URL scanning to complete before delivering the message | On | Slower delivery but safer — links are confirmed clean before the email reaches the inbox |
| Do not rewrite URLs, do only checking via Safe Links API | Off | URLs should be rewritten — this is the standard protective mode |
| Do not track when users click Safe Links | Off | Click tracking provides valuable intelligence for investigating incidents |
| Do not let users click through Safe Links to the original URL | On | Users cannot bypass the Safe Links warning |

**Office 365 apps:**

| Setting | Value |
|---|---|
| On: Safe Links checks links in Office 365 apps | On |
| Do not track when users click Safe Links in Office 365 apps | Off |
| Do not let users click through Safe Links in Office 365 apps to the original URL | On |

6. Click **Next** → **Submit** → **Done**

---

## Phase 2 — Safe Attachments

Safe Attachments opens every email attachment in a secure, isolated virtual environment (a sandbox) before delivering it to the user's inbox. The attachment runs in the sandbox — if it attempts to download malware, call home to a command-and-control server, or perform any malicious action, it is caught. Only clean attachments are delivered.

Dynamic Delivery is the recommended mode: the email body is delivered immediately while the attachment is being scanned, and the attachment is replaced with a placeholder. Once scanning is complete (typically within seconds), the real attachment replaces the placeholder. This means users do not experience significant email delivery delays.

### Step 2 — Configure the Safe Attachments Policy

1. In **Defender portal** → **Threat policies** → **Safe Attachments**
2. Click **+ Create**
3. Name: `SafeAttachments-AllUsers`
4. Click **Next**

**Users and domains:**
- Domains: `qcbhomelab.online`

**Settings:**

| Setting | Value | Reason |
|---|---|---|
| Safe Attachments unknown malware response | Dynamic Delivery | Email is delivered while attachment is scanned |
| Redirect attachments with detected malware | On | Send malicious attachments to admin for investigation |
| Redirect email to | m365admin@qcbhomelab.online | Admin receives copies of detected malicious attachments |
| Apply the above selection if malware scanning for attachments times out or error occurs | On | Fail safe — if scanning fails, treat the attachment as potentially malicious |

5. Click **Next** → **Submit** → **Done**

---

## Phase 3 — Anti-Phishing Policy

The anti-phishing policy provides protection against two distinct phishing techniques:

**Impersonation** — an email appears to come from a trusted person (Alex Carter, the Executive) or a trusted organisation, but it has been sent by an attacker. Impersonation protection checks the display name and sending address against a list of protected users and domains.

**Spoofing** — an email's sender address is forged to appear to come from the company's own domain or a trusted partner domain. Anti-spoofing intelligence checks whether the sender is authorised to send from that domain.

### Step 3 — Configure Anti-Phishing Policy

1. In **Defender portal** → **Threat policies** → **Anti-phishing**
2. Click on the existing **Office365 AntiPhish Default** policy → **Edit protection settings**

**Phishing threshold:**
- Set to **2 - Aggressive** (balances detection rate against false positives; appropriate for a security-conscious organisation)

**Impersonation — protected users:**
1. Under **Protect users**, click **Manage (n) users**
2. Add `alex.carter@qcbhomelab.online` with display name `Alex Carter`
3. This means any email that appears to come from Alex Carter — but is not actually sent from that account — is flagged as a phishing attempt

**Impersonation — protected domains:**
1. Under **Protect domains**, enable **Include domains I own**
2. This protects `qcbhomelab.online` from spoofing

**Actions:**

| Setting | Value |
|---|---|
| If a user is detected as impersonated | Quarantine the message |
| If a domain is detected as impersonated | Quarantine the message |
| If mailbox intelligence detects an impersonated user | Move message to recipients' Junk Email folders |

**Mailbox intelligence:**
- Enable mailbox intelligence: **On**
- Enable mailbox intelligence based impersonation protection: **On**

3. Click **Save**

---

## Phase 4 — Review Quarantine

### Step 4 — Configure Quarantine Notifications

Quarantined emails are not automatically delivered to users — they wait for review. Configure quarantine so that users receive notifications about quarantined messages and can request release of false positives.

1. In **Defender portal** → **Threat policies** → **Quarantine policies**
2. Select the **DefaultFullAccessPolicy** → **Edit**
3. Under **Quarantine notifications**, set:
   - Enable quarantine notifications: **On**
   - Frequency: **Daily**
4. Click **Save**

### Step 5 — Review Quarantine as Administrator

1. Navigate to **Defender portal** → **Email & Collaboration** → **Review** → **Quarantine**
2. Review any quarantined messages
3. For each message, options include:
   - **Release** — deliver the email to the recipient
   - **Release and allow sender** — deliver and add the sender to the allow list
   - **Delete** — permanently remove
   - **Preview** — view the message content before deciding

> Quarantine should be reviewed regularly — at minimum weekly. False positives (legitimate emails incorrectly quarantined) can affect business operations if not noticed promptly.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Safe Links policy active | Defender portal → Safe Links | SafeLinks-AllUsers listed, enabled |
| Safe Attachments policy active | Defender portal → Safe Attachments | SafeAttachments-AllUsers listed, enabled |
| Anti-phishing policy configured | Defender portal → Anti-phishing | Office365 AntiPhish Default — impersonation protection enabled |
| Executive user protected | Anti-phishing → protected users | alex.carter@qcbhomelab.online listed |
| Quarantine notifications configured | Quarantine policies | Daily notifications enabled |
| Safe Links test | Send a test email containing a known test URL (https://www.wicar.org/test-malware.html) | Link is blocked or flagged |

### Email Authentication Validation

Run a full email authentication check:

1. Navigate to `https://mxtoolbox.com/emailhealth`
2. Enter `qcbhomelab.online`
3. Confirm:
   - MX record → Exchange Online
   - SPF → Pass
   - DKIM → Pass
   - DMARC → p=quarantine

---

## Understanding the Layers of Email Protection

It is worth summarising how the email protection layers work together:

| Layer | Tool | What It Does |
|---|---|---|
| 1 | SPF | Verifies the sending server is authorised for the domain |
| 2 | DKIM | Verifies the email was signed by the sending domain |
| 3 | DMARC | Tells recipients what to do when SPF or DKIM fails (p=quarantine) |
| 4 | EOP Anti-spam | Filters known spam and malicious emails by reputation and content |
| 5 | EOP Anti-malware | Scans attachments for known malware signatures |
| 6 | Safe Links | Scans and re-checks URLs at click time |
| 7 | Safe Attachments | Detonates attachments in a sandbox before delivery |
| 8 | Anti-phishing | Detects impersonation of trusted users and domains |

No single layer catches everything. The security comes from the depth — an attack that bypasses one layer encounters the next. This is defence in depth applied to email.

---

## Summary

This workstream delivered:

- **Safe Links** — all URLs in email and Office apps scanned at click time, blocking malicious redirects
- **Safe Attachments** — Dynamic Delivery mode, attachments detonated in sandbox before delivery
- **Anti-phishing** — impersonation protection for Alex Carter (Executive), domain spoofing protection for qcbhomelab.online
- **Quarantine** configured — daily notifications, administrator review process established
- **Defence in depth** — 8 layers of email protection working together

This workstream also closed the second major gap from the previous version of this project. Safe Links and Safe Attachments were available in the Microsoft 365 Business Premium licence but not enabled. They are now fully configured.

**Next:** [11 — Security Posture Summary](./11-security-posture-summary.md)
