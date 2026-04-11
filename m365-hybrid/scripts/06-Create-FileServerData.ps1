# 06-Create-FileServerData.ps1 - Simulates legacy file server data for migration

$users     = @("j.carter","o.brown","m.reed","s.miller","d.wong","e.chan")
$locations = @("London","NewYork","HongKong")

foreach ($user in $users) {
    $path = "C:\Data\Home\$user"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    "Sample notes for $user."   | Out-File "$path\My Notes.txt"
    "Financial summary Q1 2024" | Out-File "$path\Q1 Summary.txt"
    New-Item -ItemType Directory -Path "$path\Projects" -Force | Out-Null
    "Project Alpha notes"        | Out-File "$path\Projects\Project Alpha.txt"
    Write-Host "Created home folder: $user" -ForegroundColor Green
}

foreach ($loc in $locations) {
    $path = "C:\Data\Group\$loc"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    "Team policies for $loc"  | Out-File "$path\Team Policies.txt"
    "$loc office procedures"  | Out-File "$path\Office Procedures.txt"
    New-Item -ItemType Directory -Path "$path\Shared Projects" -Force | Out-Null
    Write-Host "Created shared folder: $loc" -ForegroundColor Green
}
