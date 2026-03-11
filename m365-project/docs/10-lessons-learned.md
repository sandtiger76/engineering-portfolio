# 10 — Lessons Learned

## In Plain English

This is an honest reflection on the project. What worked well, what would be done differently, where the lab diverges from a real client engagement, and what the business should address next. No project is perfect, and a consultant who cannot reflect critically on their own work is not someone a client should trust with the next one.

---

## What Went Well

### The Lab Environment Was Realistic Enough to Matter

Building a purpose-built Active Directory with 15 fictional users, a proper OU structure, SMB file shares with NTFS permission matrices, and a registered public domain made this a genuine migration rather than a theoretical exercise. The decisions made — UPN suffix alignment, domain verification sequence, SPMT pre-scan before live migration — are exactly the decisions that need to be made on a real engagement. The lab forced those decisions rather than allowing them to be skipped.

### Sequencing the Workstreams Correctly

The order of workstreams matters enormously in a migration of this type, and getting it right was one of the more valuable outcomes of this project. Identity had to come before everything else — you cannot assign licences without verified users, cannot configure Conditional Access without licences, cannot migrate files without provisioned OneDrive accounts. Running workstreams 01a through 01e before anything else was the correct call and avoided a class of dependency failures that cause real-world migrations to stall.

### Documenting Decisions, Not Just Steps

The most useful thing a migration document can contain is not a list of steps — it is the reasoning behind the decisions. Why IMAP migration happens before MX cutover. Why NTFS permissions are recreated rather than migrated. Why Files On-Demand must be configured before the sync client runs. This project attempted to capture that reasoning at every step, which makes the documentation genuinely transferable to a real engagement rather than just a lab record.

### Cloudflare as the DNS Layer

Using Cloudflare for external DNS and Domain Connect for the Microsoft 365 DNS records made the domain verification and record management significantly cleaner than it would have been with a less capable DNS provider. The CNAME-based DKIM records, Intune enrolment CNAMEs, and DMARC record were all added in a single interface with fast propagation. On a real engagement, this choice would save meaningful time.

---

## What Would Be Done Differently

### Autopilot Should Have Been Implemented, Not Just Documented

The correct production approach to device enrolment is Windows Autopilot. The lab used manual Azure AD Join because Autopilot requires hardware hash registration, which requires either physical devices with a vendor relationship or specific lab tooling. Documenting Autopilot as the production method is honest, but a stronger portfolio piece would include a working Autopilot deployment — even using a custom hardware hash extracted from a VM. This is a gap to close in a future iteration of the lab.

### DMARC Should Have Been Tightened During the Project

The DMARC record was set to `p=none` at the start of the project and left there throughout. The honest reason is that `p=none` is safe — it never breaks mail flow — and the migration was complex enough without adding DMARC enforcement as an active variable. On a real engagement, a 30-day DMARC monitoring period followed by a move to `p=quarantine` would be scheduled as part of the project timeline, not left as an outstanding action. This project did not do that.

### The Backup Gap Was Left Open

Third-party backup was identified as the most significant remaining risk in workstream 08 and documented clearly. But it was not implemented. In a real engagement, leaving a client without backup of their Microsoft 365 data would be a significant consulting failure — the backup solution should be deployed and validated before the on-premises server is decommissioned. In this lab, the constraint is cost (backup solutions are not free), but the lesson is clear: backup is not optional, and it should be scoped into the project from the discovery phase.

### Defender for Business Was Not Configured

Microsoft 365 Business Premium includes Microsoft Defender for Business — an endpoint detection and response (EDR) platform. It was not configured in this project. The focus on identity, migration, and compliance was appropriate for a first project, but a complete security deployment would include Defender for Business policy configuration: attack surface reduction rules, next-generation antivirus settings, and endpoint detection. This is a natural extension of the Intune workstream.

---

## Lab vs Production Differences

This section explicitly documents where the lab environment diverges from what a real engagement would look like. These differences are important — a portfolio reviewer should understand what the lab demonstrates and what it does not.

| Area | Lab Approach | Production Approach |
|---|---|---|
| User provisioning | Manual creation or Entra Connect sync from test AD | Entra Connect sync from existing production AD |
| Device enrolment | Manual Azure AD Join | Windows Autopilot with hardware hash registration |
| IMAP migration | Simulated credentials (no real mail) | Real IMAP credentials from client; test migration before live |
| SPMT migration | Files purpose-built for the lab | Real client files — may include invalid characters, locked files, legacy formats |
| DMARC enforcement | p=none throughout | p=none → p=quarantine → p=reject on a monitored schedule |
| Backup | Not implemented | Third-party solution deployed before DC decommission |
| Defender for Business | Not configured | Fully configured — ASR rules, AV policy, EDR |
| Conditional Access | Baseline policies | Additional policies for role-based access, location-based restrictions, session controls |
| Licensing | 25-seat trial | Purchased licences — procurement and assignment should follow a formal process |
| Change management | Not applicable (fictional users) | User training, communication plan, helpdesk readiness, phased rollout |
| Rollback plan | Documented conceptually | Formally tested before cutover — especially MX and SPMT |

---

## Known Gaps in This Documentation

Transparency requires listing the things that are known to be incomplete or imperfect in this project:

**Screenshots are placeholders in several workstreams.** The lab was built on a real Proxmox environment, but not every step was captured with a screenshot at the time of execution. Some screenshots are marked as pending. On a real engagement, screenshots are taken at the time of execution — going back to recreate them later introduces risk of inaccuracy.

**Group Policy settings were documented but not fully migrated to Intune.** The GPO-to-Intune mapping table in workstream 07 is accurate, but not every GPO setting from the lab DC was replicated in Intune configuration profiles. A complete implementation would audit every applied GPO and create equivalent Intune profiles for each one.

**Teams adoption guidance is advisory, not tested.** The user communication and adoption section in workstream 06 is based on consulting best practice, not a tested rollout with real users. In a production engagement, adoption is typically the hardest part of a Teams deployment — more than the technical configuration.

**No phased rollout was implemented.** This project migrated all 15 users simultaneously across all workstreams. A real engagement with 15 users would likely still phase the migration — pilot group first, then wave 1, then wave 2 — to identify problems before they affect everyone. The documentation notes this but does not demonstrate it.

---

## Future Recommendations for QCB Homelab Consultants

The following recommendations would form the basis of a future engagement with the fictional client. They are listed in priority order.

**Immediate (within 30 days of project completion):**

- Deploy a third-party backup solution for Microsoft 365 (Exchange, SharePoint, OneDrive)
- Tighten DMARC from `p=none` to `p=quarantine`
- Enable Safe Links and Safe Attachments in the Defender portal

**Short-term (30–90 days):**

- Configure Microsoft Defender for Business — attack surface reduction, AV policy, EDR
- Implement a formal Windows Update for Business policy via Intune (patch management)
- Configure Microsoft Purview compliance — litigation hold for key mailboxes, retention policies

**Medium-term (90 days+):**

- Implement Autopilot for new device provisioning
- Tighten DMARC to `p=reject`
- Evaluate Microsoft Purview sensitivity labels for document classification
- Review and implement Data Loss Prevention (DLP) policies for client data
- Consider Privileged Identity Management (PIM) for just-in-time admin access

---

## Reflection on the Project as a Portfolio Piece

This project was designed to demonstrate three things simultaneously: technical depth, consulting process, and documentation quality. Whether it achieves all three is for the reader to judge, but the intent was to produce something that reflects genuine consulting practice — not a tutorial, not a lab writeup, but a record of decisions made and justified.

The most honest thing to say about any migration project is that the difficult parts are never the technical steps — they are the decisions made under uncertainty, the dependencies that only become visible mid-project, and the client conversations about risk. A lab cannot fully replicate those pressures. What it can do is demonstrate that the engineer has thought about them.

The gaps documented in this page are as important as the work completed. A consultant who knows what they do not know, and says so clearly, is more valuable than one who presents a polished surface over an incomplete understanding.

---

## Summary

This project migrated a fictional 15-person IT consultancy from an on-premises Windows Server environment to Microsoft 365 Business Premium. The following was delivered:

- Entra ID identity platform with 15 users, MFA, and Conditional Access
- Exchange Online with IMAP migration, DKIM, EOP, and DMARC
- SharePoint Online with four document libraries migrated from SMB
- OneDrive for Business with 15 personal drives migrated from H: drives
- Microsoft Teams with department structure and SharePoint integration
- Intune device management with compliance policies replacing Group Policy and VPN
- Formal decommission of QCBHC-DC01 with pre-decommission checklist and client sign-off

The remaining gaps — backup, DMARC enforcement, Defender for Business, Autopilot — are documented honestly and prioritised for a future engagement.

The project is complete.
