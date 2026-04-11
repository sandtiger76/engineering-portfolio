# 02-Create-Users.ps1
# Creates all staff and contractor accounts for QCB Homelab Consultants
# Idempotent — safe to run multiple times

Import-Module ActiveDirectory
$domain     = "DC=qcbhomelab,DC=online"
$upnSuffix  = "@qcbhomelab.online"
$defaultPwd = ConvertTo-SecureString "Welcome2024!" -AsPlainText -Force

$users = @(
    # Staff — placed in their office location OU under OU=Staff
    @{ First="James";  Last="Carter"; Office="London";    OU="OU=London,OU=Staff,OU=Accounts,$domain";   Dept="Consulting" },
    @{ First="Olivia"; Last="Brown";  Office="London";    OU="OU=London,OU=Staff,OU=Accounts,$domain";   Dept="Consulting" },
    @{ First="Michael";Last="Reed";   Office="New York";  OU="OU=NewYork,OU=Staff,OU=Accounts,$domain";  Dept="Consulting" },
    @{ First="Sophia"; Last="Miller"; Office="New York";  OU="OU=NewYork,OU=Staff,OU=Accounts,$domain";  Dept="Consulting" },
    @{ First="Daniel"; Last="Wong";   Office="Hong Kong"; OU="OU=HongKong,OU=Staff,OU=Accounts,$domain"; Dept="Consulting" },
    @{ First="Emily";  Last="Chan";   Office="Hong Kong"; OU="OU=HongKong,OU=Staff,OU=Accounts,$domain"; Dept="Consulting" },

    # Contractors — flat in OU=Contractors, no location sub-OU
    @{ First="Amir";  Last="Hassan"; Office="Remote"; OU="OU=Contractors,OU=Accounts,$domain"; Dept="Contractor" },
    @{ First="Petra"; Last="Novak";  Office="Remote"; OU="OU=Contractors,OU=Accounts,$domain"; Dept="Contractor" }
)

foreach ($u in $users) {
    $sam     = ($u.First[0] + "." + $u.Last).ToLower()
    $upn     = $sam + $upnSuffix
    $display = "$($u.First) $($u.Last)"

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Host "EXISTS:   $sam" -ForegroundColor Yellow
        continue
    }

    New-ADUser `
        -GivenName             $u.First `
        -Surname               $u.Last `
        -Name                  $display `
        -DisplayName           $display `
        -SamAccountName        $sam `
        -UserPrincipalName     $upn `
        -Path                  $u.OU `
        -Department            $u.Dept `
        -Office                $u.Office `
        -AccountPassword       $defaultPwd `
        -Enabled               $true `
        -ChangePasswordAtLogon $true

    Write-Host "CREATED:  $upn [$($u.Dept)]" -ForegroundColor Green
}

Write-Host "`nUser accounts complete." -ForegroundColor Cyan
