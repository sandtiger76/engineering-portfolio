# 04 — Exchange Online

## In Plain English

Email is the backbone of business communication. Exchange Online is Microsoft's cloud email platform — it gives every member of staff a professional email address, a full-featured inbox, calendar, and contacts, all without running a single mail server.

But email is also one of the most common attack vectors. Phishing, spoofing, and malware delivered by email cause the majority of security incidents in organisations of every size. This workstream does two things: it sets up Exchange Online for QCB Homelab Consultants, and it locks it down so that the company's email domain cannot be used to send fake emails, and inbound threats are filtered before they reach staff inboxes.

---

## Why This Matters

A misconfigured email platform creates two distinct risks.

The first is inbound: malicious emails reach staff inboxes, where a single click on a link or attachment can compromise an account, install malware, or initiate a fraudulent payment. Exchange Online Protection (EOP) filters inbound email automatically — but it needs to be configured correctly to be effective.

The second is outbound: without proper email authentication records, the `qcbhomelab.online` domain can be impersonated by anyone. An attacker can send emails that appear to come from `alex.carter@qcbhomelab.online` without having access to the account at all. DKIM, SPF, and DMARC prevent this — they prove that emails from this domain genuinely came from Microsoft's servers.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| 5 staff users with Business Premium licences | Completed in workstream 01 |
| qcbhomelab.online verified as default domain | Pre-configured |
| Cloudflare DNS access | Required for DKIM CNAME records and DMARC TXT record |
| MX record already pointing to Exchange Online | Configured via Cloudflare Domain Connect at domain verification |

> **MX record note:** When the domain was verified in Microsoft 365, Cloudflare Domain Connect automatically added the MX record pointing to Exchange Online. This means inbound email is already routing to Exchange. Verify this is in place before proceeding.

---

## The End State

| Component | State |
|---|---|
| 5 staff mailboxes | Active — alex.carter, morgan.blake, jordan.hayes, riley.morgan, casey.quinn |
| Shared mailbox | info@qcbhomelab.online |
| Distribution group | allstaff@qcbhomelab.online |
| Transport rule | Block external email forwarding |
| DKIM | Enabled — both selectors active |
| SPF | Active — added at domain verification |
| DMARC | p=quarantine — actively protecting the domain |
| EOP | Active by default — anti-spam, anti-malware |

---

## Phase 1 — Verify Mailbox Provisioning

Exchange Online mailboxes are created automatically when a Business Premium licence is assigned. No manual mailbox creation is required.

### Step 1 — Confirm Mailboxes Are Active

1. Navigate to **Exchange Admin Center** at `https://admin.exchange.microsoft.com`
2. Go to **Recipients** → **Mailboxes**
3. Confirm all 5 staff mailboxes are listed with status **Active**:
   - alex.carter@qcbhomelab.online
   - morgan.blake@qcbhomelab.online
   - jordan.hayes@qcbhomelab.online
   - riley.morgan@qcbhomelab.online
   - casey.quinn@qcbhomelab.online

4. Click each mailbox and confirm the primary SMTP address matches the UPN

Via PowerShell:

```powershell
Connect-ExchangeOnline -UserPrincipalName m365admin@qcbhomelab.online

# List all mailboxes
Get-Mailbox -ResultSize Unlimited |
    Select-Object DisplayName, PrimarySmtpAddress, RecipientTypeDetails |
    Format-Table
```

---

## Phase 2 — Shared Mailbox

### Step 2 — Create the Info Shared Mailbox

A shared mailbox is a mailbox that multiple users can access without requiring a separate licence. `info@qcbhomelab.online` is the company's general enquiries address — all office staff should be able to read and respond from it.

1. In **Exchange Admin Center** → **Recipients** → **Mailboxes** → **Add a shared mailbox**
2. Configure:

| Field | Value |
|---|---|
| Display name | QCB Homelab Consultants Info |
| Email address | info@qcbhomelab.online |

3. Click **Create**
4. After creation, click **Add members** → add Morgan Blake, Jordan Hayes, and Riley Morgan
5. Set permissions: **Read and manage** (allows reading and sending as the shared mailbox)

Via PowerShell:

```powershell
# Create shared mailbox
New-Mailbox -Shared -Name "QCB Info" -DisplayName "QCB Homelab Consultants Info" -Alias "info" -PrimarySmtpAddress "info@qcbhomelab.online"

# Add members
Add-MailboxPermission -Identity "info@qcbhomelab.online" -User "morgan.blake@qcbhomelab.online" -AccessRights FullAccess -InheritanceType All
Add-MailboxPermission -Identity "info@qcbhomelab.online" -User "jordan.hayes@qcbhomelab.online" -AccessRights FullAccess -InheritanceType All
Add-MailboxPermission -Identity "info@qcbhomelab.online" -User "riley.morgan@qcbhomelab.online" -AccessRights FullAccess -InheritanceType All
```

---

## Phase 3 — Distribution Group

### Step 3 — Create the All Staff Distribution Group

A distribution group is an email alias that, when sent to, delivers the message to all members. `allstaff@qcbhomelab.online` delivers to all 5 staff members simultaneously.

1. In **Exchange Admin Center** → **Recipients** → **Groups** → **Add a group**
2. Select **Distribution** → **Next**
3. Configure:

| Field | Value |
|---|---|
| Name | All Staff |
| Description | All QCB Homelab Consultants staff |
| Group email address | allstaff@qcbhomelab.online |
| Allow people outside the organisation to send to this group | No |

4. Add all 5 staff users as members
5. Set the group owner to `m365admin@qcbhomelab.online`
6. Click **Create**

---

## Phase 4 — Transport Rule

### Step 4 — Block External Email Forwarding

Automatic email forwarding to external addresses is a common data exfiltration technique. If an attacker compromises a mailbox, they may configure it to silently forward all incoming email to an external address. This transport rule prevents that.

1. In **Exchange Admin Center** → **Mail flow** → **Rules** → **+ Add a rule** → **Create a new rule**
2. Configure:

| Field | Value |
|---|---|
| Name | Block External Auto-Forward |
| Apply this rule if | The sender is located: Inside the organisation |
| And | The message properties include: Message type: Auto-forward |
| Do the following | Block the message: Reject the message and include an explanation |
| Explanation | Automatic email forwarding to external addresses is not permitted. |

3. Set **Rule mode** to **Enforce**
4. Click **Save**

Via PowerShell:

```powershell
New-TransportRule -Name "Block External Auto-Forward" `
    -FromScope InOrganization `
    -MessageTypeMatches AutoForward `
    -RejectMessageReasonText "Automatic email forwarding to external addresses is not permitted." `
    -RejectMessageEnhancedStatusCode "5.7.1"
```

---

## Phase 5 — Email Authentication

Email authentication is a set of DNS records that prove emails sent from `qcbhomelab.online` genuinely came from Microsoft's servers. Without these records, any attacker can send emails that appear to come from `@qcbhomelab.online` — known as spoofing or impersonation.

Three records work together:

- **SPF** — lists the servers authorised to send email from this domain
- **DKIM** — adds a cryptographic signature to outbound email that recipients can verify
- **DMARC** — tells receiving servers what to do with email that fails SPF or DKIM checks

### Step 5 — Verify SPF Record

SPF was added automatically by Cloudflare Domain Connect when the domain was verified. Verify it is in place.

In Cloudflare DNS, confirm the following TXT record exists for `qcbhomelab.online`:

```
v=spf1 include:spf.protection.outlook.com -all
```

The `-all` means any server not listed is unauthorised — a strict policy. Verify via PowerShell:

```powershell
Resolve-DnsName -Name "qcbhomelab.online" -Type TXT |
    Where-Object { $_.Strings -like "*spf*" }
```

### Step 6 — Enable DKIM

DKIM adds a cryptographic signature to every outbound email. The signature is verified by the recipient's mail server against a public key published in Cloudflare DNS.

**Enable DKIM in the Defender portal:**

1. Navigate to **Microsoft Defender portal** at `https://security.microsoft.com`
2. Go to **Email & Collaboration** → **Policies & Rules** → **Threat policies** → **Email authentication settings**
3. Select the **DKIM** tab
4. Select `qcbhomelab.online` → click **Create DKIM keys**
5. Microsoft generates two CNAME values — copy both

**Add DKIM CNAME records to Cloudflare:**

| Type | Name | Value |
|---|---|---|
| CNAME | selector1._domainkey | selector1-qcbhomelab-online._domainkey.qcbhomelab.onmicrosoft.com |
| CNAME | selector2._domainkey | selector2-qcbhomelab-online._domainkey.qcbhomelab.onmicrosoft.com |

> Copy the exact values generated by Microsoft — do not type them manually. The format above is illustrative; the actual values will differ.

6. After adding the CNAMEs to Cloudflare, wait 5–10 minutes for propagation
7. Return to the DKIM tab → click **Enable** for `qcbhomelab.online`
8. Status should change to **Enabled**

Verify via PowerShell:

```powershell
Get-DkimSigningConfig -Identity qcbhomelab.online |
    Select-Object Domain, Enabled, Status
```

Expected output:
```
Domain                  Enabled   Status
------                  -------   ------
qcbhomelab.online       True      Valid
```

### Step 7 — Configure DMARC

DMARC is a policy record that tells receiving mail servers what to do with email from `qcbhomelab.online` that fails SPF or DKIM checks. It is set to `p=quarantine` — failing emails are sent to the recipient's spam/quarantine folder rather than delivered to the inbox.

**Add a DMARC TXT record to Cloudflare DNS:**

| Type | Name | Value |
|---|---|---|
| TXT | _dmarc | v=DMARC1; p=quarantine; rua=mailto:m365admin@qcbhomelab.online |

**Understanding the record:**

- `v=DMARC1` — identifies this as a DMARC record
- `p=quarantine` — emails failing authentication are quarantined, not delivered
- `rua=mailto:m365admin@qcbhomelab.online` — aggregate reports on authentication failures are sent to this address

> **Why p=quarantine and not p=reject?** `p=reject` is the strictest option — failing emails are discarded entirely. However, `p=reject` can cause legitimate email to be lost if SPF or DKIM is misconfigured. `p=quarantine` is the responsible intermediate step — it protects the domain actively while allowing recovery if a misconfiguration is discovered. A production deployment would monitor quarantine reports and move to `p=reject` once confident that no legitimate email is failing.

Verify DMARC is in place:

```powershell
Resolve-DnsName -Name "_dmarc.qcbhomelab.online" -Type TXT
```

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| All 5 mailboxes active | Exchange Admin Center → Mailboxes | 5 active mailboxes listed |
| Shared mailbox created | Exchange Admin Center → Mailboxes (shared) | info@qcbhomelab.online present |
| Members can access shared mailbox | Sign in as morgan.blake, open Outlook, confirm info mailbox visible | Shared mailbox appears in Outlook |
| Distribution group created | Exchange Admin Center → Groups | allstaff@qcbhomelab.online listed |
| Send test email to allstaff | Send from external address to allstaff@qcbhomelab.online | All 5 users receive the email |
| Transport rule active | Exchange Admin Center → Rules | Block External Auto-Forward listed, Enforced |
| SPF record present | Resolve-DnsName → TXT lookup | v=spf1 include:spf.protection.outlook.com -all |
| DKIM enabled | Defender portal → DKIM | Status: Enabled, Valid |
| DMARC at p=quarantine | DNS TXT lookup for _dmarc | p=quarantine confirmed |
| Send/receive test | Send email to and from @qcbhomelab.online | Delivered successfully, DKIM signed |

### Full Email Authentication Check

Use MXToolbox to verify all three authentication records:

1. Navigate to `https://mxtoolbox.com/emailhealth`
2. Enter `qcbhomelab.online`
3. Confirm SPF, DKIM, and DMARC all show as passing

---

## Summary

This workstream delivered:

- **5 staff mailboxes** active and accessible in Outlook and Outlook Web App
- **Shared mailbox** `info@qcbhomelab.online` — accessible by office staff without a separate licence
- **Distribution group** `allstaff@qcbhomelab.online` — delivers to all 5 staff
- **Transport rule** blocking automatic external email forwarding — data exfiltration prevention
- **SPF** verified — authorised mail servers declared
- **DKIM** enabled — outbound email cryptographically signed
- **DMARC at p=quarantine** — active domain protection, aggregate reports enabled

The `qcbhomelab.online` domain is now protected against spoofing. Inbound email is filtered by Exchange Online Protection. Outbound email is signed and authenticated.

**Next:** [05 — SharePoint & OneDrive](./05-sharepoint-and-onedrive.md)
