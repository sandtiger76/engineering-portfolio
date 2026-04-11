# 01-Create-OUs.ps1 - Creates the full OU structure for QCB Homelab Consultants
# Idempotent - safe to run multiple times. Run as Domain Admin on QCBHC-DC01.

$domain = "DC=qcbhomelab,DC=online"

$ous = @(
    @{ Name = "Users";           Path = $domain },
    @{ Name = "Workstations";    Path = $domain },
    @{ Name = "Servers";         Path = $domain },
    @{ Name = "Groups";          Path = $domain },
    @{ Name = "ServiceAccounts"; Path = $domain },
    @{ Name = "London";   Path = "OU=Users,$domain" },
    @{ Name = "NewYork";  Path = "OU=Users,$domain" },
    @{ Name = "HongKong"; Path = "OU=Users,$domain" },
    @{ Name = "Home";     Path = "OU=Users,$domain" },
    @{ Name = "London";   Path = "OU=Workstations,$domain" },
    @{ Name = "NewYork";  Path = "OU=Workstations,$domain" },
    @{ Name = "HongKong"; Path = "OU=Workstations,$domain" },
    @{ Name = "Home";     Path = "OU=Workstations,$domain" },
    @{ Name = "London";   Path = "OU=Servers,$domain" },
    @{ Name = "NewYork";  Path = "OU=Servers,$domain" },
    @{ Name = "HongKong"; Path = "OU=Servers,$domain" }
)

foreach ($ou in $ous) {
    $exists = Get-ADOrganizationalUnit -Filter "Name -eq '$($ou.Name)'" -SearchBase $ou.Path -SearchScope OneLevel -ErrorAction SilentlyContinue
    if (-not $exists) {
        New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path
        Write-Host "Created: $($ou.Name) in $($ou.Path)" -ForegroundColor Green
    } else {
        Write-Host "Exists:  $($ou.Name)" -ForegroundColor Yellow
    }
}
