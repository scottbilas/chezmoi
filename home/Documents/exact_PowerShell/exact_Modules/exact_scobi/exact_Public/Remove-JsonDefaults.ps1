function Remove-JsonDefaults {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [string] $JsonPath
    )

    # fields with these values will be stripped
    $defaultValues = $null, 'null', '', '0', '0.0', 'false', '1970-01-01 00:00:00.000000 UTC'

    $jsonObject = Get-Content $JsonPath | ConvertFrom-Json

    function IsKeyValue($obj) {
        $pnames = @($obj.PSObject.Properties | ForEach-Object Name)
        $pnames.Count -eq 2 -and $pnames -contains 'Key' -and $pnames -contains 'Value'
    }

    function PropertyCount($obj) {
        @($obj.PSObject.Properties).Count
    }

    function StripDefaults($obj) {
        $obj.PSObject.Properties | ForEach-Object {
            if ($_.Value -is [PSCustomObject]) {
                $iskv = IsKeyValue $_.Value
                StripDefaults $_.Value

                $count = PropertyCount $_.Value
                if (!$count -or ($iskv -and $count -eq 1)) {
                    $obj.PSObject.Properties.Remove($_.Name)
                }
            }
            elseif ($_.Value -is [Array]) {
                $array = [Collections.ArrayList]::new()
                $array.AddRange($_.Value)
                $_.Value = $array

                if ($array.Count) {
                    for ($i = $array.Count-1; $i -ge 0; --$i) {
                        if ($array[$i] -is [PSCustomObject]) {
                            $iskv = IsKeyValue $array[$i]
                            StripDefaults $array[$i]

                            # only fully remove the object if it was a kvp ("defaults" inside arrays should be kept, but kvp arrays are special)
                            if ($iskv -and (PropertyCount $array[$i]) -eq 1) {
                                $array.RemoveAt($i)
                            }
                        }
                    }
                }

                if (!$array.Count) {
                    $obj.PSObject.Properties.Remove($_.Name)
                }
            }
            else {
                if ($defaultValues -contains $_.Value) {
                    $obj.PSObject.Properties.Remove($_.Name)
                }
            }
        }
    }

    StripDefaults $jsonObject
    $jsonObject | ConvertTo-Json -Depth 100
}
Export-ModuleMember Remove-JsonDefaults
