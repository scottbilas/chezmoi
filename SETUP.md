# Setup

## Syncthing

- `scoop install syncthingtray`
- Run syncthingtray
- Config
  - Startup
    - ✅ Autostart
    - Syncthing launcher
      - ✅ Launch Syncthing when starting tray
      - ✅ Use built-in Syncthing library
      - Config and data directory: `C:/Users/scott/.local/share/syncthing`
      - ✅ Show start/stop button
      - Apply and launch now
      - Apply
  - Tray
    - Connection
      - Insert values from local config: `c:\users\scott\.local\share\syncthing\config.xml`
      - HTTPS cert: `C:/Users/scott/.local/share/syncthing/https-cert.pem`
      - ✅ Connect automatically on startup
      - Overall status: ✅ all 4 boxes
      - Apply and reconnect
    - Notifications
      - ✅ everything except "sync on ... complete"
- Add sync folders and devices
- Where there is a `.stignore_shared`, run the top line in it to generate `.stignore`
- Go through Syncthing settings on another machine and copy over to new one bit by bit (folder defaults, and all that stuff)
- TODO: alternative to ^ is to use a common syncthingtray.ini (stored directly in `AppData\Roaming`) as a template. Same for syncthing's config.xml (only the common settings).

