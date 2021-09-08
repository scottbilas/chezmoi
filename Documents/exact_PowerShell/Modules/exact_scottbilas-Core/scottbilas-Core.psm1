# registry code adapted from https://okms.github.io/2021/01/dark-mode-cli-for-windows-using-powershell.html
function Set-DarkMode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('On', 'Off', 'Status')]
        [string]$State        
    )

    $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    if ($State -eq "Status") {
        $props = Get-ItemProperty -Path $regPath
        return $props.AppsUseLightTheme -and $props.SystemUsesLightTheme ? "Off" : "On"
    }     

    # update OS
    $value = $State -eq 'Off' ? 1 : 0
    New-ItemProperty -Path $regPath -Name AppsUseLightTheme -Value $value -Type DWord -Force > $null
    New-ItemProperty -Path $regPath -Name SystemUsesLightTheme -Value $value -Type DWord -Force > $null

    # update windows terminal chrome (necessary until https://github.com/microsoft/terminal/issues/1230 fixed)
    $chezmoiPath = '~\.config\chezmoi\chezmoi.yaml'
    $theme = $State -eq 'Off' ? 'light' : 'dark'
    ((Get-Content -Raw $chezmoiPath) -replace 'theme: \S+', "theme: $theme").TrimEnd() | Out-File -Encoding ascii $chezmoiPath
    chezmoi apply ~/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json

    # TODO:
    #
    # * figure out how to get slack inside of wavebox to switch themes (will probably require an extension..)
    # * change wallpaper :D
}
