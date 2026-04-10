# 00 — Company Profile & Project Design

## In Plain English

Before a single setting is configured, a well-run IT project starts with a clear picture of the organisation it is serving. Who are the people? What do they do? Where do they work? What devices do they use? What does the company need to protect, and from what?

This document answers all of those questions for QCB Homelab Consultants. It defines the company, its locations, its staff, its devices, and the design principles that guide every decision made in this project. It is the single source of truth that all other workstreams reference.

---

## The Company

**QCB Homelab Consultants** is a multi-sector professional services firm providing consulting, advisory, and managed services to clients across multiple industries. The company operates from three office locations — a central headquarters and two regional offices — with staff also working from home and from client sites.

The company has made a deliberate decision to operate with no on-premises server infrastructure. There is no file server, no internal email server, no on-premises Active Directory domain controller. All services are delivered from the cloud. This is not a migration from on-premises — it is a greenfield cloud deployment for a company that has chosen cloud-first from the start.

| Detail | Value |
|---|---|
| Company name | QCB Homelab Consultants |
| Primary domain | qcbhomelab.online |
| Infrastructure model | 100% cloud — no on-premises servers |
| Microsoft 365 licence | Business Premium (25 seats) |
| Total staff | 5 |
| Office locations | 3 (Central, North, South) |
| Working patterns | Office, home, and client site |
| DNS provider | Cloudflare |

---

## Why Cloud-Only

The decision to operate without on-premises infrastructure is deliberate, not a constraint. It eliminates:

- The cost and maintenance of physical server hardware
- The complexity of keeping software patched and supported
- The dependency on VPN for remote and home workers
- The single point of failure of a server room

In its place, Microsoft 365 Business Premium provides everything the company needs — email, file storage, communication, device management, and security — delivered from Microsoft's globally distributed infrastructure with a 99.9% uptime SLA.

---

## Office Locations

The company operates from three locations. Each is registered as a **named location** in Microsoft Entra ID Conditional Access — meaning the IP range of each office network is known and declared as trusted. This does not bypass any security controls; it provides context for access decisions.

| Location Name | Type | Conditional Access | Users Based Here |
|---|---|---|---|
| Central Office | HQ | Named Location 1 — trusted | Alex Carter, Morgan Blake |
| North Office | Regional | Named Location 2 — trusted | Jordan Hayes |
| South Office | Regional | Named Location 3 — trusted | Riley Morgan |
| Remote | No fixed office | Untrusted — any network | Casey Quinn |

### Home Working Policy

All staff — regardless of which office they are assigned to — may work from home. Home networks are **not** registered as trusted locations and are treated identically to any unknown network. MFA is required for every sign-in, whether the user is in the office or working from home. Named locations are used for context and reporting, not to grant implicit trust or bypass MFA.

This is the correct design for a multi-site organisation. Trust should come from verified identity and device compliance — not from network location.

---

## The 5 Users

The company has five members of staff representing three distinct role types. This variety demonstrates different security profiles and access policies for different working patterns.

| Display Name | UPN | Role | Home Office | Working Pattern | Device |
|---|---|---|---|---|---|
| Alex Carter | alex.carter@qcbhomelab.online | Executive | Central Office | Office + home + travel | Corporate Windows laptop |
| Morgan Blake | morgan.blake@qcbhomelab.online | Manager | Central Office | Office + home | Corporate Windows laptop |
| Jordan Hayes | jordan.hayes@qcbhomelab.online | Staff | North Office | Office + home | Corporate Windows laptop |
| Riley Morgan | riley.morgan@qcbhomelab.online | Staff | South Office | Office + home | Corporate Windows laptop |
| Casey Quinn | casey.quinn@qcbhomelab.online | Field Worker | Remote — no fixed office | Fully remote, client sites | Personal iPhone (BYOD) |

### Why These Five

**The Executive (Alex Carter)** represents a high-value, high-risk target. Executives are the most commonly impersonated accounts in phishing attacks. They receive the strictest Conditional Access policy — MFA always required, compliant device always required, with no exceptions for any named location. Even when Alex is sitting in the Central Office on the trusted network, MFA and device compliance are still enforced.

**The Manager (Morgan Blake)** represents a standard office worker with administrative responsibilities. They follow the standard security policy — MFA required, compliant device required for Microsoft 365 applications.

**Staff (Jordan Hayes and Riley Morgan)** are distributed across the two regional offices. They demonstrate that the same policy applies consistently across locations — Jordan in the North Office and Riley in the South Office have identical security requirements and access profiles.

**The Field Worker (Casey Quinn)** works entirely remotely with no assigned office. She uses a personal iPhone — not a corporate-managed device. MAM without enrolment is used: corporate data inside Outlook and Teams is protected by policy, but the device itself remains under Casey's personal control.

---

## Admin Accounts

Two dedicated administration accounts are maintained. Neither holds a Microsoft 365 licence — admin roles do not require licences, and keeping admin accounts unlicensed means all 25 Business Premium licences are available for staff.

| Account | Domain | Role | Purpose |
|---|---|---|---|
| qcb-az@[tenant].onmicrosoft.com | onmicrosoft.com | Global Administrator | Break-glass emergency access only |
| m365admin@qcbhomelab.online | qcbhomelab.online | Global Administrator | Day-to-day administration |

**Why two accounts?** The break-glass account exists on the `onmicrosoft.com` domain — Microsoft's permanent initial domain that cannot expire or be misconfigured in Cloudflare. If the custom domain ever fails for any reason, the break-glass account still works. It is stored securely, never used for routine tasks, and its sign-in activity is monitored — any use should be treated as significant.

---

## Security Groups

Security groups are the organisational building blocks of this deployment. Policies, licences, and permissions are assigned to groups, not individuals.

| Group Name | Members | Purpose |
|---|---|---|
| GRP-Executives | Alex Carter | Strict CA policy target — MFA + compliant device always |
| GRP-Managers | Morgan Blake | Standard CA policy target |
| GRP-Staff | Jordan Hayes, Riley Morgan | Standard CA policy target |
| GRP-FieldWorkers | Casey Quinn | MAM policy target |
| GRP-AllStaff | All 5 users | Licence assignment, SSPR, distribution group |
| GRP-ManagedDevices | (device group) | Intune compliance policy assignment |

---

## Physical Devices

| Device | Type | Owner | Location | Management |
|---|---|---|---|---|
| QCB-LAPTOP-01 | Windows laptop | Corporate asset | Central Office (used by Jordan Hayes for lab) | Entra joined · Intune MDM |
| Casey's iPhone | iOS device | Personal (Casey Quinn) | Remote | MAM without enrolment (BYOD) |

**QCB-LAPTOP-01** is the corporate Windows laptop used for this lab. In the scenario, all four office-based staff use identical corporate laptops — one physical device is used to represent all four for lab purposes. It is joined directly to Microsoft Entra ID with no on-premises AD domain controller involvement.

**Casey's iPhone** is a personal device. It is not enrolled in Intune MDM. An App Protection Policy governs corporate data within Outlook and Teams only.

---

## Naming Conventions

| Resource Type | Convention | Example |
|---|---|---|
| User accounts | firstname.lastname@qcbhomelab.online | alex.carter@qcbhomelab.online |
| Admin accounts | role@domain | m365admin@qcbhomelab.online |
| Security groups | GRP-[Description] | GRP-Executives |
| Named locations | LOC-[OfficeName] | LOC-CentralOffice |
| Conditional Access policies | CA-[Number]-[Description] | CA-01-Require-MFA-All-Users |
| Intune compliance policies | COMP-[Platform]-[Description] | COMP-WIN-Corporate-Standard |
| Intune configuration profiles | CFG-[Platform]-[Description] | CFG-WIN-Security-Baseline |
| SharePoint libraries | Title case, no abbreviations | Projects, Technical Library |
| Teams | Mirror department names | Executives, Operations, All Staff |

---

## Technology Design Decisions

### Cloud-Only Identity

There is no on-premises Active Directory. Users are created directly in Microsoft Entra ID. Entra Connect is not used — it is not needed for a greenfield deployment and would add complexity without benefit.

### Multi-Site Named Locations — Context, Not Trust

Three named locations are created in Conditional Access — one per office. These declare the public IP range of each office network as known to the tenant. They are used for:

- Reporting and sign-in log context (which office did this sign-in come from?)
- Potential future use in sign-in risk evaluation
- Demonstrating multi-site awareness in a professional deployment

They are **not** used to bypass MFA or device compliance. A user sitting in the Central Office still must complete MFA and must be on a compliant device. Named locations that bypass MFA are a common misconfiguration and a security risk — this project avoids it deliberately.

### Home Working as Untrusted Network

Home working is fully supported for all staff. Home networks are not trusted locations — they cannot be, because there is no way to guarantee the security of a residential broadband connection. The Conditional Access framework handles this correctly: MFA is required regardless of network, and device compliance is enforced regardless of location.

### Conditional Access Over Security Defaults

Microsoft 365 ships with Security Defaults — a basic protection suitable for organisations with no IT resource. This project replaces them with Conditional Access policies, which allow precise control — different policies for different user groups, device compliance as a condition, named location context, and break-glass account exclusion.

### Zero Trust Architecture

Three pillars, implemented across every workstream:

| Pillar | Implementation |
|---|---|
| Identity verification | MFA enforced via CA-01 for all users, all apps, all locations |
| Device compliance | Intune compliance policy — compliant device required via CA-04 |
| Least-privilege access | SharePoint permissions via security groups — users access only what they need |

### MAM Without Enrolment for Personal Devices

Full MDM enrolment of a personal device grants the organisation remote wipe capability over the whole device — unreasonable for personal property. MAM without enrolment protects corporate data in Outlook and Teams only, with no control over the rest of the device. This is the correct, proportionate, and legally defensible BYOD approach.

### DMARC at p=quarantine

Many deployments leave DMARC at `p=none` (monitoring only) indefinitely. This project sets DMARC to `p=quarantine` — emails failing authentication are quarantined rather than delivered. This is active protection. A future iteration would move to `p=reject` after a 30-day monitoring period confirms no false positives.

---

## Prerequisites for Implementation

| Prerequisite | Status |
|---|---|
| Microsoft 365 Business Premium trial activated | Required |
| qcbhomelab.online verified as default domain | Pre-configured |
| Cloudflare DNS access | Required for DKIM, DMARC, Intune CNAMEs, named location IP confirmation |
| Break-glass admin account accessible | Required before disabling Security Defaults |
| Public IP of each office network noted | Required for named location configuration |
| Windows laptop available for Entra join | Required for workstream 07 |
| iPhone available for MAM enrolment | Required for workstream 08 |

---

## What Comes Next

With the company profile and design decisions established, implementation begins. The workstreams must be followed in order — identity is the foundation on which every other service depends.

**Next:** [01 — Identity & Entra ID](./01-identity-and-entra-id.md)
