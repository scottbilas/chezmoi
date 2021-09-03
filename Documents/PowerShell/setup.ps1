#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

## Chezmoi

# chezmoi update << do safely

## Posh

if ((Get-PSRepository PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository PSGallery -InstallationPolicy Trusted
}

## PSDepend

# TODO: have this scoop install python; pip install gita; then have PSDepend brought in via gita (and gitree and others) in a "profile" group
# (then get rid of ghq entirely..)
# (or use ghq just for profile stuff..? two git mgmt tools?? nah.. just that ghq seems better at this job)

# git repo
Write-Output "[posh] Cloning/updating PSDepend module..."
#ghq get -s -u -p scottbilas/PSDepend
#if ($LASTEXITCODE) { throw "`ghq` returned error $LASTEXITCODE" }

# symlink
$psdependDstPath = Join-Path (Resolve-Path ~) Documents PowerShell Modules PSDepend
if (!(Test-Path $psdependDstPath)) { # TODO: check that it points to the right place (make this a utility func)
    #$psdependSrcPath = ghq list -p scottbilas/PSDepend
    New-Item -ItemType SymbolicLink -Path $psdependDstPath -Target $psdependSrcPath\PSDepend | Out-Null
}

Write-Output "[posh] Pulling module dependencies..."
Import-Module PSDepend
Invoke-PSDepend -Force $PSScriptRoot



# Upgrade to Shovel

Install-ScoopPackage 7zip
Invoke-Exe 'scoop config SCOOP_REPO https://github.com/Ash258/Scoop-Core'
Invoke-Exe 'scoop config show_update_log false'
Invoke-Exe 'scoop update'



# look for stale PATH entries
$Env:PATH = ($Env:PATH -Split ';' | Where-Object { $_ }) -join ';' # fix any blank entries, which will cause problems in other funcs that don't expect it
$badPaths = ($Env:PATH).Split(';') | Where-Object { !(Test-Path ([Environment]::ExpandEnvironmentVariables($_))) }
if ($badPaths) {
    Write-Error "PATH is invalid: $(($badPaths | ForEach-Object { "'$_'" }) -Join ', ')"
}
