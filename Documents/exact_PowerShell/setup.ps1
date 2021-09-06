#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TODO: make param
$Upgrade = $false

# UPGRADES

## Chezmoi

# chezmoi update << do safely

## Posh

# ! this must come before we pull in modules

if ((Get-PSRepository PSGallery).InstallationPolicy -ne 'Trusted') {
    Write-Output "[posh] Trusting PSGallery..."
    Set-PSRepository PSGallery -InstallationPolicy Trusted
}

## PSDepend

# ! this must come as early as possible so as to pick up `native` for `iee` etc.

$invokePSDepend = $Upgrade
if (!$invokePSDepend) {
    $missingPSModules = (Import-PowerShellDataFile ~\Documents\PowerShell\requirements.psd1).Keys |
        Where-Object { $_ -ne 'PSDependOptions' } |
        Where-Object { !(Test-Path ~\Documents\PowerShell\Modules\$_) }
    if ($missingPSModules) {
        Write-Output "[posh] Missing modules: $($missingPSModules -join ', ')"
        $invokePSDepend = $true
    }
}

if ($invokePSDepend) {
    Write-Output "[posh] Pulling module dependencies..."
    Invoke-PSDepend -Force $PSScriptRoot
}

## Scoop

if ((iee scoop config show_update_log) -match 'not set') {
    iee scoop config show_update_log false
}

## Shovel

if ((scoop config SCOOP_REPO) -ne 'https://github.com/Ash258/Scoop-Core') {
    Write-Output "[scoop] Upgrading to shovel..."
    iee scoop config SCOOP_REPO https://github.com/Ash258/Scoop-Core
    iee scoop config SCOOP_BRANCH main
    iee scoop config rm lastupdate | Out-Null
    iee scoop update
}

# CHECKS

# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$badPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($badPaths) {
    Write-Error "PATH is invalid: $(($badPaths | ForEach-Object { "'$_'" }) -Join ', ')"
}
