# 01 — Identity: Overview

## In Plain English

Identity is the foundation of everything in Microsoft 365. Before email can be set up, before
files can be moved, before devices can be managed — the right people need to exist in the
system with the right access. Get identity wrong and everything built on top of it is unstable.

In simple terms: this workstream takes the list of staff accounts that exist on the old
on-premises server and creates matching accounts in Microsoft 365. From that point forward,
each member of staff has a single set of login credentials that works for email, file storage,
video calls, and every other service in the platform.

This section covers the full identity workstream across six dedicated pages — each one focused
on a single task.

---

## Why This Matters

In the old environment, identity was managed entirely on-premises. The Windows Server held
the master list of users. If the server was unavailable, nobody could log in. There was no
MFA, no device compliance checking, and no way to enforce consistent security policy across
staff working from different locations on different devices.

Microsoft Entra ID replaces that entirely. It is Microsoft's cloud identity platform — the
system that handles authentication for every Microsoft 365 service. Once users exist in Entra
ID, their identity works from anywhere, on any device, with security controls that were simply
not possible with an on-premises domain controller.

---

## The End State

By the end of this workstream, the following will be in place:

| Component | State |
|---|---|
| Entra Connect | Installed on DC — syncing apex.local to Entra ID |
| 15 staff accounts | Synchronised from AD into Entra ID |
| UPNs | `firstname.lastname@qcbhomelab.online` — matching AD |
| Admin accounts | Two dedicated admin accounts — no named user doing admin |
| MFA | Enforced via Conditional Access for all users |
| Security defaults | Disabled — replaced by Conditional Access policies |
| Licences | Business Premium assigned to all 15 staff via group |

---

## Identity Workstream Pages

| Page | Content |
|---|---|
| [01a — Entra Connect Installation](./01a-entra-connect-installation.md) | Installing and configuring Microsoft Entra Connect on the DC |
| [01b — Entra Connect Sync Verification](./01b-entra-connect-sync-verification.md) | Verifying all 15 users synced correctly into Entra ID |
| [01c — User Provisioning Methods](./01c-user-provisioning-methods.md) | Three ways to create users — comparison and when to use each |
| [01d — Group Creation and Licensing](./01d-group-creation-and-licensing.md) | Security groups in Entra ID and group-based licence assignment |
| [01e — Admin Account Separation](./01e-admin-account-separation.md) | Break-glass account, working admin account, and least privilege |
| [01f — MFA and Security Defaults](./01f-mfa-and-security-defaults.md) | Enforcing MFA via Conditional Access, disabling security defaults |

---

## A Note on the AzureAD Module

Early in this project, the legacy `AzureAD` PowerShell module was used to query the tenant.
It returned the following error on every command:

```
Code: Authentication_Unauthorized
Message: Access blocked to AAD Graph API for this application.
```

This is expected. Microsoft deprecated the AzureAD module and blocked access to the
underlying AAD Graph API. The replacement is the **Microsoft Graph PowerShell SDK**
(`Microsoft.Graph`) — which is what all PowerShell commands in this documentation use.

> **Production note:** If working in an environment where the AzureAD module is still in use,
> plan migration to Microsoft Graph PowerShell as part of the project. Scripts and automation
> built on the old module will stop working without warning.

```powershell
# Install Microsoft Graph PowerShell SDK
Install-Module -Name Microsoft.Graph -Scope AllUsers -Force

# Connect
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"
```

---

*Previous: [00 — Discovery & Planning →](./00-discovery-and-planning.md)*
*Next: [01a — Entra Connect Installation →](./01a-entra-connect-installation.md)*
