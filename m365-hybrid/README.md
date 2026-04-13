[🏠 README](README.md) &nbsp;|&nbsp; [01 — On-Premises Infrastructure →](docs/01-on-premises-dc.md)

---

# Hybrid Microsoft Environment

## About the project

This project documents the design and implementation of a complete hybrid Microsoft environment, built from scratch for a fictional professional services firm called QCB Homelab Consultants. It was created as a hands-on portfolio piece to demonstrate practical, real-world capability across the Microsoft 365 and Azure technology stack.

The environment reflects how a modern SMB would actually operate — cloud-first, identity-driven, and secure by design — rather than a textbook exercise. Every decision made here has a reason behind it, and where there were alternatives, those trade-offs are explained.

---

## The Organisation

| Detail | Value |
|---|---|
| Company | QCB Homelab Consultants |
| Primary domain | qcbhomelab.online |
| Microsoft 365 licence | Business Premium (25 seats) |
| Infrastructure model | Hybrid identity, cloud-hosted services |
| Locations | London, New York, Hong Kong, Remote |
| Staff | 6 users across three offices |
| Devices | Corporate Windows laptops (MDM) and personal iPhones (MAM) |

---

## Architecture Overview

The diagram below shows how the three layers of this environment connect — on-premises infrastructure, Azure, and Microsoft 365 — with identity synchronisation as the thread that ties them together.

```mermaid
graph TB
    subgraph ONPREM["🏢  On-Premises"]
        DC["QCBHC-DC01\nWindows Server 2022"]
        AD["Active Directory\nqcbhomelab.online"]
        DNS["DNS Server\n+ Forwarders"]
        DC --> AD
        DC --> DNS
    end

    subgraph AZURE["☁️  Azure — UK South"]
        SYNC["Entra Connect Sync\nPassword Hash Sync"]
        subgraph RGN["RG-Networking"]
            VNET["VNET-QCBHomelab\n10.10.0.0/16"]
            NSG["NSG-Identity"]
        end
        subgraph RGM["RG-Management"]
            LAW["Log Analytics\nWorkspace"]
        end
    end

    subgraph ENTRA["🔐  Microsoft Entra ID"]
        EID["Entra ID\nCloud Identities"]
        CA["Conditional Access\nPolicies"]
        MFA["MFA / Authenticator"]
    end

    subgraph M365["📦  Microsoft 365 Business Premium"]
        EXO["Exchange Online\nEmail"]
        SPO["SharePoint\nTeam Sites"]
        ODB["OneDrive\nPersonal Storage"]
        TEAMS["Microsoft Teams\nChat & Meetings"]
        INTUNE["Intune MDM/MAM\nWindows + iOS"]
        DFND["Defender for Business\nEDR + Email Security"]
    end

    AD -->|"sync every 30 min"| SYNC
    SYNC -->|"users + password hashes"| EID
    EID --> CA
    EID --> M365
    CA -->|"enforces"| MFA
    CA -->|"governs access to"| M365
    INTUNE -->|"compliance signal"| CA
    DFND -->|"endpoint telemetry"| LAW
```

---

## Project Documents

Work through these in order. Each document is self-contained but builds on the one before it.

| # | Document | What it covers |
|---|---|---|
| 01 | [On-Premises Infrastructure](docs/01-on-premises-dc.md) | Windows Server 2022, Active Directory, DNS |
| 02 | [AD Provisioning Scripts](docs/02-ad-scripts.md) | PowerShell scripts to build the full AD structure |
| 03 | [Azure Resource Setup](docs/03-azure-setup.md) | Resource groups, networking, and Azure foundations |
| 04 | [Hybrid Identity](docs/04-hybrid-identity.md) | Entra Connect Sync, Password Hash Sync |
| 05 | [Microsoft 365 & Exchange Online](docs/05-m365-exchange.md) | Tenant setup, domain, email flow, DNS |
| 06 | [SharePoint & OneDrive](docs/06-sharepoint-onedrive.md) | Team sites, personal storage, file migration |
| 07 | [Microsoft Teams](docs/07-teams.md) | Communication layer, governance, structure |
| 08 | [Intune — Windows](docs/08-intune-windows.md) | Device enrolment, compliance, patching |
| 09 | [Intune — iOS MAM](docs/09-intune-ios.md) | BYOD mobile app management |
| 10 | [Conditional Access & MFA](docs/10-conditional-access.md) | Zero Trust access policies |
| 11 | [Defender for Business](docs/11-defender.md) | Endpoint and email security |
| 12 | [User Lifecycle](docs/12-user-lifecycle.md) | Onboarding and offboarding procedures |

---

## Technology Stack

- Windows Server 2022 (Active Directory, DNS)
- Microsoft Entra ID (formerly Azure Active Directory)
- Microsoft Entra Connect Sync
- Microsoft 365 Business Premium (Exchange Online, SharePoint, OneDrive, Teams)
- Microsoft Intune (MDM and MAM)
- Microsoft Defender for Business
- Azure (resource groups, virtual network, Log Analytics)
- PowerShell (provisioning and automation throughout)

---

## Security Posture

The environment is built on Zero Trust principles. Access to company data is never assumed based on network location. Every access decision is evaluated against three signals: who the user is, whether their device is compliant, and whether the sign-in looks normal. Multi-factor authentication is enforced for all users with no exceptions.

---

## Security Architecture

Security in this environment is not a single setting — it is a layered posture built across four distinct levels, each reinforcing the others.

**Identity layer**
Every sign-in is challenged with multi-factor authentication regardless of location or device. Legacy authentication protocols that cannot support MFA are blocked entirely. Admin accounts have no persistent sessions and must re-authenticate every time they are used.

**Device layer**
Windows laptops are enrolled in Microsoft Intune and must meet a defined compliance policy before they are permitted to access Microsoft 365 applications. Compliance status is fed as a real-time signal into Conditional Access — a device that falls out of compliance loses access automatically. Personal iPhones are governed through Mobile Application Management (MAM) rather than full device enrolment, protecting company data within managed apps without touching personal content.

**Email layer**
All inbound email attachments are detonated in a sandbox environment by Safe Attachments before reaching users. All links in emails are rewritten and checked in real time at the point of click by Safe Links. Outbound email is cryptographically signed with DKIM, SPF authorises Microsoft's sending infrastructure, and DMARC provides monitoring and a path to enforcement.

**Endpoint layer**
Microsoft Defender for Business provides endpoint detection and response (EDR) across all managed Windows devices. Behaviour monitoring, network protection, and cloud-delivered protection are all enabled. Telemetry is forwarded to a central Log Analytics workspace, providing a single place to search and analyse security events across the environment.

**Conditional Access policies in force**

| Policy | Purpose |
|---|---|
| CA01 — Require MFA for all users | No sign-in is trusted on password alone |
| CA02 — Block legacy authentication | Eliminates protocols that cannot support MFA |
| CA03 — Require compliant device for M365 | Blocks unmanaged devices from company data |
| CA04 — Protect admin accounts | No persistent sessions for privileged roles |

---

## A Note on Scope

This is an SMB-scale environment by design. Enterprise features such as Azure AD Domain Services, ADFS, DFS namespaces, and multiple subscriptions are deliberately excluded. The goal is to show clean, practical implementation of the tools most organisations of this size actually use.

---

[🏠 README](README.md) &nbsp;|&nbsp; [01 — On-Premises Infrastructure →](docs/01-on-premises-dc.md)
