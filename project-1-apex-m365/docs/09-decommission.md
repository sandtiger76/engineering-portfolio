# 09 — Decommission

## In Plain English

Everything that QCBHC-DC01 used to provide — user authentication, file storage, DNS, DHCP, email routing, remote access — has been moved to Microsoft 365. This workstream documents the formal process for powering off the server: the checks that must pass first, the order in which services are shut down, the DNS cleanup required, the third-party subscriptions to cancel, and the sign-off document that confirms the migration is complete.

## Why This Matters

Decommissioning a domain controller is not just a matter of switching something off. If it is done in the wrong order, or before all dependencies are confirmed as migrated, it can break authentication, DNS resolution, or access to resources that are still pointing at the old server. The decommission is the final proof that the migration is complete — and the document that a client signs at the end of the engagement.

## Prerequisites

All of the following workstreams must be completed and validated before decommission begins:

| Workstream | Validation Required |
|---|---|
| 01a/01b — Identity | All 15 users authenticated via Entra ID |
| 02 — Email | All mailboxes active in Exchange Online; MX confirmed pointing to Exchange |
| 03 — File shares | SharePoint migration complete; SPMT report clean |
| 04 — OneDrive | All H: drives migrated; users accessing OneDrive |
| 06 — Teams | Teams operational; SharePoint libraries connected |
| 07 — Intune | All devices enrolled and compliant |
| 08 — Security | All security controls validated |

---

## Pre-Decommission Checklist

This checklist must be completed in full before any services are stopped on QCBHC-DC01. Each item should be tested and signed off.

### Identity and Authentication

| Check | Method | Result |
|---|---|---|
| All 15 users can sign in via Entra ID | Sign in as each user at portal.office.com | ✅ Pass / ❌ Fail |
| MFA is enforced for all users | Sign in from new device — MFA prompt appears | ✅ Pass / ❌ Fail |
| No user is still dependent on NTLM/Kerberos for any resource | Review Entra ID sign-in logs — no on-prem auth errors | ✅ Pass / ❌ Fail |
| Break-glass account accessible without DC | Sign in to break-glass account with DC offline | ✅ Pass / ❌ Fail |

### Email

| Check | Method | Result |
|---|---|---|
| MX record confirmed pointing to Exchange Online | MXToolbox MX lookup for qcbhomelab.online | ✅ Pass / ❌ Fail |
| All users receiving email in Exchange Online | Send test email to each address | ✅ Pass / ❌ Fail |
| IMAP migration batch completed | Exchange Admin Center → Migration → Status: Completed | ✅ Pass / ❌ Fail |
| DKIM active and valid | Get-DkimSigningConfig PowerShell | ✅ Pass / ❌ Fail |
| Old IMAP accounts no longer receiving mail | Send test to old IMAP address — no delivery | ✅ Pass / ❌ Fail |

### File Storage

| Check | Method | Result |
|---|---|---|
| SharePoint libraries contain all migrated content | File count comparison: source vs destination | ✅ Pass / ❌ Fail |
| Sample files open correctly from SharePoint | Open 5 files per library from web | ✅ Pass / ❌ Fail |
| All OneDrive accounts populated | Browse 3+ user OneDrives via admin | ✅ Pass / ❌ Fail |
| Users can access files without VPN | Test from external network — no VPN | ✅ Pass / ❌ Fail |

### Devices and Intune

| Check | Method | Result |
|---|---|---|
| All devices enrolled in Intune | Intune → All devices — 15 devices listed | ✅ Pass / ❌ Fail |
| All devices compliant | Intune → Compliance — all show Compliant | ✅ Pass / ❌ Fail |
| Conditional Access enforcing compliance | Attempt access from non-compliant device — blocked | ✅ Pass / ❌ Fail |

### DHCP

| Check | Method | Result |
|---|---|---|
| DHCP moved off QCBHC-DC01 | DHCP service confirmed running on router/alternative | ✅ Pass / ❌ Fail |
| Devices obtaining IP from new DHCP source | ipconfig /all on a test device — DHCP server shows router IP | ✅ Pass / ❌ Fail |

> **Critical:** DHCP must be moved before the DC is powered off. If the DC is also the DHCP server and it is switched off, devices on the network will fail to obtain IP addresses when their leases expire.

---

## Decommission Order

Services must be decommissioned in a specific order to avoid cascading failures.

### Step 1 — Disable DHCP on the DC

1. On QCBHC-DC01: **Server Manager** → **DHCP** → right-click the scope → **Deactivate**
2. Confirm DHCP is now being served by the router or alternative device
3. Allow 24 hours for all device leases to renew from the new source

### Step 2 — Stop Entra Connect Sync

Entra Connect should be stopped cleanly before the DC is powered off. If Entra Connect is running when the DC shuts down, the cloud will show sync errors.

```powershell
# On QCBHC-DC01
Import-Module ADSync

# Disable sync scheduler
Set-ADSyncScheduler -SyncCycleEnabled $false

# Verify sync is stopped
Get-ADSyncScheduler
```

> **Screenshot:** `screenshots/09-decommission/01_entra_connect_sync_stopped.png`
> *PowerShell output confirming ADSync scheduler disabled*

### Step 3 — Demote the Domain Controller

Demoting the DC before decommissioning removes it cleanly from Active Directory and removes the FSMO roles. This is best practice even if the domain itself is being abandoned.

```powershell
# Demote the DC — removes AD DS role
Uninstall-ADDSDomainController -DemoteOperationMasterRole -LastDomainControllerInDomain -RemoveApplicationPartitions -Force
```

> **Note:** In this lab scenario, the domain (apex.local) is being entirely abandoned — all users are now in Entra ID. Demoting is the clean way to do this. If there were remaining domain-joined machines, they would need to be unjoined first.

> **Screenshot:** `screenshots/09-decommission/02_dc_demoted.png`
> *Server Manager showing AD DS role removed after demotion*

### Step 4 — Stop SMB File Shares

1. On QCBHC-DC01: **Server Manager** → **File and Storage Services** → **Shares**
2. Confirm no active sessions (if sessions exist, notify users)
3. Remove the share configuration: right-click each share → **Stop sharing**

> **Screenshot:** `screenshots/09-decommission/03_smb_shares_stopped.png`
> *Server Manager showing SMB shares removed*

### Step 5 — Power Off QCBHC-DC01

Once all above steps are confirmed:

1. Notify all staff that the server is being powered off
2. In Proxmox: right-click the VM → **Stop** (graceful shutdown preferred: **Shutdown** first)
3. Wait for confirmation the VM has stopped cleanly

> **Screenshot:** `screenshots/09-decommission/04_vm_powered_off.png`
> *Proxmox interface showing QCBHC-DC01 VM in stopped state*

### Step 6 — Post-Shutdown Validation

After the VM is off, run the following checks:

| Check | Method | Expected Result |
|---|---|---|
| Microsoft 365 sign-in still works | Sign in at portal.office.com | ✅ Successful — cloud auth is independent of DC |
| SharePoint accessible | Open SharePoint from browser | ✅ Content accessible |
| OneDrive sync active | Check sync client on enrolled device | ✅ Syncing normally |
| Email receiving | Send test email | ✅ Arrives in Exchange Online |
| Teams operational | Start Teams call | ✅ Call connects |

---

## DNS Cleanup

### Internal DNS (apex.local)

The internal DNS zone (`apex.local`) was hosted on QCBHC-DC01. With the DC demoted and powered off, this internal DNS no longer exists. This is intentional — all resources are now in the cloud and resolve via public DNS (Cloudflare).

No cleanup is required for internal DNS; it ceases to exist when the DC is powered off.

### External DNS (Cloudflare)

The Cloudflare DNS records added during this project should be reviewed. Records that are no longer needed:

| Record | Status | Action |
|---|---|---|
| `enterpriseenrollment.qcbhomelab.online` CNAME | Keep | Required for Intune enrolment |
| `enterpriseregistration.qcbhomelab.online` CNAME | Keep | Required for device registration |
| `selector1._domainkey` CNAME | Keep | Required for DKIM |
| `selector2._domainkey` CNAME | Keep | Required for DKIM |
| MX record (Exchange Online) | Keep | Required for email |
| SPF TXT record | Keep | Required for email authentication |
| DMARC TXT record | Keep | Required for DMARC |
| Any A records pointing to QCBHC-DC01 IP | **Remove** | Server no longer exists |
| Any CNAME records pointing to internal hostname | **Remove** | Internal DNS no longer exists |

> **Screenshot:** `screenshots/09-decommission/05_cloudflare_dns_clean.png`
> *Cloudflare DNS showing only the required records — no legacy entries*

---

## Third-Party Service Cancellations

| Service | Action | When |
|---|---|---|
| Third-party IMAP email hosting | Cancel subscription | After IMAP migration batch confirmed complete |
| Third-party VPN | Cancel subscription | After all devices enrolled in Intune and Conditional Access confirmed |
| Third-party video conferencing | Cancel subscription | After Teams operational and staff confirmed using it |
| Any domain registrar (not Namecheap) | Review — consolidate if possible | After DNS migration confirmed stable |

> **Note:** Do not cancel IMAP hosting until the migration batch status shows **Completed** and you have confirmed that staff are receiving email only in Exchange Online. Cancelling too early risks losing email in transit.

---

## Client Sign-Off Document

The following is a fictional sign-off document for QCB Homelab Consultants. In a real engagement, this would be signed by the client before the project is closed.

---

**Migration Completion Sign-Off**
**Project:** Microsoft 365 Business Premium Migration
**Client:** QCB Homelab Consultants (fictional)
**Completed by:** [Consultant Name]
**Date:** [Date]

---

**Scope of Work Completed**

The following migration activities have been completed and validated:

- ✅ Microsoft 365 Business Premium tenant configured with verified domain `qcbhomelab.online`
- ✅ 15 user accounts provisioned and licensed in Entra ID
- ✅ Multi-factor authentication enforced via Conditional Access for all users
- ✅ Email migrated from third-party IMAP to Exchange Online — DKIM and DMARC configured
- ✅ Company file share migrated from `\\QCBHC-DC01\Company` to SharePoint Online
- ✅ Personal H: drives migrated from `\\QCBHC-DC01\Home` to OneDrive for Business
- ✅ Microsoft Teams deployed and connected to SharePoint document libraries
- ✅ Windows devices enrolled in Intune — BitLocker and screen lock enforced
- ✅ Third-party VPN replaced by Intune Conditional Access
- ✅ QCBHC-DC01 domain controller demoted and powered off

**Outstanding Actions (Client Responsibility)**

- ⬜ Deploy third-party backup solution for Exchange Online, SharePoint, and OneDrive
- ⬜ Tighten DMARC from `p=none` to `p=quarantine` (recommended: 30 days post go-live)
- ⬜ Enable Safe Links and Safe Attachments in Defender portal
- ⬜ Cancel third-party IMAP, VPN, and video conferencing subscriptions

**Client Acknowledgement**

By signing below, the client confirms that the migration is complete, that access to all Microsoft 365 services has been tested and verified, and that the outstanding actions listed above are understood and accepted as client responsibility.

| | |
|---|---|
| **Client Signature:** | _________________________ |
| **Name:** | _________________________ |
| **Role:** | _________________________ |
| **Date:** | _________________________ |

---

> **Screenshot:** `screenshots/09-decommission/06_sign_off_document.png`
> *Completed sign-off document — fictional client engagement close*

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| DHCP moved to router | ipconfig /all on a client device | DHCP server = router IP |
| Entra Connect sync stopped | Get-ADSyncScheduler | SyncCycleEnabled: False |
| DC demoted | Server Manager | AD DS role not listed |
| VM powered off | Proxmox | QCBHC-DC01 status: Stopped |
| Microsoft 365 auth working | Sign in at portal.office.com | Successful — Entra ID auth |
| All services operational | Run post-shutdown validation checklist | All items pass |
| Legacy DNS entries removed | Cloudflare DNS review | No A records for DC IP |

---

## Summary

This workstream completed the formal decommission of QCBHC-DC01:

- **Pre-decommission checklist** completed — all 15 workstream items confirmed before shutdown
- **DHCP** moved from DC to router before shutdown — no IP address disruption
- **Entra Connect** sync stopped cleanly
- **Domain Controller** demoted — AD DS role removed, apex.local domain retired
- **SMB shares** stopped — Company and Home shares removed
- **QCBHC-DC01 VM** powered off in Proxmox
- **Cloudflare DNS** cleaned — legacy A records removed, all required records retained
- **Third-party services** identified for cancellation — IMAP, VPN, video conferencing
- **Client sign-off document** completed — engagement formally closed

**The migration is complete.** QCB Homelab Consultants operates entirely from Microsoft 365 Business Premium — no on-premises hardware, no VPN, no third-party services for communication or file storage.
