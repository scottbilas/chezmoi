$LightThemeRegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Update-ProfileData($light) {
    $chezmoiPath = '~\.config\chezmoi\chezmoi.yaml'
    $theme = $light ? 'light' : 'dark'
    ((Get-Content -Raw $chezmoiPath) -replace 'theme: \S+', "theme: $theme").TrimEnd() | Out-File -Encoding ascii $chezmoiPath
}
# noexport

function Get-DarkMode {
    $props = Get-ItemProperty -Path $LightThemeRegPath
    $light = $props.AppsUseLightTheme -or $props.SystemUsesLightTheme

    Update-ProfileData $light
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

    # update OS - don't do the registry stuff that everyone online says to do, none of it works fully, and the workarounds
    # really suck. dark/light theme file is way simpler and always works.
    #
    # just two issues with this:
    #
    #   1. it will apply everything in the theme file. themes are fully specified, too. if a wallpaper is not specified,
    #      then you get a solid black background, not "leave wallpaper alone".
    #
    #      there is a "Custom.theme" that gets generated, could copy that (can't modify it, as it gets auto restored by
    #      windows) to something else, set it to dark, and apply it. but when user simply sets the wallpaper without
    #      doing it through a theme, it will get stored elsewhere, and then overwritten.
    #
    #      so instead, just maintain the windows themes according to each machine. it's not the end of the world.
    #
    #   2. the settings personalization app opens and needs to be manually closed.
    #
    #      would have to detect that the window actually opens and changes (don't want to close existing settings app
    #      that was already open) which requires some window lookup and screen reader shit to detect it's in
    #      "Personalization" panel. nope.
    #
    $themeName = $light ? 'light' : 'dark'
    $themePath ="$env:LOCALAPPDATA\Microsoft\Windows\Themes\scobi-$($($env:COMPUTERNAME).ToLower())-$themeName.theme"

    if (!(Test-Path $themePath)) {
        throw "Missing theme file from '$themePath'"
    }

    & $themePath
    Update-ProfileData $light

    chezmoi apply ~/AppData/Roaming/LINQPad/RoamingUserOptions.xml
    chezmoi apply ~/.config/git/delta-current-theme.gitconfig

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
