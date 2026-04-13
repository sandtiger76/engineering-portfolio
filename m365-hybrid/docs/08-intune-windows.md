[← 07 — Microsoft Teams](07-teams.md) &nbsp;|&nbsp; [🏠 README](../README.md) &nbsp;|&nbsp; [09 — Intune: iOS MAM →](09-intune-ios.md)

---

# 08 — Intune: Windows Device Management & Patching

## Overview — What This Document Covers

When an employee gets a new laptop, someone has to set it up — install the right software, apply security settings, configure email, and make sure it meets the company's standards before it goes near any company data. Traditionally this meant the IT team physically preparing each machine. In a cloud-managed environment, the device does it itself.

Microsoft Intune is the service that makes this possible. It manages Windows laptops from the cloud — the moment a device is enrolled, it automatically receives security policies, software configuration, and compliance settings without the IT team needing to touch it. If a device falls out of compliance (for example, if security software is disabled or the OS is out of date), it loses access to company resources automatically.

This document also covers patching — keeping Windows up to date in a controlled way. Rather than letting every device update unpredictably, updates are staged through defined rings so that any problematic update can be caught before it affects everyone.

---

## Introduction

Microsoft Intune is the cloud-based device management service included in Microsoft 365 Business Premium. It allows IT to manage Windows laptops and desktops without needing a traditional on-premises tool like SCCM (System Centre Configuration Manager). Through Intune, you can enrol devices, enforce security policies, deploy applications, configure settings, and control Windows Update — all from a single web console, from anywhere.

For the users in this environment, every corporate Windows device is managed through Intune. This means the moment a device is enrolled, it receives the correct security baseline, compliance settings, and software configuration automatically — without the IT team needing to physically touch the machine.

Patching is managed through Windows Update for Business, which is configured via Intune Update Rings. An Update Ring is a policy that controls when and how Windows updates are installed. Rather than letting every device update unpredictably, Update Rings allow you to stage updates — testing them on a small group first before rolling them out to everyone else.

In this lab, corporate devices are Windows 11 Enterprise virtual machines running in Proxmox. The enrolment method demonstrated here is Windows Autopilot — the modern, Microsoft-recommended approach for provisioning corporate-owned devices. The device hardware hash is extracted and uploaded to Intune, which registers it as a known corporate device before the user even logs in for the first time.

---

## What We Are Building

- Windows 11 Enterprise VM provisioned in Proxmox with TPM and UEFI
- MDM automatic enrolment enabled in Intune
- Device hardware hash uploaded to Windows Autopilot
- Autopilot deployment profile configured for user-driven Entra ID join
- Compliance policy defining what a healthy device looks like
- Security configuration profile applying Defender and OneDrive settings
- Windows Update Rings for controlled, staged patching

---

## Prerequisites

- Microsoft 365 Business Premium licences assigned to all users (document 05)
- Users synced from Active Directory and visible in Entra ID (document 04)
- Proxmox hypervisor available with sufficient resources (2 vCPU, 4 GB RAM, 60 GB disk minimum)
- Windows 11 Enterprise Evaluation ISO downloaded from microsoft.com/en-us/evalcenter
- VirtIO drivers ISO downloaded from fedorapeople.org

---

## Implementation Steps

### Step 1 — Provision the Windows 11 VM in Proxmox

Windows 11 requires TPM 2.0 and UEFI firmware. Both must be configured at VM creation time — they cannot be added after the fact. The VirtIO drivers ISO must also be attached at creation so storage and network drivers are available during installation.

Download both ISOs to the Proxmox ISO store:

```bash
# Download VirtIO drivers
wget -O /var/lib/vz/template/iso/virtio-win.iso \
  https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
```

The Windows 11 Enterprise Evaluation ISO must be downloaded manually from the Microsoft Evaluation Center — the download requires completing a form on the website. Once downloaded, transfer it to the Proxmox ISO store or download it directly on the Proxmox host if a direct link is available.

Create the VM using the Proxmox CLI. Replace the ISO filename with the actual filename from your download:

```bash
qm create 203 \
  --name WS-LDN-CARTER \
  --machine q35 \
  --bios ovmf \
  --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 \
  --tpmstate0 local-lvm:1,version=v2.0 \
  --cpu host \
  --cores 2 \
  --memory 4096 \
  --balloon 0 \
  --scsihw virtio-scsi-pci \
  --scsi0 local-lvm:60,discard=on,ssd=1 \
  --ide0 local:iso/windows11-eval.iso,media=cdrom \
  --ide1 local:iso/virtio-win.iso,media=cdrom \
  --net0 virtio,bridge=vmbr0 \
  --ostype win11 \
  --boot order=scsi0;ide0 \
  --vga std \
  --onboot 0
```

Start the VM and open the console in the Proxmox web interface to proceed through the Windows installation.

### Step 2 — Install Windows 11

During the Windows Setup process, when you reach the **Where do you want to install Windows?** screen, no disks will be visible. This is expected — Windows cannot see the VirtIO disk without drivers.

Click **Load driver → Browse** and navigate to the VirtIO CD drive (the second CD). Browse to **vioscsi → w11 → amd64** and click OK. The 60 GB disk will appear. Select it and continue the installation.

When prompted to sign in during the Windows Out of Box Experience (OOBE), select **Sign-in options → Domain join instead** to create a local administrator account. Do not sign in with a Microsoft or work account at this stage — the Entra ID join is done separately after setup.

Create a local account:

| Setting | Value |
|---|---|
| Username | localadmin |
| Password | A strong local password |

Skip through all privacy and telemetry prompts and allow Windows to reach the desktop.

### Step 3 — Install Network Drivers and Run Windows Update

After reaching the desktop, Windows will not have network connectivity — the VirtIO network adapter also requires a driver.

Open Device Manager, locate the unknown network adapter, right-click and select **Update driver → Browse my computer → Browse** and navigate to the VirtIO CD drive, selecting **NetKVM → w11 → amd64**. Once the driver installs, network connectivity will be available.

Run Windows Update from Settings and install all available updates before proceeding. This may require one or more restarts.

Rename the computer to match the naming convention before joining Entra ID:

```powershell
Rename-Computer -NewName "WS-LDN-CARTER" -Restart
```

### Step 4 — Enable MDM Automatic Enrolment

Before enrolling the device, confirm that automatic MDM enrolment is enabled in Intune. Without this, devices that join Entra ID will register but will not enrol in Intune MDM.

In the Intune Admin Center at **intune.microsoft.com**, navigate to **Devices → Enrollment → Automatic Enrollment**. Set the **MDM user scope** to **All** and click Save.

> **Note:** This setting is easy to miss on a new tenant. The default value is **None**, which means Entra ID joins will not trigger Intune enrolment. This is a common reason devices appear in Entra ID but not in Intune.

### Step 5 — Extract the Hardware Hash and Register with Autopilot

Windows Autopilot is the modern method for provisioning corporate-owned devices. Rather than imaging machines or manually configuring each one, Autopilot uses a hardware hash — a unique fingerprint of the device — to identify it as a corporate device when it first connects to the internet during OOBE.

On the VM, open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Install-Script -Name Get-WindowsAutopilotInfo -Force
Get-WindowsAutopilotInfo -OutputFile C:\autopilot.csv
```

This generates a CSV file containing the device's hardware hash. Copy the file to your management machine and upload it to Intune.

In the Intune Admin Center, navigate to **Devices → Windows → Enrollment → Windows Autopilot → Devices → Import** and upload the CSV file. The import process takes up to 15 minutes. Click **Sync** after import completes and the device will appear in the Autopilot devices list.

> **Note:** On a VM, the serial number field in the CSV will be blank or show a placeholder value such as SMBIOS_STRING_INDEX_0. This is expected — Proxmox VMs do not have real hardware serial numbers. The hardware hash itself is sufficient for Autopilot registration.

### Step 6 — Create an Autopilot Deployment Profile

The deployment profile controls what the user sees during OOBE when they first sign in on an Autopilot-registered device.

In the Intune Admin Center, navigate to **Devices → Windows → Enrollment → Deployment profiles → Create profile → Windows PC**.

Name the profile `PROF_Autopilot_Corporate` and configure the OOBE settings:

> **Note:** The profile name cannot contain hyphens — use underscores instead.

| Setting | Value |
|---|---|
| Deployment mode | User-Driven |
| Join to Microsoft Entra ID as | Microsoft Entra joined |
| Microsoft Software License Terms | Hide |
| Privacy settings | Hide |
| Hide change account options | Hide |
| User account type | Standard |
| Allow pre-provisioned deployment | No |
| Apply device name template | No |

On the Assignments tab, assign the profile to **GRP-Devices-Windows**.

After creating the profile, go to **Devices → Windows → Enrollment → Windows Autopilot → Devices**, select the device, click **Assign user** and assign the relevant user — in this case j.carter@qcbhomelab.online. Enter **James Carter** as the user friendly name. Click **Save**, then click **Sync** to force the profile assignment to update.

### Step 7 — Enrol the Device

With the hardware hash registered and the Autopilot profile assigned, enrol the device into Intune MDM.

On the VM, go to **Settings → Accounts → Access work or school → Connect**. On the sign-in screen, click **Join this device to Microsoft Entra ID** at the bottom rather than entering credentials in the main field.

Sign in as j.carter@qcbhomelab.online when prompted. Confirm the organisation details on the confirmation screen and click **Join**.

Once joined to Entra ID, trigger MDM enrolment by opening PowerShell as Administrator and running:

```powershell
Start-Process "ms-device-enrollment:?mode=mdm"
```

A sign-in prompt will appear — sign in with the work account. Intune will then enrol the device and begin applying policies.

Alternatively, install the **Company Portal** app from the Microsoft Store, sign in with the work account, and enrolment will trigger automatically.

Verify the device has appeared in Intune by navigating to **Devices → Windows → Windows devices** in the Intune Admin Center. The device should show as **Compliant** within 15 to 30 minutes once policies have been applied.

### Step 8 — Create a Compliance Policy

A compliance policy defines the minimum security requirements a device must meet. Devices that do not meet these requirements are marked non-compliant, and Conditional Access policies (document 10) can block their access to company data.

Navigate to **Devices → Compliance → Create policy → Windows 10 and later → Windows 10/11 compliance policy**.

Name the policy `POL-Compliance-Windows` and configure the following settings across the relevant sections:

**Device Health:**

| Setting | Value |
|---|---|
| BitLocker | Require |
| Secure Boot | Require |
| Code integrity | Require |

**Device Properties:**

| Setting | Value |
|---|---|
| Minimum OS version | 10.0.19041 |

**System Security:**

| Setting | Value |
|---|---|
| Password required | Require |
| Minimum password length | 8 |
| Firewall | Require |
| Antivirus | Require |

Leave Actions for noncompliance at the default — **Mark device noncompliant: Immediately**.

On the Assignments tab, assign to **GRP-Devices-Windows** and click **Create**.

### Step 9 — Create a Security Configuration Profile

Configuration profiles push specific settings to devices. This profile applies the security baseline for a business environment and configures OneDrive Known Folder Move.

Navigate to **Devices → Configuration → Create → New policy → Windows 10 and later → Settings catalog**.

Name the profile `PROF-Security-Baseline-Windows`. On the Configuration settings tab, click **+ Add settings** and use the search box to find and add the following settings:

**Search: "Turn off Microsoft Defender Antivirus"**
Found under: Administrative Templates → Windows Components → Microsoft Defender Antivirus
- Turn off Microsoft Defender Antivirus: **Disabled** (this keeps Defender running — Disabled means the policy to turn it off is not applied)

**Search: "Allow real-time monitoring"**
Found under: Defender
- Allow Realtime Monitoring: **Allowed. Turns on and runs the real-time monitoring service**

**Search: "Allow Cortana above lock"**
Found under: Above Lock
- Allow Cortana Above Lock: **Block**

**Search: "Silently move Windows known folders to OneDrive"**
Found under: OneDrive
- Silently move Windows known folders to OneDrive: **Enabled**
- Show notification to users after folders have been redirected: **Yes**
- Tenant ID: `61ac0281-e32d-4a6f-a7d1-754f9ac66f5c`

On the Assignments tab, assign to **GRP-Devices-Windows** and click **Create**.

### Step 10 — Create Windows Update Rings

Update Rings control when devices receive Windows quality and feature updates. Two rings are used — a Pilot ring that receives updates immediately, and a Production ring that defers updates to allow time for Microsoft to identify and pull any problematic releases.

Navigate to **Devices → Windows → Manage updates → Windows update rings → Create profile**.

**Ring 1 — Pilot**

| Setting | Value |
|---|---|
| Name | RING-Windows-Pilot |
| Quality update deferral | 0 days |
| Feature update deferral | 0 days |
| Active hours start | 8 AM |
| Active hours end | 6 PM |
| Restart grace period | 2 days |

Assign to the admin account or a dedicated pilot group.

**Ring 2 — Production**

| Setting | Value |
|---|---|
| Name | RING-Windows-Production |
| Quality update deferral | 7 days |
| Feature update deferral | 30 days |
| Active hours start | 8 AM |
| Active hours end | 6 PM |
| Restart grace period | 5 days |

Assign to **GRP-AllStaff**.

Security patches reach production devices 7 days after release, and feature updates are held for 30 days — giving Microsoft time to pull any problematic updates before they reach the wider user base.

---

## What to Expect

Once enrolled, devices receive all configuration profiles and compliance policies automatically within 15 to 30 minutes. The IT team can see every managed device from the Intune portal, check compliance status, remotely wipe a lost device, and confirm patch status — all without needing physical access to the machine. OneDrive Known Folder Move runs silently in the background, redirecting Desktop, Documents, and Pictures to OneDrive without any user action required.

---

## Troubleshooting

**Device appears in Entra ID but not in Intune**
The MDM user scope is set to None. Navigate to Devices → Enrollment → Automatic Enrollment and set MDM user scope to All. Then trigger enrolment manually on the device using `Start-Process "ms-device-enrollment:?mode=mdm"` or by signing into the Company Portal app.

**No disks visible during Windows Setup**
The VirtIO storage driver is not loaded. Click Load driver and browse to the VirtIO CD drive at vioscsi → w11 → amd64. The disk will appear once the driver is loaded.

**No network connectivity after Windows installation**
The VirtIO network driver is not loaded. Open Device Manager, find the unknown network adapter, and update the driver from the VirtIO CD at NetKVM → w11 → amd64.

**Autopilot profile status shows "Not assigned"**
The profile has been created but not yet synced to the device. Click Sync on the Windows Autopilot devices page and wait a few minutes before refreshing. The profile assignment can take up to 15 minutes to reflect.

**Autopilot profile name rejected with "character not allowed"**
Autopilot deployment profile names do not accept hyphens. Use underscores instead — for example PROF_Autopilot_Corporate rather than PROF-Autopilot-Corporate.

**Device shows as "Personal" ownership in Intune**
The device was enrolled via Access work or school without being pre-registered in Autopilot. Devices enrolled this way are treated as personal BYOD devices. For corporate ownership, the hardware hash must be uploaded to Autopilot before enrolment so Intune can identify it as a corporate device.

**`Get-WindowsAutopilotInfo` fails with execution policy error**
Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force` before running the script.

**`dsregcmd /status` not recognised in PowerShell**
This command only works in Command Prompt (cmd.exe), not in PowerShell. Alternatively, confirm the Entra ID join status via Settings → Accounts → Access work or school, where the connection to QCB Homelab Consultants Entra ID will be displayed.

---

## Common Questions & Troubleshooting

**Q1: A device is enrolled in Intune but policies are not applying. The device shows in the portal but compliance is listed as "Not evaluated". What is happening?**

Intune policy application is not instant — after enrolment, allow 15 to 30 minutes for the initial policy push to complete. If it has been longer than 30 minutes, trigger a manual sync from the device: go to Settings → Accounts → Access work or school → click the work account → Info → Sync. If the device still shows "Not evaluated" after a sync, check whether the policies are assigned to a group that includes the device or the user, and confirm the device is showing as Entra ID joined (not just registered) using `dsregcmd /status` in Command Prompt.

**Q2: A compliance policy is assigned but some devices show as non-compliant for a setting that appears to be correctly configured. What should I check?**

Compliance is evaluated against the policy at the time of the last check-in — a device that was compliant yesterday may be non-compliant today if a setting drifted. Open the device in Intune Admin Center under Devices → [Device] → Device compliance and expand each policy to see exactly which setting is failing. Common causes include BitLocker reporting as not enabled if the encryption is still in progress, Defender reporting as inactive during an update, or a minimum OS version check failing after a delayed patch cycle.

**Q3: Windows Autopilot is configured but during OOBE the device does not automatically apply the Autopilot profile. The user is taken through the standard consumer setup instead. What went wrong?**

The hardware hash must be uploaded and the Autopilot profile assigned before the device first boots into OOBE. If the device has already been through OOBE, the Autopilot profile will not apply retrospectively during a normal startup — the device needs to be reset (Settings → System → Recovery → Reset this PC → Remove everything) to trigger OOBE again. Also confirm the profile is assigned to the device (not just in a pending state) in Intune Admin Center under Devices → Enrol devices → Windows Autopilot devices.

**Q4: Windows Update rings are configured but devices are still installing updates immediately rather than following the deferral period. Why?**

Update rings apply to Windows Update for Business, which governs feature and quality updates delivered through the standard Windows Update channel. If devices have a different update source configured — such as a WSUS server from a previous on-premises setup, or a registry key pointing to a different update server — the Intune ring settings will be overridden. Check the device's update source with `Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"` and remove any conflicting WSUS or update server settings.

**Q5: A device was wiped via Intune remote wipe but it is still appearing as enrolled in the Intune portal. How long does it take to disappear?**

After a remote wipe is initiated, the device must complete the wipe process and check back in to Intune before it is removed from the portal — which requires the device to be powered on and connected to the internet. A device that is offline will not process the wipe command until it comes online. Once the wipe completes and the device goes through OOBE again without being re-enrolled, it will be removed from Intune automatically. If you need to remove the device record immediately, you can delete it manually from the Devices list in the Intune Admin Center.

---
