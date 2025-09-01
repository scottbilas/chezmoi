# inspired by Kindle app, which sets a global hotkey, wtf

function Dump-StartMenuShortcuts {
    foreach ($path in
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:USERPROFILE\Desktop",
        "$env:PUBLIC\Desktop",
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch",
        "$env:APPDATA\Microsoft\Windows\Recent") {
        if (-Not (Test-Path -Path $path)) {
            continue
        }
        write-host "Checking $path..."
        Get-ChildItem -Path $path -Recurse -Filter *.lnk | ForEach-Object {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($_.FullName)
            if ($shortcut.Hotkey -and $shortcut.Hotkey -ne "") {
                [PSCustomObject]@{
                    Shortcut     = $_.FullName
                    Hotkey       = $shortcut.Hotkey
                    TargetPath   = $shortcut.TargetPath
                }
            }
        }
    }
}
Export-ModuleMember Dump-StartMenuShortcuts
