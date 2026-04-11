# 04-Add-GroupMembers.ps1
# Assigns users to location, membership, and licensing groups
# Idempotent — safe to run multiple times

Import-Module ActiveDirectory

$members = @(
    # Staff location groups
    @{ Group = "GRP-Location-London";             Users = @("j.carter","o.brown") },
    @{ Group = "GRP-Location-NewYork";            Users = @("m.reed","s.miller") },
    @{ Group = "GRP-Location-HongKong";           Users = @("d.wong","e.chan") },

    # Staff membership and licensing
    @{ Group = "GRP-AllStaff";                    Users = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan") },
    @{ Group = "GRP-License-M365BusinessPremium"; Users = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan") },

    # Contractor membership and licensing
    @{ Group = "GRP-Contractors";                 Users = @("a.hassan","p.novak") },
    @{ Group = "GRP-License-M365Basic";           Users = @("a.hassan","p.novak") }
)

foreach ($entry in $members) {
    foreach ($user in $entry.Users) {
        try {
            Add-ADGroupMember -Identity $entry.Group -Members $user -ErrorAction Stop
            Write-Host "ADDED:    $user → $($entry.Group)" -ForegroundColor Green
        }
        catch [Microsoft.ActiveDirectory.Management.ADException] {
            Write-Host "EXISTS:   $user in $($entry.Group)" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nGroup membership complete." -ForegroundColor Cyan
