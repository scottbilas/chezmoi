$ErrorActionPreference = 'Stop'
Import-Module Pester -MinimumVersion 5.0.0

BeforeAll {
    Import-Module $PSScriptRoot/../OkUnity -Force
    $script:testfs = Resolve-Path $PSScriptRoot/../_testfs/configfiles
}

Describe 'Get-OkUnityConfig' {

    It 'errors if missing config file' {
        { Get-OkUnityConfig -ConfigPath definitely/not/a/path } | Should -Throw 'Config file*does not exist'
    }

    It 'returns valid config for empty config file' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/Empty.yml
        $config.ContainsKey('builds') | Should -Not -Be $null
    }

    It 'returns valid config for comments-only config file' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/CommentsOnly.yml
        $config.ContainsKey('builds') | Should -Not -Be $null
    }

    It 'has pajv available (`npm install -g pajv`)' {
        { Get-Command pajv } | Should -Not -Throw
    }

    It 'errors for invalid data' {
        { Get-OkUnityConfig -ConfigPath $testfs/Invalid.yml 2>$null } | Should -Throw '*data.builds should be object'
    }

    It 'returns parsed config for valid data' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/Valid.yml
        $config.builds.global | Should -Be @('path1')
        $config.builds.project | Should -Be @('path2', 'path3')
    }

    It 'returns expanded config for partial data' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/ValidPartial.yml
        $config.builds.global | Should -Be @('path1')
        $config.builds.project.length | Should -Be 0
    }
}
