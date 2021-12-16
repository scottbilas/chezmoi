Set-StrictMode -Version Latest

$script:CachedConfig = $null
$script:LastHash = $null

const ConfigPath = '~/.config/okunity/config.yaml'
const SchemaPath = (Resolve-Path $PSScriptRoot\..\config.schema.json)

function Get-OkUnityConfig {
    [CmdletBinding()]
    param($ConfigPath)

    function Expand($db) {
        if (!$db) { $db = @{} }
        if (!$db.ContainsKey('builds')) { $db.builds = @{} }
        if (!$db.builds.ContainsKey('global')) { $db.builds.global = @() }
        if (!$db.builds.ContainsKey('project')) { $db.builds.project = @() }
        return $db
    }

    $testConfigPath = $ConfigPath ?? $script:ConfigPath
    $validConfigPath = Resolve-Path -ea:silent $testConfigPath

    if ($validConfigPath) {

        # cached config if hash hasn't changed
        $hash = (Get-FileHash $validConfigPath).Hash
        if ($script:LastHash -ne $hash) {

            # status
            if ($script:LastHash) {
                Write-Verbose "Config file $validConfigPath has changed"
            }
            else {
                Write-Verbose "Parsing config file $validConfigPath for the first time"
            }

            # schema validation
            if (Get-Command pajv) {
                Write-Verbose "Using pajv to validate via schema $SchemaPath"
                ie pajv --errors=text -d $validConfigPath -s $SchemaPath >$null
            }

            # parse and cache config
            $script:CachedConfig = Expand(Get-Content $validConfigPath | ConvertFrom-Yaml)
            $script:LastHash = $hash
        }
    }
    elseif ($ConfigPath) {
        Write-Error "Config file $ConfigPath does not exist"
    }
    elseif ($LastHash) {
        Write-Verbose "Config file $testConfigPath was deleted"
    }
    elseif (!$script:CachedConfig) {
        Write-Verbose "No config file detected at $testConfigPath"
    }

    if (!$script:CachedConfig) {
        $script:CachedConfig = Expand($null)
        $LastHash = $null
    }

    $script:CachedConfig
}
