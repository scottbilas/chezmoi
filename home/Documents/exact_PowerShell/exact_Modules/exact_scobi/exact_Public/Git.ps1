<# WIP WIP
function Git-GetChangedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Branch
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


# TODO: integrate this into ugit, and have it handle:
#
# -l/--long (optional size)
# blob vs tree (size will be just '-')
# -z termination and also quote stripping (see help on ls-files and git config 'core.quotePath')
function Git-LsTree {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Position=0)]
        [string]$Path = '.',

        [string]$RepoRoot = $null, # corresponds to git -C
        [string]$Branch = 'HEAD'
    )

    $gitArgs = @()
    if ($RepoRoot) { $gitArgs += '-C', $RepoRoot }
    $gitArgs += 'ls-tree', '-r', '--long', $Branch, $Path

    git $gitArgs | ForEach-Object {
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

filter Git-ToDict($Delim = ':') {
    begin {
        $dict = @{}
    }

    process {
        if ($_) {
            $k, $v = $_.Split($Delim, 2, 'trim')
            $dict[$k] = $v
        }
        else {
            $dict
            $dict = @{}
        }
    }

    end {
        if ($dict.Count) { $dict }
    }
}
Export-ModuleMember Git-ToDict

function Git-WorktreeList {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [string]$RepoRoot = $null # corresponds to git -C
    )

    $gitArgs = @()
    if ($RepoRoot) { $gitArgs += '-C', $RepoRoot }
    $gitArgs += 'worktree', 'list', '--porcelain'

    git $gitArgs | Git-ToDict -Delim ' ' | ForEach-Object {
        $gitdir = $_.worktree + '/.git'
        $_.gitdir = $gitdir
        if (Test-Path -PathType Leaf $_.gitdir) {
            $_.gitdirwt = (Get-Content $_.gitdir | Git-ToDict).gitdir
        }
        if ($_.branch.StartsWith("refs/heads/")) {
            $_.branch = $_.branch.Substring(11)
        }
        $_
    }
}
Export-ModuleMember Git-WorktreeList
