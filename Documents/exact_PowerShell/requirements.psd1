@{
    PSDependOptions = @{
        Target = 'CurrentUser'
    }
    
    'Functional' = 'latest'
    'Native' = 'latest'
    'oh-my-posh' = 'latest'
    'Pester' = 'latest'
    'powershell-yaml' = 'latest'

    'PSReadLine' = @{
        Version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    'Terminal-Icons' = 'latest'
    'ZLocation' = 'latest'
}
