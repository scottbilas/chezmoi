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

            # parse config
            $yaml = Get-Content -raw $validConfigPath | ConvertFrom-Yaml

            # schema validation (don't bother on an empty or all-comments file tho)
            if ($yaml -and (Get-Command -ea:silent pajv)) {
                Write-Verbose "pajv --errors=text -d $validConfigPath -s $SchemaPath"
                $errors = pajv --errors=text -d $validConfigPath -s $SchemaPath 2>&1
                if ($LASTEXITCODE) {
                    throw (($errors |
                        Where-Object { $_.GetType().Name -eq "ErrorRecord" } |
                        ForEach-Object { $_.ToString() }
                    ) -join '; ')
                }
            }

            # cache config with defaults filled out
            $script:CachedConfig = Expand($yaml)
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
