# OFFBOARD-User.ps1
# Usage: .\OFFBOARD-User.ps1 -SamAccountName "j.carter"
# After running, complete the manual cloud steps listed at the end.

param([Parameter(Mandatory=$true)] [string]$SamAccountName)

$user = Get-ADUser -Identity $SamAccountName -Properties MemberOf -ErrorAction SilentlyContinue
if (-not $user) { Write-Host "ERROR: $SamAccountName not found." -ForegroundColor Red; exit 1 }

Write-Host "Offboarding: $($user.Name)" -ForegroundColor Yellow

Disable-ADAccount -Identity $SamAccountName
Write-Host "Account disabled." -ForegroundColor Green

$rnd = -join ((48..57) + (65..90) + (97..122) + (33..47) | Get-Random -Count 20 | ForEach-Object { [char]$_ })
Set-ADAccountPassword -Identity $SamAccountName -Reset -NewPassword (ConvertTo-SecureString $rnd -AsPlainText -Force)
Write-Host "Password randomised." -ForegroundColor Green

foreach ($g in $user.MemberOf) {
    try { Remove-ADGroupMember -Identity $g -Members $SamAccountName -Confirm:$false; Write-Host "Removed from: $g" -ForegroundColor Green }
    catch { Write-Host "Could not remove from: $g" -ForegroundColor Yellow }
}

Start-ADSyncSyncCycle -PolicyType Delta
Write-Host "Entra sync triggered." -ForegroundColor Green

Write-Host ""
Write-Host "AD offboarding complete for $($user.Name)" -ForegroundColor Green
Write-Host ""
Write-Host "MANUAL STEPS REQUIRED:" -ForegroundColor Yellow
Write-Host "  1. Entra Admin Center  - Revoke all sessions for this user" -ForegroundColor White
Write-Host "  2. Intune              - Remote wipe corporate Windows device" -ForegroundColor White
Write-Host "  3. Intune              - Wipe org data from personal iOS device" -ForegroundColor White
Write-Host "  4. Exchange Admin      - Convert mailbox to shared or export data" -ForegroundColor White
Write-Host "  5. Entra Admin Center  - Remove M365 licence" -ForegroundColor White
Write-Host "  6. Schedule            - Delete AD account after 30-day retention" -ForegroundColor White
