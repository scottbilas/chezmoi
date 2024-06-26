foreach ($service in (get-service `
    *razer*, `
    RzActionSvc, `
    *nvidia*, `
    HPPrintScan*, `
    Mgl3DCtlrRPCService, `
    Samsung*, `
    ZeroTier*, `
    Epic*, `
    GameSDK*, `
    JetBrainsEtwHost*)) {
    if ($service.Status -ne 'Running') { continue }
    "Stopping service: $($service.Name)"
    $service | stop-service -Force -ea:Continue
}

foreach ($process in (get-process `
    nvidia*)) {
    "Stopping process: $($process.Name)"
    $process | stop-process -Force -ea:Continue
}
