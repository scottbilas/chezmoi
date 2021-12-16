if ((Get-Command Invoke-Pester).Version -lt [version]'5.0.0') { throw "Requires a much newer Pester" }

BeforeAll {
    Import-Module $PSScriptRoot/../OkUnity -Force
    $script:testfs = Resolve-Path $PSScriptRoot/../_testfs/configfiles
}

Describe 'Get-OkUnityConfig' {

    It 'With missing config file given, it errors' {
        { Get-OkUnityConfig -ConfigPath definitely/not/a/path } | Should -Throw 'Config file*does not exist'
    }

    It 'With empty config file, it returns valid config' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/Empty.yml
        $config.ContainsKey('builds') | Should -Not -Be $null
    }

    It 'With comments-only config file, it returns valid config' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/CommentsOnly.yml
        $config.ContainsKey('builds') | Should -Not -Be $null
    }

    It 'Expecting to have pajv available (`npm install -g pajv`)' {
        { Get-Command pajv } | Should -Not -Throw
    }

    It 'With invalid data, it errors' {
        { Get-OkUnityConfig -ConfigPath $testfs/Invalid.yml 2>$null } | Should -Throw '*Invalid.yml invalid'
    }

    It 'With valid data, it returns parsed config' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/Valid.yml
        $config.builds.global | Should -Be @('path1')
        $config.builds.project | Should -Be @('path2', 'path3')
    }

    It 'With partial data, it returns expanded config' {
        $config = Get-OkUnityConfig -ConfigPath $testfs/ValidPartial.yml
        $config.builds.global | Should -Be @('path1')
        $config.builds.project.length | Should -Be 0
    }
}
