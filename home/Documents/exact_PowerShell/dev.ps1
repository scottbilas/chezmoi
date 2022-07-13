#Requires -Version 7

#FINISH migrating from old
#$Script:IsFirstRun = Test-Path Variable:Global:ProfileVars

oh-my-posh init pwsh --config ~/Documents/PowerShell/prompt.json | Invoke-Expression

# TODO ^ get back prompt i used to have
Import-Module Terminal-Icons
# TODO ^ less harsh/neon themes, and also dark/light options (wire up to Set-DarkMode)

Update-FormatData -PrependPath ~/Documents/PowerShell/CustomFormatters.ps1xml

# needed to have zlocation hook into prompt. note that zlocation may have already hooked the
# prompt because of posh auto-import. force it to re-hook it after oh-my-posh above grabs it.
# TODO: fork and publish the prompt registration func (with a -force flag) and I'll just call it directly..
Remove-Item -ea:silent function:ZLocationOrigPrompt
Import-Module ZLocation
Set-ZLocation (Get-Location)
if (-not (Get-Content Function:\prompt).ToString().Contains('Update-ZLocation')) {
    Write-Warning "ZLocation+ohmyposh prompt collision"
}

### FUNCTIONS

function pester($file) {
    if (!$file) {
        pwsh -NoProfile -Command { Invoke-Pester }
        return
    }

    if ($file -notmatch '\.ps1$')  {
        if ($file -notmatch '\.tests') {
            $file = "$file.Tests.ps1"
        }
        else {
            $file = "$file.ps1"
        }
    }

    pwsh -NoProfile $file
}

if (Test-Path C:\UnitySrc\p4\UnityExtPacks\Tools\okunity.exe) {
    Set-Alias oku C:\UnitySrc\p4\UnityExtPacks\Tools\okunity.exe
}

### COMPLETIONS

Set-PSReadLineOption `
    -PredictionSource History `
    -PredictionViewStyle ListView

# from https://gist.github.com/shanselman/25f5550ad186189e0e68916c6d7f44c3?WT.mc_id=-blog-scottha
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# scoop install scoop-completion (from extras bucket)
# TODO: figure out why this doesn't complete on `scoop install <tab>` - it only gives a file completion.
# ..probably something with psreadline settings..
#Import-Module ~/scoop/modules/scoop-completion
