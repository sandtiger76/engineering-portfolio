[← 04 — Hybrid Identity](04-hybrid-identity.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [06 — SharePoint & OneDrive →](06-sharepoint-onedrive.md)

---

# 05 — Microsoft 365 & Exchange Online

## Introduction

Microsoft 365 is the suite of cloud-based productivity tools that most modern businesses run on. It includes email (Exchange Online), file storage (OneDrive and SharePoint), communication (Teams), device management (Intune), and security (Defender). Rather than maintaining these services on local servers, Microsoft hosts everything in their global data centres and organisations pay a per-user monthly subscription.

Exchange Online is the email component of Microsoft 365. For email to flow correctly, the internet needs to know that messages addressed to @qcbhomelab.online should be delivered to Microsoft's servers. This is controlled through DNS records — specifically an MX record — that were already configured during the initial domain setup for this project using Cloudflare's Domain Connect integration.

This document covers the Microsoft 365 tenant configuration, confirms what has already been completed, and sets up the remaining email security components (DKIM and DMARC) that are not added automatically.

---

## What We Are Building

| Item | Status |
|---|---|
| Microsoft 365 Business Premium trial (25 seats) | Already provisioned |
| Domain qcbhomelab.online verified in M365 | Already completed |
| MX record pointing to Exchange Online | Already configured via Cloudflare |
| SPF record | Already configured |
| Autodiscover, Intune enrolment CNAMEs | Already configured |
| DKIM signing | To be completed in this document |
| DMARC record | To be completed in this document |
| Shared mailboxes | To be configured |

---

## Implementation Steps

### Step 1 — Confirm Domain and DNS Status

Log in to the Microsoft 365 Admin Center at admin.microsoft.com. Navigate to Settings → Domains and confirm that qcbhomelab.online shows as Healthy with a green tick. All DNS records added via Domain Connect should show as verified.

If any record shows an error, check the Cloudflare DNS dashboard and compare the values against what M365 expects under Settings → Domains → qcbhomelab.online → DNS records.

### Step 2 — Enable DKIM Signing

DKIM adds a cryptographic signature to every outbound email, allowing the receiving server to verify the message genuinely came from qcbhomelab.online and has not been tampered with. Without it, email from this domain is more likely to be treated as spam.

DKIM is not added automatically and must be enabled manually.

1. Go to the Exchange Admin Center — admin.exchange.microsoft.com
2. Navigate to Mail flow → Email authentication
3. Select DKIM
4. Click on qcbhomelab.online
5. Click Enable — Microsoft will display two CNAME records that need to be added to Cloudflare

Add both CNAME records to Cloudflare DNS. They will look similar to:

| Type | Name | Value |
|---|---|---|
| CNAME | selector1._domainkey | selector1-qcbhomelab-online._domainkey.qcbhomelab.onmicrosoft.com |
| CNAME | selector2._domainkey | selector2-qcbhomelab-online._domainkey.qcbhomelab.onmicrosoft.com |

After adding the records, return to the Exchange Admin Center and enable DKIM. DNS propagation may take up to an hour before the enable button succeeds.

Verify DKIM from PowerShell:

```powershell
Resolve-DnsName selector1._domainkey.qcbhomelab.online -Type CNAME
```

### Step 3 — Add a DMARC Record

DMARC tells receiving mail servers what to do with emails from qcbhomelab.online that fail SPF or DKIM checks. Without DMARC, those decisions are left to the receiving server — which may silently accept or silently drop the message. With DMARC, you are in control.

Add the following TXT record to Cloudflare DNS manually:

| Type | Name | Value |
|---|---|---|
| TXT | _dmarc | v=DMARC1; p=none; rua=mailto:dmarc@qcbhomelab.online |

The `p=none` policy means no action is taken on failing messages initially — emails are still delivered but reports are sent to the rua address. Once you are confident that all legitimate email is passing SPF and DKIM, the policy can be changed to `p=quarantine` and eventually `p=reject`.

Verify DMARC from PowerShell:

```powershell
Resolve-DnsName _dmarc.qcbhomelab.online -Type TXT
```

### Step 4 — Create Shared Mailboxes

Shared mailboxes are email addresses that multiple people can access without needing a separate licence. Common examples include a general enquiries mailbox or a support address.

In the Exchange Admin Center, navigate to Recipients → Shared mailboxes and create the following:

| Display name | Email address |
|---|---|
| QCB IT Support | itsupport@qcbhomelab.online |
| QCB General Enquiries | info@qcbhomelab.online |

Add the relevant users as members who can send from and access each mailbox.

### Step 5 — Test Email Flow

Send a test email from a personal email address to one of the provisioned user accounts (e.g. j.carter@qcbhomelab.online). Log in to Outlook on the web at outlook.office.com using that account and confirm the email arrives.

Send a reply and confirm the outbound email is received by the sender. Use Microsoft's Remote Connectivity Analyzer at testconnectivity.microsoft.com to run a full inbound email flow test and verify MX, SPF, and DKIM are all passing.

### Step 6 — Verify the Full DNS Record Set

```powershell
# MX record
Resolve-DnsName -Name "qcbhomelab.online" -Type MX

# SPF record
Resolve-DnsName -Name "qcbhomelab.online" -Type TXT

# Autodiscover
Resolve-DnsName -Name "autodiscover.qcbhomelab.online" -Type CNAME

# DKIM
Resolve-DnsName -Name "selector1._domainkey.qcbhomelab.online" -Type CNAME

# DMARC
Resolve-DnsName -Name "_dmarc.qcbhomelab.online" -Type TXT
```

All five should return values pointing to Microsoft infrastructure.

---

## What to Expect

Once these steps are complete, email flows correctly in both directions, outbound messages are cryptographically signed, and you have DMARC reporting in place to monitor authentication results. The domain and tenant are ready for the SharePoint, Teams, and Intune configurations that follow.

---

[← 04 — Hybrid Identity](04-hybrid-identity.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [06 — SharePoint & OneDrive →](06-sharepoint-onedrive.md)
