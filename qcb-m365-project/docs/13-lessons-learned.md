# 13 — Lessons Learned

## In Plain English

Every project teaches something. The most valuable lessons are often not the technical ones — they are the decisions made under uncertainty, the dependencies that only became visible mid-project, and the gaps that were honest enough to document rather than hide.

This document reflects on the QCB Homelab Consultants deployment. What worked well. What would be done differently. Where this lab diverges from a real production engagement. And what an honest consultant would recommend as the next steps.

A project document that presents only what went well is not trustworthy. This one attempts to be honest.

---

## What This Project Is (And What It Is Not)

This project is a complete, working Microsoft 365 Business Premium deployment built in a real tenant with real physical devices. Every setting was applied, every policy was tested, and every step was documented as it was implemented.

It is not a production deployment for a real organisation. The users are fictional, the company is fictional, and some constraints that exist in production — change management, user training, rollback procedures, procurement of third-party backup — are documented as gaps rather than implemented.

The distinction matters. A lab is valuable because it forces real decisions. A lab is limited because it removes the human complexity of a real engagement. This document tries to be clear about both.

---

## What Went Well

### The Sequencing Was Correct

The most important architectural decision in a Microsoft 365 deployment is sequencing. Identity before everything — you cannot assign licences without users, cannot enforce Conditional Access without licences, cannot enrol devices without identity. Getting this sequence right at the planning stage prevented a class of dependency failures that derail real projects.

### Conditional Access Over Security Defaults

Choosing Conditional Access over Security Defaults from the start was the right call. Security Defaults would have been simpler to configure, but they cannot target specific groups, cannot accommodate the break-glass account exclusion, and cannot combine MFA with device compliance requirements. The additional complexity of Conditional Access was justified from the first policy.

### MAM Without Enrolment for the Personal Device

The decision to use MAM without enrolment for Casey Quinn's personal iPhone, rather than full MDM, was technically and ethically correct. Full MDM on a personal device is an overreach — it grants remote wipe capability over someone's personal property. MAM protects corporate data without this intrusion. This distinction is commonly misunderstood, and demonstrating it clearly is one of the more valuable aspects of this project.

### Decision Documentation

The most useful thing in any technical document is not the list of steps — it is the reasoning behind the decisions. Why was Cloud Sync chosen over Connect Sync in the previous version of this project? Why is DMARC at `p=quarantine` rather than `p=reject`? Why are ASR rules in audit mode before block mode in production? Every significant decision in this project was documented with reasoning, not just a value.

### Closing the Gaps From the Previous Version

The previous iteration of this project identified three gaps at close: Defender for Business not configured, Safe Links and Safe Attachments not enabled, and DMARC not tightened beyond `p=none`. All three were addressed in this version. Documenting gaps explicitly at project close creates accountability — a list of what was promised to be fixed next time.

---

## What Would Be Done Differently

### Autopilot Should Be Implemented, Not Just Documented

The production standard for device enrolment is Windows Autopilot. In this project, the Windows laptop was enrolled via manual Entra ID join — the correct lab approach, but not what would happen in a real deployment. A future iteration of this project should implement Autopilot using a hardware hash extracted from the lab device, demonstrating the full zero-touch provisioning experience.

### DMARC Monitoring Before Moving to p=quarantine

In this project, DMARC was set directly to `p=quarantine`. The more rigorous approach is to start at `p=none` for 30 days, review the aggregate reports sent to the `rua` address, confirm that no legitimate email is failing authentication, and then move to `p=quarantine`. This project skipped the monitoring phase — acceptable for a lab, not acceptable in production.

### Third-Party Backup Was Not Implemented

Third-party backup remains the most significant unaddressed risk in this deployment. Microsoft 365's resilience model (geo-redundant infrastructure, 99.9% SLA) is not the same as backup. The 93-day recycle bin and version history cover accidental deletion, but not a determined insider, not a ransomware event that outpaces version history, and not a billing failure that terminates the account. This gap is documented in workstream 11 with recommended solutions — but it is documented, not closed.

---

## Lab vs Production Differences

This table documents explicitly where the lab diverges from a real engagement. These differences are important — a reader of this project should understand what it demonstrates and what it does not.

| Area | Lab Approach | Production Approach |
|---|---|---|
| User provisioning | Manual creation in Entra ID | Entra Cloud Sync from existing AD (if hybrid), or managed creation process with HR system integration |
| Device enrolment | Manual Entra join | Windows Autopilot with hardware hash registration |
| DMARC | Set directly to p=quarantine | 30-day monitoring at p=none before moving to p=quarantine |
| ASR rules | Block mode from day 1 | Audit mode for 2–4 weeks to catch false positives, then block |
| Backup | Not implemented | Third-party solution deployed before go-live |
| Change management | Not applicable (fictional users) | User communication, training plan, phased rollout, helpdesk readiness |
| Rollback plan | Documented conceptually | Formally tested for critical changes — especially MX cutover and Conditional Access |
| Autopilot | Documented as production standard | Implemented — devices provisioned via Autopilot from vendor |
| PIM | Not available (Business Premium) | Entra ID P2 or E5 licence — admin roles activated just-in-time |
| DMARC tightening | p=quarantine | p=reject after monitoring period confirms no false positives |

---

## Known Gaps — Prioritised

| Gap | Recommended Action | Priority |
|---|---|---|
| No third-party backup | Deploy Veeam Backup for Microsoft 365 or equivalent | High |
| DMARC at p=quarantine, not p=reject | Review DMARC reports after 30 days, tighten to p=reject | Medium |
| No PIM for admin accounts | Evaluate Entra ID P2 add-on — just-in-time admin activation | Medium |
| Autopilot not implemented | Implement for next device using hardware hash extraction | Low |
| No formal change management process | Document a lightweight change approval process | Low |

---

## What This Project Demonstrates

This project was designed to demonstrate three things simultaneously: technical depth, professional process, and documentation quality.

**Technical depth:** Every major Microsoft 365 security and productivity workload was configured — identity, email, file storage, communication, device management, endpoint security, email security, and access governance. Not as a checklist, but with understanding of how they work together.

**Professional process:** The project followed a deliberate sequence — identity before licensing, licensing before Conditional Access, device compliance before enforcing CA-04. Decisions were made explicitly, documented with reasoning, and tested before moving on.

**Documentation quality:** Every workstream explains the technology in plain English before explaining how to configure it. Every decision explains the why, not just the what. Known gaps are documented honestly with remediation steps. The documentation is written to be followed by someone who was not there — which is the standard every technical document should be held to.

The gaps documented in this page are as important as the work completed. A consultant who knows what they do not know, and says so clearly, is more valuable than one who presents a polished surface over an incomplete understanding.

---

## Summary

This project deployed Microsoft 365 Business Premium for a fictional five-person multi-sector consultancy. The following was delivered:

- **Identity platform** — Entra ID with admin separation, 5 cloud-native users, 6 security groups, Conditional Access framework
- **Email** — Exchange Online with DKIM, SPF, DMARC (p=quarantine), shared mailbox, distribution group, transport rules
- **File storage and collaboration** — SharePoint, OneDrive, Teams with department structure and SharePoint integration
- **Device management** — Intune compliance policy, security baseline, update rings, Windows laptop enrolled and compliant
- **Personal device protection** — iOS MAM without enrolment for field worker BYOD
- **Endpoint security** — Defender for Business with EDR, ASR rules, threat dashboard
- **Email security** — Safe Links, Safe Attachments, anti-phishing with executive impersonation protection
- **Access governance** — access reviews, audit logging, sign-in log monitoring

The remaining gaps — third-party backup, DMARC enforcement, PIM, Autopilot — are documented honestly and prioritised for a future engagement.

The project is complete. QCB Homelab Consultants operates on a Zero Trust security model, entirely from the cloud, with no on-premises infrastructure and no VPN dependency.
