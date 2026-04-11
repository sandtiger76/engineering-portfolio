# 05-Create-ComputerObjects.ps1 - Creates workstation and server objects

$domain = "DC=qcbhomelab,DC=online"

$computers = @(
    @{ Name = "WS-LDN-CARTER"; OU = "OU=London,OU=Workstations,$domain" },
    @{ Name = "WS-LDN-BROWN";  OU = "OU=London,OU=Workstations,$domain" },
    @{ Name = "WS-NYC-REED";   OU = "OU=NewYork,OU=Workstations,$domain" },
    @{ Name = "WS-NYC-MILLER"; OU = "OU=NewYork,OU=Workstations,$domain" },
    @{ Name = "WS-HKG-WONG";   OU = "OU=HongKong,OU=Workstations,$domain" },
    @{ Name = "WS-HKG-CHAN";   OU = "OU=HongKong,OU=Workstations,$domain" },
    @{ Name = "QCBHC-DC01";    OU = "OU=London,OU=Servers,$domain" }
)

foreach ($c in $computers) {
    if (Get-ADComputer -Filter "Name -eq '$($c.Name)'" -ErrorAction SilentlyContinue) {
        Write-Host "Exists: $($c.Name)" -ForegroundColor Yellow
    } else {
        New-ADComputer -Name $c.Name -Path $c.OU -Enabled $true
        Write-Host "Created: $($c.Name)" -ForegroundColor Green
    }
}
