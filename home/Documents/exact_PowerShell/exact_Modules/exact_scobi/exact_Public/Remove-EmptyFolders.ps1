function Remove-EmptyFolders {
    <#
    .SYNOPSIS
        Removes empty folders recursively from a root directory.
        The root directory itself is not removed.
    .EXAMPLE
        Remove-EmptyFolders -Path E:\FileShareFolder
    .EXAMPLE
        Remove-EmptyFolders -Path \\server\share\data
    .EXAMPLE
        Remove-EmptyFolders -Path E:\FileShareFolder -WhatIf
    .EXAMPLE
        Remove-EmptyFolders -Path E:\FileShareFolder -Confirm

    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [String] $Path
    )
    Begin {
        # explicit state passed through recursion so -WhatIf can correctly include
        # folders that would become empty after deleting their empty descendants. this makes the
        # non-whatif scenario more complex, but that's an ok price to pay. 
        $state = [pscustomobject]@{
            RootPath = $Path
            Removed  = [hashtable]::new([StringComparer]::Ordinal) # track folders that are (actually or virtually) removed.
        }

        Remove-EmptyFoldersInternal -Path $Path -State $state
    }
}
Export-ModuleMember Remove-EmptyFolders

function Remove-EmptyFoldersInternal {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [String] $Path,
        [Parameter(Mandatory)]
        [psobject] $State
    )

    Process {
        # recurse into child dirs
        foreach ($ChildDirectory in Get-ChildItem -LiteralPath $Path -Force -Directory) {
            Remove-EmptyFoldersInternal -Path $ChildDirectory.FullName -State $State
        }

        # if it has any files, it's not empty and must abort
        if (Get-ChildItem -LiteralPath $Path -Force -File -ErrorAction SilentlyContinue |
            Select-Object -First 1) {
            return
        }

        # if it has any directories not already removed, it's not empty and must abort
        if (Get-ChildItem -LiteralPath $Path -Force -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not $State.Removed.ContainsKey($_.FullName) } |
            Select-Object -First 1) {
            return
        }

        # do not delete the root folder itself
        if ($Path -eq $State.RootPath) {
            return
        }

        # ok do the actual removal (maybe!)
        if ($PSCmdlet.ShouldProcess($Path, 'Remove empty folder')) {
            if (-not $WhatIfPreference) {
                Write-Output "Removing empty folder '$Path'."
            }
            Remove-Item -LiteralPath $Path -Force
            $State.Removed[$Path] = $true
        }
    }
}
