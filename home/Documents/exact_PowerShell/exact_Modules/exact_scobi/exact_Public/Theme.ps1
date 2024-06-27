# registry code adapted from https://okms.github.io/2021/01/dark-mode-cli-for-windows-using-powershell.html

# TODO: this is out of date with latest Win11, switch to theme-apply approach

$LightThemeRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Get-DarkMode {
    $props = Get-ItemProperty -Path $LightThemeRegPath
    $light = $props.AppsUseLightTheme -or $props.SystemUsesLightTheme

    $chezmoiPath = '~\.config\chezmoi\chezmoi.yaml'
    $theme = $light ? 'light' : 'dark'
    ((Get-Content -Raw $chezmoiPath) -replace 'theme: \S+', "theme: $theme").TrimEnd() | Out-File -Encoding ascii $chezmoiPath

    !$light
}
Export-ModuleMember Get-DarkMode

function Set-DarkMode {
    [CmdletBinding()]
    param (
        [switch]$Off,
        [switch]$Force
    )

    $light = $Off.ToBool()
    if (($light -eq !(Get-DarkMode)) -and !$force) {
        Write-Host "DarkMode already set to $(!$light), skipping os/file updates (use -Force to override this)"
        return
    }

    # update OS
    New-ItemProperty -Path $LightThemeRegPath -Name AppsUseLightTheme -Value $light -Type DWord -Force > $null
    New-ItemProperty -Path $LightThemeRegPath -Name SystemUsesLightTheme -Value $light -Type DWord -Force > $null

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
    $unityreg = $null
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
    [CmdletBinding()]
    param (
        [switch]$Force
    )

    Set-DarkMode -Off -Force:$Force
}
Export-ModuleMember Set-LightMode
