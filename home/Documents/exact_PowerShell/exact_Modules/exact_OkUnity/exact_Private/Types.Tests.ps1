$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0.0

BeforeAll {
    . ($PSCommandPath -replace '.Tests.ps1', '.ps1')
}

Describe 'UnityVersion' {

    # TODO: comparisons and equality

    Context 'Parsing' {

        It 'throws on empty string' {
            { [UnityVersion]'' } | Should -Throw '*Unexpected Unity version format*'
        }

        It 'returns a filled out UnityVersion for a full version string' {
            $v = [UnityVersion]'2020.3.24f1-dots_a675c7af6899'
            $v | Should -Be (New-Object UnityVersion 2020, 3, 24, 'f', 1, 'dots', 'a675c7af6899')
        }

        It 'returns a partially filled out UnityVersion for various partial scenarios' {
            $v = [UnityVersion]'2020.3.25'
            $v | Should -Be (New-Object UnityVersion 2020, 3, 25)
            [string]$v | Should -Be '2020.3.25'

            $v = [UnityVersion]'2020.3.25f1'
            $v | Should -Be (New-Object UnityVersion 2020, 3, 25, 'f', 1)
            [string]$v | Should -Be '2020.3.25f1'

            $v = [UnityVersion]'2020.3.25f1-c07b56b34d4b'
            $v | Should -Be (New-Object UnityVersion 2020, 3, 25, 'f', 1, $null, 'c07b56b34d4b')
            [string]$v | Should -Be '2020.3.25f1-c07b56b34d4b'

            $v = [UnityVersion]'2020.3.24f1-dots_a675c7af6899'
            $v | Should -Be (New-Object UnityVersion 2020, 3, 24, 'f', 1, 'dots', 'a675c7af6899')
            [string]$v | Should -Be '2020.3.24f1-dots_a675c7af6899'

            $v = [UnityVersion]'2017.2.0'
            $v | Should -Be (New-Object UnityVersion 2017, 2, 0)
            [string]$v | Should -Be '2017.2.0'

            $v = [UnityVersion]'2017'
            $v | Should -Be (New-Object UnityVersion 2017)
            [string]$v | Should -Be '2017.0.0'

            $v = [UnityVersion]'2017.3'
            $v | Should -Be (New-Object UnityVersion 2017, 3)
            [string]$v | Should -Be '2017.3.0'
        }
    }

    Context 'String Conversion' {
        It 'converts to and from strings with the same resulting version' {
            $v = [UnityVersion]'2020.3.25'                     
            [string]$v | Should -Be '2020.3.25'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2020.3.25f1'                   
            [string]$v | Should -Be '2020.3.25f1'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2020.3.25f1-c07b56b34d4b'      
            [string]$v | Should -Be '2020.3.25f1-c07b56b34d4b'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2020.3.24f1-dots_a675c7af6899' 
            [string]$v | Should -Be '2020.3.24f1-dots_a675c7af6899'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2017.2.0'                      
            [string]$v | Should -Be '2017.2.0'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2017'                          
            [string]$v | Should -Be '2017.0.0'
            [UnityVersion][string]$v | Should -Be $v

            $v = [UnityVersion]'2017.3'                        
            [string]$v | Should -Be '2017.3.0'
            [UnityVersion][string]$v | Should -Be $v

        }
    }
}
