if ((Get-Command Invoke-Pester).Version -lt [version]'5.0.0') { throw "Requires a much newer Pester" }

BeforeAll {
    Import-Module scobi -Force
}

Describe 'Remove-EmptyFolders' {

    It 'With -WhatIf, nothing is removed; actual run removes both child and parent' {
        $root = Join-Path $env:TEMP ("RemoveEmptyFoldersTest_{0}" -f ([guid]::NewGuid().ToString()))

        try {
            New-Item -ItemType Directory -Path (Join-Path $root 'A\B') -Force | Out-Null

            # -WhatIf should not remove anything
            Remove-EmptyFolders -Path $root -WhatIf
            Test-Path -LiteralPath (Join-Path $root 'A\B') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $root 'A') | Should -BeTrue

            # Actual run should remove both the leaf and its now-empty parent
            Remove-EmptyFolders -Path $root
            Test-Path -LiteralPath (Join-Path $root 'A\B') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $root 'A') | Should -BeFalse
        }
        finally {
            if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        }
    }

    It 'Does not remove the root folder itself' {
        $root = Join-Path $env:TEMP ("RemoveEmptyFoldersTest_{0}" -f ([guid]::NewGuid().ToString()))

        try {
            New-Item -ItemType Directory -Path (Join-Path $root 'A') -Force | Out-Null

            Remove-EmptyFolders -Path $root

            Test-Path -LiteralPath $root | Should -BeTrue
        }
        finally {
            if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        }
    }

    It 'Does not remove a directory that contains a file' {
        $root = Join-Path $env:TEMP ("RemoveEmptyFoldersTest_{0}" -f ([guid]::NewGuid().ToString()))

        try {
            $dir = Join-Path $root 'HasFile'
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $dir 'keep.txt') -Value 'x'

            Remove-EmptyFolders -Path $root

            Test-Path -LiteralPath $dir | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $dir 'keep.txt') | Should -BeTrue
        }
        finally {
            if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
        }
    }
}
