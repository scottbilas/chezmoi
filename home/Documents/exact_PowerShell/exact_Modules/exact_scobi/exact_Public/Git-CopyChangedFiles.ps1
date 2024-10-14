function Git-CopyChangedFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutDir,
        [Parameter(Mandatory=$true)]
        [string]$BaseBranch,
        [Parameter(Mandatory=$true)]
        [string]$Branch
    )

    $baseCommit = git merge-base $Branch $BaseBranch
    foreach ($file in git diff --name-only $baseCommit $Branch) {
        $dst = "$Outdir\$file"

        git cat-file -e $branch`:$file 2>$null
        if ($LASTEXITCODE -eq 0) {

            $dir = Split-Path $dst
            if (!(Test-Path $dir)) {
                mkdir $dir >$null
            }

            $dst
            git show $branch`:$file > $dst
        }
        else {
            "deleted: $file"
        }
    }
}
Export-ModuleMember Git-CopyChangedFiles

# this is mostly meant as a "remind me what i changed" rather than a precise tool.
# i use it when comparing a couple PR's where the second is a "v2" of the first.
function Git-CompareChangedFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutDir,
        [Parameter(Mandatory=$true)]
        [string]$BaseBranch,
        [Parameter(Mandatory=$true)]
        [string]$Branch1,
        [Parameter(Mandatory=$true)]
        [string]$Branch2
    )

    Git-CopyChangedFiles -OutDir $OutDir\v1 -BaseBranch $BaseBranch -Branch $Branch1
    Git-CopyChangedFiles -OutDir $OutDir\v2 -BaseBranch $BaseBranch -Branch $Branch2
}
Export-ModuleMember Git-CompareChangedFiles
