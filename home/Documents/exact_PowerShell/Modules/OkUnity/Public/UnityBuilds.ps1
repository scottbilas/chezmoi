Set-StrictMode -Version Latest

function Find-UnityBuilds() {
    function getUnityExes($paths) {
        $paths | ForEach-Object { Get-ChildItem (join-path $_ "unity.exe")}
    }

    $buildsGlobal = getUnityExes (Get-OkUnityConfig).builds.global
    $buildsProject = getUnityExes (Get-OkUnityConfig).builds.project

    "global: $buildsGlobal"
    "project: $buildsProject"
}
