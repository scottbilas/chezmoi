#Requires -Version 7
$ErrorActionPreference = 'Stop'

# important: don't set strict mode for the profile. rando cli ops need to stay fuzzy else they get annoying.
# but stopping on any error is good, let's keep that one.


### POSH CORE

# override the worst default ever (UTF-16LE); see much detail at https://stackoverflow.com/a/40098904/14582
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8NoBOM'


### ENVIRONMENT

$Env:BAT_CONFIG_PATH = "$HOME/.config/bat/bat.conf"
$Env:DOTNET_CLI_TELEMETRY_OPTOUT = 1
$Env:FZF_DEFAULT_COMMAND = 'fd --hidden -E .git'
$Env:FZF_DEFAULT_OPTS = "--tabstop=4 --preview-window=right:60% --bind 'alt-p:toggle-preview' --preview '$HOME\dotfiles\scripts\fzf-preview.cmd {} | head -500'"
$Env:HOME = Resolve-Path ~
$Env:LESS = '--tabs=4 -RFXi'
$Env:RIPGREP_CONFIG_PATH = (Resolve-Path ~/.config/ripgrep/config)
$Env:SCOOP = Resolve-Path ~\scoop
$Env:UNITY_MIXED_CALLSTACK = 1


### PSREADLINE

Set-PSReadLineKeyHandler -Chord Ctrl-u DeleteLineToFirstChar
Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

Set-PSReadLineOption `
    -HistorySavePath "~/.local/state/powershell/PSReadLine/$($Host.Name)_history.txt" `
    -HistorySearchCursorMovesToEnd


### ALIASES AND ALIAS-ISHES

# these aliases only cause problems or collide with other things or otherwise are lame
'diff', 'rm', 'set', 'sort', 'r', 'kill' | ForEach-Object {
    # remove from every scope (https://stackoverflow.com/a/24743647/14582)
    while (Test-Path Alias:$_) {
        Remove-Item -Force Alias:$_
    }
}

# shortyshortcuts
Set-Alias o explorer
Set-Alias g git
Set-Alias m micro
Set-Alias cm chezmoi
Set-Alias lg lazygit
function cm-cd { Set-Location (chezmoi source-path) }
function cm-d { chezmoi diff --use-builtin-diff @args }
function dotf { code (Resolve-Path ~\.local\share\chezmoi\chezmoi.code-workspace) }
function up { Set-Location .. }
function ov($what) { Set-Location ../$what }
function ~ { Set-Location ~ }

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

& {
    $bc = Resolve-Path -ea:silent ~/scoop/apps/beyondcompare/current/bcomp.exe
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

function Time([scriptblock]$exec) {
    $now = Get-Date
    $result = Invoke-Command $exec -Args (Flatten $args)
    $delta = (Get-Date) - $now
    $result
    Write-Host ("`n>>> seconds: {0}" -f $delta.TotalSeconds)
}