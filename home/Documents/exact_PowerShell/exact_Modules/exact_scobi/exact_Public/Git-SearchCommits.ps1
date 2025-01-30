function Git-SearchCommits {
    [CmdletBinding()]
    param($pattern)

    $maxWidth = [Console]::WindowWidth-1

    $styles = @{
        heading = $PSStyle.Background.Yellow + $PSStyle.Foreground.Black
        date = $PSStyle.Foreground.Green
        desc = $PSStyle.Foreground.Blue
        prefix = $PSStyle.Foreground.BrightRed
    }
    
    function line($front, $mid, $back) {
    
        function strip($str) {
            $str -replace '\e\[[0-9;]*[mK]'
        }
        
        $extra = ((strip $front).Length + (strip $mid).Length + (strip $back).Length) - $maxWidth
        if ($extra -gt 0) {
            $newLen = $mid.Length - $extra
            if ($newLen -gt 0) {
                $mid = $mid.Substring(0, $newLen) + '…'
            }
            else {
                $mid = ''
            }
        }
    
        $front + $PSStyle.Reset + $mid + $PSStyle.Reset + $back + $PSStyle.Reset
    }
    
    git log -p -S $pattern --pretty=format:'desc %h;%ad;%s' --date=relative -- *.cs | %{
        if ($_ -match '^desc (.*)') {
            $hash, $date, $desc = $matches[1] -split ';'
            ''
            line `
                ($styles.heading + $hash) `
                ($styles.desc + " $desc") `
                ($styles.date + " ($date)")
            ''
        }
        elseif ($_ -match '\+{3} b/(.*)') {
            '  ' + $PSStyle.Foreground.Green + $matches[1] + $PSStyle.Reset
        }
        elseif ($_ -match "([-+])\s*($([regex]::Escape($pattern)).*)") {
            line ($styles.prefix + "    $($matches[1]) ") $matches[2]
        }
    }
}
Export-ModuleMember Git-SearchCommits
