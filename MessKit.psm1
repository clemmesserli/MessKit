[cmdletbinding()]
Param ()

Set-Location -Path $PSScriptRoot

if (Test-Path -Path "$PSScriptRoot\functions") {
    Get-ChildItem -Recurse -Path $PSScriptRoot\functions\*.ps1 -Exclude '*.Tests.ps1' | ForEach-Object -Process {
        . $_.FullName
    }
}