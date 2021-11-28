if ((Get-Command Invoke-Pester).Version -lt [version]'5.0.0') { throw "Requires a much newer Pester" }

BeforeAll {
    Import-Module scottbilas-Setup -Force
}

Describe 'Invoke-SetupEnvPaths' {

    It 'With empty path components, it removes them' {
        (Invoke-SetupEnvPaths 'abc;;def;').ResultPath | Should -Be 'abc;def'
    }

    It 'With whitespace around path components, it trims them' {
        (Invoke-SetupEnvPaths '  abc ; def   ').ResultPath | Should -Be 'abc;def'
    }

    It 'With duplicate paths, it returns them' {
        (Invoke-SetupEnvPaths 'abc;def;abc\ ;ghi; def').DuplicatePaths | Should -Be 'abc', 'def'
    }

    It 'With invalid paths, it returns them' {
        (Invoke-SetupEnvPaths ';; c:\windows;c:\windows_xyzzy;definitelynotapath').InvalidPaths | Should -Be 'c:\windows_xyzzy', 'definitelynotapath'
    }

    It 'With Powershell path, it is not a duplicate' {
        (Invoke-SetupEnvPaths "$PSHOME;$PSHOME").DuplicatePaths | Should -Be @()
    }
}
