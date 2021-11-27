#Requires -Version 7

[CmdletBinding()]
param (
    [switch]$Upgrade
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # distracting and ends up with cursor in wrong vertical position sometimes (maybe exposes a terminal bug)

$jobs = @()

trap {
    foreach ($job in $jobs) {
        # $???$?
    }
    
    "Error: $_"
    break
}

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
    $missingPSModules = (Import-PowerShellDataFile ~/Documents/PowerShell/requirements.psd1).Keys |
        Where-Object { $_ -ne 'PSDependOptions' } |
        Where-Object { !(Test-Path ~/Documents/PowerShell/Modules/$_) }
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

## Posh help

$jobs += Start-Job { Update-Help }

#  ____   ____ ___   ___  ____  
# / ___| / ___/ _ \ / _ \|  _ \ 
# \___ \| |  | | | | | | | |_) |
#  ___) | |__| |_| | |_| |  __/ 
# |____/ \____\___/ \___/|_|

## Scoop pre

if ((iee scoop config show_update_log) -match 'not set') {
    iee scoop config show_update_log $false
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

### FAILS SOMEWHERE IN HERE....

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
        # ^ TODO: "aria2" will get used by shovel, but it has failures. using shovel+aria2 on fzf fails with an error, but succeeds with plain scoop
        # ^ so this should be an issue or PR to fix, or maybe fall back if aria2 fails..

        # shell stuff
        'busybox', 'echoargs', 'less', 'wget', 'which'
        # other core utils
        '7zip', 'autohotkey', 'bat', 'chezmoi', 'delta', 'fd', 'file', 'fzf', 'git', 'gsudo', 'kalk', 'lazygit', 'micro', 'ripgrep'
    )) {
    addPackage($install)
}

# special note on fonts: avoid packages with "mono" in the name - these lose ligatures ("nerd font policy")
addPackage -sudo CascadiaCode-NF
addPackage -sudo JetBrainsMono-NF

if ((iee scoop config MSIEXTRACT_USE_LESSMSI) -match 'not set') {
    iee scoop config MSIEXTRACT_USE_LESSMSI $true
}

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

### TODO: sudo Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
### also look at existing powershell scripts that i already wrote to do registry stuff..

# CHECKS

# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$invalidPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($invalidPaths) {
    Write-Error -ea:cont "[check] PATH invalid: $(($invalidPaths | ForEach-Object { "'$_'" }) -Join ', ')"
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

Write-Output '[check] Scoop apps ok'

# anything (else) going on with scoop?
if ($badScoop -or $Upgrade) {
    scoop status
}

# look for bcomp not wired up to explorer

$bcShellPath = (Get-ItemProperty -ea:silent 'HKLM:\SOFTWARE\Classes\CLSID\{57FA2D12-D22D-490A-805A-5CB48E84F12A}\InProcServer32')."(Default)"
if (Test-Path alias:bc) {
    $bcPath = Get-Content alias:bc
    if ($bcShellPath -ne $bcPath) {
        Write-Error "[check] Beyond Compare Explorer integration mismatch; run bcomp4-shell-integration.reg (bc=$bcPath, reg=$bcShellPath)"
    }
}
elseif ($bcShellPath) {
    Write-Error "[check] Beyond Compare Explorer integration is registered, but bc cannot be found; install bc or run bcomp4-shell-integration-remove.reg"
}
