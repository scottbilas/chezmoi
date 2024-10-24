function get-prs {
    $user = ((git config user.email) -split '@')[0]
    $token = (Get-ConfigToml)['GitHub Enterprise Personal Access Tokens'].cli

    $query = "{
        search(query: `"is:pr author:$user`", type: ISSUE, first: 100) {
            edges { node { ... on PullRequest { id url headRefName headRefOid merged } } } } }"

    $response = Invoke-RestMethod https://github.cds.internal.unity3d.com/api/graphql `
        -Method Post `
        -Headers @{ 'Authorization'="bearer $token"; 'Content-Type'='application/json' } `
        -Body (@{ query = $query } | ConvertTo-Json)

    if ($response | Get-Member errors) {
        throw $response.errors[0].message
    }

    $response.data.search.edges.node | % { @{ id = $_.id; url = $_.url; branch = $_.headRefName; commit = $_.headRefOid; merged = $_.merged } }
}

function Git-DeadBranches {
    [CmdletBinding()]
    param()

    $branches = git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | Sort-Object | %{
        $v = $_ -split ' ', 2
        @{ local=$v[0]; tracked=$v[1] }
    }

    $prs = get-prs
    $wts = Git-LsWorktrees
    $any = $false

    foreach ($branch in $branches) {
        if (!$branch.tracked) {
            $upstreamState = 'none'
        }
        elseif (git rev-parse --verify --quiet $branch.tracked) {
            $upstreamState = 'valid'
        }
        else {
            $upstreamState = 'deleted'
        }

        $pr = $prs | ?{ $_.branch -eq $branch.local } | Select-Object -First 1

        Write-Verbose "Processing $($branch.local), state is $upstreamState"
        if ($pr) {
            Write-Verbose "PR is $($pr.url) at $($pr.commit)"
        }

        if ($pr -and $pr.merged) {
            $any = $true

            if ($upstreamState -eq 'valid') {
                if ($branch.tracked.StartsWith('sco')) {
                    Write-Warning "Branch PR got merged, but is still tracking a sco remote: $($branch.tracked)"
                }
                else {
                    Write-Warning "Branch PR got merged ($($pr.url)) but upstream branch still exists locally: $($branch.local) -> $($branch.tracked) (probably need to `git fetch`)"
                }
                continue
            }

            $branch.local
            if ($upstreamState -eq 'none') {
                "  (no upstream tracking branch)"
            }
            else {
                "  $($upstreamState): $($branch.tracked)"
            }
            $head = git rev-parse $branch.local
            if ($head -ne $pr.commit) {
                # TODO: check to see if $head is an ancestor of $pr.commit (requires a different kind of gh query or possibly pullign those changes local)
                "  ! potentially unsafe to delete (HEAD $($head.Substring(0, 12)) is not the PR head $($pr.commit.Substring(0, 12)) (PR = $($pr.url)/commits)"
                git log -5 --oneline "main..$($branch.local)" | % { "    | $_" }
            }
            else {
                "  merged PR was $($pr.url)"
                "  local head matches PR head $($head.Substring(0, 12))"
            }

            $wt = $wts | ?{ $_.Branch -eq $branch.local }
            if ($wt) {
                "  ! $($branch.local) checked out at $($wt.worktree)"
                git -C $($wt.worktree) status --porcelain | %{ "  ! status: $_" }
                $cmd = "git -C $($wt.worktree) co --detach && git branch -D $($branch.local)"
                if ($LASTEXITCODE) {
                    "  > git -C $($wt.worktree) diff"
                    "  > git -C $($wt.worktree) trash && $cmd"
                }
                else {
                    "  > $cmd"
                }
            }
            else {
                "  ($($branch.local) not checked out in any worktree)"
                "  > git branch -D $($branch.local)"
            }
        }
    }

    if (!$any) {
        'No dead branches found'
    }
}
Export-ModuleMember Git-DeadBranches
