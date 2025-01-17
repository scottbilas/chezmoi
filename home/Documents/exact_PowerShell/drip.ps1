foreach ($service in (get-service -ea:silent `
    *razer*,
    RzActionSvc,
    *nvidia*,
    HPPrintScan*,
    Mgl3DCtlrRPCService,
    Samsung*,
    ZeroTier*,
    Epic*,
    GameSDK*,
    JetBrainsEtwHost*,
    DSAUpdateService,
    DSAService)) {
    if ($service.Status -ne 'Running') { continue }
    "Stopping service: $($service.Name)"
    $service | stop-service -Force -ea:Continue
}

foreach ($process in (get-process -ea:Silent `
    nvidia*,
    onedrive,
    syncthingtray,
    *resilio*,
    ferdium,
    dsatray,
    zerotier_desktop_ui
    )) {
    "Stopping process: $($process.Name)"
    $process | stop-process -Force -ea:Continue
}
