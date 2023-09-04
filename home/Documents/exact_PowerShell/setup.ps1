#Requires -Version 7
#Requires -Modules scobi # do not add any more to this

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

#    "Error: $_"
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

## Scoop pre

if (!(Get-Command -ea:silent powershell)) {
    # put C:\Windows\System32\WindowsPowerShell\v1.0 on path
    $poshPath = "$Env:SystemRoot\System32\WindowsPowerShell\v1.0"
    if (!(Test-Path $poshPath\powershell.exe)) {
        Write-Error "[scoop] powershell.exe not detected on system (should be at $poshPath)"
    }
    Write-Error "[scoop] powershell.exe not detected on path (required by scoop); add $poshPath to path"
}

if ((iee scoop config show_update_log) -match 'not set') {
    iee scoop config show_update_log $false
}
else {
    Write-Output '[scoop] Config ok'
}

## Scoop buckets

if ($Upgrade) {
    Write-Output '[scoop] Updating buckets'
    iee scoop update
}

### FAILS SOMEWHERE IN HERE....

$buckets = scoop bucket list | % name

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

$scoopPackages = (Get-ChildItem ~/scoop/apps).Name
if (Test-Path $env:ProgramData\scoop\apps) {
    $scoopPackages += (Get-ChildItem $env:ProgramData\scoop\apps).Name
}

function installScoopPackage([string]$name, [switch]$sudo, [switch]$global) {
    if ($scoopPackages -notcontains $name) {
        if ($sudo) {
            Write-Host "[scoop] Asking for sudo to install $name.."
            if ($global) {
                sudo iee scoop install -g $name
            }
            else {
                sudo iee scoop install $name
            }
        }
        else {
            iee scoop install $name
        }
    }
}

foreach ($name in @(
        # shell stuff
        'busybox', 'echoargs', 'less', 'moar', 'wget', 'curl', 'which',
        # other core utils
        '7zip', 'autohotkey1.1', 'bat', 'delta', 'fd', 'file', 'fzf', 'git', 'git-lfs',
        'gsudo', 'highlight', 'kalk', 'gitui', 'micro', 'ripgrep', 'hexyl',
        # bigger things
        'python', 'nodejs', 'rust', 'perl', 'go'
        'syncthingtray', 'linqpad', 'linqpadless', 'sysinternals', 'wiztree'
    )) {
    installScoopPackage($name)
}

# special note on fonts: avoid packages with "mono" in the name - these lose ligatures ("nerd font policy")
installScoopPackage -sudo -global CascadiaCode-NF
installScoopPackage -sudo -global JetBrainsMono-NF

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
    * copy in and update ~\appdata\roaming\syncthingtray.ini
    * copy in and update ~\.local\share\syncthing\{config.xml,https-*.pem,csrftokens.txt} (the cert.pem and key.pem will be created on next launch)
    * configure the name of this device
    * go to bunk-windows and accept

sysinternals - accept eula registry crap

# bigger apps

paint.net
tailblazer
vcxsrv

# unity stuff

lz4
unity-downloader-cli
#>

Write-Output '[scoop] Core packages ok'

### TODO: sudo Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1
### also look at existing powershell scripts that i already wrote to do registry stuff..

# CHECKS

$envPaths = Invoke-SetupEnvPaths
$Env:PATH = $envPaths.ResultPath
if ($envPaths.InvalidPaths) {
    Write-Error -ea:cont "[check] PATH contains invalid paths: $(($envPaths.InvalidPaths | Sort-Object | ForEach-Object { "'$_'" }) -Join ', ')"
}
if ($envPaths.DuplicatePaths) {
    Write-Error -ea:cont "[check] PATH contains duplicate paths: $(($envPaths.DuplicatePaths | Sort-Object | ForEach-Object { "'$_'" }) -Join ', ')"
}

if (!$envPaths.InvalidPaths -and !$envPaths.DuplicatePaths) {
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
    Write-Output '[check] Scoop upgrade status (scoop update *)'
    scoop status
}

# winget also
if ($Upgrade -and (Get-Command winget)) {
    Write-Output '[winget] Winget upgrade status (`invoke-wgupgrade -id *pattern*`)'
    winget upgrade
}

# check for default shell not pointing at pwsh. this is important for a couple reasons:
#
# 1. git through ssh into this machine will fail because single quotes get added around params, which are passed directly through to git commands, which then fail. for example a fetch will give an error like `fatal: ''C:/proj/OkTools'' does not appear to be a git repository`. switching to pwsh removes the quotes. (credit: https://serverfault.com/a/973455/1920)
# 2. i actually want powershell to be the default shell anyway for my own uses.
#
# to get remote fetch to work, have to..
#   g remote add mymachine mymachine:C:/path/to/thing
#   config remote.mymachine.uploadpack /C/Users/scott/scoop/apps/git/current/mingw64/bin/git-upload-pack.exe
#
# TODO: make that config unnecessary somehow..
#    1. just add it to the standard path, whatev (dislike, will cause collisions)
#    2. add a symlink just to that file from somewhere
#    3. detect we're running as ssh+git from profile and add path there (see https://github.com/PowerShell/Win32-OpenSSH/wiki/DefaultShell for how to pass args in..though easy to detect from env var SSH_ stuff set)
#    4. diagnose why this stupid problem is happening anyway and fix the actual issue..

$sshDefaultShell = Get-ItemProperty -ea:silent 'HKLM:\SOFTWARE\OpenSSH' | % DefaultShell
if (Test-Path -ea:silent $sshDefaultShell) {
    if ((Split-Path -Leaf $sshDefaultShell) -eq 'pwsh.exe') {
        Write-Output "[check] OpenSSH(d) default shell set to pwsh ok"
    }
    else {
        Write-Error "[check] OpenSSH(d) default shell set to $sshDefaultShell rather than pwsh"
    }
}
else {
    Write-Error "[check] OpenSSH(d) default shell is not set"
    # sudo New-ItemProperty -PropertyType String -Force -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value C:\Program Files\PowerShell\7\pwsh.exe
}

# look for bcomp not wired up to explorer

$bcShellPath = Get-ItemProperty -ea:silent 'HKCU:\SOFTWARE\Classes\CLSID\{57FA2D12-D22D-490A-805A-5CB48E84F12A}\InProcServer32' | % '(Default)'
if (Test-Path alias:bc) {
    $bcPath = Get-Content alias:bc
    if (!$bcShellPath -or ((Split-Path $bcShellPath) -ne (Split-Path $bcPath))) {
        Write-Error "[check] Beyond Compare Explorer integration mismatch; run bcomp4-shell-integration.reg (bc=$bcPath, reg=$bcShellPath)"
    }
    Write-Output "[check] Beyond Compare Explorer integration ok"
}
elseif ($bcShellPath) {
    Write-Error '[check] Beyond Compare Explorer integration is registered, but bc cannot be found; install bc or run bcomp4-shell-integration-remove.reg'
}

# ensure we have a python 3

if ($scoopPackages -contains 'python') {
    if ((iee python --version) -notmatch 'Python 3') {
        Write-Error '[python] Python 3 not found or is not default'
    }
    if ((iee pip config list) -match 'global.index-url') {
        # this can slip in from a copy-pasta of an install command intended for CI server
        Write-Host '[python] Found override of global index for pip, clearing it'
        iee pip config unset global.index-url
    }
    if ($Upgrade) {
        Write-Host '[python] Ensuring pip is the latest version'
        iee python -m pip install --upgrade pip
    }

    <# not sure i want to use git yet..
    # ok now ensure we have gita

    # skip header and grab name
    $pipPackages = iee pip list | Select-Object -Skip 2 | ForEach-Object { $_.Split(' ')[0] }

    function installPipPackage([string]$name) {
        if ($pipPackages -notcontains $name) {
            iee Pip install $name
        }
    }

    foreach ($name in @(
            # core utils
            'gita'
        )) {
        installPipPackage($name)
    }
    #>
}

# mute

oh-my-posh disable notice
