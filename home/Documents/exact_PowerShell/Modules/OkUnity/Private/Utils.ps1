<#
.SYNOPSIS
    Creates constants.
.DESCRIPTION
    This function can help you to create constants so easy as it possible.
    It works as keyword 'const' as such as in C#.
.EXAMPLE
    PS C:\> Set-Constant a = 10
    PS C:\> $a += 13

    There is a integer constant declaration, so the second line return
    error.
.EXAMPLE
    PS C:\> const str = "this is a constant string"

    You also can use word 'const' for constant declaration. There is a
    string constant named '$str' in this example.
.LINK
    Set-Variable
    About_Functions_Advanced_Parameters
#>
function Set-Constant {
    # credit: https://stackoverflow.com/a/17839741/14582

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1)][ValidateSet('=')]
        [char] $Link,

        [Parameter(Mandatory=$true, Position=2)][ValidateNotNullOrEmpty()]
        [object] $Mean,

        [Parameter(Mandatory=$false)]
        [string] $Surround = 'script'
    )

    Set-Variable -n $name -val $mean -opt Constant -s $surround
}

Set-Alias const Set-Constant
