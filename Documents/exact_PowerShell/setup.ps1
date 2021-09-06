#Requires -Version 7

[CmdletBinding()]
param (
    [switch]$Upgrade
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

## Chezmoi

# chezmoi update << do safely

## Posh

# ! this must come before we pull in modules

if ((Get-PSRepository PSGallery).InstallationPolicy -ne 'Trusted') {
    Write-Output '[posh] Trusting PSGallery...'
    Set-PSRepository PSGallery -InstallationPolicy Trusted
}
else {
    Write-Output '[posh] PSGallery ok'
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
    Write-Output '[posh] Pulling modules...'
    Invoke-PSDepend -Force $PSScriptRoot
}
else {
    Write-Output '[posh] Modules ok'
}

## Scoop pre

if ((iee scoop config show_update_log) -match 'not set') {
    iee scoop config show_update_log false
}
else {
    Write-Output '[scoop] Config ok'
}

## Shovel

if ((scoop config SCOOP_REPO) -ne 'https://github.com/Ash258/Scoop-Core') {
    Write-Output '[scoop] Upgrading to Shovel...'
    iee scoop config SCOOP_REPO https://github.com/Ash258/Scoop-Core
    iee scoop config SCOOP_BRANCH main
    iee scoop update
}
else {
    Write-Output '[scoop] Shovel ok'
}

## Scoop buckets

if ($Upgrade) {
    Write-Output '[scoop] Updating buckets'
    iee scoop update
}

$buckets = iee scoop bucket

function addBucket([string]$name, [string]$url = $null) {
    if ($buckets -notcontains $name) { iee scoop bucket add $name $url }
}

addBucket extras
addBucket github-gh https://github.com/cli/scoop-gh.git
addBucket nerd-fonts
addBucket nirsoft
addBucket nonportable
addBucket twpayne https://github.com/twpayne/scoop-bucket

Write-Output '[scoop] Bucket presence ok'

## Scoop core

$packages = (Get-ChildItem ~/scoop/apps).Name

function addPackage([string]$name, [switch]$sudo) {
    if ($packages -notcontains $install) {
        if ($sudo) {
            sudo ie scoop install $install
        }
        else {
            ie scoop install $install
        }
    }
}

foreach ($install in @(
        # stuff shovel wants
        'dark', 'innounp', 'lessmsi'
        # shell stuff
        'busybox', 'less', 'which', 'echoargs', 'wget', 'lz4'
        # other core utils
        'ripgrep', 'kalk', '7zip', 'autohotkey', 'fd', 'gsudo', 'chezmoi', 'git'
    )) {
    addPackage($install)
}

# special note on fonts: avoid packages with "mono" in the name - these lose ligatures ("nerd font policy")
addPackage -sudo CascadiaCode-NF
addPackage -sudo JetBrainsMono-NF

<#
# each of these requires special setup

barrier-np
everything
gh
syncthingtray

7tt
linqpad
micro
nodejs
paint.net
sysinternals
tailblazer
vscode-portable
vcxsrv
windirstat

perl
python
go
rust

unity-downloader-cli
#>

Write-Output '[scoop] Core packages ok'

# CHECKS

# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$badPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($badPaths) {
    Write-Error "PATH is invalid: $(($badPaths | ForEach-Object { "'$_'" }) -Join ', ')"
}
else {
    Write-Output '[scoop] PATH ok'
}

if ($Upgrade) {
    scoop status
}
