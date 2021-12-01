@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    
    'Functional' = 'latest'
    'ListFunctions' = 'latest'
    'Microsoft.PowerShell.ConsoleGuiTools' = 'latest'
    'Native' = 'latest'
    'oh-my-posh' = 'latest'
    'Pester' = 'latest'
    'plinqo' = 'latest'

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
