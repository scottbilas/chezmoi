#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# UPGRADES

## Chezmoi

# chezmoi update << do safely

## Posh

if ((Get-PSRepository PSGallery).InstallationPolicy -ne 'Trusted') {
    Write-Output "[posh] Trusting PSGallery..."
    Set-PSRepository PSGallery -InstallationPolicy Trusted
}

## PSDepend

Write-Output "[posh] Pulling module dependencies..."
Import-Module PSDepend
Invoke-PSDepend -Force $PSScriptRoot

## Upgrade to Shovel

Write-Output "[scoop] Upgrading to shovel..."
Invoke-Exe 'scoop config SCOOP_REPO https://github.com/Ash258/Scoop-Core'
Invoke-Exe 'scoop config SCOOP_BRANCH main'
Invoke-Exe 'scoop config show_update_log false'
Invoke-Exe 'scoop update scoop'

# CHECKS

# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$badPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($badPaths) {
    Write-Error "PATH is invalid: $(($badPaths | ForEach-Object { "'$_'" }) -Join ', ')"
}
