[← 04 — Hybrid Identity](04-hybrid-identity.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [06 — SharePoint & OneDrive →](06-sharepoint-onedrive.md)

---

# 05 — Microsoft 365 & Exchange Online

## Introduction

Microsoft 365 is the suite of cloud-based productivity tools that most modern businesses run on. It includes email (Exchange Online), file storage (OneDrive and SharePoint), communication (Teams), device management (Intune), and security (Defender). Rather than maintaining these services on local servers, Microsoft hosts everything in their global data centres and organisations pay a per-user monthly subscription.

Exchange Online is the email component of Microsoft 365. For email to flow correctly, the internet needs to know that messages addressed to @qcbhomelab.online should be delivered to Microsoft's servers. This is controlled through DNS records — specifically an MX record — that are configured in Cloudflare.

Properly securing outbound email requires three complementary DNS-based mechanisms working together: SPF, DKIM, and DMARC. Together they allow receiving mail servers to verify that email claiming to come from your domain genuinely did, and to decide what to do with messages that fail that verification.

---

## What We Are Building

| Item | Status |
|---|---|
| Microsoft 365 Business Premium trial (25 seats) | Already provisioned |
| Domain qcbhomelab.online verified in M365 | Already completed |
| MX record pointing to Exchange Online | Already configured via Cloudflare Domain Connect |
| SPF record | Already configured via Cloudflare Domain Connect |
| Autodiscover and Intune enrolment CNAMEs | Already configured via Cloudflare Domain Connect |
| Usage location set on all users | Completed in this document |
| Licence assignment | Completed in this document |
| DKIM signing | Completed in this document |
| DMARC record | Completed in this document |
| Shared mailboxes | Completed in this document |

---

## Prerequisites

The following must be in place before starting this document:

- Microsoft 365 Business Premium trial provisioned
- Domain `qcbhomelab.online` added and verified in the Microsoft 365 Admin Center
- DNS hosted in Cloudflare with Domain Connect integration completed — this automatically configures MX, SPF, and Autodiscover records
- Users synced from Active Directory and visible in Entra ID (document 04)

---

## Implementation Steps

### Step 1 — Confirm Domain and DNS Status

Log in to the Microsoft 365 Admin Center at **admin.microsoft.com**. Navigate to **Settings → Domains** and confirm that `qcbhomelab.online` shows as the default domain with a healthy status.

In the Exchange Admin Center at **admin.exchange.microsoft.com**, navigate to **Mail flow → Accepted domains** and confirm `qcbhomelab.online` appears as an Authoritative domain with Allow Sending enabled.

### Step 2 — Set Usage Location on All Users

Microsoft requires a usage location to be set on each user account before a licence can be assigned. This is a compliance requirement — some Microsoft services have different availability in different countries, and Microsoft needs to know which region's terms apply.

For synced users, the usage location is not populated automatically from Active Directory. Set it via Microsoft Graph PowerShell before attempting licence assignment.

On your management machine, open PowerShell and run:

```powershell
Connect-MgGraph -Scopes "User.ReadWrite.All"

$users = @(
    "j.carter@qcbhomelab.online",
    "o.brown@qcbhomelab.online",
    "m.reed@qcbhomelab.online",
    "s.miller@qcbhomelab.online",
    "d.wong@qcbhomelab.online",
    "e.chan@qcbhomelab.online",
    "a.hassan@qcbhomelab.online",
    "p.novak@qcbhomelab.online"
)

foreach ($upn in $users) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'"
    Update-MgUser -UserId $user.Id -UsageLocation "GB"
    Write-Host "Updated: $upn" -ForegroundColor Green
}
```

> For future users, the usage location should be set as part of the AD provisioning script in document 02, or as part of the onboarding process in document 12, to avoid repeating this step manually.

### Step 3 — Assign Microsoft 365 Licences

Licence assignment is managed in the **Microsoft 365 Admin Center** — not the Entra Admin Center.

Navigate to **Billing → Licenses → Microsoft 365 Business Premium** and click **Assign licenses**.

Search for and add all eight users:

| User | Licence |
|---|---|
| James Carter | Microsoft 365 Business Premium |
| Olivia Brown | Microsoft 365 Business Premium |
| Michael Reed | Microsoft 365 Business Premium |
| Sophia Miller | Microsoft 365 Business Premium |
| Daniel Wong | Microsoft 365 Business Premium |
| Emily Chan | Microsoft 365 Business Premium |
| Amir Hassan | Microsoft 365 Business Premium |
| Petra Novak | Microsoft 365 Business Premium |

Click **Assign licenses**. The counter should update to **8/25 assigned**.

> **Production note:** In a production environment, contractors would typically receive Microsoft 365 Business Basic rather than Business Premium — this provides access to web apps and Teams without the full desktop Office suite or Intune MDM entitlements. For this lab, all users receive Business Premium for simplicity.

Once licences are assigned, Exchange Online automatically provisions mailboxes for all users in the background. This typically takes a few minutes. No manual action is required.

### Step 4 — Enable DKIM Signing

DKIM adds a cryptographic signature to every outbound email, allowing receiving servers to verify that the message genuinely came from `qcbhomelab.online` and has not been tampered with in transit. Without DKIM, outbound email is more likely to be treated as spam by receiving servers.

DKIM is configured in the **Microsoft Defender portal**, not the Exchange Admin Center.

Navigate to **security.microsoft.com → Email & collaboration → Policies & rules → Threat policies → Email authentication settings → DKIM**.

Click on `qcbhomelab.online` and select **Create DKIM keys**. Microsoft will generate a key pair and display two CNAME records that must be added to Cloudflare DNS before DKIM can be enabled:

| Type | Name | Value |
|---|---|---|
| CNAME | `selector1._domainkey` | `selector1-qcbhomelab-online._domainkey.qcbazoutlook362.a-v1.dkim.mail.microsoft` |
| CNAME | `selector2._domainkey` | `selector2-qcbhomelab-online._domainkey.qcbazoutlook362.a-v1.dkim.mail.microsoft` |

Add both records to Cloudflare DNS with proxy status set to **DNS only** (grey cloud). DKIM CNAMEs must not be proxied through Cloudflare.

Verify the records are resolving from an external DNS server before enabling:

```powershell
Resolve-DnsName selector1._domainkey.qcbhomelab.online -Type CNAME -Server 1.1.1.1
Resolve-DnsName selector2._domainkey.qcbhomelab.online -Type CNAME -Server 1.1.1.1
```

Both should return the Microsoft DKIM target values. Once confirmed, return to the Defender portal and toggle DKIM **On** for `qcbhomelab.online`. The status should change to **Valid — Enabled**.

### Step 5 — Add a DMARC Record

DMARC tells receiving mail servers what to do with emails from `qcbhomelab.online` that fail SPF or DKIM checks. Without DMARC, those decisions are left entirely to the receiving server. With DMARC, you control the policy and receive reporting on authentication results.

Add the following TXT record to Cloudflare DNS:

| Type | Name | Value |
|---|---|---|
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@qcbhomelab.online` |

The `p=none` policy means no action is taken on failing messages initially — emails are still delivered but aggregate reports are sent to the `rua` address. This allows you to monitor authentication results before enforcing a stricter policy.

Once you are confident that all legitimate email is passing SPF and DKIM, the policy should be progressively tightened:

| Stage | Policy | Effect |
|---|---|---|
| Initial | `p=none` | Monitor only — no action on failures |
| Intermediate | `p=quarantine` | Failing messages sent to spam/junk |
| Final | `p=reject` | Failing messages rejected outright |

Verify the record is in place:

```bash
dig _dmarc.qcbhomelab.online TXT
```

### Step 6 — Create Shared Mailboxes

Shared mailboxes are email addresses that multiple users can access and send from without requiring a dedicated licence. They are suited to generic addresses like IT support or general enquiries that multiple team members need to monitor.

In the Exchange Admin Center, navigate to **Recipients → Mailboxes** and click **Add a shared mailbox**.

Create the following two shared mailboxes:

| Display Name | Email Address |
|---|---|
| QCB IT Support | itsupport@qcbhomelab.online |
| QCB General Enquiries | info@qcbhomelab.online |

After creating each mailbox, configure delegation so the relevant staff can access and send from it. Click on each mailbox and navigate to the **Delegation** tab.

For each shared mailbox, add all six staff members to both permission types:

| Permission | Purpose |
|---|---|
| Read and manage (Full Access) | Allows users to open the mailbox and read emails in Outlook |
| Send as | Allows users to send email appearing to come from the shared address |

> Do not use **Send on behalf** — this sends as "User on behalf of QCB IT Support" which looks unprofessional for a shared address. **Send as** shows only the shared mailbox address as the sender.

Contractors (Amir Hassan and Petra Novak) are not added to shared mailbox delegation — they do not have access to internal shared inboxes.

### Step 7 — Verify the Complete DNS Record Set

With all records in place, verify the complete email DNS configuration:

```powershell
# MX record
Resolve-DnsName -Name "qcbhomelab.online" -Type MX -Server 1.1.1.1

# SPF record
Resolve-DnsName -Name "qcbhomelab.online" -Type TXT -Server 1.1.1.1

# Autodiscover
Resolve-DnsName -Name "autodiscover.qcbhomelab.online" -Type CNAME -Server 1.1.1.1

# DKIM selectors
Resolve-DnsName -Name "selector1._domainkey.qcbhomelab.online" -Type CNAME -Server 1.1.1.1
Resolve-DnsName -Name "selector2._domainkey.qcbhomelab.online" -Type CNAME -Server 1.1.1.1

# DMARC
Resolve-DnsName -Name "_dmarc.qcbhomelab.online" -Type TXT -Server 1.1.1.1
```

All six should return values pointing to Microsoft infrastructure. On Linux, use `dig` in place of `Resolve-DnsName`:

```bash
dig qcbhomelab.online MX
dig qcbhomelab.online TXT
dig autodiscover.qcbhomelab.online CNAME
dig selector1._domainkey.qcbhomelab.online CNAME
dig selector2._domainkey.qcbhomelab.online CNAME
dig _dmarc.qcbhomelab.online TXT
```

---

## What to Expect

Once these steps are complete, all eight users have active Exchange Online mailboxes and can sign in to Outlook on the web at **outlook.office.com** using their AD credentials. Outbound email is cryptographically signed with DKIM, SPF is in place to authorise Microsoft's sending infrastructure, and DMARC provides monitoring and a path to enforcement.

The two shared mailboxes are immediately accessible by all six staff members from their own Outlook clients — the shared mailboxes appear automatically in Outlook once Full Access delegation is applied.

---

## Troubleshooting

**"License assignment cannot be done for user with invalid usage location"**
The usage location has not been set on the user account. Run the PowerShell script in Step 2 to set the usage location to `GB` for all users before attempting licence assignment.

**DKIM location has changed**
As of 2025, DKIM is no longer configured in the Exchange Admin Center. It is now managed exclusively in the Microsoft Defender portal under Email & collaboration → Policies & rules → Threat policies → Email authentication settings.

**DKIM enable fails with "CNAME record does not exist"**
The CNAME records have been added to Cloudflare but Microsoft's verification servers haven't picked them up yet. Verify the records are resolving publicly using `Resolve-DnsName` with `-Server 1.1.1.1` and retry enabling DKIM after a few minutes. Cloudflare propagates quickly but Microsoft's verification can lag slightly behind.

**Shared mailbox delegation — users not found**
If user accounts do not appear when searching for delegates, their Exchange Online mailboxes have not been provisioned yet. Mailboxes are created automatically when a licence is assigned — wait a few minutes after licence assignment before configuring delegation.

**Running Resolve-DnsName from DC01 returns "DNS name does not exist"**
By default, DC01 queries its own local DNS server which only knows about internal records. Always specify `-Server 1.1.1.1` when verifying external DNS records from DC01. On Linux, use `dig` instead — `Resolve-DnsName` is a Windows-only cmdlet.

---

[← 04 — Hybrid Identity](04-hybrid-identity.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [06 — SharePoint & OneDrive →](06-sharepoint-onedrive.md)
