[← 10 — Conditional Access & MFA](10-conditional-access.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [12 — User Lifecycle →](12-user-lifecycle.md)

---

# 11 — Microsoft Defender for Business

## Introduction

Antivirus software used to be the whole of endpoint security — install it, let it scan files, and hope for the best. Modern threats have outgrown that model significantly. Attackers today use legitimate tools, fileless malware, and compromised credentials rather than files that a traditional antivirus scanner would catch.

Microsoft Defender for Business, included in Microsoft 365 Business Premium, is a modern endpoint detection and response (EDR) platform. It does more than scan for known viruses. It monitors behaviour across every device, correlates signals across the environment, and surfaces incidents that need attention — along with recommended remediation steps. It also provides email protection through Defender for Office 365, which catches phishing, malicious links, and suspicious attachments before they reach users' inboxes.

The key advantage of Defender for Business over standalone antivirus is the unified view. Rather than logging into each device separately to check its security status, everything is visible from a single portal: which devices have alerts, what the alert is, how serious it is, and what to do about it.

---

## What We Are Building

- Defender for Business enabled and onboarding Windows devices
- Security baseline policy applied via Intune
- Defender for Office 365 — Safe Links and Safe Attachments policies
- Review of the Defender portal and incident dashboard

---

## Implementation Steps

### Step 1 — Access the Microsoft Defender Portal

Navigate to security.microsoft.com. This is the unified Microsoft Defender portal where endpoint security, email security, and identity protection are all managed from one place.

With Microsoft 365 Business Premium, Defender for Business is already provisioned. You should see Devices and Email & collaboration in the left navigation.

### Step 2 — Onboard Windows Devices via Intune

Devices managed by Intune can be onboarded to Defender for Business automatically without manual agent installation.

In the Microsoft Defender portal, navigate to Settings → Endpoints → Device management → Onboarding. Select Intune as the deployment method. This enables the integration between Intune and Defender, so any device that is enrolled in Intune and has the Defender sensor enabled will automatically appear in the Defender portal.

In the Intune Admin Center, navigate to Endpoint security → Endpoint detection and response → Create policy → Windows 10 and later → Endpoint detection and response.

Name the policy `POL-Defender-EDR-Onboarding` and set Telemetry reporting frequency to Expedited. Assign the policy to all Windows devices.

Within 15 to 30 minutes of policy application, enrolled devices will appear in the Defender portal under Devices.

### Step 3 — Apply a Security Baseline for Defender

Microsoft provides a pre-built security baseline for Defender Antivirus that configures recommended settings in a single policy.

In the Intune Admin Center, navigate to Endpoint security → Antivirus → Create policy → Windows 10 and later → Microsoft Defender Antivirus.

Name the policy `POL-Defender-AV-Baseline` and accept the recommended defaults which include:

- Cloud-delivered protection: Enabled
- Automatic sample submission: Enabled
- Real-time protection: Enabled
- Behaviour monitoring: Enabled
- Network protection: Enabled (block mode)
- Potentially unwanted app protection: Enabled

Assign the policy to all Windows devices.

### Step 4 — Configure Safe Links

Safe Links rewrites all URLs in emails and Office documents. When a user clicks a link, Safe Links checks it in real time against Microsoft's threat intelligence before allowing the browser to open it. If the URL has been flagged as malicious since the email was received, the click is blocked.

In the Microsoft Defender portal, navigate to Email & collaboration → Policies & rules → Threat policies → Safe Links.

Create a new policy named `POL-SafeLinks-AllUsers`:

| Setting | Value |
|---|---|
| Users and domains | qcbhomelab.online |
| URL and click protection settings | On for email messages |
| Track when users click protected links | Enabled |
| Let users click through to the original URL | Disabled |
| Display the organisation branding on notification pages | Enabled |

### Step 5 — Configure Safe Attachments

Safe Attachments detonates email attachments in a secure sandbox environment before delivering them to the user. If the attachment behaves maliciously in the sandbox, it is blocked and the email is delivered without the attachment, or quarantined entirely.

In the Defender portal, navigate to Threat policies → Safe Attachments. Create a new policy named `POL-SafeAttachments-AllUsers`:

| Setting | Value |
|---|---|
| Users and domains | qcbhomelab.online |
| Safe Attachments unknown malware response | Block |
| Quarantine policy | AdminOnlyAccessPolicy |
| Enable redirect | Yes — redirect to your admin email |

### Step 6 — Review the Defender Dashboard

Navigate to the Microsoft Defender portal home page. With devices onboarded, you will see:

- Secure Score — a percentage representing how well-configured your environment is, with specific recommendations to improve it
- Active incidents and alerts — any security events that need attention
- Device health — which devices are at risk, out of date, or not running Defender

Review the Secure Score recommendations and work through the high-priority items. Each recommendation includes an explanation of the risk and the exact steps to remediate it.

---

## What to Expect

Once devices are onboarded and policies are applied, Defender monitors all device activity continuously. Email with malicious attachments or links is caught before it reaches users. The Defender portal provides a single pane of glass for the security posture of the entire environment, with clear guidance on what to fix and how.

---

[← 10 — Conditional Access & MFA](10-conditional-access.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [12 — User Lifecycle →](12-user-lifecycle.md)
