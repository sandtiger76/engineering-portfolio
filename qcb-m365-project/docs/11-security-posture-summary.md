# 11 — Security Posture Summary

## In Plain English

Security is not a single thing that gets switched on. It is a collection of overlapping controls — each one addressing a specific risk, each one adding a layer of protection. This workstream brings all of those controls together and presents them as a coherent picture: what the security posture of QCB Homelab Consultants looks like before this project, what it looks like now, what risks have been addressed, and what remains.

For a company operating across three offices with staff also working from home, a security posture that only works in the office is not a security posture — it is an illusion. The controls implemented in this project work consistently regardless of where a user is connecting from. That is the point.

A security summary that only lists what was done well is not useful. This one includes an honest assessment of what remains — and why.

---

## Zero Trust as Implemented

Zero Trust is a security model built on one principle: never trust implicitly, always verify explicitly. No user or device is trusted by default, regardless of whether they are in the Central Office, the North Office, at home, or at a client site. Every access request is evaluated in real time against three questions:

1. **Who are you?** — Identity verified via Entra ID with MFA required
2. **Is your device trustworthy?** — Device compliance checked via Intune
3. **Do you need this access?** — Least-privilege permissions enforced via security groups

### Pillar 1: Identity Verification

| Control | Implementation |
|---|---|
| MFA required | CA-01 — all users, all apps, all locations including offices and home |
| Legacy auth blocked | CA-02 — legacy protocols cannot bypass MFA |
| Executive extra controls | CA-03 — MFA + compliant device always, no named location exceptions |
| Admin accounts separated | Break-glass (onmicrosoft.com) + working admin (licensed) |
| SSPR enabled | Users reset their own passwords without IT intervention |
| Named locations declared | 3 office networks registered — used for context, not MFA exemption |

### Pillar 2: Device Compliance

| Control | Implementation |
|---|---|
| Windows compliance policy | BitLocker, screen lock, OS version, firewall enforced via Intune |
| Security baseline | 150+ hardened settings applied via Intune |
| Compliant device required | CA-04 — M365 apps require compliant device or MAM-protected app |
| iOS MAM without enrolment | Corporate data protected in Outlook and Teams on personal iPhone |
| Endpoint detection | Defender for Business — real-time threat monitoring and EDR |
| Attack surface reduction | 9 ASR rules in block mode — common attack techniques prevented |

### Pillar 3: Least-Privilege Access

| Control | Implementation |
|---|---|
| SharePoint permissions | Library-level permissions via security groups |
| Executive library restricted | Accessible only to GRP-Executives and GRP-Managers |
| External sharing disabled | No SharePoint or OneDrive content shareable outside the organisation |
| Guest access disabled | No external users can be invited to Teams |
| Transport rule | External email forwarding blocked |
| Admin accounts unlicensed | No mailbox, OneDrive, or Teams — minimal footprint |

---

## Multi-Site Security Consistency

One of the most important outcomes of this deployment is that security is consistent regardless of location. This table demonstrates how the same user receives the same protection whether in the office or at home:

| Scenario | MFA Required | Device Compliance Required | Access Granted |
|---|---|---|---|
| Jordan Hayes — North Office, managed laptop | Yes | Yes — laptop is compliant | Yes |
| Jordan Hayes — home network, managed laptop | Yes | Yes — laptop is compliant | Yes |
| Jordan Hayes — coffee shop, managed laptop | Yes | Yes — laptop is compliant | Yes |
| Jordan Hayes — any location, unmanaged device | Yes | Fail — device not compliant | No |
| Casey Quinn — any location, iPhone (MAM) | Yes | MAM policy satisfied | Yes — M365 apps only |
| Alex Carter — Central Office, managed laptop | Yes — always | Yes — always | Yes |
| Alex Carter — Central Office, unmanaged device | Yes | Fail — no exception for office location | No |

The named locations (LOC-CentralOffice, LOC-NorthOffice, LOC-SouthOffice) provide valuable sign-in context and reporting visibility — but they do not bypass any security control. This is a deliberate design decision.

---

## Before and After

| Area | Before | After |
|---|---|---|
| Authentication | Password only | MFA required via Conditional Access — all locations |
| Legacy protocols | Uncontrolled | Blocked via Conditional Access |
| Multi-site awareness | None | 3 named locations declared — sign-in context and reporting |
| Home working security | Unknown | Same policy as office — MFA + compliant device required |
| Device management | None | Intune compliance and configuration policies |
| Device encryption | Unknown | BitLocker required and enforced |
| Screen lock | Unknown | 5-minute timeout enforced |
| OS patching | Unknown | Windows Update for Business with deferral rings |
| Personal device access | Uncontrolled | MAM app protection — corporate data governed |
| Email authentication | Unknown | DKIM, SPF, DMARC (p=quarantine) |
| Email threat filtering | Basic | EOP + Safe Links + Safe Attachments + Anti-phishing |
| Endpoint threat detection | None | Defender for Business — EDR active |
| Attack surface | Uncontrolled | 9 ASR rules in block mode |
| File access control | Unknown | SharePoint library permissions via security groups |
| External sharing | Unknown | Disabled at tenant level |
| Guest access | Unknown | Disabled |
| Admin separation | Unknown | Break-glass + working admin, both unlicensed |
| Password self-service | None | SSPR enabled for all staff |

---

## Security Controls Summary

| Control | Status | Workstream |
|---|---|---|
| MFA via Conditional Access | Active | 02 |
| Block legacy authentication | Active | 02 |
| Executive strict policy | Active | 02 |
| Compliant device or MAM required | Active | 02 / 07 |
| 3 named locations declared | Active | 02 |
| SSPR enabled | Active | 03 |
| DKIM | Active | 04 |
| SPF | Active | 04 |
| DMARC p=quarantine | Active | 04 |
| External forwarding blocked | Active | 04 |
| SharePoint external sharing disabled | Active | 05 |
| Guest access disabled | Active | 06 |
| Windows compliance policy | Active | 07 |
| Security baseline profile | Active | 07 |
| Windows Update rings | Active | 07 |
| iOS MAM app protection | Active | 08 |
| Defender for Business EDR | Active | 09 |
| ASR rules (9 rules, block mode) | Active | 09 |
| Safe Links | Active | 10 |
| Safe Attachments | Active | 10 |
| Anti-phishing + impersonation protection | Active | 10 |

---

## Known Gaps and Remaining Risks

### Gap 1: No Third-Party Backup

**Risk:** Microsoft 365 provides resilience but not backup. Ransomware, a determined insider, or accidental permanent deletion may result in unrecoverable data loss beyond the 93-day recycle bin window.

**Recommended action:** Deploy Veeam Backup for Microsoft 365 or equivalent with daily backups of Exchange, SharePoint, and OneDrive retained for at least 1 year.

**Priority: High**

### Gap 2: DMARC at p=quarantine, Not p=reject

**Risk:** `p=quarantine` sends failing emails to spam rather than blocking them entirely. `p=reject` provides stronger protection.

**Recommended action:** Monitor DMARC aggregate reports for 30 days. If no legitimate email is failing, update the DNS record to `p=reject`.

**Priority: Medium**

### Gap 3: No Privileged Identity Management (PIM)

**Risk:** Both admin accounts hold Global Administrator permanently. PIM would require just-in-time activation with justification recorded, reducing the risk window if an admin account is compromised.

**Constraint:** PIM requires Entra ID P2, not included in Business Premium.

**Recommended action:** Evaluate Entra ID P2 add-on. As a compensating control, monitor admin sign-in activity via audit logs — any unexpected admin sign-in should trigger immediate investigation.

**Priority: Medium — licence dependent**

### Gap 4: Home Network IP Ranges Not Declared

**Risk:** Home working is treated as untrusted, which is correct. However, this means sign-in logs do not differentiate between "Jordan working from home" and "unknown location sign-in." For a larger organisation, this could make anomaly detection harder.

**Recommended action:** This is acceptable at this scale. For larger deployments, consider Entra ID Identity Protection (P2) which uses machine learning to evaluate sign-in risk regardless of whether a location is declared.

**Priority: Low for this deployment**

### Gap 5: Autopilot Not Implemented

**Risk:** New devices are enrolled manually via Entra join. This does not scale beyond a handful of devices.

**Recommended action:** Register the next device via Windows Autopilot using hardware hash registration. Document as the production standard.

**Priority: Low for current scale**

---

## What This Deployment Demonstrates

This project demonstrates a complete, professionally configured Microsoft 365 Business Premium deployment appropriate for a distributed professional services firm with multiple offices and remote workers.

Specifically:

- **Cloud-first architecture** — no on-premises dependencies; location is irrelevant to how services are configured or accessed
- **Multi-site consistency** — three named locations declared, but security applied consistently regardless of which office or home network a user connects from
- **Zero Trust implementation** — identity, device, and access controls working together as a coherent model
- **Decision-led configuration** — every setting has a documented reason
- **Honest self-assessment** — gaps documented with remediation steps
- **Operational readiness** — runbooks for onboarding and offboarding

**Next:** [12 — Access Governance](./12-access-governance.md)
