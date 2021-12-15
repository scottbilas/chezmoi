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
    'Profiler' = 'latest'

    # we want this, but shovel comes with it, and get conflicts if try to import this and also use scoop :(
    # 'powershell-yaml' = 'latest'

    'PSReadLine' = @{
        Version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    'Terminal-Icons' = 'latest'
    'ZLocation' = 'latest'
}
