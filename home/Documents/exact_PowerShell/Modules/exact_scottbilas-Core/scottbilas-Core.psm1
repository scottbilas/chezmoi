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
    $unityreg = Get-ItemPropertyValue -ea:silent 'HKCU:Software\Unity Technologies\Unity Editor 5.x' UserSkin_h307680651
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
