[← 10 — Conditional Access & MFA](10-conditional-access.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [12 — User Lifecycle →](12-user-lifecycle.md)

---

# 11 — Microsoft Defender for Business

## Overview — What This Document Covers

Traditional antivirus software works by recognising known threats — it compares files against a list of known bad things and blocks them. That worked reasonably well when attacks were straightforward, but modern attackers have largely moved beyond files that any scanner would recognise. Today's threats use legitimate tools in unexpected ways, hide inside normal-looking processes, and exploit human behaviour rather than software vulnerabilities.

Microsoft Defender for Business is a modern approach to endpoint security. It watches what is actually happening on a device — what processes are running, what network connections are being made, what files are being accessed — and looks for patterns that suggest something malicious is happening, even if none of the individual components are on a known threat list. It also protects email, catching malicious links and dangerous attachments before they reach users.

This document covers enabling that protection across all managed devices, configuring email security, and understanding how to read and respond to what the Defender portal is telling you.

---

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

## Common Questions & Troubleshooting

**Q1: Devices are enrolled in Intune but are not appearing in the Defender portal under Devices. The EDR onboarding policy has been assigned. What should I check?**

First confirm the Intune-Defender integration is enabled — in the Defender portal go to Settings → Endpoints → Device management → Onboarding and verify Intune is selected as the deployment method. Then check that the EDR policy (`POL-Defender-EDR-Onboarding`) has been assigned to the correct device group and that the devices have checked in to Intune since the policy was assigned. Devices that have not synced recently will not have received the policy. Trigger a manual sync from the device via Settings → Accounts → Access work or school → Sync, then allow 15–30 minutes for the device to appear in the Defender portal.

**Q2: The Defender portal is showing alerts but they all appear to be false positives from legitimate software. How should these be managed without disabling protection?**

Do not disable protection globally to resolve false positives. Instead, use Defender's Allow list for specific files, processes, or URLs that are known good. In the Defender portal, navigate to Settings → Endpoints → Rules → Indicators and add an allow indicator for the specific file hash, certificate, or URL that is triggering the false alert. For software that is deployed across the organisation, consider suppressing the specific alert rule for that behaviour rather than whitelisting the file broadly. Document all exceptions — suppressed alerts and allow-listed indicators represent gaps in visibility that need to be justified and reviewed periodically.

**Q3: Safe Attachments is configured but users are reporting significant delays receiving emails with attachments — sometimes 10 to 15 minutes. Is this expected?**

Some delay is expected — Safe Attachments detonates attachments in a sandbox before delivery, which takes time. For most attachments, the delay is under 5 minutes. Delays of 10–15 minutes may indicate the sandbox is processing a complex file or that the attachment triggered additional analysis. If the delay is consistently long for a particular file type from a trusted sender, you can create a transport rule to bypass Safe Attachments for that specific sender, but document the exception and ensure the sender's domain has valid SPF, DKIM, and DMARC in place before doing so.

**Q4: Microsoft Secure Score is showing a low score despite policies being configured. Many recommendations refer to settings that appear to already be enabled. Why?**

Secure Score pulls its signals from the actual state of the environment, not from the policy configuration. A policy may be configured correctly in Intune but not yet applied to all devices — Secure Score will reflect the actual device state rather than the intended policy. Allow 24–48 hours after policy deployment for the score to update as devices check in and report their state. Also note that some recommendations require specific licence tiers — a recommendation grayed out or showing as "Not applicable" may require a higher licence than Business Premium.

**Q5: A device has been showing as "At risk" in the Defender portal for several days but there are no active alerts or incidents visible. What does this mean and how is it resolved?**

"At risk" without visible alerts usually means the device has an unresolved historical alert that was not properly remediated, or a background threat signal that has not yet escalated to a full alert. In the Defender portal, click on the device and review its full timeline under the Device page — look for any alerts in a "Resolved" or "Investigating" state that may have been closed without remediation. Also check whether Defender antivirus is reporting any quarantined items. If the device shows as at risk with no discernible cause, running a full antivirus scan from the device and triggering a fresh Defender report via the Defender portal (Actions → Run antivirus scan) will refresh the status.

---
