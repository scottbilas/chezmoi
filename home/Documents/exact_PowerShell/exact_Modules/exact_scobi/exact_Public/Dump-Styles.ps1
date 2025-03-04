function Dump-Styles {
    $styles = @(
        @{ Style = $PSStyle.Bold; Name = "Bold" },
        @{ Style = $PSStyle.Italic; Name = "Italic" },
        @{ Style = $PSStyle.Underline; Name = "Underline" },
        @{ Style = $PSStyle.Strikethrough; Name = "Strike" },
        @{ Style = $PSStyle.Reverse; Name = "Reverse" },
        @{ Style = $PSStyle.Blink; Name = "Blink (if supported)" },
        @{ Style = $PSStyle.Hidden; Name = "Hidden (invisible)" }
    )

    $fgColors = @{
        ' Blk ' = $PSStyle.Foreground.Black
        ' Red ' = $PSStyle.Foreground.Red
        ' Grn ' = $PSStyle.Foreground.Green
        ' Yel ' = $PSStyle.Foreground.Yellow
        ' Blu ' = $PSStyle.Foreground.Blue
        ' Mag ' = $PSStyle.Foreground.Magenta
        ' Cyn ' = $PSStyle.Foreground.Cyan
        ' Wht ' = $PSStyle.Foreground.White
        'BrRed' = $PSStyle.Foreground.BrightRed
        'BrGrn' = $PSStyle.Foreground.BrightGreen
        'Brblu' = $PSStyle.Foreground.BrightBlue
        'BrYel' = $PSStyle.Foreground.BrightYellow
    }

    $bgColors = @{
        ' Blk ' = $PSStyle.Background.Black
        ' Red ' = $PSStyle.Background.Red
        ' Grn ' = $PSStyle.Background.Green
        ' Yel ' = $PSStyle.Background.Yellow
        ' Blu ' = $PSStyle.Background.Blue
        ' Mag ' = $PSStyle.Background.Magenta
        ' Cyn ' = $PSStyle.Background.Cyan
        ' Wht ' = $PSStyle.Background.White
        'BrRed' = $PSStyle.Background.BrightRed
        'BrGrn' = $PSStyle.Background.BrightGreen
        'Brblu' = $PSStyle.Background.BrightBlue
        'BrYel' = $PSStyle.Background.BrightYellow
    }

    $fgProps = $PSStyle.Foreground.PSObject.Properties
    $bgProps = $PSStyle.Background.PSObject.Properties

    #$PSStyle.Background.PSObject.Properties['red'].Value

    $sz = ($fgProps.Name | measure -max length).Maximum

    Write-Host -NoNewLine ("$($PSStyle.Foreground.BrightBlack){0,$sz} {1}$($PSStyle.Reset)" -f 'fg↓', 'bg→')
    $i = 0
    foreach ($dummy in $bgProps.Name) {
        Write-Host -NoNewline (" $($PSStyle.Italic){0,2}$($PSStyle.Reset)   " -f $i++)
    }
    Write-Host

    $i = 0
    foreach ($fg in $fgProps.Name) {
        Write-Host -NoNewLine ("{0,$sz} $($PSStyle.Italic){1,2}$($PSStyle.ItalicOff) " -f $fg, $i++)
        foreach ($bg in $bgProps.Name) {
            Write-Host -NoNewline "$($fgProps[$fg].Value)$($bgProps[$bg].Value) Abc $($PSStyle.Reset) "
        }
        Write-Host
    }
    Write-Host
    $styles | ForEach-Object { Write-Host -NoNewline "$($_.Style)$($_.Name)$($PSStyle.Reset) " }
}
Export-ModuleMember Dump-Styles
