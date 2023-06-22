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
