#Requires -Version 7

#FINISH migrating from old
#$Script:IsFirstRun = Test-Path Variable:Global:ProfileVars

Set-PoshPrompt -Theme ~/Documents/PowerShell/prompt.json
# TODO ^ get back prompt i used to have
Import-Module Terminal-Icons
# TODO ^ less harsh/neon themes, and also dark/light options (wire up to Set-DarkMode)

Update-FormatData -PrependPath ~/Documents/PowerShell/CustomFormatters.ps1xml

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

Import-Module ~/scoop/apps/scoop/current/supporting/completion/Scoop-Completion.psd1
