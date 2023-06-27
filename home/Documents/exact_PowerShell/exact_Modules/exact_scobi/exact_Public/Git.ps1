<# WIP WIP
function Git-GetChangedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$branch
    )

    # Set the paths you're interested in
    $paths = @("path1", "path2", "path3")

    # Compare the local main branch with the fetched branch
    $changedFiles = git diff --name-only origin/main

    # Check if any of the changed files match the paths you're interested in
    foreach ($path in $paths) {
        if ($changedFiles -match "^$path/") {
            Write-Host "Changes detected in $path"
        }
    }
}
#>


function Git-LsTree {
    [CmdletBinding()]
    param (
        [string]$branch = 'HEAD',
        [string]$path = ''
    )

    git ls-tree -r --long $branch $path | ForEach-Object {
        if ($_ -match '(\d+) (\w+) (\w+) *(\d+)\t(.*)') {
            [pscustomobject]@{
                path = $matches[5]
                size = [int]$matches[4]
                type = $matches[2]
                hash = $matches[3]
                perms = [int]$matches[1]
            }
        }
        else {
            Write-Warning "Failed to parse git ls-tree output: $_"
        }
    }
}
Export-ModuleMember Git-LsTree
