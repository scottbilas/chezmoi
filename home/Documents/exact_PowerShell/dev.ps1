#Requires -Version 7

#FINISH migrating from old
#$Script:IsFirstRun = Test-Path Variable:Global:ProfileVars

Set-PoshPrompt -Theme ~/Documents/PowerShell/prompt.json
# TODO ^ get back prompt i used to have
Import-Module Terminal-Icons
# TODO ^ less harsh/neon themes, and also dark/light options (wire up to Set-DarkMode)

Update-FormatData -PrependPath ~/Documents/PowerShell/CustomFormatters.ps1xml

# needed to have zlocation hook into prompt
Import-Module ZLocation

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
Import-Module ~/scoop/modules/scoop-completion
