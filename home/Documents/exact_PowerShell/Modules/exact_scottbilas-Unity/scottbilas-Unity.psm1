#Requires -Version 7
#Requires -Modules Native, powershell-yaml
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


<#
    Unity module

    Purpose: support common workflows in Unity

        * Run Unity
            * Choose an EXE
                * Match something I already have on my machine (latest beta or released, or give me a chooser)
                * Whatever this project wants, or use a matcher to select something close if I don't have it
                * A specific (hash, full version name) or partial version name (just the year and dot.., or "latest beta" perhaps)
                * Warnings about debug vs release, or mismatched project causing an upgrade (does Unity do this already? or was it the Hub?)
            * Set env and command line etc.
                * Standard flags I always set, like mixed stacks and log output
                * Make Unity's flags visible with tab completion (something like Crescendo would do..except Crescendo doesn't seem to support parameterized exe location..)
                * Support an individual project's extensions to tab completion for any command line flags the project supports
                * PSReadLine support for tabbing through matching discovered unity versions
            * Support the exe run
                * Start separate job watching unity.exe and monitoring pmip files from it, holding handle open and copy on process exit
                * Hub killing
                * Log rotation
                * Automatic bringing to front of an existing Unity (avoid Unity's stupid handling of this)

        * Manage Unity installations
            * Download with cli downloader (specific version or fuzzy, but still expanded to full version name+hash for install folder)
            * Upgrade an install (add symbols to an existing installation)
            * Install into or remove from Hub (clean up Hub install tracker json)
            * Download and install a public release (invoke-webrequest https://unity3d.com/get-unity/download/archive and rx `https://[^"]+UnitySetup(64)?-(\d+\.\d+\.\w+)\.exe`)

    Also requires some utilities:

        * Detection of whether a folder/file is in a Unity project and find the project root
        * Detection of a Unity project's version
        * Detection of various build related info, especially versions related to Unity and its components (like mono)
        * Enumeration of builds - cli-downloaded, Hub-installed, download site-installed, locally built trunk, etc.
        * Crescendo wrapper for cli downloader
        * Some kind of caching into a json to avoid re-scanning all the folders every time
        * oh-my-posh prompt support for when within a Unity project (show version number etc.)


#>


# TODO support arrays here, including autodetect from hub state and custom builds
# TODO make this a dirinfo? want it to be optional though..
$DefaultBuildsRoot = 'c:\builds\editor'

function Get-UnityBuildConfig($UnityExePath) {

    # least awful method, given we don't store buildconfig in VERSIONINFO..just go by some kind of size threshold
    # https://unity.slack.com/archives/C07B85AE5/p1586853975112200?thread_ts=1586852005.107100&cid=C07B85AE5

    $fileSize = (Get-Item $UnityExePath).Length

    if ($fileSize -gt 60MB -and $fileSize -lt 150MB) { return 'Release' }
    if ($fileSize -gt 300MB -and $fileSize -lt 400MB) { return 'Debug' }

    throw "Unexpected size of $UnityExePath, need to revise detection bounds for Unity buildconfig"
}
Export-ModuleMember Get-UnityBuildConfig

function Get-MonoBuildConfig($MonoDllPath) {

    # same as unity, no info in VERSIONINFO i can use

    $fileSize = (Get-Item $MonoDllPath).Length

    if ($fileSize -gt 4MB -and $fileSize -lt 7.5MB) { return 'Release' }
    if ($fileSize -gt 9MB -and $fileSize -lt 11MB) { return 'Debug' }

    throw "Unexpected size $([Math]::Round($fileSize / 1MB, 2))MB for $MonoDllPath, need to revise detection bounds for Mono buildconfig (rel=4-7.5MB, dbg=9-11MB)"
}
Export-ModuleMember Get-MonoBuildConfig

function Get-IsUnityProject($ProjectPath) {
    $resolvedItem = Get-Item $ProjectPath

    # must have a ProjectVersion.txt
    $projectVersionTxt = Get-Item -ea:silent (Join-Path $resolvedItem ProjectSettings\ProjectVersion.txt)
    if (!$projectVersionTxt -or $projectVersionTxt.PSIsContainer) { return $false }

    # must have an Assets folder
    $assetsDir = Get-Item -ea:silent (Join-Path $resolvedItem Assets)
    if (!$assetsDir -or !$assetsDir.PSIsContainer) { return $false }

    $true
}
Export-ModuleMember Get-IsUnityProject

# `using module scottbilas-Unity` to pick this up in the profile
enum UnityVersionMatch {
    # important: order must be increasing in fuzziness

    Exact       # precise match
    NoHash      # same version, but hash is different
    # NoRelease (2020.1.3f4 etc. is close enough to 2020.1.3f8)
    # NoMinorMinor
    # don't forget about the -dots type of postfix..maybe if that doesn't match, the whole thing refuses to match without a -Force
    # alpha vs beta vs release?
    # custom local builds? including my own branch names and so on..?
    # break down by component and then have helpers (like Exact) to OR them together..?
}

[UnityVersionMatch] | Add-Member -Force -MemberType ScriptMethod IsMatch {
    param(
        [UnityVersionMatch]$actualMatch,
        [UnityVersionMatch]$requestedMatch
    )

    # if the actual match is as or more strict than the reqested match, yahtzee
    $actualMatch -le $requestedMatch
}

<#
.Description
Gets the Unity version and hash from the EXE, project, or version file at the given path. If not given an EXE directly,
attempts to find one in $BuildsRoot. Also attempts to discover useful attributes of the given build, if found.
#>
function Get-UnityInfo {
    [CmdletBinding()]
    param(
        # TODO: take $Version, $Hash, $VersionText and parse
        [Parameter(ValueFromPipeline)]$Path = (Get-Location),
        [string]$BuildsRoot = $DefaultBuildsRoot
    )

    Process {

    # TODO: split up these parts of the function into separate functions, then have an outer one with `-IncludeExeInfo` or whatever optionally call them
    #
    #   * get the projectversion from a folder/file
    #   * try to find a unity exe that matches (exact, partial, custom, etc..)
    #   * take a given unity exe and fill in a bunch more info about it and its components/origin
        $resolvedItem = Get-Item $Path
        if (!$resolvedItem) { return }

        # if it's a directory, get at the project's version file
        if ($resolvedItem.PSIsContainer) {
            $resolvedItem = Get-Item -ea:silent (Join-Path $Path ProjectVersion.txt)
            if (!$resolvedItem) {
                $resolvedItem = Get-Item -ea:silent (Join-Path $Path ProjectSettings ProjectVersion.txt)
                if (!$resolvedItem) {
                    # try getting unity.exe at that path..
                    $resolvedItem = Get-Item -ea:silent (Join-Path $Path Unity.exe)
                    if (!$resolvedItem) {
                        return Write-Error "No Unity exe or project found at $Path"
                    }
                }
            }
        }

        if ($resolvedItem.Extension -eq '.txt') {

            # projectversion route

            if ((Get-Content -Raw $resolvedItem) -notmatch 'm_EditorVersionWithRevision: (\S+) \((\S+)\)') {
                return Write-Error "Unable to extract version number from $resolvedItem"
            }

            $result = [pscustomobject]@{ Version=$Matches[1]; Hash=$Matches[2]; ProjectVersionFile=$resolvedItem }

            $unityExe = Get-Item -ea:silent (Join-Path $BuildsRoot "$($result.Version)-$($result.Hash)" Unity.exe)
            if ($unityExe) {
                $result | Add-Member UnityExe $unityExe
                $result | Add-Member UnityVersionMatch ([UnityVersionMatch]::Exact)
            }
            else {
                $unityExe = Get-Item (Join-Path $BuildsRoot "$($result.Version)-*" Unity.exe) |
                    Sort-Object -Descending LastWriteTime |
                    Select-Object -First 1
                if ($unityExe) {
                    $result | Add-Member UnityExe $unityExe
                    $result | Add-Member UnityVersionMatch ([UnityVersionMatch]::NoHash)
                }
                else {
                    # TODO: break down 2020.3.14f1-dots-051fb20b3877 to do a partial match that requires the 
                    # same branch, major, and minor, but allows fuzzy matching on 2020.3.(\d+)([a-z]?\d+)
                }

                # TODO: additional validation that the Unity.exe we've found in a given dir matches its folder name exactly
            }

            # part of a project?
            $projectPathProbe = Get-Item -ea:silent (Split-Path $resolvedItem);
            if ($projectPathProbe) {
                $projectPathProbe = $projectPathProbe.Parent;
                if ($projectPathProbe -and (Get-IsUnityProject $projectPathProbe)) {
                    $result | Add-Member ProjectPath $projectPathProbe
                }
            }
        }
        else {

            # unity.exe route

            $versioninfo = $resolvedItem.VersionInfo;
            if ($versioninfo.FileDescription -ne 'Unity Editor') {
                return Write-Error "Binary found at $resolvedItem is not the Unity Editor"
            }

            $comments = $versioninfo.Comments
            if (!$comments) {
                return Write-Error "Unity at $_path has unexpected VERSIONINFO contents (missing 'Comments' field)"
            }
            if ($comments -notmatch '(\S+) \((\S+)\)') {
                return Write-Error "Unity at $_path has unexpected VERSIONINFO.Comments format (found '$comments')"
            }

            $result = [pscustomobject]@{ Version=$Matches[1]; Hash=$Matches[2]; UnityExe=$resolvedItem; UnityVersionMatch=([UnityVersionMatch]::Exact) }
        }

        # if we found a unity.exe, try to get some more interesting info on it
        if ($result.PSObject.Properties.Item("UnityExe")) {
            $unityFolder = Split-Path $result.UnityExe

            $result | Add-Member UnityBuildConfig (Get-UnityBuildConfig $result.UnityExe)
        
            $udcliPath = Get-Item -ea:silent (Join-Path $unityFolder .unity-downloader-meta.yml)
            if ($udcliPath) {
                $udcliMeta = Get-Content $udcliPath | ConvertFrom-Yaml
                $result | Add-Member UnityBranch $udcliMeta.revision_info.branch
                $result | Add-Member InstalledComponents $udcliMeta.components.Keys
            }
        
            $result | Add-Member MonoRuntimeDll (Get-Item (Join-Path $unityFolder Data/MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll))
            $result | Add-Member MonoRuntimeBuildConfig (Get-MonoBuildConfig $result.MonoRuntimeDll)
        
            $result | Add-Member -MemberType ScriptMethod GetVersionFull { "$($this.Version)-$($this.Hash)" }
        }

        $result
    }
}
Export-ModuleMember Get-UnityInfo

function Install-Unity2 { # TODO :/
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]$Version, # TODO: validate this is actually a version object, not just text/int
        [string]$BuildsRoot = $DefaultBuildsRoot,
        [switch]$IncludeSymbols,
        [switch]$IncludeStandaloneIL2CPP)

    Install-Unity `
        -Version:$Version.Version `
        -Hash:$Version.Hash `
        -IncludeSymbols:$IncludeSymbols `
        -IncludeStandaloneIL2CPP:$IncludeStandaloneIL2CPP `
        -WhatIf:$WhatIfPreference
}

function Get-UnityVersion($Version) {
    #$results = unity-downloader-cli -u $Version -s -c Editor
    #^^ not working because sublaunch process not getting redirected
    #^^ Henrik says "Version:" and the following hash should be relatively stable
    # https://unity.slack.com/archives/CCXLULRGV/p1636717847023300?thread_ts=1631517211.016500&cid=CCXLULRGV
    # until fixed, just have this do the query and show it, but not actually try to parse

    unity-downloader-cli -u $Version -s -c Editor
}
Export-ModuleMember Get-UnityVersion

function Install-Unity {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Hash,

        [string]$BuildsRoot = $DefaultBuildsRoot,

        [switch]$IncludeSymbols,
        [switch]$IncludeStandaloneIL2CPP
    )

    $installPath = Join-Path $BuildsRoot "$Version-$Hash"

    # let udcli deal with ignoring already-downloaded components
    $udargs = 'unity-downloader-cli', '-u', $Hash, '-p', $installPath, '-c', 'Editor'
    if ($IncludeSymbols) {
        $udargs += '-c', 'Symbols'
    }
    if ($IncludeStandaloneIL2CPP) {
        $udargs += '-c', 'StandaloneSupport-IL2CPP'
    }
    $udargs += '--wait'

    if ($PSCmdlet.ShouldProcess($udargs -join ' ')) { 
        iee @udargs

        # we have full symbols, so nuke the stripped symbols otherwise vs may use them as the pdb is in the same folder as the exe
        if ($IncludeSymbols) {
            Remove-Item -Verbose:$VerbosePreference $installPath\*.pdb
        }
    }

    # TODO: support downloading from unity public web site, or perhaps driving the Hub..

    # TODO: (consider) support telling the Hub about the newly installed build
}
Export-ModuleMember Install-Unity

function Find-UnityProjects {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][string]$Path = (Get-Location),
        [int]$SearchDepth = 1
    )

    Get-ChildItem -Path $Path -Depth $SearchDepth -Filter 'ProjectSettings' | ForEach-Object {
        # if we have this file and this path, then it's probably a unity project
        if ((Test-Path (Join-Path $_ 'ProjectVersion.txt')) -and (Test-Path (Join-Path $_ '../Assets'))) {
            # could return it as a DirectoryInfo, but that gets confusing when also using -Depth, because the default
            # formatted result appears to be (if you look quickly) the contents of a single dir. could improve this
            # with a subclass or something for DirectoryInfo that can have a better formatter on it..but for now just
            # go with the string path. can `Get-Info` on it if really needed.
            $_.Parent.FullName
        }
    }
}
Export-ModuleMember Find-UnityProjects

function Start-UnityForProject {

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline)] $ProjectPath = (Get-Location),
        [UnityVersionMatch]$BuildMatch = [UnityVersionMatch]::Exact,
        $UnityBuild,
        [switch] $AttachDebugger,
        [switch] $VerboseUpmlogs,
        [switch] $Rider,
        [switch] $NoBurst,
        [switch] $NoLocalLog
    )

    $info = Get-UnityInfo $ProjectPath

    if (!$info.PSObject.Properties.Item('ProjectPath')) {
        return Write-Error "No Unity project at $ProjectPath"
    }
    if (!$info.PSObject.Properties.Item('UnityExe')) {
        return Write-Error "No Unity exe found for project at $ProjectPath (version = $($info.GetVersionFull()))"
    }
    if (![UnityVersionMatch].IsMatch($info.UnityVersionMatch, $BuildMatch)) {
        return Write-Error "Unity Version does not match (expected: $($info.GetVersionFull()), match: $($info.UnityVersionMatch), found: $($info.UnityExe))"
    }

    $unityArgs = '-projectPath', $info.ProjectPath

    if ($VerboseUpmlogs) {
        write-warning "Turning on extra debug logging for UPM (%LOCALAPPDATA%\Unity\Editor\upm.log)"
        $unityArgs += '-enablePackageManagerTraces'
    }

    if ($Rider) {
        $unityArgs += '-executeMethod', 'Packages.Rider.Editor.RiderScriptEditor.SyncSolutionAndOpenExternalEditor'
    }

    if ($NoBurst) {
        $unityArgs += "--burst-disable-compilation"
    }

    # override with project-local log file (unity..this should be DEFAULT)
    if (!$NoLocalLog) {
        $logPath = Join-Path $info.ProjectPath Logs
        $logProject = $info.ProjectPath.BaseName

        $logFilename = Join-Path $logPath "$logProject-editor.log"
        $logFile = Get-Item -ea:silent $logFilename

        # rotate out old log
        if ($logFile) {
            $targetBase = Join-Path $logPath ("$logProject-editor_{0:yyyyMMdd_HHMMss}" -f $logFile.LastWriteTime)
            Move-Item $logFile "$targetBase.log"
        }

        $unityArgs += '-logFile', $logFilename
    }

    # TODO: check to see if a unity already running for that path. either activate if identical to the one we want (and command line we want)
    # or abort if different with warnings.

    if ($PSCmdlet.ShouldProcess("$($info.UnityExe) $unityArgs", "Running Unity")) {
        $oldAttach = $Env:UNITY_GIVE_CHANCE_TO_ATTACH_DEBUGGER
        $oldMixed = $Env:UNITY_MIXED_CALLSTACK
        $oldExtLog = $Env:UNITY_EXT_LOGGING
        try {
            if ($AttachDebugger) {
                $Env:UNITY_GIVE_CHANCE_TO_ATTACH_DEBUGGER = 1
            }

            # always want these features
            $Env:UNITY_MIXED_CALLSTACK = 1
            $Env:UNITY_EXT_LOGGING = 1

            & $info.UnityExe @unityArgs
        }
        finally {
            $Env:UNITY_GIVE_CHANCE_TO_ATTACH_DEBUGGER = $oldAttach
            $Env:UNITY_MIXED_CALLSTACK = $oldMixed
            $Env:UNITY_EXT_LOGGING = $oldExtLog
        }
    }
}
Export-ModuleMember Start-UnityForProject

<#

function Get-UnityForProject($projectPath, [switch]$skipCustomBuild, [switch]$forceCustomBuild, $customBuild = $null) {

    $version, $hash = Get-UnityInfoFromProjectVersion -getHash $projectPath
    $forcingCustomHash = $false

    if ($customBuild) {
        if (!(test-path $customBuild)) {
            throw "Cannot find custom build given '$customBuild'"
        }
        $customExePath = $customBuild
        if ((split-path -leaf $customExePath) -ne 'unity.exe') {
            $customExePath = join-path $customBuild 'unity.exe'
            if (!(test-path $customExePath)) {
                $customExePath = join-path $customBuild 'build/windowseditor/unity.exe'
            }
        }
        $exePath = resolve-path $customExePath
        if (!(test-path $exePath)) {
            throw "Cannot find custom build given '$exePath'"
        }
        $exeVersion, $exeHash = Get-UnityInfoFromExe -getHash $exePath

        if ($skipCustomBuild) {
            throw "Wat you cannot give custom build and also skip it"
        }
    }
    else {
        $exePath = "$buildsEditorRoot\$version\unity.exe"

        $exeVersion, $exeHash = $null, $null
        if (test-path $exePath) {
            $exeVersion, $exeHash = Get-UnityInfoFromExe -getHash $exePath
            if ($exeVersion -ne $version) {
                throw "Unity at $exePath has version $exeVersion, but was expecting $version"
            }
        }
        else {
            $exePath = $null
        }

        if ($forceCustomBuild -and $skipCustomBuild) {
            throw "Wat you cannot force and skip"
        }

        $foundCustomBuilds = @()
        if ($forceCustomBuild -or (!$skipCustomBuild -and $exeHash -ne $hash)) {
            $built = 'c:', 'd:' | %{ dir "$_\work\unity*" -ea:silent } | ?{ $_ -match 'unity\d*$' } | %{ "$_\build\WindowsEditor" }
            foreach ($base in $built + "$projectPath\..\Unity\Editor") {
                $customExe = join-path $base 'Unity.exe'
                if (test-path $customExe) {
                    $customExe = resolve-path $customExe
                    $customVersion, $customHash = Get-UnityInfoFromExe -getHash $customExe
                    $foundCustomBuilds += "$customVersion.$customHash"
                    if ($customVersion -eq $version) {
                        if ($customHash -eq $hash) {
                            write-warning "Substituting custom build found matching $customVersion/$customHash ($customExe)"
                            $exePath = $customExe
                            $exeHash = $customHash
                            break
                        }
                        elseif ($forceCustomBuild) {
                            write-warning "(forceCustomBuild=true) Substituting custom build found with same version but different hash $customVersion/$customHash ($customExe)"
                            $exePath = $customExe
                            $exeHash = $customHash
                            $forcingCustomHash = $true
                            break
                        }
                    }
                }
            }
        }

        if (!$exePath) {
            if ($skipCustomBuild) {
                throw "Cannot find standard build for version $version.$hash"
            }
            elseif ($foundCustomBuilds) {
                throw "Cannot find either standard or custom build for version $version.$hash (found custom builds: $foundCustomBuilds)"
            }
            else {
                throw "Cannot find either standard or custom build for version $version.$hash"
            }
        }
    }

    if (!$forcingCustomHash -and $exePath -and ($exeHash -ne $hash)) {
        write-warning "Found matching $exeVersion at $exePath, but unable to find exact hash $hash installed or in custom builds"
    }

    $buildConfig = get-unitybuildconfig $exePath
    if ($buildConfig -ne 'release') {
        write-warning "Unity: running non-release build ($buildConfig) of $(split-path -leaf $exePath)"
    }

    $monoPath = join-path (split-path $exePath) 'Data/MonoBleedingEdge/EmbedRuntime/mono-2.0-bdwgc.dll'
    $buildConfig = get-monobuildconfig $monoPath
    if ($buildConfig -ne 'release') {
        write-warning "Mono: running non-release build ($buildConfig) of $(split-path -leaf $monoPath)"
    }

    $exePath
}

#>

<#
#$path = '$env:APPDATA\UnityHub\logs\info-log.json'

function Tail-Json($path, $timestampField = 'timestamp', [switch]$skipToEnd) {

    $lastRead = 0
    if ($skipToEnd) {
        $lastRead = (dir $path -ea:continue).Length
    }

    for (;;) {
        for (;;) {
            try {
                $len = (dir $path -ea:stop).Length
                if ($len -ne $lastRead) {
                    sleep -seconds 1
                    if ((dir $path -ea:stop).Length -eq $len) {
                        break;
                    }
                }
            }
            catch { $lastRead = 0 }
            sleep -seconds 1
        }

        try {
            $file = new io.filestream($path, 'open', 'read', 'readwrite,delete')
            $file.seek($lastRead, 'begin') >$null
            $reader = new io.streamreader($file)
            for (;;) {
                $json = $reader.readline()
                $lastRead = $file.position
                if (!$json) { break }
                $json | convertfrom-json | %{ "$([datetime]($_.$timestampField)) $($_.message)" }
            }
        }
        finally {
            $file.dispose()
        }
    }
}
#>
