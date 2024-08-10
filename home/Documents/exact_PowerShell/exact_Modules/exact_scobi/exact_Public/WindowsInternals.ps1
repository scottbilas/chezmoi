# see https://stackoverflow.com/a/78764635/14582
function Get-QuietHoursProfile {
    $rawData = Get-ItemPropertyValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.notifications.quiethourssettings\Current' Data
    $string = [Text.Encoding]::Unicode.GetString($rawData[0x1a..($rawData.length-1)])

    if ($string -notmatch 'Microsoft\.QuietHoursProfile\.(\w+)') { throw "/shrug"}
    $matches[1]
}
Export-ModuleMember Get-QuietHoursProfile
