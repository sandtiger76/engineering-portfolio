# 09 — Microsoft Defender for Business

## In Plain English

Antivirus software checks files against a list of known threats and blocks anything that matches. That was sufficient in the 1990s. Modern attacks are different — they use legitimate tools, live entirely in memory without writing to disk, and can sit undetected in an environment for weeks or months. Traditional antivirus would never see them.

Microsoft Defender for Business is an endpoint detection and response (EDR) platform. It watches what is happening on the device in real time: which processes are running, which network connections are being made, which files are being accessed, and how. When something suspicious happens — even if no malware is involved — Defender notices, records it, and either blocks it automatically or raises an alert for investigation.

Defender for Business is included in Microsoft 365 Business Premium at no additional cost. Not configuring it means leaving active security capability on the table.

---

## Why This Matters

The Windows laptop enrolled in workstream 07 has Intune managing its compliance and configuration. But Intune does not provide threat detection — it does not know if malicious code is running on the device, if a user has been phished, or if an attacker is moving laterally through the system.

Defender for Business fills that gap. Once the laptop is onboarded:
- Every process, file access, and network connection is monitored
- Threats are detected and blocked automatically
- Alerts are raised in the Microsoft Defender portal for investigation
- Attack Surface Reduction (ASR) rules block the techniques attackers use most commonly

For QCB Homelab Consultants — a consultancy handling client data — having endpoint detection in place is both a security requirement and a demonstration of professional practice.

---

## Prerequisites

| Requirement | Detail |
|---|---|
| Microsoft 365 Business Premium licence | Defender for Business is included |
| QCB-LAPTOP-01 enrolled in Intune | Completed in workstream 07 — device must be Intune managed |
| m365admin access to Microsoft Defender portal | https://security.microsoft.com |

---

## The End State

| Component | State |
|---|---|
| Defender for Business | Activated in the Microsoft Defender portal |
| QCB-LAPTOP-01 | Onboarded to Defender for Business |
| Security recommendations | Reviewed and actioned |
| Attack Surface Reduction rules | Block mode enabled for high-confidence rules |
| Threat dashboard | Active — showing device security posture |

---

## Phase 1 — Activate Defender for Business

### Step 1 — Access the Microsoft Defender Portal

1. Navigate to `https://security.microsoft.com`
2. Sign in as `m365admin@qcbhomelab.online`
3. If this is the first time accessing Defender for Business, a setup wizard may appear
4. Click **Go to setup** if the wizard appears, or navigate to **Settings** → **Endpoints**

### Step 2 — Complete the Defender Setup Wizard (If Prompted)

If the setup wizard appears:

1. **Data storage location** — select the region closest to your location (United Kingdom for this deployment)
2. **Turn on preview features** — set to **On** (recommended for a lab environment)
3. **Email notifications** — configure notifications to send to `m365admin@qcbhomelab.online` for:
   - High severity alerts
   - Medium severity alerts
4. Click **Continue** through each step
5. Click **Continue to Microsoft Defender for Business** when the wizard completes

---

## Phase 2 — Onboard the Windows Laptop

Onboarding connects the Windows laptop to Defender for Business, enabling threat monitoring and detection.

### Step 3 — Onboard via Intune (Recommended Method)

Because QCB-LAPTOP-01 is already enrolled in Intune, the easiest and most consistent onboarding method is through Intune's endpoint security settings.

1. Navigate to **Intune Admin Center** at `https://intune.microsoft.com`
2. Go to **Endpoint security** → **Endpoint detection and response**
3. Click **+ Create Policy**
4. Platform: **Windows 10, Windows 11, and Windows Server**
5. Profile: **Endpoint detection and response**
6. Click **Create**
7. Name: `EDR-WIN-Defender-Onboarding`
8. Accept the default settings (onboarding configuration is handled automatically)
9. Assignments → assign to **All devices** (or GRP-ManagedDevices)
10. Click **Review + create** → **Create**

The policy pushes the Defender for Business onboarding configuration to the enrolled Windows laptop. Onboarding completes within 15–30 minutes.

### Step 4 — Verify Onboarding in the Defender Portal

1. Navigate to `https://security.microsoft.com`
2. Go to **Assets** → **Devices**
3. QCB-LAPTOP-01 should appear with status **Active** within 30 minutes of the policy being applied

If the device does not appear within 30 minutes:
1. On QCB-LAPTOP-01, open **Command Prompt** as Administrator
2. Run: `sc query sense`
3. The Windows Defender Advanced Threat Protection service should be listed as **Running**

---

## Phase 3 — Review Security Recommendations

### Step 5 — Review the Threat & Vulnerability Management Dashboard

Once the device is onboarded, Defender for Business performs a security assessment and produces a list of recommendations.

1. In the **Defender portal** → **Vulnerability management** → **Dashboard**
2. Review the **Exposure score** — a lower score indicates better security posture
3. Review the **Microsoft Secure Score for Devices**
4. Navigate to **Recommendations** — review the prioritised list of security improvements

For each recommendation:
- Review the description and affected devices
- Note the exposure reduction value (how much onboarding or fixing this will improve the score)
- Action or defer each recommendation with a documented reason

> For a lab environment, the Secure Score and recommendations provide a useful checklist of security improvements and a talking point for interview discussions about security posture and continuous improvement.

---

## Phase 4 — Attack Surface Reduction Rules

Attack Surface Reduction (ASR) rules block specific techniques commonly used by attackers. Rather than detecting malware after it runs, ASR prevents it from running in the first place by blocking the behaviours it relies on.

### Step 6 — Configure ASR Rules via Intune

1. Navigate to **Intune Admin Center** → **Endpoint security** → **Attack surface reduction**
2. Click **+ Create Policy**
3. Platform: **Windows 10, Windows 11, and Windows Server**
4. Profile: **Attack surface reduction rules**
5. Click **Create**
6. Name: `ASR-WIN-Corporate-Standard`

Configure the following rules — set each to **Block**:

| Rule | Setting | What It Blocks |
|---|---|---|
| Block executable content from email client and webmail | Block | Email-delivered executables — a common malware delivery vector |
| Block all Office applications from creating child processes | Block | Office macros spawning PowerShell or cmd — a very common attack technique |
| Block Office applications from creating executable content | Block | Office macros writing executable files to disk |
| Block Office applications from injecting code into other processes | Block | Process injection via Office macros |
| Block JavaScript or VBScript from launching downloaded executable content | Block | Script-based malware delivery |
| Block execution of potentially obfuscated scripts | Block | Obfuscated PowerShell — commonly used in living-off-the-land attacks |
| Block process creations originating from PSExec and WMI commands | Block | Lateral movement tools used by ransomware operators |
| Block credential stealing from the Windows local security authority subsystem | Block | LSASS dumping — used to harvest credential hashes |
| Block abuse of exploited vulnerable signed drivers | Block | Bring-your-own-vulnerable-driver attacks |

7. Assignments → assign to **All devices**
8. Click **Review + create** → **Create**

> **Important:** ASR rules in Block mode can occasionally block legitimate software that uses the same techniques as malware. For a lab environment, Block mode is appropriate. For a production deployment with existing software, start with **Audit mode** for 2–4 weeks to identify any false positives before switching to Block.

---

## Phase 5 — Review the Defender Dashboard

### Step 7 — Explore the Security Dashboard

With onboarding complete and ASR rules applied, the Defender portal provides a real-time view of the device's security posture.

1. Navigate to `https://security.microsoft.com` → **Home**
2. Review the dashboard sections:
   - **Active alerts** — any threats currently detected
   - **Devices at risk** — devices with active incidents or unresolved recommendations
   - **Vulnerable devices** — devices with known software vulnerabilities
   - **Threat analytics** — current threat landscape relevant to this environment

3. Navigate to **Assets** → **Devices** → click **QCB-LAPTOP-01**
4. Review the device page:
   - **Overview** — device details, risk level, onboarding status
   - **Alerts** — any alerts associated with this device
   - **Timeline** — chronological record of all events on the device
   - **Security recommendations** — device-specific recommendations
   - **Discovered vulnerabilities** — known CVEs affecting software on the device
   - **Installed software** — complete software inventory

> The **Timeline** view is particularly powerful. It shows every process that ran, every file that was created, every network connection that was made — on the device, in chronological order. This is what enables an incident responder to reconstruct exactly what happened during an attack.

---

## Validation

| Check | Method | Expected Result |
|---|---|---|
| Defender portal accessible | Navigate to security.microsoft.com | Portal loads — no setup wizard (completed) |
| QCB-LAPTOP-01 onboarded | Defender portal → Assets → Devices | Device listed as Active |
| Onboarding policy applied | Intune → EDR-WIN-Defender-Onboarding | Applied to device |
| ASR rules applied | Intune → ASR-WIN-Corporate-Standard | Applied to device |
| Security recommendations reviewed | Defender → Vulnerability management | Recommendations list reviewed |
| No active threats | Defender → Active alerts | No high-severity alerts |

### PowerShell Verification on Device

On QCB-LAPTOP-01, run as Administrator:

```powershell
# Verify Defender for Business agent is running
Get-Service -Name "Sense" | Select-Object Name, Status, StartType

# Verify Windows Defender is active
Get-MpComputerStatus | Select-Object AMRunningMode, AntivirusEnabled, RealTimeProtectionEnabled
```

Expected output:
```
Name    Status   StartType
----    ------   ---------
Sense   Running  Automatic
```

---

## Summary

This workstream delivered:

- **Defender for Business activated** in the Microsoft Defender portal
- **QCB-LAPTOP-01 onboarded** via Intune EDR policy — real-time threat monitoring active
- **Security recommendations reviewed** — exposure score and Secure Score documented
- **Attack Surface Reduction rules** configured in Block mode — 9 high-confidence rules active
- **Threat dashboard** reviewed — timeline, alerts, and vulnerability data available

The Windows laptop now has active endpoint detection and response. Any suspicious behaviour — whether malware, a phishing attempt, or an attacker using legitimate tools — is monitored, and alerts are raised in the Defender portal.

This workstream closed one of the documented gaps from the previous version of this project. Defender for Business was included in the Microsoft 365 Business Premium licence but not configured. It is now fully deployed.

**Next:** [10 — Defender for Office 365](./10-defender-for-office365.md)
