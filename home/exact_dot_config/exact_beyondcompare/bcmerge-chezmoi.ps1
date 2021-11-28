#Requires -Version 7

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)] $Destination,
    [Parameter(Mandatory = $true)] $Source,
    $Target # not used currently, but this is a (possibly template-expanded) file in the temp folder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$gitRoot = chezmoi source-path
$gitSource = git -C $gitRoot ls-files $Source

$Destination = Resolve-Path $Destination
$Source = Resolve-Path $Source

# if not added to git repo yet, there will be no base
if ($gitSource) {
    $base = [IO.Path]::GetTempFileName()
    git -C $gitRoot show HEAD:$gitSource > $base

    bc $Source $Destination $base /centertitle="HEAD:$gitSource"
}
else {
    bc $Source $Destination
}

# TODO: wait on bcomp and then delete tempfile $base
# TODO: reinterpret bcomp exit code as success/fail for chezmoi