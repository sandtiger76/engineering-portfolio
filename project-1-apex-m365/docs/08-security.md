# 08 — Security Consolidation

## In Plain English

Security is not a single step at the end of a migration — it is woven through every decision made in this project. This page brings together all of the security controls implemented across the workstreams and presents them as a coherent picture. It also calls out the one significant gap that Microsoft 365 does not close on its own: there is no built-in backup, and this must be addressed by the business.

## Why This Matters

At the start of this engagement, QCB Homelab Consultants had no MFA, no device management, no email authentication, no centralised security policy, and files stored on an on-premises server with no offsite copy. The completed migration addresses all of these. Documenting the security posture in one place gives the client a clear view of what protection they now have, what the remaining gaps are, and what the recommended next steps are.

## Prerequisites

All workstreams must be substantially complete before this page is written. The security posture described here is cumulative — it draws on decisions made in every preceding workstream.

---

## Zero Trust Design: What It Means in Practice

"Zero Trust" is often treated as a marketing term. In this deployment, it has a specific meaning: **no implicit trust based on network location**. Every access request is evaluated against explicit conditions regardless of whether the user is in the office, at home, or on a client site.

The three pillars of the Zero Trust model as implemented here:

### 1. Identity Verification (Workstream 01f)

Every user must authenticate with MFA before accessing Microsoft 365 resources. Conditional Access policies enforce this on every sign-in from an unmanaged or non-compliant device. There is no "trusted network" from which MFA is bypassed.

### 2. Device Compliance (Workstream 07)

Conditional Access requires that the device used to access company resources is enrolled in Intune and meets the compliance policy (BitLocker, screen lock, current OS, firewall). A stolen device with valid credentials but no Intune enrolment cannot access Microsoft 365.

### 3. Least-Privilege Access (Workstreams 01d, 03, 04)

SharePoint document library permissions are set at the library level using security groups, not individual user assignments. Users have access only to the libraries their department requires. The administration library is not accessible to general staff. The break-glass admin account has no licence and is excluded from Conditional Access — it exists only for emergency access.

### Zero Trust Control Summary

| Control | Implementation | Workstream |
|---|---|---|
| MFA required | Conditional Access policy — all users | 01f |
| Device compliance required | Conditional Access policy — compliant device condition | 07 |
| Device encryption | Intune compliance policy — BitLocker required | 07 |
| Privileged account separation | Break-glass (onmicrosoft.com) + working admin (licensed) | 01e |
| Least-privilege file access | SharePoint library permissions via Entra ID groups | 03 |
| Personal file isolation | OneDrive per-user — no cross-user access | 04 |
| Guest access blocked | Teams guest access disabled at tenant level | 06 |
| External sharing blocked | SharePoint external sharing disabled (documented below) | 08 |

---

## Conditional Access Policies

The following Conditional Access policies are in place, created in workstream 01f:

| Policy Name | Condition | Action |
|---|---|---|
| Require MFA — All Users | All users, all cloud apps | Require MFA |
| Require Compliant Device | All users, Microsoft 365 apps | Require compliant or Entra-joined device |
| Block Legacy Authentication | Any legacy auth protocol | Block access |
| Break-Glass Exclusion | Break-glass account excluded from all policies | Allows emergency access without MFA |

> **Screenshot:** `screenshots/08-security/01_conditional_access_policies.png`
> *Entra ID Conditional Access showing all policies in place*

### Why Blocking Legacy Authentication Matters

Legacy authentication protocols (IMAP, POP3, SMTP AUTH, Basic Auth) do not support MFA. An attacker with a stolen password can authenticate via a legacy protocol and bypass the MFA requirement entirely. Blocking legacy authentication closes this gap. In this deployment, all mail is now Exchange Online — no client needs legacy authentication.

---

## Exchange Online Protection (EOP)

EOP is active for all Exchange Online mailboxes by default. No additional configuration is required to enable it. The following summarises what is active and what additional configuration is recommended.

### EOP: Default vs Recommended Configuration

| Capability | Default State | Recommended State |
|---|---|---|
| Anti-spam (inbound) | Active — standard policy | Active — no change needed for SMB |
| Anti-malware | Active — common attachments blocked | Enable enhanced filtering |
| Anti-phishing | Active — basic | Enable impersonation protection for admins |
| Safe Links | **Not active** — requires Defender for Office 365 Plan 1 | Enable for email and Office apps |
| Safe Attachments | **Not active** — requires Defender for Office 365 Plan 1 | Enable in Dynamic Delivery mode |
| Outbound spam protection | Active | Active — no change needed |
| Quarantine | Active | Review quarantine weekly |
| DKIM | Enabled (workstream 02) | Active |
| DMARC | p=none (monitoring) | Tighten to p=quarantine after 30 days |
| SPF | Active (workstream 00) | Active |

> **Note:** Safe Links and Safe Attachments are available within Microsoft 365 Business Premium via Microsoft Defender for Office 365 Plan 1. They are not enabled by default — they must be explicitly configured in the Microsoft Defender portal.

> **Screenshot:** `screenshots/08-security/02_eop_policies_overview.png`
> *Microsoft Defender portal showing EOP policy configuration*

### DMARC Tightening Roadmap

The DMARC record was set to `p=none` at the start of the project (monitoring only). The recommended progression:

| Phase | DMARC Policy | When |
|---|---|---|
| Initial (current) | `p=none` | During migration |
| Post-migration | `p=quarantine` | 30 days after MX cutover — once mail flow is confirmed clean |
| Mature | `p=reject` | 90 days post-migration — after quarantine phase confirms no false positives |

The DMARC record is managed in Cloudflare DNS. Updating from `p=none` to `p=quarantine` requires editing the existing TXT record.

---

## SharePoint External Sharing

### SharePoint External Sharing: Disabled at Tenant Level

SharePoint's default configuration allows authenticated external users to be invited to share documents and sites. For QCB Homelab Consultants — a consultancy handling confidential client data — this is unacceptable. External sharing is disabled at the tenant level.

**Configuration:**
1. Navigate to **SharePoint Admin Center** → **Policies** → **Sharing**
2. Set the external sharing level to **Only people in your organisation**
3. Apply the same setting to OneDrive

> **Screenshot:** `screenshots/08-security/03_sharepoint_sharing_disabled.png`
> *SharePoint Admin Center showing external sharing set to Only people in your organisation*

This setting means:

- No document or library can be shared with an external email address
- "Share" links that work for anyone or specific external guests are blocked
- Existing sharing links are revoked

> **Note for real engagements:** Some clients need to share documents with external parties (contractors, clients, auditors). If this is a requirement, the recommended approach is to enable external sharing for specific sites only (not the whole tenant), require external users to authenticate (not anonymous links), and apply expiration dates to all external shares.

---

## The Backup Gap

### Microsoft 365 Has No Built-In Backup

This is the most important thing to communicate to any Microsoft 365 client, and it is frequently misunderstood.

Microsoft 365 provides **resilience** — the service is replicated across datacentres, protected against infrastructure failure, and guaranteed to be available via SLA. It does **not** provide **backup** in the way most organisations understand the term.

Specifically:

| Scenario | Microsoft 365 Response | Backup Needed? |
|---|---|---|
| Microsoft datacentre failure | Automatic failover — no data loss | No |
| User accidentally deletes a file | 93-day recycle bin — recoverable | Usually no |
| Admin accidentally deletes a site | 93-day site collection recycle bin | Usually no |
| Ransomware encrypts OneDrive files | Version history — may allow recovery | **Yes — version history has limits** |
| Malicious insider deletes content and empties recycle bin | No recovery | **Yes** |
| Exchange litigation hold not configured — email deleted | No recovery after 30 days | **Yes** |
| Microsoft account terminated (billing failure) | 90-day grace period, then data deleted | **Yes** |

### Recommended Third-Party Backup Solutions

| Solution | Notes |
|---|---|
| Veeam Backup for Microsoft 365 | Market-leading — backs up Exchange, SharePoint, OneDrive, Teams |
| Acronis Cyber Protect | Strong SMB option with endpoint protection included |
| Dropsuite | SaaS backup purpose-built for Microsoft 365 — low admin overhead |
| AvePoint Cloud Backup | Enterprise-grade — may be more than QCB needs |

**Minimum recommended configuration for QCB Homelab Consultants:**

- Daily backup of Exchange Online mailboxes (all 15 users)
- Daily backup of SharePoint document libraries
- Daily backup of OneDrive for Business (all 15 users)
- Retention: 1 year minimum
- Offsite storage: backup vendor's cloud — not the same tenant being backed up

> **Screenshot:** `screenshots/08-security/04_backup_gap_diagram.png`
> *Diagram illustrating what Microsoft 365 resilience covers vs what requires third-party backup*

---

## Security Posture Summary

### What Has Been Achieved

| Area | Before | After |
|---|---|---|
| Authentication | Password only | MFA required via Conditional Access |
| Device management | None | Intune — BitLocker, screen lock, OS compliance |
| Email authentication | No DKIM or DMARC | DKIM enabled, DMARC monitoring |
| Email threat filtering | Provider-dependent | Exchange Online Protection (default + recommended) |
| File access control | NTFS on domain-joined machines | SharePoint permissions via Entra ID groups |
| Remote access | Third-party VPN | Conditional Access — no VPN required |
| Admin account security | Single admin account | Break-glass separated, working admin licensed only |
| Guest / external access | Unknown | Disabled at tenant level |
| Device encryption | Not enforced | BitLocker required via Intune compliance policy |

### What Remains to Address

| Gap | Recommended Action | Priority |
|---|---|---|
| No third-party backup | Deploy Veeam or equivalent | **High** |
| DMARC at p=none | Tighten to p=quarantine after 30 days | **High** |
| Safe Links / Safe Attachments not configured | Enable via Defender portal | **High** |
| Defender for Business not configured | Deploy endpoint protection (included in Business Premium) | **Medium** |
| No DLP policies | Configure Data Loss Prevention for sensitive data types | **Medium** |
| No sensitivity labels | Configure Microsoft Purview sensitivity labels | **Low — future state** |

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Conditional Access policies active | Entra ID → Conditional Access | All four policies enabled |
| MFA enforced | Sign in as test user from new device | MFA prompt appears |
| Legacy auth blocked | Attempt IMAP connection to Exchange | Connection refused |
| DKIM active | PowerShell — Get-DkimSigningConfig | Status: Valid |
| DMARC record correct | MXToolbox DMARC lookup | p=none (monitoring) |
| SharePoint external sharing off | SharePoint Admin Center → Sharing | Only people in your organisation |
| EOP active | Send test email with EICAR test attachment | Attachment blocked by EOP |
| Intune compliance active | Intune → Compliance — check device | Compliant / Not compliant with reasons |

---

## Summary

This workstream documents the security posture of the completed QCB Homelab Consultants Microsoft 365 deployment. The key outcomes are:

- **Zero Trust** model implemented — MFA, device compliance, and least-privilege access enforced across all access paths
- **Exchange Online Protection** active — anti-spam, anti-malware, and spoofing protection enabled by default with DKIM and DMARC in place
- **SharePoint external sharing** disabled — no accidental exposure of client-confidential documents
- **Backup gap** explicitly documented — this is the most significant remaining risk and must be addressed before the decommission of on-premises infrastructure is considered complete

**What this enables next:**

- The decommission checklist (workstream 09) can be completed with confidence that all security controls are in place
- DMARC can be tightened to p=quarantine 30 days after go-live
- Safe Links, Safe Attachments, and Defender for Business configuration provide the next layer of protection
