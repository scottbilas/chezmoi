Set-StrictMode -Version Latest

function Find-UnityBuilds() {

    filter Resolve($type) {
        $original = $_
        $_ |
        ForEach-Object { Get-ChildItem (join-path $_ "unity.exe")} |
        Where-Object { Test-Path $_ } |
        ForEach-Object {
            [PSCustomObject]@{
                Type = $type
                Path = $_
                Pattern = $original
            }
        }
    }

    $buildsGlobal = (Get-OkUnityConfig).builds.global | Resolve Global
    $buildsProject = (Get-OkUnityConfig).builds.project | Resolve Project

    $buildsGlobal + $buildsProject
}
