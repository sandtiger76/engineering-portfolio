# 01-Create-OUs.ps1
# Creates the full OU structure for QCB Homelab Consultants
# Idempotent — safe to run multiple times

Import-Module ActiveDirectory
$domain = "DC=qcbhomelab,DC=online"

$ous = @(
    # Root-level OUs
    @{ Name = "Accounts";        Path = $domain },
    @{ Name = "Devices";         Path = $domain },
    @{ Name = "Groups";          Path = $domain },
    @{ Name = "ServiceAccounts"; Path = $domain },

    # Accounts sub-OUs
    @{ Name = "Staff";       Path = "OU=Accounts,$domain" },
    @{ Name = "Contractors"; Path = "OU=Accounts,$domain" },

    # Staff location sub-OUs
    @{ Name = "London";   Path = "OU=Staff,OU=Accounts,$domain" },
    @{ Name = "NewYork";  Path = "OU=Staff,OU=Accounts,$domain" },
    @{ Name = "HongKong"; Path = "OU=Staff,OU=Accounts,$domain" },

    # Devices sub-OUs
    @{ Name = "Workstations"; Path = "OU=Devices,$domain" }
)

foreach ($ou in $ous) {
    $ouDN = "OU=$($ou.Name),$($ou.Path)"
    try {
        Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction Stop | Out-Null
        Write-Host "EXISTS:   $ouDN" -ForegroundColor Yellow
    }
    catch {
        try {
            New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path -ProtectedFromAccidentalDeletion $true
            Write-Host "CREATED:  $ouDN" -ForegroundColor Green
        }
        catch {
            Write-Host "FAILED:   $ouDN — $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`nOU structure complete." -ForegroundColor Cyan
