#Requires -Version 7

[CmdletBinding()]
param (
    [switch] $BeyondCompare, [switch] $KDiff3,
    [Parameter(Mandatory = $true)] $Destination,
    [Parameter(Mandatory = $true)] $Source,
    $Target # not used currently, but this is a (possibly template-expanded) file in the temp folder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gitRoot = git -C (chezmoi source-path) rev-parse --show-toplevel
$gitSource = git -C $gitRoot ls-files $Source

$dst = Resolve-Path -ea:silent $Destination
if (!$dst) {
    Write-Output "Nothing to merge with $Source, file does not exist at $Destination"
}

$Source = Resolve-Path $Source

# if not added to git repo yet, there will be no base
if ($gitSource) {
    $base = [IO.Path]::GetTempFileName()
    git -C $gitRoot show HEAD:$gitSource > $base

    # "destination on the left" matches chezmoi status
    if ($BeyondCompare) {
        bc $dst $Source $base /centertitle="HEAD:$gitSource"
    }
    if ($KDiff3) {
        kdiff3 -m $base $dst $Source -o $Source --L1 "HEAD:$gitSource"
        if (test-path "$Source.orig") {
            del "$Source.orig" # not needed, we have version control
        }
    }
}
else {
    if ($BeyondCompare) {
        bc $dst $Source
    }
    if ($KDiff3) {
        kdiff3 $dst $Source
    }
}

# TODO: wait on bcomp and then delete tempfile $base
# TODO: reinterpret bcomp exit code as success/fail for chezmoi
