#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-SetupEnvPaths([string]$EnvPaths = $Env:PATH) {

    $result = [PSCustomObject]@{
        # fix any blank entries, which will cause problems in other funcs that don't expect it
        ResultPath = $EnvPaths.Split(';',
            [stringsplitoptions]::RemoveEmptyEntries -bor [stringsplitoptions]::TrimEntries) -Join ';'

        DuplicatePaths = @()
        InvalidPaths = @()
    }

    $uniques = @{}

    foreach ($item in $result.ResultPath -Split ';') {
        # some paths have trailing backslash, remove for canonical compare
        $item = $item -Replace '[/\\]+$', ''

        # posh 7 (at least) inserts its own path at the front of PATH. but we can't just remove
        # it from the system path, otherwise everything else (like mswinterm) wanting to run `pwsh`
        # will have to fully-qualify it.
        $ispshome = $item -eq $PSHOME

        if (!$ispshome -and $uniques.ContainsKey($item)) {
            $result.DuplicatePaths += $item
        }
        else {
            if (!$ispshome) { $uniques.Add($item, 0) }
            if (!(Test-Path -ea:silent ([Environment]::ExpandEnvironmentVariables($item)))) {
                $result.InvalidPaths += $item
            }
        }
    }

    $result
}
Export-ModuleMember Invoke-SetupEnvPaths

function Invoke-FixExplorerIconCache {
    # from https://answers.microsoft.com/en-us/xbox/forum/all/broken-shortcut-icons-in-windows-11/f95d31d5-babf-494a-b16f-042e1442a287?auth=1


}
