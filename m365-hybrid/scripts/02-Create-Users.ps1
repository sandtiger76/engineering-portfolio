# 02-Create-Users.ps1 - Creates all user accounts for QCB Homelab Consultants

$domain    = "DC=qcbhomelab,DC=online"
$upnSuffix = "@qcbhomelab.online"
$pwd       = ConvertTo-SecureString "Welcome2024!" -AsPlainText -Force

$users = @(
    @{ First="James";   Last="Carter"; Office="London";    OU="OU=London,OU=Users,$domain";   Dept="Consulting" },
    @{ First="Olivia";  Last="Brown";  Office="London";    OU="OU=London,OU=Users,$domain";   Dept="Consulting" },
    @{ First="Michael"; Last="Reed";   Office="New York";  OU="OU=NewYork,OU=Users,$domain";  Dept="Consulting" },
    @{ First="Sophia";  Last="Miller"; Office="New York";  OU="OU=NewYork,OU=Users,$domain";  Dept="Consulting" },
    @{ First="Daniel";  Last="Wong";   Office="Hong Kong"; OU="OU=HongKong,OU=Users,$domain"; Dept="Consulting" },
    @{ First="Emily";   Last="Chan";   Office="Hong Kong"; OU="OU=HongKong,OU=Users,$domain"; Dept="Consulting" }
)

foreach ($u in $users) {
    $sam     = ($u.First[0] + "." + $u.Last).ToLower()
    $upn     = $sam + $upnSuffix
    $display = "$($u.First) $($u.Last)"

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        Write-Host "Exists: $sam" -ForegroundColor Yellow
        continue
    }
    New-ADUser -GivenName $u.First -Surname $u.Last -Name $display -DisplayName $display `
        -SamAccountName $sam -UserPrincipalName $upn -Path $u.OU `
        -Department $u.Dept -Office $u.Office -AccountPassword $pwd `
        -Enabled $true -ChangePasswordAtLogon $true
    Write-Host "Created: $upn" -ForegroundColor Green
}
