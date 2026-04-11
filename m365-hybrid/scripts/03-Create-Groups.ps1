# 03-Create-Groups.ps1 - Creates security groups for QCB Homelab Consultants

$domain  = "DC=qcbhomelab,DC=online"
$groupOU = "OU=Groups,$domain"

$groups = @(
    "GRP-Location-London", "GRP-Location-NewYork", "GRP-Location-HongKong", "GRP-Location-Home",
    "GRP-License-M365BusinessPremium",
    "GRP-Devices-Windows", "GRP-Devices-iOS",
    "GRP-AllStaff"
)

foreach ($g in $groups) {
    if (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue) {
        Write-Host "Exists: $g" -ForegroundColor Yellow
    } else {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $groupOU
        Write-Host "Created: $g" -ForegroundColor Green
    }
}
