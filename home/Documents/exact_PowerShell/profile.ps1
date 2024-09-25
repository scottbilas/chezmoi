#Requires -Version 7

# important: don't set strict mode for the profile. rando cli ops need to stay fuzzy else they get annoying.
#Set-StrictMode -Version Latest
# but stopping on any error is good, let's keep this one
$ErrorActionPreference = 'Stop'

<#
profile requirements:

- only simple work that avoids file activity as much as possible. every Resolve-Path hits IO..
- profile can be reloaded, and as a command script. use $global:ProfileState.Initializing to detect first run.
#>

### PROFILE MANAGEMENT

if (!$global:ProfileState) {
    $global:ProfileState = @{ Initializing = $true }

    $PROFILE = $MyInvocation.MyCommand.Path
}

$profileTimerStart = Get-Date

function Reload-Profile {
    write-host 'Reloading profile...'
    Invoke-Expression -Command $PROFILE

    # TODO: force-reimport modules..?
}


### POSH CORE

# override the worst default ever (UTF-16LE); see much detail at https://stackoverflow.com/a/40098904/14582
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8NoBOM'


### ENVIRONMENT

$Env:BAT_CONFIG_PATH = "$HOME/.config/bat/bat.conf"
$Env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
$Env:FZF_DEFAULT_COMMAND = 'fd --hidden -E .git'
$Env:FZF_DEFAULT_OPTS = "--tabstop=4 --preview-window=right:60% --bind 'alt-p:toggle-preview' --preview '$HOME\.local\bin\fzf-preview.cmd {} | head -500'"
$Env:HOME = Resolve-Path ~
$Env:LESS = '--tabs=4 -RFXi'
$Env:MOAR = '-quit-if-one-screen -style dracula -no-statusbar -no-linenumbers -wrap'
$Env:RIPGREP_CONFIG_PATH = (Resolve-Path ~/.config/ripgrep/config)
$Env:SCOOP = Resolve-Path ~\scoop
$Env:UNITY_MIXED_CALLSTACK = 1
$Env:WSL_UTF8 = 1

Invoke-Expression (&scoop-search --hook) # this replaces crappy built-in scoop search with something very fast

### PSREADLINE

Set-PSReadLineKeyHandler -Chord Ctrl-u DeleteLineToFirstChar
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

Set-PSReadLineOption `
    -HistorySavePath "~/.local/state/powershell/PSReadLine/$($Host.Name)_history.txt" `
    -HistorySearchCursorMovesToEnd `
    -AddToHistoryHandler { # thanks to https://megamorf.gitlab.io/cheat-sheets/powershell-psreadline/
        param([string]$line)

        $sensitive = 'password|secret|API_KEY\s*='
        return ($line -notmatch $sensitive)
    }

### ALIASES AND ALIAS-ISHES

# these aliases only cause problems or collide with other things or otherwise are lame
'diff', 'rm', 'mv', 'set', 'sort', 'r', 'kill', 'tee' | ForEach-Object {
    # remove from every scope (https://stackoverflow.com/a/24743647/14582)
    while (Test-Path Alias:$_) {
        Remove-Item -Force Alias:$_
    }
}

if (Get-Command micro) {
    Set-Alias m micro
    $Env:EDITOR = 'micro'
}

# shortyshortcuts
Set-Alias g git
Set-Alias o explorer
Set-Alias cm chezmoi
Set-Alias devenv 'C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe'
function cm-c { Set-Location (chezmoi source-path) }
function cm-s { chezmoi status }
function cm-d { chezmoi diff --use-builtin-diff @args }
function dotf { code (Resolve-Path ~\.local\share\chezmoi\chezmoi.code-workspace) }
function mcd($name) { [void](mkdir $name) && Set-Location $name }
function up { Set-Location .. }
function ov($what) { Set-Location ../$what }
function ~ { Set-Location ~ }

function Get-ConfigToml {
    $baseDir = '~\.local\share\private\keys'

    $path = Join-Path $baseDir scott.toml
    if (!(Test-Path $path)) {
        $path = Join-Path $baseDir unity.toml
    }

    Get-Content $path | convertfrom-toml
}

function Expand-Path {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValuefromPipeline=$True)]
        [string[]]$path
    )

    process {
        foreach ($i in $path) {
            if ($i.StartsWith('~')) {
                $Home + $i.Substring(1)
            }
            else {
                $i
            }
        }
    }
}

if (Test-Path 'C:\Program Files\WSL\wsl.exe') {
    Set-Alias wsl 'C:\Program Files\WSL\wsl.exe'
}

if (Get-Command -ea:silent rg) {
    function rgh { rg --hidden --no-ignore @args }
}

if (Get-Command -ea:silent fd) {
    function fdh { fd -HI @args }
}

if (Get-Command -ea:silent eza) {
    $Env:EXA_GRID_ROWS = 10

    # scoop install eza
    function l { eza --all --group-directories-first --icons --classify ($args | Expand-Path) }
    function ll { l --long --header @args }
    function llg { ll --git @args }
}
else {
    function l { Get-ChildItem $args | Format-Wide -AutoSize }
    function ll { Get-ChildItem -fo $args }
}

if (Get-Command -ea:silent btm) {
    function top { btm @args }
}
elseif (Get-Command -ea:silent htop) {
    function top { htop @args }
}

if (Get-Command -ea:silent lazygit) {
    Set-Alias lg lazygit
}

if (Get-Command -ea:silent pskill) {
    function kill { pskill -nobanner @args }
}

if (Get-Command -ea:silent gpt) {
    function gpt {
        $env:OPENAI_API_KEY = (Get-ConfigToml).'Auth Tokens'.openai
        gpt.exe @args
        $env:OPENAI_API_KEY = $null
    }
}
elseif (Get-Command -ea:silent chatgpt) {
    function gpt {
        $env:OPENAI_API_KEY = (Get-ConfigToml).'Auth Tokens'.openai
        chatgpt.exe @args
        $env:OPENAI_API_KEY = $null
    }
}

if (Get-Command -ea:silent gh) {
    . $PSScriptRoot/gh-copilot.ps1
}

# default sort.exe is in system32; avoid that one
& {
    $sort = Resolve-Path -ea:silent ~\scoop\apps\git\current\usr\bin\sort.exe
    if ($sort) {
        Set-Alias -Scope Global sort $sort
    }
}

Set-Alias psdev (Join-Path $PSScriptRoot dev.ps1)
Set-Alias pssetup (Join-Path $PSScriptRoot setup.ps1)
function psup { & (Join-Path $PSScriptRoot setup.ps1) -Upgrade }
function zsh { wsl -e /home/linuxbrew/.linuxbrew/bin/zsh --login }

& {
    $bc = Resolve-Path -ea:silent ~/scoop/apps/beyondcompare/current/bcomp.exe
    if (!$bc) {
        $bc = Resolve-Path -ea:silent "$env:ProgramFiles\Beyond Compare 5\BComp.exe"
    }
    if (!$bc) {
        $bc = Resolve-Path -ea:silent "$env:ProgramFiles\Beyond Compare 4\BComp.exe"
    }
    if ($bc) {
        Set-Alias -Scope Global bc $bc
    }
}


### FUNCTIONS

function Flatten($a) {
    ,@($a | ForEach-Object{ $_ })
}

function Time($exec) {
    $now = Get-Date
    Invoke-Command $exec
    $delta = (Get-Date) - $now

    Write-Host ("`n>>> completed in {0:F3}s" -f $delta.TotalSeconds)
}

# https://stackoverflow.com/a/46583549/14582
function Expand-EnvironmentVariablesRecursively($unexpanded) {
    $previous, $expanded = '', $unexpanded
    while ($previous -ne $expanded) {
        $previous = $expanded
        $expanded = [Environment]::ExpandEnvironmentVariables($previous)
    }
    return $expanded
}

function Update-EnvPath {
    $machine = Expand-EnvironmentVariablesRecursively([Environment]::GetEnvironmentVariable("Path", "Machine"))
    $user = Expand-EnvironmentVariablesRecursively([Environment]::GetEnvironmentVariable("Path", "User"))

    $env:PATH = ($machine -replace ';$', '') + ';' + ($user -replace ';$', '')
}

function Title($title) {
    $host.ui.RawUI.WindowTitle = $title
    $env:SHELL_TITLE = $title
}
Title posh

$unityProfile = '~/.local/share/private/posh/unity-profile.ps1'
if (Test-Path $unityProfile) {
    . $unityProfile
}

### FINISHED

if ($global:ProfileState.Initializing) {
    $global:ProfileState.InitializeTime = (Get-Date) - $profileTimerStart
    $global:ProfileState.Initializing = $false
}
