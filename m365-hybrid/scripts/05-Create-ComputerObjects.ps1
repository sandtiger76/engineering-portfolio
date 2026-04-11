# 05-Create-ComputerObjects.ps1
# Creates workstation objects for staff users
# No objects for contractors — BYOD/MAM only
# QCBHC-DC01 lives in OU=Domain Controllers — not touched here
# Idempotent — safe to run multiple times

Import-Module ActiveDirectory
$domain = "DC=qcbhomelab,DC=online"
$wsOU   = "OU=Workstations,OU=Devices,$domain"

$workstations = @(
    "WS-LDN-CARTER",
    "WS-LDN-BROWN",
    "WS-NYC-REED",
    "WS-NYC-MILLER",
    "WS-HKG-WONG",
    "WS-HKG-CHAN"
)

foreach ($name in $workstations) {
    if (Get-ADComputer -Filter "Name -eq '$name'" -ErrorAction SilentlyContinue) {
        Write-Host "EXISTS:   $name" -ForegroundColor Yellow
        continue
    }
    New-ADComputer -Name $name -SamAccountName $name -Path $wsOU -Enabled $true
    Write-Host "CREATED:  $name" -ForegroundColor Green
}

Write-Host "`nWorkstation objects complete." -ForegroundColor Cyan
