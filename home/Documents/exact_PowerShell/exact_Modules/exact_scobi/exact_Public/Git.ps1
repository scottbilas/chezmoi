[Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSPossibleIncorrectUsageOfRedirectionOperator', '')]
param()

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

filter Git-ToDict([string]$Delim = ':') {
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

function Git-LsWorktrees([string]$RepoRoot = $null) { # corresponds to git -C

    $gitArgs = @()
    if ($RepoRoot) {
        $gitArgs += '-C', $RepoRoot
    }
    else {
        $RepoRoot = '.'
    }
    $gitArgs += 'worktree', 'list', '--porcelain'

    # TODO: use `git rev-parse --git-path config.worktree` (see https://git-scm.com/docs/git-rev-parse for other variants and apply elsewhere in this script)
    # can get rid of the path-specific stuff in here. though using rev-parse requires spawning processes and is slower, not sure we care about perf here

    foreach ($wt in git $gitArgs | Git-ToDict -Delim ' ') {
        if ($wt.ContainsKey('branch')) {
            if ($wt.branch.StartsWith("refs/heads/")) {
                $wt.branch = $wt.branch.Substring(11)
            }
        }
        else {
            $wt.branch = $null
        }

        $wt.detached = $wt.ContainsKey('detached')

        $wt.gitdir = Resolve-Path ($wt.worktree + '/.git')
        $wt.worktree = Resolve-Path $wt.worktree

        if (Test-Path -PathType Leaf $wt.gitdir) {
            $gd = (Get-Content $wt.gitdir | Git-ToDict).gitdir
            $wt.worktree_gitdir_raw = $gd

            if (![IO.Path]::IsPathRooted($gd)) {
                $gd = Join-Path $RepoRoot $gd
            }

            $wt.worktree_gitdir = Resolve-Path $gd

            $wt.gitconfig = Resolve-Path (Join-Path $wt.worktree_gitdir .. .. config)
            $wt.worktree_gitconfig = $wt.worktree_gitdir
        }
        else {
            $wt.gitconfig = Resolve-Path (Join-Path $wt.gitdir config)
            $wt.worktree_gitconfig = $wt.gitdir
        }

        $wt_gitconfig = Resolve-Path -ea:silent (Join-Path $wt.worktree_gitconfig config.worktree)
        if ($wt_gitconfig) {
            $wt.worktree_gitconfig = $wt_gitconfig
        }
        else {
            $wt.Remove('worktree_gitconfig')
        }

        $wt
    }
}
Export-ModuleMember Git-LsWorktrees

function Git-FixConfigs {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$RepoRoot = $null # corresponds to git -C
    )

    # TODO: check that local branch name matches tracking branch if any
    # TODO: this really ought to be in git bash, not powershell, so works everywhere

    $wts = Git-LsWorktrees -RepoRoot $RepoRoot

    foreach ($wt in $wts) {
        if ($wt.ContainsKey('worktree_gitdir_raw') -and
            [IO.Path]::IsPathRooted($wt.worktree_gitdir_raw) -and
            $PSCmdlet.ShouldProcess($wt.gitdir, 'Fix .git path to be relative')) {

            Write-Host "Fixing gitdir path to be relative in $($wt.gitdir)"
            
            $rel = [IO.Path]::GetRelativePath($wt.worktree, $wt.worktree_gitdir).Replace('\', '/')
            $old = [IO.File]::ReadAllText($wt.gitdir)
            $new = $old -replace 'gitdir:\s*?.*', "gitdir: $rel"
            if ($old -ne $new) {
                [IO.File]::WriteAllText($wt.gitdir, $new)
            }
            else {
                Write-Error "Pattern match fail in $($wt.gitdir)"
            }
        }

        if ($wt.ContainsKey('worktree_gitconfig')) {
            $wtconfig = Get-IniContent $wt.worktree_gitconfig
            $include = $wtconfig['include']?['path']
            if ($include -and
                [IO.Path]::IsPathRooted($include) -and
                $PSCmdlet.ShouldProcess($wt.worktree_gitconfig, 'Fix include.path to be relative')) {

                Write-Host "Fixing include.path to be relative in $($wt.worktree_gitconfig)"

                $rel = [IO.Path]::GetRelativePath($wt.worktree, $include).Replace('\', '/')
                $wtconfig['include']['path'] = $rel
                $wtconfig | Out-IniFile $wt.worktree_gitconfig -force -loose -pretty
            }
        }

        # test the worktree is ok
        if ((git -C $wt.worktree rev-parse --is-inside-work-tree) -ne 'true') {
            Write-Error "Worktree $($wt.worktree) is not ok"
        }
    }

    # is there a common include? test it is there
    $main = Split-Path -Leaf $wts[0].worktree
    $common = "~/.local/share/private/git/repo-config-$main"
    if (Test-Path $common) {
        if (((git config --get-all include.path) -notcontains $common) -and
            $PSCmdlet.ShouldProcess($common, 'Add include.path for common config to repo')) {

            Write-Host "Adding include.path=$common to $($wts[0].gitconfig)"
            git config --local --add include.path $common

            if ((git config --get-all include.path) -notcontains $common) {
                Write-Error "Failed to add common include $common"
            }
        }
    }

    # TODO:
    # check `git update-index --index-version 4` (or just do it)

    # TODO:
    # test if we can enable caching for untracked files
    #   git update-index --test-untracked-cache
    # then if it's ok..
    #   git config core.untrackedCache true
    #   git update-index --untracked-cache
}
Export-ModuleMember Git-FixConfigs
