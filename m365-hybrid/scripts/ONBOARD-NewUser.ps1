# ONBOARD-NewUser.ps1
# Usage: .\ONBOARD-NewUser.ps1 -FirstName "Jane" -LastName "Smith" -Office "London" -Department "Consulting"

param(
    [Parameter(Mandatory=$true)] [string]$FirstName,
    [Parameter(Mandatory=$true)] [string]$LastName,
    [Parameter(Mandatory=$true)] [ValidateSet("London","NewYork","HongKong","Home")] [string]$Office,
    [Parameter(Mandatory=$true)] [string]$Department
)

$domain = "DC=qcbhomelab,DC=online"
$sam    = ($FirstName[0] + "." + $LastName).ToLower()
$upn    = $sam + "@qcbhomelab.online"
$ouPath = "OU=$Office,OU=Users,$domain"

if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
    Write-Host "ERROR: $sam already exists. Check for duplicate names." -ForegroundColor Red; exit 1
}

New-ADUser -GivenName $FirstName -Surname $LastName -Name "$FirstName $LastName" -DisplayName "$FirstName $LastName" `
    -SamAccountName $sam -UserPrincipalName $upn -Path $ouPath `
    -Department $Department -Office $Office `
    -AccountPassword (ConvertTo-SecureString "Welcome2024!" -AsPlainText -Force) `
    -Enabled $true -ChangePasswordAtLogon $true

Write-Host "Created: $upn" -ForegroundColor Green

foreach ($g in @("GRP-AllStaff","GRP-License-M365BusinessPremium","GRP-Location-$Office")) {
    Add-ADGroupMember -Identity $g -Members $sam
    Write-Host "Added to: $g" -ForegroundColor Green
}

Start-ADSyncSyncCycle -PolicyType Delta

Write-Host ""
Write-Host "Onboarding complete: $FirstName $LastName" -ForegroundColor Green
Write-Host "UPN: $upn  |  Temp password: Welcome2024!" -ForegroundColor White
Write-Host "Action: Communicate credentials securely and arrange device setup." -ForegroundColor Yellow
