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
