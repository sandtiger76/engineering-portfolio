# 03-Create-Groups.ps1
# Creates all security groups for QCB Homelab Consultants
# Idempotent — safe to run multiple times

Import-Module ActiveDirectory
$domain  = "DC=qcbhomelab,DC=online"
$groupOU = "OU=Groups,$domain"

$groups = @(
    # Location groups — GPO and Intune policy targeting for staff
    "GRP-Location-London",
    "GRP-Location-NewYork",
    "GRP-Location-HongKong",

    # Membership groups
    "GRP-AllStaff",
    "GRP-Contractors",

    # Licensing groups — drive group-based licence assignment in Entra ID
    "GRP-License-M365BusinessPremium",
    "GRP-License-M365Basic",

    # Device platform groups — Intune policy targeting
    "GRP-Devices-Windows",
    "GRP-Devices-iOS"
)

foreach ($g in $groups) {
    if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) {
        Write-Host "EXISTS:   $g" -ForegroundColor Yellow
        continue
    }
    New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $groupOU
    Write-Host "CREATED:  $g" -ForegroundColor Green
}

Write-Host "`nSecurity groups complete." -ForegroundColor Cyan
