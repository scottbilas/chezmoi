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
        'aria2', 'dark', 'innounp', 'lessmsi'
        # shell stuff
        'busybox', 'less', 'which', 'echoargs', 'wget'
        # other core utils
        'ripgrep', 'kalk', '7zip', 'autohotkey', 'fd', 'gsudo', 'chezmoi', 'git', 'micro'
    )) {
    addPackage($install)
}

# special note on fonts: avoid packages with "mono" in the name - these lose ligatures ("nerd font policy")
addPackage -sudo CascadiaCode-NF
addPackage -sudo JetBrainsMono-NF

<#
# TODO: also check which shim has been overridden

# each of these requires special setup

barrier-np - client/server, also only for work computers
everything - configure and hold
gh - auth << setup from unity.toml
syncthingtray - lots of config, validation, machine-specific
vscode-portable - cannot chezmoi publish before scoop/apps/current symlink is set up, right..?

# bigger apps

7tt
linqpad
paint.net
sysinternals
tailblazer
vcxsrv
windirstat

# languages and platforms

nodejs
perl
python
go
rust

# unity stuff

lz4
unity-downloader-cli
#>

Write-Output '[scoop] Core packages ok'

# CHECKS

# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$badPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($badPaths) {
    Write-Error "[check] PATH is invalid: $(($badPaths | ForEach-Object { "'$_'" }) -Join ', ')"
}
else {
    Write-Output '[check] PATH ok'
}

# look for bad scoop installs
$badScoop = @()
foreach ($app in (Get-ChildItem ~/Scoop/Apps -Exclude scoop)) {
    if (Test-Path $app/current) {
        if (!(Test-Path $app/current/*install.json)) {
            $badScoop += $app.Name
        }
    }
    else {
        $badScoop += $app.Name
    }
}
if ($badScoop) {
    Write-Error "[check] Scoop has invalid installs: $($badScoop -join ', ')"
}

# anything (else) going on with scoop?
if ($badScoop -or $Upgrade) {
    scoop status
}
