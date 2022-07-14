# Invoke-PSDepend -Force ~\Documents\PowerShell\requirements.psd1

@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }

    'Functional' = 'latest'
    'ListFunctions' = 'latest'
    'Microsoft.PowerShell.ConsoleGuiTools' = 'latest'
    'Microsoft.PowerShell.Crescendo' = 'latest'
    'Native' = 'latest'
    'Pester' = 'latest'
    'plinqo' = 'latest'
    'powershell-yaml' = 'latest'
    'Profiler' = 'latest'
    'PSReadLine' = @{
        Version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    'Terminal-Icons' = 'latest'
    'WingetTools' = 'latest'
    'ZLocation' = 'latest'
}
