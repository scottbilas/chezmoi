Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# TODO: this is probably slow. should rely on .psd1 to export symbols instead.
# do a little profiling to see how big a deal this is, once the module gets big.

Get-ChildItem -ea:silent -r $PSScriptRoot/Private, $PSScriptRoot/Public *.ps1 | ForEach-Object { . $_ }
