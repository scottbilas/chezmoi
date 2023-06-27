### TODO: these broke in the last major revision. lots of new uncovered code too..

if ((Get-Command Invoke-Pester).Version -lt [version]'5.0.0') { throw "Requires a much newer Pester" }

BeforeAll {
    Import-Module ScottBilas.Unity -Force
}

Describe 'Get-UnityVersion' {

    It 'With invalid Path, it errors' {
        { Get-UnityVersion non/existent/path } | Should -Throw 'Cannot find path*'
    }

    It 'With invalid Path but -ea:continue, it errors and continues' {
        Get-UnityVersion -ea:continue non/existent/path 2>&1
    }

    It 'With valild Path but missing version file or EXE, it errors' -ForEach @(
        @{ path = "$PSScriptRoot\_testfs" },
        @{ path = "$PSScriptRoot\_testfs\barefiles" }
    ) {
        { Get-UnityVersion $path } | Should -Throw 'No Unity exe or project*'
    }

    It 'With valid Path and version file, it returns correct versions' -ForEach @(
        @{ path     = 'barefiles\ValidProjectVersion.txt';
           expected = 'barefiles\ValidProjectVersion.txt' },
        @{ path     = 'validprj'
           expected = 'validprj\ProjectSettings\ProjectVersion.txt' },
        @{ path     = 'validprj\ProjectSettings'
           expected = 'validprj\ProjectSettings\ProjectVersion.txt' },
        @{ path     = 'validprj\ProjectSettings\ProjectVersion.txt'
           expected = 'validprj\ProjectSettings\ProjectVersion.txt' }
    ) {
        $actual = Get-UnityVersion $PSScriptRoot\_testfs\$path

        $actual.Version | Should -Be '2020.3.14f1-dots'
        $actual.Hash | Should -Be '86b16565e3c0'
        $actual.GetVersionFull() | Should -Be '2020.3.14f1-dots-86b16565e3c0'

        $actual.ProjectVersionFile | Should -Exist
        $actual.ProjectVersionFile | Should -Be $PSScriptRoot\_testfs\$expected
        # TODO: check UnityExe, UnityVersionMatch
        # TODO: check that no more fields exist than the ones we test (also for other tests here)

    }

    It 'With valid Path and invalid version file, it errors' -ForEach @(
        @{ path     = 'barefiles\InvalidProjectVersion.txt' },
        @{ path     = 'invalidprj' },
        @{ path     = 'invalidprj\ProjectSettings' },
        @{ path     = 'invalidprj\ProjectSettings\ProjectVersion.txt' }
    ) {
        { Get-UnityVersion $PSScriptRoot\_testfs\$path } | Should -Throw 'Unable to extract version number*'
    }

    # TODO: make a couple micro .exe's for the VERSIONINFO checks
    # TODO: also test that it can find and match the unity.exe if we go from projectversion
}
