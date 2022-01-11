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

    # TODO:
    #
    # * figure out how to get slack inside of wavebox to switch themes (will probably require an extension..)
    # * change wallpaper :D
}
Export-ModuleMember Set-DarkMode

function Set-LightMode {
    Set-DarkMode -Off
}
Export-ModuleMember Set-LightMode
