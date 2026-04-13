[← 11 — Defender for Business](11-defender.md) &nbsp;|&nbsp; [🏠 README](../README.md)

---

# 12 — User Lifecycle: Onboarding & Offboarding

## Overview — What This Document Covers

Two of the most operationally important moments in any organisation's IT are when someone joins and when someone leaves. Get onboarding wrong and a new employee's first day is spent waiting for access rather than being productive. Get offboarding wrong and a former employee may still be able to access company email, files, and systems long after they have left — which is both a security risk and a potential compliance issue.

In a hybrid environment like this one, both processes involve multiple layers: the on-premises directory, the cloud identity, email and licences, device management, and active login sessions. None of these are automatically connected — each layer has to be handled in the right order.

This document defines the standard procedures for both processes and provides PowerShell scripts to handle the repetitive steps consistently. A process that is scripted and documented is one that can be followed correctly every time, by anyone, under pressure — which is exactly what good operational practice looks like.

---

## Introduction

One of the most operationally important processes in any IT environment is user lifecycle management — what happens when someone joins the organisation, and what happens when they leave. Done well, onboarding means a new employee has everything they need from day one: an account, a device, access to the right systems, and a working email address. Done poorly, it means their first day is spent waiting for IT to sort things out.

Offboarding is equally critical, and the consequences of doing it badly are more serious. When someone leaves — whether on good terms or not — their access must be revoked promptly and completely. A former employee who can still access company email, files, or systems is a significant security and data risk. In a hybrid environment like this one, offboarding is not just about disabling one account — it means working through multiple layers: Active Directory, Entra ID, Microsoft 365 licences, device management, and active sessions.

This document defines the standard procedures for both processes, with PowerShell scripts to handle the repetitive steps consistently.

---

## Onboarding

### What We Are Doing

When a new user joins, the following must be completed:

1. Create AD account in the correct OU and add to correct groups
2. Sync to Entra ID
3. Assign Microsoft 365 licence via group membership
4. Configure shared mailbox access if required
5. For staff: prepare and enrol the corporate Windows device
6. For contractors: no corporate device — confirm MAM policy applies when they sign into Outlook and Teams on their personal iPhone
7. Communicate credentials to the user securely

### Onboarding Script

Save the following as `ONBOARD-NewUser.ps1` and run it on QCBHC-DC01 when a new user joins.

The script handles both staff and contractor onboarding. Staff are placed in their office location OU and receive a Business Premium licence. Contractors are placed in `OU=Contractors` and receive a Business Basic licence with no Intune MDM enrolment.

```powershell
# ONBOARD-NewUser.ps1
# Creates a new user account and adds them to the correct groups
# Supports both staff (London, NewYork, HongKong) and contractors (Remote)
# Run as Domain Admin on QCBHC-DC01

param(
    [Parameter(Mandatory=$true)] [string]$FirstName,
    [Parameter(Mandatory=$true)] [string]$LastName,
    [Parameter(Mandatory=$true)] [ValidateSet("London","NewYork","HongKong","Remote")] [string]$Office,
    [Parameter(Mandatory=$true)] [ValidateSet("Consulting","Contractor")] [string]$Department
)

Import-Module ActiveDirectory
$domain    = "DC=qcbhomelab,DC=online"
$upnSuffix = "@qcbhomelab.online"
$sam       = ($FirstName[0] + "." + $LastName).ToLower()
$upn       = $sam + $upnSuffix
$display   = "$FirstName $LastName"
$tempPwd   = ConvertTo-SecureString "Welcome2024!" -AsPlainText -Force

# Determine OU path and group assignments based on user type
if ($Department -eq "Contractor") {
    $ouPath = "OU=Contractors,OU=Accounts,$domain"
    $groups = @(
        "GRP-Contractors",
        "GRP-License-M365Basic"
    )
} else {
    $ouPath = "OU=$Office,OU=Staff,OU=Accounts,$domain"
    $groups = @(
        "GRP-AllStaff",
        "GRP-License-M365BusinessPremium",
        "GRP-Location-$Office"
    )
}

# Check for duplicate
if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
    Write-Host "ERROR: User $sam already exists. Check for duplicate names." -ForegroundColor Red
    exit 1
}

# Create the account
New-ADUser `
    -GivenName            $FirstName `
    -Surname              $LastName `
    -Name                 $display `
    -DisplayName          $display `
    -SamAccountName       $sam `
    -UserPrincipalName    $upn `
    -Path                 $ouPath `
    -Department           $Department `
    -Office               $Office `
    -AccountPassword      $tempPwd `
    -Enabled              $true `
    -ChangePasswordAtLogon $true

Write-Host "CREATED: $upn [$Department]" -ForegroundColor Green

# Add to groups
foreach ($g in $groups) {
    Add-ADGroupMember -Identity $g -Members $sam
    Write-Host "ADDED:   $sam → $g" -ForegroundColor Green
}

# Trigger sync to Entra ID
Write-Host "Triggering Entra Connect sync..." -ForegroundColor Cyan
Start-ADSyncSyncCycle -PolicyType Delta

Write-Host ""
Write-Host "Onboarding complete for $display" -ForegroundColor Green
Write-Host "UPN:           $upn" -ForegroundColor White
Write-Host "Type:          $Department" -ForegroundColor White
Write-Host "Temp password: Welcome2024!" -ForegroundColor White
if ($Department -eq "Contractor") {
    Write-Host "Action: Communicate credentials. No corporate device — user accesses M365 via personal device and MAM policy." -ForegroundColor Yellow
} else {
    Write-Host "Action: Communicate credentials and arrange corporate device setup." -ForegroundColor Yellow
}
```

### Device Setup

**Staff — Corporate Windows device:**

Once the account is ready and the user's Windows device is available:

1. Start the device and proceed through the Windows Out of Box Experience (OOBE)
2. When prompted to sign in, select Set up for work or school
3. Enter the user's UPN (e.g. j.carter@qcbhomelab.online)
4. Complete MFA registration when prompted
5. The device will join Entra ID and enrol in Intune automatically
6. Intune will apply all policies within 15 to 30 minutes — compliance settings, OneDrive Known Folder Move, and Defender configuration are all applied silently

**Contractors — Personal device (BYOD):**

Contractors have no corporate device. Their access is governed entirely by the iOS MAM policy configured in document 09:

1. The contractor installs Outlook, Teams, and OneDrive from the App Store on their personal iPhone
2. They sign in with their work account (e.g. a.hassan@qcbhomelab.online)
3. The MAM policy is applied automatically — they will be prompted to set a PIN
4. Company data is isolated within managed apps — no MDM enrolment of the personal device occurs

---

## Offboarding

### What We Are Doing

When a user leaves, the following must be completed in order:

1. Disable the AD account immediately
2. Revoke all active Entra ID sessions
3. Reset the account password (prevents any cached credential use)
4. Remove from all security groups
5. Convert mailbox to shared or export and delete
6. Remove Microsoft 365 licence
7. Initiate Intune remote wipe on corporate device
8. Wipe company data from personal iOS device
9. Disable and eventually delete the AD account after the retention period

### Offboarding Script

Save the following as `OFFBOARD-User.ps1` and run it on QCBHC-DC01 when a user leaves.

```powershell
# OFFBOARD-User.ps1
# Disables a departing user and removes their access
# Run as Domain Admin on QCBHC-DC01
# Complete cloud steps manually in Entra Admin Center and Intune after running this

param(
    [Parameter(Mandatory=$true)] [string]$SamAccountName
)

$user = Get-ADUser -Identity $SamAccountName -Properties MemberOf -ErrorAction SilentlyContinue

if (-not $user) {
    Write-Host "ERROR: User $SamAccountName not found in Active Directory." -ForegroundColor Red
    exit 1
}

Write-Host "Starting offboarding for: $($user.Name)" -ForegroundColor Yellow

# Step 1 — Disable the account
Disable-ADAccount -Identity $SamAccountName
Write-Host "AD account disabled." -ForegroundColor Green

# Step 2 — Reset the password to a random value
$randomPwd = [System.Web.Security.Membership]::GeneratePassword(20, 5)
Set-ADAccountPassword -Identity $SamAccountName -Reset -NewPassword (ConvertTo-SecureString $randomPwd -AsPlainText -Force)
Write-Host "Password reset to random value." -ForegroundColor Green

# Step 3 — Remove from all groups except Domain Users
$groups = $user.MemberOf
foreach ($g in $groups) {
    try {
        Remove-ADGroupMember -Identity $g -Members $SamAccountName -Confirm:$false
        Write-Host "Removed from group: $g" -ForegroundColor Green
    } catch {
        Write-Host "Could not remove from: $g" -ForegroundColor Yellow
    }
}

# Step 4 — Move to a Disabled accounts OU to keep AD tidy (optional)
# Uncomment the line below — create OU=Disabled,OU=Accounts first if using this
# Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Disabled,OU=Accounts,DC=qcbhomelab,DC=online"

# Step 5 — Trigger sync to push changes to Entra ID
Start-ADSyncSyncCycle -PolicyType Delta
Write-Host "Entra Connect sync triggered." -ForegroundColor Green

Write-Host ""
Write-Host "AD offboarding complete for $($user.Name)" -ForegroundColor Green
Write-Host ""
Write-Host "MANUAL STEPS STILL REQUIRED:" -ForegroundColor Yellow
Write-Host "  1. Entra Admin Center — Revoke all sessions for this user" -ForegroundColor White
Write-Host "  2. Intune — Remote wipe corporate Windows device" -ForegroundColor White
Write-Host "  3. Intune — Wipe org data from personal iOS device" -ForegroundColor White
Write-Host "  4. Exchange Admin Center — Convert mailbox to shared or export data" -ForegroundColor White
Write-Host "  5. Remove M365 licence from user in Entra Admin Center" -ForegroundColor White
Write-Host "  6. Schedule AD account deletion after 30-day retention period" -ForegroundColor White
```

### Cloud Steps (Complete Manually After Running the Script)

**Revoke Entra ID Sessions:**
Entra Admin Center → Users → [User] → Revoke sessions. This immediately invalidates all active tokens, including any browser sessions, Outlook connections, and Teams sign-ins across all devices.

**Remote Wipe — Corporate Windows Device:**
Intune Admin Center → Devices → [Device] → Wipe. This performs a full factory reset of the device, removing all data and re-preparing it for the next user.

**Wipe Organisation Data — Personal iOS Device:**
Intune Admin Center → Users → [User] → Devices → [iOS Device] → Wipe → Wipe only organisation data. The user's personal data is untouched.

**Mailbox Handling:**
Exchange Admin Center → Recipients → [User] → Convert to shared mailbox if the account needs to remain accessible. Assign the manager or team lead as a delegate. Remove the licence from the user — a shared mailbox does not require a licence.

---

## What to Expect

A well-executed onboarding means a new user is productive from their first hour. A well-executed offboarding means a departing user has zero access within minutes of the process starting. Both procedures are consistent, documented, and auditable — which is exactly what a security-conscious organisation needs.

---

## Common Questions & Troubleshooting

**Q1: The onboarding script ran successfully and the user account was created in AD, but the account is not appearing in Entra ID after the sync cycle. What should I check?**

First confirm the user was created in an OU that is within the Cloud Sync scope — accounts created outside the scoped OUs will not synchronise regardless of how long you wait. Run `Get-ADUser -Identity <samaccountname> -Properties DistinguishedName` to confirm the account's location. If the OU is correct, trigger a manual delta sync with `Start-ADSyncSyncCycle -PolicyType Delta` on DC01 and wait 2–3 minutes. If the account still does not appear, check the Cloud Sync agent health in Entra Admin Center under Identity → Hybrid management → Cloud sync.

**Q2: During offboarding, the script disabled the AD account and triggered a sync, but the user's Entra ID account still shows as enabled and they can still sign in. What is happening?**

AD account disable synchronises to Entra ID, but it does not immediately revoke active session tokens. A user with a valid token can continue to access services until that token expires — which can be up to an hour for standard tokens. To cut access immediately, the Entra ID session revocation must be done manually and separately from the AD disable: in the Entra Admin Center go to Users → [User] → Revoke sessions. This invalidates all active tokens immediately. This step is called out explicitly in the offboarding script output as a required manual action.

**Q3: A user's mailbox needs to be preserved after they leave but their licence has already been removed. Now the mailbox has disappeared. How can it be recovered?**

When a licence is removed, the mailbox enters a soft-delete state and is retained for 30 days before being permanently deleted. To recover it, reassign the licence temporarily, convert the mailbox to a shared mailbox (which does not require a licence), then remove the licence again. The shared mailbox will persist without a licence indefinitely as long as it is under 50GB. If the 30-day window has passed, the mailbox data may still be recoverable through the Microsoft 365 compliance centre using Content Search, depending on your retention policies.

**Q4: A new user went through Windows Autopilot OOBE but the device is showing as non-compliant in Intune immediately after enrolment. Should this be addressed before handing the device to the user?**

This is normal immediately after enrolment — compliance policies need time to evaluate after the device first checks in, and some settings (particularly BitLocker encryption) take time to complete on first boot. Allow 30–60 minutes after enrolment for the device to reach a compliant state. If the device is still non-compliant after an hour, open it in Intune Admin Center under Devices → [Device] → Device compliance to see exactly which setting is failing and address that specific issue before issuing the device. Handing out a non-compliant device means Conditional Access will block the user from M365 apps, which makes for a poor first day.

**Q5: During offboarding, the remote wipe command was sent to a corporate Windows laptop but the device was offline. How is this tracked and what happens when it comes back online?**

Intune queues the wipe command and delivers it the next time the device connects to the internet and checks in with Intune. The wipe status in Intune Admin Center will show as "Pending" until the device receives and executes the command. For devices that may not come back online (for example, a laptop taken by a departing employee), the pending wipe provides protection if the device ever connects to any network — it does not require the company's network specifically. In the meantime, the combination of disabled AD account, revoked Entra ID sessions, and removed licence means the device cannot be used to access any company data even while the wipe is pending.

---
