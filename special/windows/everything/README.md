# Installation

* `scoop install everything`
* `scoop hold everything`
* `everything`
* Select "install the Everything service" and continue
* Ctrl-P to go into options
  * General -> check "Store settings and data in %APPDATA%\Everything"
  * Also check "Start Everything on system startup"
* Exit Everything fully (right-click in tray to close) and also `sudo stop-service everything` to kill the service
* `copy "$(cm source-path)\..\special\windows\everything\Everything.ini" $env:appdata\Everything\`
* `sudo start-service everything` also start Everything
* Ctrl-P back to options and fix _NTFS_ and _Folders_
* Double check "Exclude" list, it's kind of out of date (need update the template source)
