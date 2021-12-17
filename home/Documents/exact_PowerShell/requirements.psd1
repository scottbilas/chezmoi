@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    
    'Functional' = 'latest'
    'ListFunctions' = 'latest'
    'Microsoft.PowerShell.ConsoleGuiTools' = 'latest'
    'Microsoft.PowerShell.Crescendo' = 'latest'
    'Native' = 'latest'
    'oh-my-posh' = 'latest'
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
    'ZLocation' = 'latest'
}
