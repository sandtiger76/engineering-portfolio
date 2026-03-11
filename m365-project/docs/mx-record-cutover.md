# DNS & MX Record Reference

## In Plain English

For email to flow into Microsoft 365, the internet needs to know that `@qcbhomelab.online`
email should be delivered to Microsoft's servers — not to the old third-party email host.
This is done via DNS records, specifically an MX record (Mail Exchange record) that points
to Exchange Online.

In addition to the MX record, several other DNS records are required to make email work
correctly and securely — records that prevent the domain being used for spam, help email
clients configure themselves automatically, and enable Intune device enrolment.

---

## How DNS Was Configured in This Project

During the domain setup wizard in Microsoft 365 Admin Center, Microsoft detected that
`qcbhomelab.online` uses Cloudflare as its DNS provider. It offered to add all required
DNS records automatically via the **Cloudflare Domain Connect** integration — a one-click
authorisation that added every record in a single operation.

This is the recommended approach when the DNS provider supports Domain Connect. It
eliminates manual entry errors and ensures records are added with the correct values and TTLs.

> **Production note:** Not all DNS providers support Domain Connect. Where it is not
> available, DNS records must be added manually using the values provided in the M365
> Admin Center under Settings → Domains → [domain name] → DNS records.

---

## DNS Records Added

The following records were added automatically to Cloudflare DNS for `qcbhomelab.online`:

| Type | Host / Name | Value | TTL | Purpose |
|---|---|---|---|---|
| MX | `@` | `qcbhomelab-online.mail.protection.outlook.com` (priority 0) | 1 hr | Routes inbound email to Exchange Online |
| TXT | `@` | `v=spf1 include:spf.protection.outlook.com -all` | 1 hr | SPF — prevents domain spoofing |
| CNAME | `autodiscover` | `autodiscover.outlook.com` | 1 hr | Outlook auto-configuration |
| CNAME | `enterpriseregistration` | `enterpriseregistration.windows.net` | 1 hr | Intune device registration |
| CNAME | `enterpriseenrollment` | `enterpriseenrollment-s.manage.microsoft.com` | 1 hr | Intune device enrolment |

All records are set to **DNS only** — no Cloudflare proxy. This is correct for mail and
Microsoft service records which must resolve directly to Microsoft's infrastructure.

---

## Record Explanations

**MX Record** — tells the internet where to deliver email for this domain. Priority 0 means
this is the primary and only mail server. Once live, all inbound email goes to Exchange Online.

**SPF Record** — specifies which mail servers are authorised to send email from this domain.
The `-all` means any server not listed should be treated as unauthorised, preventing other
servers from impersonating the domain to send spam.

**Autodiscover CNAME** — allows Outlook and other email clients to automatically discover
the correct Exchange Online server settings when a user enters their email address. Without
this, users must configure server settings manually.

**Enterpriseregistration CNAME** — enables Windows devices to automatically find and register
with Intune when a user signs in with their work account.

**Enterpriseenrollment CNAME** — works alongside enterpriseregistration to complete the Intune
enrolment process. Both CNAMEs are required for the full enrolment experience.

---

## DKIM — Additional Step Required

DKIM is not added automatically by the Domain Connect process. It must be enabled separately
in the Exchange Admin Center after the domain is verified.

DKIM adds a digital signature to outbound emails, allowing receiving servers to verify they
genuinely came from this domain. Without DKIM, email from `@qcbhomelab.online` is more likely
to be treated as spam by recipients.

```
Exchange Admin Center → Email authentication → DKIM →
qcbhomelab.online → Enable
```

Microsoft generates two CNAME records to add to Cloudflare DNS. Once added and propagated,
DKIM signing is active.

---

## DMARC — Recommended Addition

DMARC builds on SPF and DKIM to tell receiving mail servers what to do with emails that fail
authentication checks. It must be added manually.

Recommended starting record:

| Type | Host | Value |
|---|---|---|
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc@qcbhomelab.online` |

`p=none` means no action is taken on failing emails initially — this allows monitoring
before enforcement. Once confident that legitimate email is passing SPF and DKIM, the
policy can be changed to `p=quarantine` or `p=reject`.

> DMARC is increasingly treated as a baseline requirement by receiving mail providers.
> Domains without DMARC are at higher risk of being treated as spam sources.

---

## Verification

Once all records are in place, verify via PowerShell:

```powershell
# Verify MX record
Resolve-DnsName -Name "qcbhomelab.online" -Type MX

# Verify SPF record
Resolve-DnsName -Name "qcbhomelab.online" -Type TXT

# Verify Autodiscover
Resolve-DnsName -Name "autodiscover.qcbhomelab.online" -Type CNAME
```

All three should return values pointing to Microsoft's infrastructure.

---

*For the email migration process see [02 — Email Migration](../docs/02-email-migration.md).*
