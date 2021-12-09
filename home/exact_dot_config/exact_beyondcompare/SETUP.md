# Beyond Compare Setup

1. Install from the extras bucket

    `scoop install beyondcompare`

2. Install to Explorer context menu

    `~\.config\beyondcompare\bcomp4-shell-integration.reg`

3. Run Beyond Compare

4. Tools | Import Settings -> `~\.config\beyondcompare\bcsettings.bcpkg`
    * Check all Settings boxes for import
    * Check "Delete all existing file formats"

## Updating bcsettings.bcpkg

1. Run Beyond Compare

2. Tools | Export Settings
    * Check these options
        * Program Options
        * Colors, Fonts
        * Toolbars, Shortcuts, Menus
        * File Formats
        * Pick all file formats
    * Export to `~\.config\beyondcompare\bcsettings.bcpkg` and overwrite
    * Delete the `bcsettings` folder from there and un-zip(*) the `.bcpkg` so we can get the xml's into the diff

(*) Note that a `.bcpkg` file is just a zip file. To recreate it, just zip up all the xml files (as files in the zip's root, no folder prefix).

## TODO

It looks like the bcsettings are a full dump of all settings. In `~\AppData\Roaming\Scooter Software\Beyond Compare 4` there are xml files that seem to only hold overrides from defaults. This may be nicer and more manageable. Todo: switch to this.
