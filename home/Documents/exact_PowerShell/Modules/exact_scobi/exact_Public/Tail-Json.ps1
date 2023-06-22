function Tail-Json($path, $timestampField = 'timestamp', [switch]$skipToEnd) {

    $lastRead = 0
    if ($skipToEnd) {
        $lastRead = (Get-ChildItem $path -ea:continue).Length
    }

    for (;;) {
        for (;;) {
            try {
                $len = (Get-ChildItem $path -ea:stop).Length
                if ($len -ne $lastRead) {
                    Start-Sleep -seconds 1
                    if ((Get-ChildItem $path -ea:stop).Length -eq $len) {
                        break;
                    }
                }
            }
            catch { $lastRead = 0 }
            Start-Sleep -seconds 1
        }

        try {
            $file = new io.filestream($path, 'open', 'read', 'readwrite,delete')
            $file.seek($lastRead, 'begin') >$null
            $reader = new io.streamreader($file)
            for (;;) {
                $json = $reader.readline()
                $lastRead = $file.position
                if (!$json) { break }
                $json | convertfrom-json | ForEach-Object { "$([datetime]($_.$timestampField)) $($_.message)" }
            }
        }
        finally {
            $file.dispose()
        }
    }
}
Export-ModuleMember Tail-Json
