filter Get-FileInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path
    )

    $reader = [IO.StreamReader]::New((Resolve-Path $Path))
    $content = $reader.ReadToEnd()
    $encoding = $reader.CurrentEncoding.WebName
    $reader.Close()

    # silly test for "binary". ascii and utf8 shouldn't have nulls, binary usually will. utf16/32 will also, but i don't care about that.
    if ($content -match "`0") {
        if (Get-Command file) { # scoop install file :)
            file $Path
        }
        else {
            "$($Path): binary"
        }
    }
    else {
        $crlf = [regex]::Matches($content, "`r`n").Count
        $lf   = [regex]::Matches($content, "(?<!`r)`n").Count
    
        $eol = if ($crlf -and $lf) {
            "mixed ({0:.00}% crlf)" -f (($crlf/($crlf+$lf))*100)
        }
        elseif ($crlf) {
            "crlf"
        }
        elseif ($lf) {
            "lf"
        }
        else {
            "no eol found"
        }
    
        $info = "$encoding, $eol"
    
        if (Get-Command file) {
            (file $Path).Trim() + ", " + $info
        }
        else {
            "$($Path): $info"
        }
    }
}
Export-ModuleMember Get-FileInfo
