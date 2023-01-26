# registry code adapted from https://okms.github.io/2021/01/dark-mode-cli-for-windows-using-powershell.html

$LightThemeRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Get-DarkMode {
    $props = Get-ItemProperty -Path $LightThemeRegPath
    !($props.AppsUseLightTheme -and $props.SystemUsesLightTheme)
}
Export-ModuleMember Get-DarkMode

function Set-DarkMode {
    [CmdletBinding()]
    param (
        [switch]$Off
    )

    # update OS
    $value = $Off.ToBool()
    New-ItemProperty -Path $LightThemeRegPath -Name AppsUseLightTheme -Value $value -Type DWord -Force > $null
    New-ItemProperty -Path $LightThemeRegPath -Name SystemUsesLightTheme -Value $value -Type DWord -Force > $null

    # update windows terminal chrome (necessary until https://github.com/microsoft/terminal/issues/1230 fixed)
    $chezmoiPath = '~\.config\chezmoi\chezmoi.yaml'
    $theme = $Off ? 'light' : 'dark'
    ((Get-Content -Raw $chezmoiPath) -replace 'theme: \S+', "theme: $theme").TrimEnd() | Out-File -Encoding ascii $chezmoiPath
    chezmoi apply ~/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json
    chezmoi apply ~/AppData/Roaming/LINQPad/RoamingUserOptions.xml

    # update p4v
    $p4vxpath = Resolve-Path -ea:silent '~\.p4qt\ApplicationSettings.xml'
    if ($p4vxpath) {
        $p4vxml = [xml](Get-Content $p4vxpath)

        $p4vtheme = $Off ? 'false' : 'true'
        $entry = $p4vxml.PropertyList.Bool | Where-Object { $_.varName -eq 'DarkTheme' }
        if ($entry -and $entry.'#text' -ne $p4vtheme) {

            if (get-process -ea:silent p4v) {
                # on p4v exit, it will overwrite the xml
                Write-Host 'P4V is running, theme cannot change automatically'
            }
            else {
                $entry.'#text' = $p4vtheme
                $p4vxml.Save($p4vxpath)
            }
        }
    }

    # update unity
    # try/catch because https://github.com/PowerShell/PowerShell/issues/5906
    try { $unityreg = Get-ItemPropertyValue -ea:silent 'HKCU:Software\Unity Technologies\Unity Editor 5.x' UserSkin_h307680651 } catch {}
    if ($null -ne $unityreg) {
        $unitytheme = $Off ? 0 : 1
        if ($unityreg -ne $unitytheme) {
            Set-ItemProperty 'HKCU:Software\Unity Technologies\Unity Editor 5.x' UserSkin_h307680651 $unitytheme

            if (get-process -ea:silent unity) {
                Write-Host 'Restart Unity for theme change to take effect (or manually update theme in editor prefs)'
            }
        }
    }

    # TODO: change wallpaper :D
}
Export-ModuleMember Set-DarkMode

function Set-LightMode {
    Set-DarkMode -Off
}
Export-ModuleMember Set-LightMode

function Remove-EmptyFolders {
    <#
    .SYNOPSIS
        Removes empty folders recursively from a root directory.
        The root directory itself is not removed.

        Author: Joakim Borger Svendsen, Svendsen Tech, Copyright 2022.
        MIT License.
        
        Semantic version: v1.0.0        
        https://github.com/EliteLoser/misc/blob/master/PowerShell/Remove-EmptyFolders.ps1
    .EXAMPLE
        . .\Remove-EmptyFolders.ps1
        Remove-EmptyFolders -Path E:\FileShareFolder
    .EXAMPLE
        Remove-EmptyFolders -Path \\server\share\data
    
    #>
    [CmdletBinding()]
    Param(
        [String] $Path
    )
    Begin {
        [Int32] $Script:Counter = 0
        if (++$Counter -eq 1) {
            $RootPath = $Path
            Write-Verbose -Message "Saved root path as '$RootPath'."
        }
        # Avoid overflow. Overly cautious?
        if ($Counter -eq [Int32]::MaxValue) {
            $Counter = 1
        }
    }
    Process {
        # List directories.
        foreach ($ChildDirectory in Get-ChildItem -LiteralPath $Path -Force |
            Where-Object {$_.PSIsContainer}) {
            # Use .ProviderPath on Windows instead of .FullName in order to support UNC paths (untested).
            # Process each child directory recursively.
            Remove-EmptyFolders -Path $ChildDirectory.FullName
        }
        $CurrentChildren = Get-ChildItem -LiteralPath $Path -Force
        # If it's empty, the condition below evaluates to true. Get-ChildItem 
        # returns $null for empty folders.
        if ($null -eq $CurrentChildren) {
            # Do not delete the root folder itself.
            if ($Path -ne $RootPath) {
                Write-Verbose -Message "Removing empty folder '$Path'."
                Remove-Item -LiteralPath $Path -Force
            }
        }
    }
}
Export-ModuleMember Remove-EmptyFolders

# like from choco (originally from https://stackoverflow.com/a/22670892/14582)
# TODO: print out what got updated!
# TODO: also have the registry path override the current path (like if anything was reordered there)
function refreshenv {
    foreach ($level in 'Machine', 'User') {
        [Environment]::GetEnvironmentVariables($level).GetEnumerator() | % {
            if ($_.Name -eq 'path') { 
                $_.Value = (((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select -unique) -join ';'
            }
            $_
        } | Set-Content -Path { "Env:$($_.Name)" }
    }
}
Export-ModuleMember refreshenv
