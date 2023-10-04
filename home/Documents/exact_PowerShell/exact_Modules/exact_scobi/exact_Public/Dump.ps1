function Dump {
    [CmdletBinding(PositionalBinding=$false)]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, Mandatory=$true)]
        [hashtable]$Hashtable,

        [int]$IndentLevel = 0
    )

    begin {
        $iter = 0
    }

    process {
        $indent = ' ' * $IndentLevel
        if ($iter) { "$indent[$iter]" }

        $fields = @()
        $tables = @()

        foreach ($kvp in $Hashtable.GetEnumerator()) {
            if ($kvp.Value -is [hashtable]) {
                $tables += $kvp
            }
            else {
                $fields += $kvp
            }
        }

        $maxWidth = 0
        foreach ($field in $fields) {
            $maxWidth = [Math]::Max($maxWidth, $field.Key.Length)
        }

        foreach ($field in $fields | Sort-Object Key) {
            $fieldExtra = ' ' * ($maxWidth - $field.Key.Length)
            "$indent$($field.Key):$fieldExtra $($field.Value)"
        }

        foreach ($table in $tables | Sort-Object Key) {
            "$indent$($table.Key):"
            Dump $table.Value -IndentLevel ($IndentLevel + 2)
        }

        ++$iter
    }
}
Export-ModuleMember Dump
