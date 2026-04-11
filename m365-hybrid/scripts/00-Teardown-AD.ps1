# 00-Teardown-AD.ps1
# Removes all QCB Homelab AD objects so the provisioning scripts can be re-run cleanly.
# Handles both the current OU structure and any stale OUs from previous script versions.
# Run as Domain Admin on QCBHC-DC01.
# QCBHC-DC01 in OU=Domain Controllers is NOT touched.

Import-Module ActiveDirectory
$domain = "DC=qcbhomelab,DC=online"

Write-Host "`n=== QCB Homelab AD Teardown ===" -ForegroundColor Cyan
Write-Host "This will delete all QCB users, computers, groups, and OUs." -ForegroundColor Yellow
$confirm = Read-Host "Type YES to continue"
if ($confirm -ne "YES") {
    Write-Host "Aborted." -ForegroundColor Red
    exit
}

# -----------------------------------------------------------------------
# Step 1 — Remove workstation objects
# -----------------------------------------------------------------------
Write-Host "`n[1/5] Removing workstation objects..." -ForegroundColor Cyan

$workstations = @(
    "WS-LDN-CARTER","WS-LDN-BROWN",
    "WS-NYC-REED","WS-NYC-MILLER",
    "WS-HKG-WONG","WS-HKG-CHAN"
)

foreach ($name in $workstations) {
    $obj = Get-ADComputer -Filter "Name -eq '$name'" -ErrorAction SilentlyContinue
    if ($obj) {
        Remove-ADComputer -Identity $obj -Confirm:$false
        Write-Host "  REMOVED:    $name" -ForegroundColor Green
    } else {
        Write-Host "  NOT FOUND:  $name" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------
# Step 2 — Remove user accounts
# -----------------------------------------------------------------------
Write-Host "`n[2/5] Removing user accounts..." -ForegroundColor Cyan

$users = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan","a.hassan","p.novak")

foreach ($u in $users) {
    $obj = Get-ADUser -Filter "SamAccountName -eq '$u'" -ErrorAction SilentlyContinue
    if ($obj) {
        Remove-ADUser -Identity $obj -Confirm:$false
        Write-Host "  REMOVED:    $u" -ForegroundColor Green
    } else {
        Write-Host "  NOT FOUND:  $u" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------
# Step 3 — Remove security groups
# -----------------------------------------------------------------------
Write-Host "`n[3/5] Removing security groups..." -ForegroundColor Cyan

$groups = @(
    "GRP-Location-London","GRP-Location-NewYork","GRP-Location-HongKong",
    "GRP-AllStaff","GRP-Contractors",
    "GRP-License-M365BusinessPremium","GRP-License-M365Basic",
    "GRP-Devices-Windows","GRP-Devices-iOS"
)

foreach ($g in $groups) {
    $obj = Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue
    if ($obj) {
        Remove-ADGroup -Identity $obj -Confirm:$false
        Write-Host "  REMOVED:    $g" -ForegroundColor Green
    } else {
        Write-Host "  NOT FOUND:  $g" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------
# Step 4 — Remove current OUs (deepest first)
# -----------------------------------------------------------------------
Write-Host "`n[4/5] Removing current OUs..." -ForegroundColor Cyan

$currentOUs = @(
    # Staff location sub-OUs
    "OU=London,OU=Staff,OU=Accounts,$domain",
    "OU=NewYork,OU=Staff,OU=Accounts,$domain",
    "OU=HongKong,OU=Staff,OU=Accounts,$domain",

    # Accounts sub-OUs
    "OU=Staff,OU=Accounts,$domain",
    "OU=Contractors,OU=Accounts,$domain",

    # Devices sub-OUs
    "OU=Workstations,OU=Devices,$domain",

    # Root-level OUs
    "OU=Accounts,$domain",
    "OU=Devices,$domain",
    "OU=Groups,$domain",
    "OU=ServiceAccounts,$domain"
)

foreach ($ouDN in $currentOUs) {
    $obj = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue
    if ($obj) {
        Set-ADOrganizationalUnit -Identity $ouDN -ProtectedFromAccidentalDeletion $false
        Remove-ADOrganizationalUnit -Identity $ouDN -Confirm:$false
        Write-Host "  REMOVED:    $ouDN" -ForegroundColor Green
    } else {
        Write-Host "  NOT FOUND:  $ouDN" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------
# Step 5 — Remove any stale OUs from previous script versions
# -----------------------------------------------------------------------
Write-Host "`n[5/5] Removing stale OUs from previous versions..." -ForegroundColor Cyan

$staleOUs = @(
    # Old Users sub-OUs
    "OU=London,OU=Users,$domain",
    "OU=NewYork,OU=Users,$domain",
    "OU=HongKong,OU=Users,$domain",
    "OU=Home,OU=Users,$domain",
    "OU=Users,$domain",

    # Old QCB Users sub-OUs
    "OU=London,OU=QCB Users,$domain",
    "OU=NewYork,OU=QCB Users,$domain",
    "OU=HongKong,OU=QCB Users,$domain",
    "OU=Home,OU=QCB Users,$domain",
    "OU=QCB Users,$domain",

    # Old Workstations sub-OUs
    "OU=Home,OU=Workstations,$domain",
    "OU=London,OU=Workstations,$domain",
    "OU=NewYork,OU=Workstations,$domain",
    "OU=HongKong,OU=Workstations,$domain",
    "OU=Workstations,$domain",

    # Old Servers OUs
    "OU=London,OU=Servers,$domain",
    "OU=NewYork,OU=Servers,$domain",
    "OU=HongKong,OU=Servers,$domain",
    "OU=Servers,$domain"
)

foreach ($ouDN in $staleOUs) {
    $obj = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue
    if ($obj) {
        Set-ADOrganizationalUnit -Identity $ouDN -ProtectedFromAccidentalDeletion $false
        Remove-ADOrganizationalUnit -Identity $ouDN -Confirm:$false
        Write-Host "  REMOVED:    $ouDN" -ForegroundColor Green
    } else {
        Write-Host "  NOT FOUND:  $ouDN" -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
Write-Host "`n=== Teardown complete ===" -ForegroundColor Cyan
Write-Host "AD is clean. Run scripts 01 through 05 to rebuild." -ForegroundColor White
Write-Host "Note: QCBHC-DC01 in OU=Domain Controllers was not touched." -ForegroundColor DarkGray
