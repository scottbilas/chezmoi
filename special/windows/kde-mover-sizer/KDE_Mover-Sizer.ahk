;	Internationally known as "KDE Mover-Sizer"                               Version 2.9
;
;	http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

;	Which is essentially..

;	Easy Window Dragging -- KDE style (requires XP/2k/NT) -- by Jonny
;	..with nobs on. See http://www.autohotkey.com and their forum.
;
;	This script makes it much easier to move or resize a window: 1) Hold down
;	the ALT key and LEFT-click anywhere inside a window to drag it to a new
;	location;	2) Hold down ALT and RIGHT-click-drag anywhere inside a window
;	to easily resize it; 3) Press ALT twice, but before releasing it the second
;	time, left-click to minimize the window under the mouse cursor, right-click
;	to maximize it, or middle-click to close it.
;
;	This script was inspired by and built on many like it in the forum. Thanks 
;	go out to ck, thinkstorm, Chris, and aurelian for a job well done.


;	Itstory:
;   Sep  10, 2014:		Added option to hide tray icon - a message will appear first, warning you that you have no easy way to shutdown KMS
;   Aug  10, 2013:      Added: Option to use 3x3 grid for resizing as to lock resizing horizontally or vertically depending on mouse position
;                       Fixed: Resizing wrong window after resizing a restored maximized window
;   July 28, 2013:      Moved options into "Options" submenu and merged with "Resize Options"
;                       Changed WheelUp/Down: SendMessage replaced with PostMessage for extended application support for Focusless scrolling
;   July 25, 2013:      removed "SendMode Input" and added a static m-hook button (~^!+MButton) for testing compatibility with MacroExpress
;   July 22, 2013:      Added focusless scrolling: sends WheelUP/Down to Window under mousecursor, even if not active (mih, shimanov, scoox)
;   June  7, 2013:      Changed Hotkey handling back to use RegisterHotkey() instead of keyboard hook (no $)
;                       Updated Tooltips and About box to show actual hotkeys instead of the default ones
;                       Added more grid lines for QuickPositioning: Now at 1/4, 1/3, 0.382 and 1/2 plus 3 center grids (mih)
;   June  5, 2013:      Improved handling of horizontal/vertical locking during resizing
;   May  14, 2013:      Added LockHorizontalVertical: Press LockHorizVert_Hotkey2 (default: Shift) during Moving or Resizing
;                       to constrain mouse to either horizontal or vertical movements (mih)
;                       Added Hide Windows content while moving and resizing
;   Aug   8, 2012:      Added QuickPositionWindow: Press QuickPosition_Hotkey2 during Moving or Resizing to quickly position window on screen edge (mih)
;   Aug   6, 2012:      Added special feature: Insert Special Character with hotkey (mih)
;                         Can be used to define shortcuts (e.g. AltGr+c) to insert special characters (e.g. cedille) from foreign languages
;                         Example: Press AltGr + c to enter French cedille .  Add new
;                         Configuration: Edit .INI File, Section [SpecialCharacters]
;                           Add new SpecialCharactersTrig_# and SpecialCharactersChar_# and Increment SpecialCharacters_Num
;                           See here for trigger key symbols: http://www.autohotkey.com/docs/Hotkeys.htm
;                           Max. Number of custom keys: 15
;                         Known Limitations:
;                           If Mover-Sizer hotkey is Ctrg+Alt, it collides with SpecialCharacter Hotkey AltGr
;                           only works for ASCII/ANSII character set. No Unicode (UTF-8/UTF-16/...)!
;   Aug   1, 2012:      Changed default for LWin hotkey, ShowMeasuresAsTooltip=1, DrawGridShowDistance=1
;                       Changed default for AltGr: DrawGridOverlay_Hotkey=<^>!+
;   July 27, 2012:      Fixed: send DoubleKey_hotkey2 after execution of hotkey action
;   July 22, 2012:      Added option to disable Double-Alt shortcuts
;                       Fixed loop performance issues and window redraw for DrawGrid
;   July 19, 2012:      Added option to show grid measurements as a ToolTip (for folk with balloon tips disabled)
;                       This also prevents the Taskbar from popping into view when measuring (if you have it hidden) ~ Cor
;   July 17, 2012:      Added special feature "Draw Grid" to overlay golden ratio/3x3 & 4x4 grid to analyze images (mih)
;                       Added colour sampler
;                       Added Escape button to abort moving & resizing
;                       Added script reload after closing INI editor
;                       Added configurable hotkeys (based on jlr's version)
;   May 17, 2011:       Added "Ignore Window" list to pass-through hotkeys (e.g. for Remote Desktop or Adobe Photoshop) (mih)
;   October 31, 2009:   Added special feature "Always On Top". Click with the cross cursor on a window you want to toggle AlwaysOnTop (mih)
;   October 12, 2009:	V3 icon! (the last one produced even more mails!). This one rocks. No complaints please!
;						You can now get straight to the KDE Mover-Sizer page from the About dialog.
;						Removed superfluous default AutoHotKey tray menu items.
;						Added an "Enable HotKeys" tray menu item, which toggles the HotKeys (it un/checks) 
;						Added an Exit menu item and simple exit function.
;						Added a menu option to get to the ini file, to hack at the things there's no menu item for.
;						All current prefs get written to the ini file so the user can see/set what's available.
;						Cleaned up documentation and web page, some. More to come. Maybe even comments!
;						Added about box text, some default prefs, tray, gui + menu fixes, other minor stuff.	~ Cor
;   October 10, 2009:	Added new algorithm for Snapping on Resize (mih)
;						Added option for Restoring Window on Resize
;   October 4, 2009:	Added full support for multi screens (incl. snapping) (mih)
;						Fixed Snapping on WorkArea (excluding task bar)
;						Added INI option for Snapping Distance and WinDelay
;						Added About box
;   October 3, 2009:	Added configuration file and option to enable&disable snapping (mih)
;						Added snapping for (Alt-Left-Click) Moving Windows
;   June 16, 2009:		Added Vista Alt-Tab fix (by jordoex)
;						Added an information tip for the tray hover. Updated Icon (I noticed it 
;						clashed with a portable Linux I recently tried, so I created an original 
;						icon for KDE Mover-Sizer. ~ Cor
;   March    10, 2009:	Moving a maximized windows is now possible (First WinRestore to orig. size, then move)
;						Added: Alt+Middle Button maximizes/restores a window (mih)
;   December 04, 2007:	Window snap-to-edge - just like KDE, but with extra fun!
;						Added Tray ToolTip help. ~ Cor
;   November 07, 2006:	Optimized resizing code in !RButton, courtesy of bluedawn.
;   February 05, 2006:	Fixed double-alt (the ~Alt hotkey) to work with latest versions of AHK.


;	Snap-To Edges ..
;
;	If their edge comes within ten pixels of your desktop edge, the window snaps to it. 
;	Very neat;	it's what KDE does. But there's more..
;
;	If you keep mousing after the window snaps, you get a beautiful resizing control which
;	keeps on going. Also you can Alt-right-click any oversized windows and pop them straight back 
;	into the desktop. Note: If you are quick enough, you can break the snap when needed. 
;	Have fun! NOTE: You can now disable the right-click-to-snap behaviour, if preferred.
;
;	;o) Cor
;
;	June 16, 2009:
;
;		Since giving this a page of its own, it's become insanely popular, 
;		and keeps finding its way onto those "five wee apps you can't live
;		without" type lists, which says a lot for the kind of software you
;		can have for yourself if you only rake about in the AutoIt and 
;		AutoHotKey forums once in a while.

;
;	NOTE: If your application wants the Alt key for hotkey modifiers, use Alt+Win+Key for that.
;	It's quite easy once you do it a few times, simply roll your thumb and finger on and off.


If (A_AhkVersion < "1.0.39.00")
{
    MsgBox, 0x30,,This script may not work properly with your version of AutoHotkey. Continue?
    IfMsgBox, No
      ExitApp
}

;if not A_IsAdmin
;{
;    ; TODO: Check if windows version is Win8
;    MsgBox, 0x30,,% "Note: KDE_Mover-Size is not run as administrator. It may not work on all Windows. Try: `r`n"
;                  . "runas.exe /savecred /user:administrator """ . %A_ScriptFullPath%
;}
; TODO: Add Menu command to create/delete a KDEMoverSize_as_admin.lnk in Startmenu/Autostart

;***********************
; Read INI file

    IniRead,   SnapOnSizeEnabled,       KDE_Mover-Sizer.ini, Settings, SnapOnSizeEnabled, 1          ; default: true
    IniWrite, %SnapOnSizeEnabled%,      KDE_Mover-Sizer.ini, Settings, SnapOnSizeEnabled
    IniRead,   SnapOnMoveEnabled,       KDE_Mover-Sizer.ini, Settings, SnapOnMoveEnabled, 1          ; default: true
    IniWrite, %SnapOnMoveEnabled%,      KDE_Mover-Sizer.ini, Settings, SnapOnMoveEnabled
    IniRead,   SnapOnResizeMagnetic,    KDE_Mover-Sizer.ini, Settings, SnapOnResizeMagnetic, 1       ; default: true
    IniWrite, %SnapOnResizeMagnetic%,   KDE_Mover-Sizer.ini, Settings, SnapOnResizeMagnetic
    IniRead,   DoRestoreOnResize,       KDE_Mover-Sizer.ini, Settings, DoRestoreOnResize,  1         ; default: true
    IniWrite, %DoRestoreOnResize%,      KDE_Mover-Sizer.ini, Settings, DoRestoreOnResize
    IniRead,   Use3x3ResizeGrid,        KDE_Mover-Sizer.ini, Settings, Use3x3ResizeGrid,  0          ; default: false (use 2x2 grid)
    IniWrite, %Use3x3ResizeGrid%,       KDE_Mover-Sizer.ini, Settings, Use3x3ResizeGrid
    IniRead,   DoubleAltShortcuts,      KDE_Mover-Sizer.ini, Settings, DoubleAltShortcuts,  1        ; default: true
    IniWrite, %DoubleAltShortcuts%,     KDE_Mover-Sizer.ini, Settings, DoubleAltShortcuts
    IniRead,   BringWindowToFront,      KDE_Mover-Sizer.ini, Settings, BringWindowToFront,  0        ; default: false
    IniWrite, %BringWindowToFront%,     KDE_Mover-Sizer.ini, Settings, BringWindowToFront
    IniRead,   ShowWindowWhenDragging,  KDE_Mover-Sizer.ini, Settings, ShowWindowWhenDragging,  1    ; default: true
    IniWrite, %ShowWindowWhenDragging%, KDE_Mover-Sizer.ini, Settings, ShowWindowWhenDragging
    IniRead,   SnappingDistance,        KDE_Mover-Sizer.ini, Settings, SnappingDistance, 10          ; default: 10 pixels
    IniWrite, %SnappingDistance%,       KDE_Mover-Sizer.ini, Settings, SnappingDistance
    ; This is the setting that runs smoothest on my system. Depending on your video card and cpu power, 
    ; you may want to raise or lower this value.. System default: 100
    IniRead,   WinDelay,                KDE_Mover-Sizer.ini, Settings, WinDelay, 2
    IniWrite, %WinDelay%,               KDE_Mover-Sizer.ini, Settings, WinDelay

    IniRead,   DoubleModifierKey_MaxDelay_ms,      KDE_Mover-Sizer.ini, Settings, DoubleModifierKey_MaxDelay_ms, 400
    IniWrite, %DoubleModifierKey_MaxDelay_ms%,     KDE_Mover-Sizer.ini, Settings, DoubleModifierKey_MaxDelay_ms
    IniRead,   WindowIgnoreList,		KDE_Mover-Sizer.ini, Settings, WindowIgnoreList, mstsc.exe,      ; default: MS Terminal Services Client
    IniWrite, %WindowIgnoreList%,		KDE_Mover-Sizer.ini, Settings, WindowIgnoreList
    
    IniRead,   HideTrayIcon,			KDE_Mover-Sizer.ini, Settings, HideTrayIcon, 0					; default is to show the icon
    IniWrite, %HideTrayIcon%,			KDE_Mover-Sizer.ini, Settings, HideTrayIcon

    ; Settings for hotkeys
    ;
    s := "Alt=!, Ctrl=^, Shift=+, LWin=#, AltGr=<^>!"
    IniWrite,  %s%, KDE_Mover-Sizer.ini, Hotkeys, Hints_Hotkeys                                        ; quick hotkey reference
    IniRead,   MovingWindow_Hotkey,     KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey, !           ; default: ! (Alt)
    IniWrite, %MovingWindow_Hotkey%,    KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniRead,   MovingWindow_Mouse,      KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Mouse, LButton      ; default: LButton
    IniWrite, %MovingWindow_Mouse%,     KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Mouse

    IniRead,   ResizingWindow_Hotkey,   KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey, !         ; default: ! (Alt)
    IniWrite, %ResizingWindow_Hotkey%,  KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniRead,   ResizingWindow_Mouse,    KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Mouse, RButton    ; default: RButton
    IniWrite, %ResizingWindow_Mouse%,   KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Mouse

    IniRead,   ToggleMaximize_Hotkey,   KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey, !         ; default: ! (Alt)
    IniWrite, %ToggleMaximize_Hotkey%,  KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniRead,   ToggleMaximize_Mouse,    KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Mouse, MButton    ; default: MButton
    IniWrite, %ToggleMaximize_Mouse%,   KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Mouse

    IniRead,   DoubleKey_Hotkey2,       KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2, Alt           ; default: Alt
    IniWrite, %DoubleKey_Hotkey2%,      KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniRead,   QuickPosition_Hotkey2,   KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2, Alt       ; default: Alt
    IniWrite, %QuickPosition_Hotkey2%,  KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    IniRead,   LockHorizVert_Hotkey2,   KDE_Mover-Sizer.ini, Hotkeys, LockHorizVert_Hotkey2, Shift     ; default: Shift
    IniWrite, %LockHorizVert_Hotkey2%,  KDE_Mover-Sizer.ini, Hotkeys, LockHorizVert_Hotkey2

    IniRead,   DrawGridOverlay_Hotkey,  KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey, !^       ; default: !^ (Ctrl+Alt)
    IniWrite, %DrawGridOverlay_Hotkey%, KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniRead,   DrawGridOverlay_Mouse,   KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Mouse, RButton   ; default: RButton, also used as OK for Colour Sampler
    IniWrite, %DrawGridOverlay_Mouse%,  KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Mouse
    IniRead,   FreezeSampler_Mouse,     KDE_Mover-Sizer.ini, Hotkeys, FreezeSampler_Mouse, LButton     ; default: LButton, pins location of Colour Sampler
    IniWrite, %FreezeSampler_Mouse%,    KDE_Mover-Sizer.ini, Hotkeys, FreezeSampler_Mouse
    
    ; Settings for Draw Grid and colour sampler
    ;
    IniRead,   EnableDrawGrid,          KDE_Mover-Sizer.ini, Special, EnableDrawGrid, 0                ; default: disabled
    IniWrite, %EnableDrawGrid%,         KDE_Mover-Sizer.ini, Special, EnableDrawGrid
    IniRead,   DrawGridShowDistance,    KDE_Mover-Sizer.ini, Special, DrawGridShowDistance, 1          ; default: no info box
    IniWrite, %DrawGridShowDistance%,   KDE_Mover-Sizer.ini, Special, DrawGridShowDistance
    IniRead,   DrawGridColour,          KDE_Mover-Sizer.ini, Special, DrawGridColour, White            ; default: White
    IniWrite, %DrawGridColour%,         KDE_Mover-Sizer.ini, Special, DrawGridColour
    IniRead,   DrawGridGUIOptions,      KDE_Mover-Sizer.ini, Special, DrawGridGUIOptions, +Border      ; default: +Border
    IniWrite, %DrawGridGUIOptions%,     KDE_Mover-Sizer.ini, Special, DrawGridGUIOptions
    IniRead,   DrawGridMouseAutoHold,   KDE_Mover-Sizer.ini, Special, DrawGridMouseAutoHold, 1         ; default: true, release grid with another click
    IniWrite, %DrawGridMouseAutoHold%,  KDE_Mover-Sizer.ini, Special, DrawGridMouseAutoHold
    IniRead,   DrawGridWidth,           KDE_Mover-Sizer.ini, Special, DrawGridWidth, 1                 ; default: 1px, make bigger if no border
    IniWrite, %DrawGridWidth%,          KDE_Mover-Sizer.ini, Special, DrawGridWidth
    IniRead,   ShowMeasuresAsToolTip,   KDE_Mover-Sizer.ini, Special, ShowMeasuresAsToolTip, 1         ; default: true
    IniWrite, %ShowMeasuresAsToolTip%,  KDE_Mover-Sizer.ini, Special, ShowMeasuresAsToolTip
    IniRead,   ShowMeasuresToolTip_X,   KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_X, 3         ; default: top-left
    IniWrite, %ShowMeasuresTooltip_X%,  KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_X
    IniRead,   ShowMeasuresToolTip_Y,   KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_Y, 3         ; default: top-left
    IniWrite, %ShowMeasuresTooltip_Y%,  KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_Y

    ; Settings for focusless scrolling
    ;
    IniRead,   EnableFocuslessScroll,   KDE_Mover-Sizer.ini, Special, EnableFocuslessScroll, 0         ; default: disabled
    IniWrite, %EnableFocuslessScroll%,  KDE_Mover-Sizer.ini, Special, EnableFocuslessScroll
    IniRead,   FocuslessScrollSpeed,    KDE_Mover-Sizer.ini, Special, FocuslessScrollSpeed, 120        ; default: 120
    IniWrite, %FocuslessScrollSpeed%,   KDE_Mover-Sizer.ini, Special, FocuslessScrollSpeed
    IniRead,   FocuslessScrollModifier, KDE_Mover-Sizer.ini, Special, FocuslessScrollModifier, -       ; -/empty:none, *:all, ^:Ctrl, +:Shift, ...
    If FocuslessScrollModifier = -
        FocuslessScrollModifier := ""
    IniWrite, %FocuslessScrollModifier%,KDE_Mover-Sizer.ini, Special, FocuslessScrollModifier


    ; Mappings and status for key shortcuts to special characters
    ;
    IniRead,   EnableSpecialCharacters,  KDE_Mover-Sizer.ini, SpecialCharacters, EnableSpecialCharacters, 0          ; default: disabled
    IniWrite, %EnableSpecialCharacters%, KDE_Mover-Sizer.ini, SpecialCharacters, EnableSpecialCharacters
    IniRead,   SpecialCharactersTrig_1,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersTrig_1, <^>!c      ; default: AltGr+c
    IniWrite, %SpecialCharactersTrig_1%, KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersTrig_1
    IniRead,   SpecialCharactersChar_1,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersChar_1, �
    IniWrite, %SpecialCharactersChar_1%, KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersChar_1
    IniRead,   SpecialCharactersTrig_2,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersTrig_2, <^>!+c     ; default: AltGr+C
    IniWrite, %SpecialCharactersTrig_2%, KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersTrig_2
    IniRead,   SpecialCharactersChar_2,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersChar_2, �
    IniWrite, %SpecialCharactersChar_2%, KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersChar_2
    IniRead,   SpecialCharacters_NumberOfActiveHotkeys,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharacters_NumberOfActiveHotkeys, 2  ; default: 2 (_1 and _2 are active)
    IniWrite, %SpecialCharacters_NumberOfActiveHotkeys%, KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharacters_NumberOfActiveHotkeys
    
    ; enable(=1)/disable(=0) a special feature. If they are disabled here, they are also hidden in the AddOn menu.
    ;
    s := "If the AddOns are disabled here, they are not shown in the Special Features menu."
    IniWrite,  %s%, KDE_Mover-Sizer.ini, AddOns, Hints_AddOns
    IniRead,   AddOnEnable_ToggleForeground,   KDE_Mover-Sizer.ini, AddOns, AddOnEnable_ToggleForeground, 1
    IniWrite, %AddOnEnable_ToggleForeground%,  KDE_Mover-Sizer.ini, AddOns, AddOnEnable_ToggleForeground
    IniRead,   AddOnEnable_SpecialCharacters,  KDE_Mover-Sizer.ini, AddOns, AddOnEnable_SpecialCharacters, 0
    IniWrite, %AddOnEnable_SpecialCharacters%, KDE_Mover-Sizer.ini, AddOns, AddOnEnable_SpecialCharacters
    IniRead,   AddOnEnable_FocuslessScroll,    KDE_Mover-Sizer.ini, AddOns, AddOnEnable_FocuslessScroll, 1
    IniWrite, %AddOnEnable_FocuslessScroll%,   KDE_Mover-Sizer.ini, AddOns, AddOnEnable_FocuslessScroll
    IniRead,   AddOnEnable_ColourSampler,      KDE_Mover-Sizer.ini, AddOns, AddOnEnable_ColourSampler, 0
    IniWrite, %AddOnEnable_ColourSampler%,     KDE_Mover-Sizer.ini, AddOns, AddOnEnable_ColourSampler
    IniRead,   AddOnEnable_DrawGrid,           KDE_Mover-Sizer.ini, AddOns, AddOnEnable_DrawGrid, 0
    IniWrite, %AddOnEnable_DrawGrid%,          KDE_Mover-Sizer.ini, AddOns, AddOnEnable_DrawGrid



;*********************************************
; Prepare Menu

; If compiled, hide standard menu options
If A_IsCompiled
    Menu, tray, NoStandard

; Useful info on tray mouse hover.. ;o)
Menu, Tray,Tip, % "KDE Mover-Sizer.. `n" . strname(MovingWindow_Hotkey) . "-" . strname(MovingWindow_Mouse) . "-Click Windows to Move`n"
                  . strname(ResizingWindow_Hotkey) . "-" . strname(ResizingWindow_Mouse) . "-Click Windows to Resize`n[right-click here for a menu]"

; Create Special menu
;
if ( AddOnEnable_ToggleForeground )
    Menu, MySpecialMenu, add, Toggle Window-Always-On-Top.., MenuToggleAlwaysOnTop

if ( AddOnEnable_ToggleForeground AND ( AddOnEnable_SpecialCharacters OR AddOnEnable_FocuslessScroll OR AddOnEnable_DrawGrid OR AddOnEnable_ColourSampler ) )
    Menu, MySpecialMenu, add

if ( AddOnEnable_SpecialCharacters )
    Menu, MySpecialMenu, add, Enable Hotkeys to insert Special Characters, MenuEnableSpecialCharacters

if ( AddOnEnable_FocuslessScroll )
    Menu, MySpecialMenu, add, Enable Mouse Wheel Scrolling on inactive Windows, MenuEnableFocuslessScroll

if ( (AddOnEnable_SpecialCharacters OR AddOnEnable_FocuslessScroll) AND ( AddOnEnable_DrawGrid OR AddOnEnable_ColourSampler ) )
    Menu, MySpecialMenu, add

if ( AddOnEnable_ColourSampler ) {
    Menu, MySpecialMenu, add, Colour sampler.., MenuColourSampler
    Menu, MySpecialMenu, add
}
if ( AddOnEnable_DrawGrid ) {
    Menu, MySpecialMenu, add, Enable Draw grid, MenuDrawGrid
    Menu, MySpecialMenu, add, Auto-hold grid, MenuDrawGridMouseAutoHold
    Menu, MySpecialMenu, add, Show Grid Measures, MenuDrawGridShowDistance
    Menu, MySpecialMenu, add
}
if ( AddOnEnable_ColourSampler OR AddOnEnable_DrawGrid )
    Menu, MySpecialMenu, add, Show Measures as ToolTip, MenuShowMeasuresAsToolTip

; Create Options-, Ignore- and Hotkey Menu
;
Menu, MyOptionsMenu, add, Snap on Move, MenuSnapOnMoveHandler
Menu, MyOptionsMenu, add, Snap on Resize, MenuSnapOnSizeHandler
Menu, MyOptionsMenu, add
Menu, MyOptionsMenu, add, Magnetic Resizing, MenuSnapOnResizeMagnetic
Menu, MyOptionsMenu, add, Resize restores Maximized Window, MenuDoRestoreOnResize
Menu, MyOptionsMenu, add, Use 3x3 grid on Resize, MenuUse3x3ResizeGrid
Menu, MyOptionsMenu, add
Menu, MyOptionsMenu, add, Bring Windows to Front on dragging, MenuBringWindowToFront
Menu, MyOptionsMenu, add, Show Window Contents while dragging, MenuShowWindowWhenDragging
Menu, MyIgnoreMenu, add, Add Window to Ignore List.., MenuAddWindowToIgnoreList
Menu, MyIgnoreMenu, add, Remove Window from Ignore List.., MenuRemoveWindowFromIgnoreList
Menu, MyIgnoreMenu, add
Menu, MyIgnoreMenu, add, Show currently ignored Windows, MenuShowIgnoreList
Menu, MyHotkeyMenu, add, Reset all Hotkeys to Default, MenuHotkey_Default
Menu, MyHotkeyMenu, add
Menu, MyHotkeyMenu, add, Swap Left<->Right Mouse buttons, MenuHotkey_MouseSwap
Menu, MyHotkeyMenu, add
Menu, MyHotkeyMenu, add, Use Alt key, MenuHotkey_Alt
Menu, MyHotkeyMenu, add, Use Control+Shift key, MenuHotkey_ControlShift
Menu, MyHotkeyMenu, add, Use Control+Alt key, MenuHotkey_ControlAlt
Menu, MyHotkeyMenu, add, Use Left Windows key, MenuHotkey_LWin
Menu, MyHotkeyMenu, add, Use AltGr key, MenuHotkey_AltGr

; Create main tray menu
;
Menu, tray, add, About.., MenuAbout
Menu, tray, add
Menu, tray, add, Enable Double-Alt Shortcuts, MenuDoubleAltShortcuts
Menu, tray, add, Options, :MyOptionsMenu
Menu, tray, add
Menu, tray, add, Ignore Windows, :MyIgnoreMenu
Menu, tray, add, Change Hotkeys, :MyHotkeyMenu
Menu, tray, add
if ( AddOnEnable_ToggleForeground OR AddOnEnable_ColourSampler OR AddOnEnable_DrawGrid OR AddOnEnable_SpecialCharacters OR AddOnEnable_FocuslessScroll)
{
    Menu, tray, add, Special Features, :MySpecialMenu
    Menu, tray, add
}
Menu, tray, add, Edit My Ini File, EditMyIni
Menu, tray, add, Enable HotKeys, HotKeysToggle
Menu, tray, add
Menu, tray, add, Hide Tray Icon, HideIcon
Menu, tray, add
Menu, tray, add, Exit, MenuExit

; Set initial "enable" Checks in menu according to configuration variables
;
    if ( AddOnEnable_DrawGrid )
    {
        if EnableDrawGrid
            Menu, MySpecialMenu, ToggleCheck, Enable Draw grid
        if DrawGridMouseAutoHold
            Menu, MySpecialMenu, ToggleCheck, Auto-hold grid
        if DrawGridShowDistance
            Menu, MySpecialMenu, ToggleCheck, Show Grid Measures
    }
    if ( AddOnEnable_DrawGrid OR AddOnEnable_ColourSampler )
    {
        if ShowMeasuresAsToolTip
            Menu, MySpecialMenu, ToggleCheck, Show Measures as ToolTip
    }
    if ( AddOnEnable_SpecialCharacters )
        if EnableSpecialCharacters
            Menu, MySpecialMenu, ToggleCheck, Enable Hotkeys to insert Special Characters

    if ( AddOnEnable_FocuslessScroll )
        if EnableFocuslessScroll
            Menu, MySpecialMenu, ToggleCheck, Enable Mouse Wheel Scrolling on inactive Windows

    Menu, tray, Check, Enable HotKeys
    if SnapOnMoveEnabled
        Menu, MyOptionsMenu, ToggleCheck, Snap on Move
    if SnapOnSizeEnabled
        Menu, MyOptionsMenu, ToggleCheck, Snap on Resize
    if BringWindowToFront
        Menu, MyOptionsMenu, ToggleCheck, Bring Windows to Front on dragging
    if ShowWindowWhenDragging
        Menu, MyOptionsMenu, ToggleCheck, Show Window Contents while dragging
    if SnapOnResizeMagnetic
        Menu, MyOptionsMenu, ToggleCheck, Magnetic Resizing
    if DoRestoreOnResize
        Menu, MyOptionsMenu, ToggleCheck, Resize restores Maximized Window
    if DoubleAltShortcuts
        Menu, tray, ToggleCheck, Enable Double-Alt Shortcuts
    if Use3x3ResizeGrid
        Menu, MyOptionsMenu, ToggleCheck, Use 3x3 grid on Resize

#NoEnv          ; Recommended for performance and compatibility with future AutoHotkey releases. (jlr)
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability. (jlr)
;#IfTimeout 150 ; #if must complete in under 150ms or key will be passed through

SetWinDelay, %WinDelay%

CoordMode, Mouse,Screen
CoordMode, Pixel,Screen
CoordMode, ToolTip,Screen

MayToggle := true

#MaxHotkeysPerInterval 150 ;Avoid warning when mouse wheel turned very fast

if HideTrayIcon
	Menu,Tray,NoIcon


Init_SetHotkeyHandler()

return


; **************************************
; ********* MENU handler ***************
; **************************************

; *** MENU: Configure Moving & Resizing ***
;
MenuSnapOnMoveHandler:
    Menu, MyOptionsMenu, ToggleCheck, Snap on Move
    SnapOnMoveEnabled := NOT SnapOnMoveEnabled
    ; save option to INI file in working directory
    IniWrite, %SnapOnMoveEnabled%, KDE_Mover-Sizer.ini, Settings, SnapOnMoveEnabled
    return

MenuSnapOnSizeHandler:
    Menu, MyOptionsMenu, ToggleCheck, Snap on Resize
    SnapOnSizeEnabled := NOT SnapOnSizeEnabled
    IniWrite, %SnapOnSizeEnabled%, KDE_Mover-Sizer.ini, Settings, SnapOnSizeEnabled
    if NOT SnapOnSizeEnabled AND SnapOnResizeMagnetic
        Gosub, MenuSnapOnResizeMagnetic
    return

MenuDoubleAltShortcuts:
    Menu, tray, ToggleCheck, Enable Double-Alt Shortcuts
    DoubleAltShortcuts := NOT DoubleAltShortcuts
    IniWrite, %DoubleAltShortcuts%, KDE_Mover-Sizer.ini, Settings, DoubleAltShortcuts
    Reload
    return

MenuBringWindowToFront:
    Menu, MyOptionsMenu, ToggleCheck, Bring Windows to Front on dragging
    BringWindowToFront := NOT BringWindowToFront
    If BringWindowToFront
        Traytip Bring Window to Front enabled, Automatically brings up window to foreground on Resizing and Moving.,20,1
    IniWrite, %BringWindowToFront%, KDE_Mover-Sizer.ini, Settings, BringWindowToFront
    return

MenuShowWindowWhenDragging:
    Menu, MyOptionsMenu, ToggleCheck, Show Window Contents while dragging
    ShowWindowWhenDragging := NOT ShowWindowWhenDragging
    If ShowWindowWhenDragging
        Traytip Show window contents while moving or resizing, Disable this to show only frame and reduce UI redrawing on slow or remote machines.,20,1
    IniWrite, %ShowWindowWhenDragging%, KDE_Mover-Sizer.ini, Settings, ShowWindowWhenDragging
    return

MenuSnapOnResizeMagnetic:
    Menu, MyOptionsMenu, ToggleCheck, Magnetic Resizing
    SnapOnResizeMagnetic := NOT SnapOnResizeMagnetic
    If SnapOnResizeMagnetic
        Traytip Magnetic Resizing, Allows to keep the window snapped when resizing slowly.`r`nDrag a snapped window slowly to see how it works`.,20,1
    IniWrite, %SnapOnResizeMagnetic%, KDE_Mover-Sizer.ini, Settings, SnapOnResizeMagnetic
    if SnapOnResizeMagnetic AND NOT SnapOnSizeEnabled
        Gosub, MenuSnapOnSizeHandler
    return

MenuDoRestoreOnResize:
    Menu, MyOptionsMenu, ToggleCheck, Resize restores Maximized Window
    DoRestoreOnResize := NOT DoRestoreOnResize
    If DoRestoreOnResize
        Traytip Resize restores maximized Window, When enabled`, a maximized window is restored to its original size before resizing.`r`nWhen disabled`, a maximized window starts resizing from the maximized width and height.`r`nYou'll only notice the difference when you resize a maximized window`.,20,1
    IniWrite, %DoRestoreOnResize%, KDE_Mover-Sizer.ini, Settings, DoRestoreOnResize
    return

MenuUse3x3ResizeGrid:
    Menu, MyOptionsMenu, ToggleCheck, Use 3x3 grid on Resize
    Use3x3ResizeGrid := NOT Use3x3ResizeGrid
    If Use3x3ResizeGrid
        Traytip Use 3x3 grid on Resize, The Windows is divided into 9 areas`. If the mouse is not on the corner fields`, direction of resizing is restricted`.,20,1
    else
        Traytip Use 2x2 grid on Resize, % "The Windows is divided into 4 areas.`nDirection of resizing can be restricted with " . strname(LockHorizVert_Hotkey2) . ".",20,1
    IniWrite, %Use3x3ResizeGrid%, KDE_Mover-Sizer.ini, Settings, Use3x3ResizeGrid
    return


; *** MENU: Edit Windows Ignore List ***
;
MenuAddWindowToIgnoreList:
    SetMouseCursorCross()
    TrayTip Add window to Ignore list, Left-Click the window you want to restore the original application-specific hotkey behaviour`.`r`nUse this e.g. for Remote Desktop or imaging applications`., 20, 1
    KeyWait, LButton, D            ; Wait for left button to be pressed down
    SetMouseCursorDefault()
    MouseGetPos, ,,curwin_id
    WinGet currentwinname, ProcessName, ahk_id %curwin_id%
    
    if ( InStr( WindowIgnoreList, currentwinname, CaseSensitive = false ) != 0 )
    {
        TrayTip Add window to Ignore list, Application already on Ignore list, 2
        return
    }
    WindowIgnoreList := WindowIgnoreList . currentwinname . ","
    IniWrite, %WindowIgnoreList%,   KDE_Mover-Sizer.ini, Settings, WindowIgnoreList
    TrayTip Applications now on Ignore list:, %WindowIgnoreList%, 10, 1
    return

MenuRemoveWindowFromIgnoreList:
    SetMouseCursorCross()
    TrayTip Remove window from Ignore list, Left-Click the window which you want to control with KDE Mover-Sizer`., 15, 1
    KeyWait, LButton, D            ; Wait for left button to be pressed down
    SetMouseCursorDefault()
    MouseGetPos, ,,curwin_id
    WinGet currentwinname, ProcessName, ahk_id %curwin_id%
    currentwinname := currentwinname . ","
    StringReplace, WindowIgnoreList, WindowIgnoreList, %currentwinname%
    IniWrite, %WindowIgnoreList%,   KDE_Mover-Sizer.ini, Settings, WindowIgnoreList
    TrayTip Applications now on Ignore list:, %WindowIgnoreList%, 10, 1
    return

MenuShowIgnoreList:
    MsgBox 64, KDE Mover-Sizer Ignore list, Applications currently on Ignore list:`r`n%WindowIgnoreList%
    return


; *** MENU: Change Hotkey settings
;
MenuHotkey_Default:
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Mouse
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Mouse
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, MButton, KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Mouse
    IniWrite, Alt,     KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, Alt,     KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    IniWrite, Shift,   KDE_Mover-Sizer.ini, Hotkeys, LockHorizVert_Hotkey2
    IniWrite, !^,      KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Mouse
    IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, FreezeSampler_Mouse
    Reload
    return

MenuHotkey_MouseSwap:
    If MovingWindow_Mouse = LButton
    {
        IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Mouse
        IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Mouse
        IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Mouse
        IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, FreezeSampler_Mouse
    } else
    {
        IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Mouse
        IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Mouse
        IniWrite, RButton, KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Mouse
        IniWrite, LButton, KDE_Mover-Sizer.ini, Hotkeys, FreezeSampler_Mouse
    }
    Reload
    return

MenuHotkey_Alt:
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, !,       KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, !^,      KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, Alt,     KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, Alt,     KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    Reload
    return

MenuHotkey_ControlShift:
    IniWrite, ^+,       KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, ^+,       KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, ^+,       KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, !^+,      KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, LControl, KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, Control,  KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    Reload
    return

MenuHotkey_ControlAlt:
    IniWrite, ^!,       KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, ^!,       KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, ^!,       KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, ^!+,      KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, LControl, KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, Alt,      KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    Reload
    return

MenuHotkey_LWin:
    IniWrite, #,        KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, #,        KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, #,        KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, #^,       KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, LWin,     KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, LWin,     KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    Reload
    return

MenuHotkey_AltGr:
    IniWrite, <^>!,     KDE_Mover-Sizer.ini, Hotkeys, MovingWindow_Hotkey
    IniWrite, <^>!,     KDE_Mover-Sizer.ini, Hotkeys, ResizingWindow_Hotkey
    IniWrite, <^>!,     KDE_Mover-Sizer.ini, Hotkeys, ToggleMaximize_Hotkey
    IniWrite, <^>!+,    KDE_Mover-Sizer.ini, Hotkeys, DrawGridOverlay_Hotkey
    IniWrite, AltGr,    KDE_Mover-Sizer.ini, Hotkeys, DoubleKey_Hotkey2
    IniWrite, Alt,      KDE_Mover-Sizer.ini, Hotkeys, QuickPosition_Hotkey2
    Reload
    return


; *** MENU: Special features ***
;
MenuToggleAlwaysOnTop:
    SetMouseCursorCross()
    Traytip Toggle Always-on-Top, Left-Click the window you want to keep in the foreground. Redo to restore normal behaviour.,15,1
    KeyWait, LButton, D         ; Wait for left button to be pressed down
    SetMouseCursorDefault()
    MouseGetPos, ,,curwin_id
    WinSet AlwaysOnTop, Toggle, ahk_id %curwin_id%
    TrayTip
    return

MenuEnableSpecialCharacters:
    Menu, MySpecialMenu, ToggleCheck, Enable Hotkeys to insert Special Characters
    EnableSpecialCharacters := NOT EnableSpecialCharacters
    IniWrite, %EnableSpecialCharacters%, KDE_Mover-Sizer.ini, SpecialCharacters, EnableSpecialCharacters
    Init_SetHotkeyHandler()
    If EnableSpecialCharacters
        Traytip Key Shortcuts for Special Characters enabled, Use this to create up to 15 key shortcuts to insert special characters`, e.g. for foreign languages.`r`nConfigure hotkeys and characters in Ini file.`r`nExample (default): Press AltGr+c for �.,30,1
    Else
        Reload
    return

MenuEnableFocuslessScroll:
    Menu, MySpecialMenu, ToggleCheck, Enable Mouse Wheel Scrolling on inactive Windows
    EnableFocuslessScroll := NOT EnableFocuslessScroll
    IniWrite, %EnableFocuslessScroll%, KDE_Mover-Sizer.ini, Special, EnableFocuslessScroll
    Init_SetHotkeyHandler()
    If EnableFocuslessScroll
        Traytip Focusless Scrolling enabled, Mouse wheel scrolls window under mouse cursor`, even if it has no focus.`r`n(To include modifier combinations`, set FocuslessScrollModifier (*:any`, ^:Ctrl`, +:Shift) in Ini file. Keep in mind this may not work on all windows!),30,1
    Else
        Reload
    return

MenuColourSampler:
    Traytip Colour Sampler, % "Click " . strname(DrawGridOverlay_Mouse) . " to save colour to clipboard.`r`nClick " . strname(FreezeSampler_Mouse) . " to freeze sampler position.`r`nPress Control and/or Shift to average colour of surrounding pixels.`r`nCancel with ESC", 30, 1
    DoColourSampler()
    return

MenuDrawGrid:
    Menu, MySpecialMenu, ToggleCheck, Enable Draw grid
    EnableDrawGrid := NOT EnableDrawGrid
    if EnableDrawGrid
        Traytip Drawing Grid Enabled, % "Use " . strname(DrawGridOverlay_Hotkey) . "+" . strname(DrawGridOverlay_Mouse) . "-click to draw grid.`r`nTo change ratio`, press Control (1/4 grid) or Shift (1/3 grid)`r`nor none (golden ratio grid).`r`nClick " . strname(DrawGridOverlay_Mouse) . " to hide it.", 30, 1
    IniWrite, %EnableDrawGrid%, KDE_Mover-Sizer.ini, Special, EnableDrawGrid
    return

MenuDrawGridMouseAutoHold:
    Menu, MySpecialMenu, ToggleCheck, Auto-hold grid
    DrawGridMouseAutoHold := NOT DrawGridMouseAutoHold
    if DrawGridMouseAutoHold
        Traytip Drawing Grid Auto Hold, Grid remains after releasing button. Click again or press ESC to remove grid`., 20, 1
    IniWrite, %DrawGridMouseAutoHold%, KDE_Mover-Sizer.ini, Special, DrawGridMouseAutoHold
    return

MenuDrawGridShowDistance:
    Menu, MySpecialMenu, ToggleCheck, Show Grid Measures
    DrawGridShowDistance := NOT DrawGridShowDistance
    IniWrite, %DrawGridShowDistance%, KDE_Mover-Sizer.ini, Special, DrawGridShowDistance
    return

MenuShowMeasuresAsToolTip:
    Menu, MySpecialMenu, ToggleCheck, Show Measures as ToolTip
    ShowMeasuresAsToolTip := NOT ShowMeasuresAsToolTip
    IniWrite, %ShowMeasuresAsToolTip%, KDE_Mover-Sizer.ini, Special, ShowMeasuresAsToolTip
    return


; *** MENU: General functions
;
EditMyIni:
    RunWait, KDE_Mover-Sizer.ini
    Reload
    return

HotKeysToggle:
    Menu,Tray,Icon,,,1
    menu, tray, ToggleCheck,Enable HotKeys
    Suspend
    return

MenuExit:
    ExitApp
    return

HideIcon:
	MsgBox, 4,Be Careful!, % "If you disable the tray icon will have no way to shutdown`r`n"
. "KDE-Mover-Sizer!`r`n`r`n"
. "To revert to the normal behaviour, you will need to set:`r`n`r`n"
. "    HideTrayIcon=0`r`n`r`n"
. "..in your KDE_Mover-Sizer.ini.`r`n`r`n"
. "Are you sure you wish to continue disabling the icon?"
	IfMsgBox No
		return
	HideTrayIcon = 1
	IniWrite, %HideTrayIcon%, KDE_Mover-Sizer.ini, Settings, HideTrayIcon
	Menu,Tray,NoIcon
	return

MenuAbout:
MsgBox,4,About KDE Mover-Sizer.., % "KDE Mover-Sizer..                                                Version 2.9 (September, 2014)`r`n"
. "`r`n"
. "KDE-Mover-Sizer (created with AutoHotKey: autohotkey.com) makes it easy`r`n"
. "to move and resize windows without having to position your mouse cursor accurately.`r`n"
. "Simply hold down the " . strname(MovingWindow_Hotkey) . " key, and click or drag anywhere on the window.`r`n"
. "`r`n"
. "During move or resize, use " . strname(LockHorizVert_Hotkey2) . " to lock movements horizontally or vertically.`r`n"
. "During move or resize, (release,) press and hold " . strname(QuickPosition_Hotkey2) . " to quick-fit window into grid. Move mouse to select window position and size.`r`n"
. "`r`n"
. "The shortcuts:`r`n"
. "`r`n"
. "   " . strname(MovingWindow_Hotkey)   . " + " . strname(MovingWindow_Mouse) . " Button  -> Drag to move a window.`r`n"
. "   " . strname(ResizingWindow_Hotkey) . " + " . strname(ResizingWindow_Mouse) . " Button -> Drag to resize a window.`r`n"
. "   " . strname(ToggleMaximize_Hotkey) . " + " . strname(ToggleMaximize_Mouse) . " Button -> Maximize/Restore a window.`r`n"
. "`r`n"
. "    Double-" . strname(DoubleKey_Hotkey2) . " + " . strname(MovingWindow_Mouse) . " Button   -> Minimize a window.`r`n"
. "    Double-" . strname(DoubleKey_Hotkey2) . " + " . strname(ResizingWindow_Mouse) . " Button  -> Maximize/Restore a window.  `r`n"
. "    Double-" . strname(DoubleKey_Hotkey2) . " + " . strname(ToggleMaximize_Mouse) . " Button -> Close a window.`r`n"
. "`r`n"
. "     The Double-" . strname(DoubleKey_Hotkey2) . " modifier is activated by pressing the`r`n"
. "     " . strname(DoubleKey_Hotkey2) . " key twice, much like a double-click. Hold the second`r`n"
. "     " . strname(DoubleKey_Hotkey2) . "-press down until you click the mouse button. Tada!`r`n"
. "`r`n"
. "For more, see menu and tray info balloons.`r`n"
. "For even more, edit the INI file and the [AddOns] section.`r`n"
. "`r`n"
. "If it doesn't work on all windows, try to run KDE-Mover-Sizer as administrator:`r`n"
. "runas.exe /savecred /user:administrator """ . A_ScriptFullPath . """`r`n"
. "`r`n"
. "Known authors (in alphabetical order)..`r`n"
. "`r`n"
. "   aurelian`r`n"
. "   Chris`r`n"
. "   ck`r`n"
. "   Cor`r`n"
. "   Jonny`r`n"
. "   jordoex`r`n"
. "   Matthias Ihmig`r`n"
. "   scoox`r`n"
. "   shimanov`r`n"
. "   thinkstorm`r`n"
. "`r`n"
. "Do you wish to visit the KDE Mover-Sizer web page?`r`n"

IfMsgBox No
    return
else IfMsgBox Yes
        Run, http://corz.org/windows/software/accessories/KDE-resizing-moving-for-XP-or-Vista.php

return


; *********************************************************
; ********* Install MOUSE & KEY EVENT handler *************
; *********************************************************
;
; Set hotkeys for event handlers dynamically
; Details on http://www.autohotkey.com/docs/Hotkeys.htm
;     and on http://www.autohotkey.com/docs/commands/Hotkey.htm
;
Init_SetHotkeyHandler()
{
    global

    ; Init Catch hotkeys, used to hinder windows to pass them to underlying window
    Hotkey, !Escape, CatchEscape1
    Hotkey, Escape, CatchEscape2
    DisableEscapeHotkey()

    ; Init actual Mover-Sizer hotkeys
    Hotkey, %MovingWindow_Hotkey%%MovingWindow_Mouse%, DoMovingWindowMinimize, On
    Hotkey, %ResizingWindow_Hotkey%%ResizingWindow_Mouse%, DoResizingWindowMaximize, On
    Hotkey, %ToggleMaximize_Hotkey%%ToggleMaximize_Mouse%, DoToggleMaximize, On
    Hotkey, %ToggleMaximize_Hotkey%%ToggleMaximize_Mouse% Up, DoToggleMaximize_Up, On

    if ( AddOnEnable_DrawGrid )
        Hotkey, %DrawGridOverlay_Hotkey%%DrawGridOverlay_Mouse%, DoDrawGridOverlay, On

    ; DoubleAlt requires special handling for AltGr (a different KeyWait in OnDoubleKey)
    if DoubleKey_Hotkey2 = AltGr
    {
        DoubleKey_isAltGr := 1
        DoubleKey_Hotkey2 := "LControl & ~RAlt"
    }

    ; Set Special Characters hotkey handler
    if ( AddOnEnable_SpecialCharacters AND EnableSpecialCharacters )
    {
        if ( SpecialCharacters_NumberOfActiveHotkeys > 15 )
        {
            MsgBox Warning: Maximum number of special character hotkeys (SpecialCharacters_NumberOfActiveHotkeys) is 15.
            SpecialCharacters_NumberOfActiveHotkeys := 15
        }
        Loop, %SpecialCharacters_NumberOfActiveHotkeys%
        {
            IniRead, SpecialCharactersTrig_%A_Index%,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersTrig_%A_Index%, <^>!a
            IniRead, SpecialCharactersChar_%A_Index%,  KDE_Mover-Sizer.ini, SpecialCharacters, SpecialCharactersChar_%A_Index%, a
            val := SpecialCharactersTrig_%A_Index%
            Hotkey, %val%, SpecialCharactersLbl_%A_Index%
        }
    }
    
    if ( AddOnEnable_FocuslessScroll AND EnableFocuslessScroll )
    {
        Hotkey, %FocuslessScrollModifier%WheelUp,   DoFocuslessScrollUp, On
        HotKey, %FocuslessScrollModifier%WheelDown, DoFocuslessScrollDown, On
    }
    
    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, OnDoubleKey, On
}

; *********************************************
; *********** ACTION: MOVING WINDOW ***********
; *********************************************
;
DoMovingWindowMinimize:

    If CheckIsWindowInIgnoreList(WindowIgnoreList)
    {
        SendEvent {Blind}{%MovingWindow_Mouse% down}
        KeyWait %MovingWindow_Mouse%, U
        SendEvent {Blind}{%MovingWindow_Mouse% up}
        return
    }

    If DoubleAlt
    {
        MouseGetPos,,,KDE_id
        ; This message is mostly equivalent to WinMinimize,
        ; but it avoids a bug with PSPad.
        PostMessage, 0x112,0xf020,,,ahk_id %KDE_id%

        DoubleAlt := false
        Send {Blind}{%DoubleKey_hotkey2%}

        return
    }

    ; Vista+ Alt-Tab fix by jordoex..
    IfWinActive ahk_class TaskSwitcherWnd
    {
        Send {Blind}{%MovingWindow_Mouse%}
        return
    }

    ; stop the double-key from interfering
    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, Off

    SaveOriginalWindowState()     ; and enable ESC keys
    
    If ( NOT ShowWindowWhenDragging )
        DrawRectFrame_Prepare()

    ; Get the initial mouse position and window id, and
    ; WinRestore if the window is maximized.

    MouseGetPos, KDE_X1,KDE_Y1,KDE_id

    If ( BringWindowToFront )
        WinActivate, ahk_id %KDE_id% 
    WinGet, KDE_Win,MinMax,ahk_id %KDE_id%

    If KDE_Win
        WinRestore,ahk_id %KDE_id%     ; restore window size

    QuickPosition_Button_wasUp := NOT GetKeyState( QuickPosition_Hotkey2, "P" )     ; check that Alt button was released once before window is QuickPositioned.
    LockHorizVert_Button_wasUp := NOT GetKeyState( LockHorizVert_Hotkey2, "P" )     ; check that Shift button was released once before movement is locked.

    ; Get the initial window position.
    WinGetPos,KDE_WinX1,KDE_WinY1,KDE_WinW,KDE_WinH,ahk_id %KDE_id%

    Loop
    {
        GetKeyState,KDE_Button,%MovingWindow_Mouse%,P ; Break if button has been released.
        If KDE_Button = U
            break

        GetKeyState,Esc_Button,Escape,P ; Break if escape button was pressed.
        If Esc_Button = D
        {
            RestoreOriginalWindowState()
            break
        }

        if ( NOT QuickPosition_Button_wasUp )
            QuickPosition_Button_wasUp := NOT GetKeyState( QuickPosition_Hotkey2, "P" )
        if ( NOT LockHorizVert_Button_wasUp )
            LockHorizVert_Button_wasUp := NOT GetKeyState( LockHorizVert_Hotkey2, "P" )

        if ( QuickPosition_Button_wasUp AND GetKeyState( QuickPosition_Hotkey2 , "P" ) )      ; no regular moving, but quickly snap and resize window to screen edge/corner
        {
            QuickPositionWindowOnEdge( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
        }
        else 
        {
            MouseGetPos,KDE_X2,KDE_Y2 ; Get the current mouse position.
            KDE_X2 -= KDE_X1    ; Obtain an offset from the initial mouse position.
            KDE_Y2 -= KDE_Y1
            
            if ( LockHorizVert_Button_wasUp AND GetKeyState( LockHorizVert_Hotkey2 , "P" ) )      ; lock mouse to horizontal or vertical movements
            {
                if ( abs(KDE_X2) - abs(KDE_Y2) > 0 )
                    KDE_Y2 := 0 ; lock Y
                else
                    KDE_X2 := 0 ; lock X
            }

            KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
            KDE_WinY2 := (KDE_WinY1 + KDE_Y2)
    
            ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
            GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom)

            if SnapOnMoveEnabled
            {
                if (KDE_WinX2 < CurrentScreenLeft + SnappingDistance) AND (KDE_WinX2 > CurrentScreenLeft - SnappingDistance)
                    KDE_WinX2 := CurrentScreenLeft 

                if (KDE_WinY2 < CurrentScreenTop + SnappingDistance) AND (KDE_WinY2 > CurrentScreenTop - SnappingDistance)
                    KDE_WinY2 := CurrentScreenTop

                if (KDE_WinX2 + KDE_WinW > CurrentScreenRight - SnappingDistance) AND (KDE_WinX2 + KDE_WinW < CurrentScreenRight + SnappingDistance)
                    KDE_WinX2 := CurrentScreenRight - KDE_WinW

                if (KDE_WinY2 + KDE_WinH > CurrentScreenBottom - SnappingDistance) AND (KDE_WinY2 + KDE_WinH < CurrentScreenBottom + SnappingDistance)
                    KDE_WinY2 := CurrentScreenBottom - KDE_WinH
            }
            KDE_WinW2 := KDE_WinW
            KDE_WinH2 := KDE_WinH
        }

        If ( ShowWindowWhenDragging )
            WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%, %KDE_WinW2%, %KDE_WinH2%  ; Move the window to the new position.
        Else
            DrawRectFrame_Show( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
    }

    If ( NOT ShowWindowWhenDragging )
    {
        DrawRectFrame_Cancel()
        If Esc_Button = U
            WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%, %KDE_WinW2%, %KDE_WinH2%  ; Move the window to the new position.
    }

    DisableEscapeHotkey()

    ; reenable DoubleKey_Hotkey
    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, OnDoubleKey, On

    return


; ***********************************************
; *********** ACTION: RESIZING WINDOW ***********
; ***********************************************
;
DoResizingWindowMaximize:

    If CheckIsWindowInIgnoreList(WindowIgnoreList)
    {
        SendEvent {Blind}{%ResizingWindow_Mouse% down}
        KeyWait %ResizingWindow_Mouse%, U
        SendEvent {Blind}{%ResizingWindow_Mouse% up}
        return
    }

    If DoubleAlt
    {
        MouseGetPos,,,KDE_id

        If ( BringWindowToFront )
            WinActivate, ahk_id %KDE_id%

        ; Toggle between maximized and restored state.
        WinGet, KDE_Win,MinMax,ahk_id %KDE_id%
        If KDE_Win
            WinRestore, ahk_id %KDE_id%
        Else
            WinMaximize, ahk_id %KDE_id%

        DoubleAlt := false
        Send {Blind}{%DoubleKey_hotkey2%}

        return
    }

    ; Vista+ Alt-Tab fix by jordoex..
    IfWinActive ahk_class TaskSwitcherWnd
    {
        Send {Blind}{%ResizingWindow_Mouse%}
        return
    }

    ; stop the double-key from interfering
    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, Off

    If ( NOT ShowWindowWhenDragging )
        DrawRectFrame_Prepare()

    SaveOriginalWindowState()

    ; Get the initial mouse position and window id, and
    ; do WinRestore if the window is maximized.

    MouseGetPos, KDE_X1,KDE_Y1,KDE_id

    If ( BringWindowToFront )
        WinActivate, ahk_id %KDE_id% 

    WinGet, KDE_Win,MinMax,ahk_id %KDE_id%

    If KDE_Win
    {
        if DoRestoreOnResize
            WinRestore, ahk_id %KDE_id%
        else
        {
            GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom)
            WinRestore, ahk_id %KDE_id%
            WinMove, ahk_id %KDE_id%,, CurrentScreenLeft  ; X of resized window
                                , CurrentScreenTop       ; Y of resized window
                                , CurrentScreenRight  - CurrentScreenLeft ; W of resized window
                                , CurrentScreenBottom - CurrentScreenTop  ; H of resized window
        }
    }

    ; Get the initial window position and size.
    WinGetPos,KDE_WinX1,KDE_WinY1,KDE_WinW, KDE_WinH, ahk_id %KDE_id%
    WinGetPos,KDE_WinX2,KDE_WinY2,KDE_WinW2,KDE_WinH2,ahk_id %KDE_id%

    ; save original position to use for locked magnetic resizing
    MouseGetPos, Lock_saveKDE_X1, Lock_saveKDE_Y1
    WinGetPos,   Lock_saveKDE_WinX2, Lock_saveKDE_WinY2, Lock_saveKDE_WinW2, Lock_saveKDE_WinH2, ahk_id %KDE_id%

    ; Define the window region the mouse is currently in.
    ;
    if NOT Use3x3ResizeGrid      ; use 2x2 grid
    {
        ; The four regions are Up and Left, Up and Right, Down and Left, Down and Right
        ; WinLeft = [-1;1], WinUp = [-1;1]
    
        If (KDE_X1 < KDE_WinX1 + KDE_WinW / 2)
            KDE_WinLeft := 1
        Else
            KDE_WinLeft := -1
        If (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2)
            KDE_WinUp := 1
        Else
            KDE_WinUp := -1
    }
    else                         ; use 3x3 grid
    {
        ; WinLeft = [-1;0;1], WinUp = [-1;0;1]

        KDE_WinLeft := 0
        KDE_WinUp   := 0
        If (KDE_X1 < KDE_WinX1 + KDE_WinW / 3)
            KDE_WinLeft := 1
        If (KDE_X1 > KDE_WinX1 + KDE_WinW *2/3)
            KDE_WinLeft := -1
        If (KDE_Y1 < KDE_WinY1 + KDE_WinH / 3)
            KDE_WinUp := 1
        If (KDE_Y1 > KDE_WinY1 + KDE_WinH *2/3)
            KDE_WinUp := -1
    }

    QuickPosition_Button_wasUp := NOT GetKeyState( QuickPosition_Hotkey2, "P" )
    LockHorizVert_Button_wasUp := NOT GetKeyState( LockHorizVert_Hotkey2, "P" )
    QuickPosition_wasActive    := 0
    locked := 0

    Loop
    {
        GetKeyState, KDE_Button,%ResizingWindow_Mouse%,P ; Break if button has been released / pressed twice
        If KDE_Button = U
            break

        GetKeyState, Esc_Button,Escape,P ; Break if escape button was pressed.
        If Esc_Button = D
        {
            RestoreOriginalWindowState()
            break
        }

        MouseGetPos,MouseX,MouseY ; Get the current mouse position.
        KDE_X2 := MouseX - KDE_X1 ; Obtain an offset from the initial mouse position.
        KDE_Y2 := MouseY - KDE_Y1

        if ( LockHorizVert_Button_wasUp AND GetKeyState( LockHorizVert_Hotkey2 , "P" ) )      ; lock mouse to horizontal or vertical movements
        {
            if (SnapOnSizeEnabled AND SnapOnResizeMagnetic)     ; locking during Magnetic Resizing needs special handling because of the way it's updated
            {
                if ( locked = 0 )
                {
                    MouseMove Lock_saveKDE_X1, Lock_saveKDE_Y1
                    MouseX := Lock_saveKDE_X1
                    MouseY := Lock_saveKDE_Y1
                    KDE_WinX2 := Lock_saveKDE_WinX2
                    KDE_WinY2 := Lock_saveKDE_WinY2
                    KDE_WinW2 := Lock_saveKDE_WinW2
                    KDE_WinH2 := Lock_saveKDE_WinH2
                    KDE_X1 := Lock_saveKDE_X1
                    KDE_Y1 := Lock_saveKDE_Y1
                    KDE_X2 := 0
                    KDE_Y2 := 0
                    If ( ShowWindowWhenDragging )
                        WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%, %KDE_WinW2%, %KDE_WinH2%
                    Else
                        DrawRectFrame_Show( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
            
                    Loop        ; wait until mouse moved to determine locked direction
                    {
                        MouseGetPos,MX,MY
                        if ( abs(MouseX-MX)>4 or abs(MouseY-MY)>4 or NOT GetKeyState(LockHorizVert_Hotkey2,"P") or GetKeyState("Escape","P") )
                            break
                        Sleep, 20
                    }
                    if ( abs(MX - MouseX) - abs(MY - MouseY) > 0)
                        locked := 1 ; lock Y
                    else
                        locked := 2 ; lock X
                }
                if ( locked = 1 )
                    KDE_Y2 := 0
                if ( locked = 2 )
                    KDE_X2 := 0
            } else                                                ; locking for default Resizing
            {
                if ( abs(KDE_X2) - abs(KDE_Y2) > 0 )
                    KDE_Y2 := 0 ; lock Y
                else
                    KDE_X2 := 0 ; lock X
            }
        }
        if ( LockHorizVert_Button_wasUp AND NOT GetKeyState( LockHorizVert_Hotkey2 , "P" ) AND locked != 0 )
        {
            locked := 0
        }

        ; snap the window to the edge of the screen if closer than 10 pixels to border
        ; first, get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
        ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
        GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom)

        if ( NOT QuickPosition_Button_wasUp )
            QuickPosition_Button_wasUp := NOT GetKeyState( QuickPosition_Hotkey2, "P" )
        if ( NOT LockHorizVert_Button_wasUp )
            LockHorizVert_Button_wasUp := NOT GetKeyState( LockHorizVert_Hotkey2, "P" )

        if ( QuickPosition_Button_wasUp AND GetKeyState( QuickPosition_Hotkey2, "P") )      ; "quick positioning", Control button must be released once before window is QuickPositioned
        {
            if ( NOT QuickPosition_wasActive )   ; save mouse and window position to allow clean switch between magnetic resizing and QuickPositioning
            {
                QuickPos_saveMouseX := MouseX
                QuickPos_saveMouseY := MouseY
                QuickPos_saveKDE_WinX2 := KDE_WinX2
                QuickPos_saveKDE_WinY2 := KDE_WinY2
                QuickPos_saveKDE_WinW2 := KDE_WinW2
                QuickPos_saveKDE_WinH2 := KDE_WinH2
                QuickPosition_wasActive := 1
            }
            QuickPositionWindowOnEdge( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
        }
        else if (SnapOnSizeEnabled AND NOT SnapOnResizeMagnetic)    ; "normal" resizing
        {
            KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft =1 ? 1 : 0)*KDE_X2) ; X of resized windows
            KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   =1 ? 1 : 0)*KDE_Y2) ; Y of resized windows
            KDE_WinW2 := (KDE_WinW  -  KDE_WinLeft *KDE_X2) ; W of resized windows
            KDE_WinH2 := (KDE_WinH  -  KDE_WinUp   *KDE_Y2) ; H of resized windows

            if (KDE_WinX2 < CurrentScreenLeft + SnappingDistance) AND (KDE_WinX2 > CurrentScreenLeft - SnappingDistance) AND (KDE_WinLeft > 0) {
                KDE_WinW2 := KDE_WinW + KDE_WinX1 - CurrentScreenLeft
                KDE_WinX2 := CurrentScreenLeft
            }
            if (KDE_WinY2 < CurrentScreenTop + SnappingDistance) AND (KDE_WinY2 > CurrentScreenTop - SnappingDistance) AND (KDE_WinUp > 0) {
                KDE_WinH2 := KDE_WinH + KDE_WinY1 - CurrentScreenTop
                KDE_WinY2 := CurrentScreenTop
            }
            if (KDE_WinX2 + KDE_WinW2 > CurrentScreenRight - SnappingDistance) AND (KDE_WinX2 + KDE_WinW2 < CurrentScreenRight + SnappingDistance)  AND (KDE_WinLeft < 0) {
                KDE_WinW2 := - KDE_WinX1 + CurrentScreenRight
            }
            if (KDE_WinY2 + KDE_WinH2 > CurrentScreenBottom - SnappingDistance) AND (KDE_WinY2 + KDE_WinH2 < CurrentScreenBottom + SnappingDistance) AND (KDE_WinUp < 0) {
                KDE_WinH2 := - KDE_WinY1 + CurrentScreenBottom
            }
        }
        else if (SnapOnSizeEnabled AND SnapOnResizeMagnetic)      ;  Magnetic Edges resize the window but keep the edge "locked"
        {
            if (QuickPosition_wasActive)                          ;  restore previous mouse and window position to ensure clean switch between Magnetic resizing and QuickPositioning
            {
                MouseMove QuickPos_saveMouseX, QuickPos_saveMouseY
                MouseX := QuickPos_saveMouseX
                MouseY := QuickPos_saveMouseY
                KDE_WinX2 := QuickPos_saveKDE_WinX2
                KDE_WinY2 := QuickPos_saveKDE_WinY2
                KDE_WinW2 := QuickPos_saveKDE_WinW2
                KDE_WinH2 := QuickPos_saveKDE_WinH2
                KDE_X2 := QuickPos_saveMouseX - KDE_X1
                KDE_Y2 := QuickPos_saveMouseY - KDE_Y1
                QuickPosition_wasActive := 0
            }
            
            ; Get the current window position and size.
            KDE_WinX1 := KDE_WinX2
            KDE_WinY1 := KDE_WinY2
            KDE_WinW  := KDE_WinW2
            KDE_WinH  := KDE_WinH2

            if (KDE_WinX1 < CurrentScreenLeft + SnappingDistance) ;AND (KDE_WinX1 > CurrentScreenLeft - SnappingDistance)
                KDE_WinX1 := CurrentScreenLeft

            if (KDE_WinY1 < CurrentScreenTop + SnappingDistance) ;AND (KDE_WinY1 > CurrentScreenTop - SnappingDistance)
                KDE_WinY1 := CurrentScreenTop

            if (KDE_WinX1 + KDE_WinW > CurrentScreenRight - SnappingDistance) ;AND (KDE_WinX1 + KDE_WinW < CurrentScreenRight + SnappingDistance)
                KDE_WinX1 := CurrentScreenRight - KDE_WinW

            if (KDE_WinY1 + KDE_WinH > CurrentScreenBottom - SnappingDistance) ;AND (KDE_WinY1 + KDE_WinH < CurrentScreenBottom + SnappingDistance)
                KDE_WinY1 := CurrentScreenBottom - KDE_WinH

            KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft =1 ? 1 : 0)*KDE_X2) ; X of resized windows
            KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   =1 ? 1 : 0)*KDE_Y2) ; Y of resized windows
            KDE_WinW2 := (KDE_WinW  -  KDE_WinLeft *KDE_X2) ; W of resized windows
            KDE_WinH2 := (KDE_WinH  -  KDE_WinUp   *KDE_Y2) ; H of resized windows
     
            KDE_X1 := MouseX ; Reset the initial position for the next iteration.
            KDE_Y1 := MouseY
        }
        else    ; no snapping, just resizing
        {
            KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft =1 ? 1 : 0)*KDE_X2) ; X of resized windows
            KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   =1 ? 1 : 0)*KDE_Y2) ; Y of resized windows
            KDE_WinW2 := (KDE_WinW  -     KDE_WinLeft  *KDE_X2) ; W of resized windows
            KDE_WinH2 := (KDE_WinH  -       KDE_WinUp  *KDE_Y2) ; H of resized windows
        }

        ; Then, act according to the defined region.
        If ( ShowWindowWhenDragging )
            WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%, %KDE_WinW2%, %KDE_WinH2%
        Else
            DrawRectFrame_Show( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
        Sleep, 1
    }

    If ( NOT ShowWindowWhenDragging )
    {
        DrawRectFrame_Cancel()
        If Esc_Button = U
            WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%, %KDE_WinW2%, %KDE_WinH2%  ; Move the window to the new position.
    }

    DisableEscapeHotkey()

    ; reenable DoubleKey_Hotkey
    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, OnDoubleKey, On

    return


; *************************************************************
; *********** ACTION: TOGGLE Maximize/Original size ***********
; *************************************************************

DoToggleMaximize:

    If CheckIsWindowInIgnoreList(WindowIgnoreList)
    {
        SendEvent {Blind}{%ToggleMaximize_Mouse% down}
        KeyWait %ToggleMaximize_Mouse%, U
        SendEvent {Blind}{%ToggleMaximize_Mouse% up}
        return
    }

    ; For Double-Alt + middle Button: Close Window
    ;
    If DoubleAlt
    {
        MouseGetPos, ,,KDE_id
        WinClose, ahk_id %KDE_id%
        DoubleAlt := false
        Send {Blind}{%DoubleKey_hotkey2%}
        return
    }

    ; Toggle window Maximize/Original size with Alt+Middle mouse button
    ;
    If MayToggle
    {
        ; Toggle between maximized and restored state of window under mouse cursor
        MouseGetPos, ,,KDE_id
        WinGet, KDE_Win,MinMax,ahk_id %KDE_id%
        If KDE_Win
            WinRestore, ahk_id %KDE_id%
        Else
            WinMaximize, ahk_id %KDE_id%

        MayToggle := false
        return
    }
    return

DoToggleMaximize_Up:
    MayToggle := true
    return


; ********************************************************************************
; ******* This detects "double-clicks" of the alt/DoubleKey_hotkey2 key.   *******
; ********************************************************************************

OnDoubleKey:
    if ( DoubleAltShortcuts )
        DoubleAlt := A_PriorHotKey = "~"DoubleKey_hotkey2 AND A_TimeSincePriorHotkey < DoubleModifierKey_MaxDelay_ms
    Sleep 0
    if DoubleKey_isAltGr
        KeyWait RAlt
    else
        KeyWait %DoubleKey_hotkey2%  ; This prevents the keyboard's auto-repeat feature from interfering.
    return


; *******************************************************************************
; ************* ACTION: DRAW GRID OVERLAY, e.g. to analyze images ***************
; *******************************************************************************
;
; Default Trigger: Control+Alt+Right + mousebutton
; - overlay a golden ratio, 3x3 or 4x4 grid, to find out why those other images always looks so great.
; - Position, Size, length of diagonal and ratio of grid is shown in Tooltip or balloon (configurable)
; - HINT: Move the tooltip with Alt+Left(default moving hotkey) mouse button to new destination and confirm with Right click.
;         This position will be used the next time . Edit INI to change how grid looks, e.g. for a thinner 2px black grid, set:
;         DrawGridColour=Black and DrawGridGUIOptions=-Border and DrawGridWidth=2
; Keys:
; - Use Ctrl, Shift or both to toggle grid ratio
; - Use Right click or ESC to abort

DoDrawGridOverlay:

    If CheckIsWindowInIgnoreList(WindowIgnoreList) OR NOT EnableDrawGrid
    {
        SendEvent {Blind}{%DrawGridOverlay_Mouse% down}
        KeyWait %DrawGridOverlay_Mouse%, U
        SendEvent {Blind}{%DrawGridOverlay_Mouse% up}
        return
    }

    CatchGridButtonHotkey()   ; Catch %DrawGridOverlay_Mouse% mouse button and don't pass it to underlying app

    SetMouseCursorCross()

    MouseGetPos,Mouse_X1,Mouse_Y1,curwin_id ; Get the current mouse position.

    Loop, 12
    {
        Gui, %A_Index%: -Caption +ToolWindow +AlwaysOnTOp +OwnDialogs %DrawGridGUIOptions%
        Gui, %A_Index%: Color, %DrawGridColour%
    }

    ButtonOnce := 0
    KeyLast    := 0
    KeyToggle  := 0

    Hotkey, Escape,  On                ; Catch ESC to stop underlying app to handle it

    Loop
    {
        If ( GetKeyState("Escape","P") )   ; Break if escape button was pressed.
            break

        GetKeyState, KDE_Button,%DrawGridOverlay_Mouse%,P ; Break if button has been released (and AutoHold is off). Otherwise, freeze grid
        If KDE_Button = U
            If DrawGridMouseAutoHold = 1
            {
                If ( ButtonOnce = 0 )
                    ButtonOnce = 1
            }
            Else
                break

        If ButtonOnce = 1 
            If KDE_Button = D
                break

        GetKeyState, KDE_Ctrl,Control,P ; Toggle 3x3 and 4x4 grid with Control key
        GetKeyState, KDE_Shift,Shift,P  ; Toggle golden cut and 1/3 grid with Shift key

        If ButtonOnce = 0
        {
            Loop        ; wait with graphics update until mouse moved or keys were pressed/released
            {
                GetKeyState, KDE_Ctrl_new, Control,P
                GetKeyState, KDE_Shift_new,Shift,P
                
                MouseGetPos, MX,MY ; Get the current mouse position.
                if ( MX != Mouse_X2 or MY != Mouse_Y2 or NOT GetKeyState(DrawGridOverlay_Mouse,"P") or GetKeyState("Escape","P") )
                    break
                if ( KDE_Ctrl_new != KDE_KCtrl or KDE_Shift_new != KDE_Shift )
                {
                    KDE_Ctrl  := KDE_Ctrl_new
                    KDE_Shift := KDE_Shift_new
                    break
                }
                Sleep, 20
            }
            Mouse_X2 = %MX%
            Mouse_Y2 = %MY%
            WinX := min( Mouse_X1, Mouse_X2 )
            WinY := min( Mouse_Y1, Mouse_Y2 )
            WinW := abs( Mouse_X1 - Mouse_X2 )
            WinH := abs( Mouse_Y1 - Mouse_Y2 )
        }

        If ( KDE_Ctrl = "D" AND KDE_Shift = "U" ) {   ; draw 1/4 grid
            WX1 := WinX
            WX2 := WinX + 1/4 * WinW
            WX3 := WinX + 2/4 * WinW
            WX4 := WinX + 3/4 * WinW
            WX5 := WinX + 4/4 * WinW
            WX6 := WinX + 4/4 * WinW
            WY1 := WinY
            WY2 := WinY + 1/4 * WinH
            WY3 := WinY + 2/4 * WinH
            WY4 := WinY + 3/4 * WinH
            WY5 := WinY + 4/4 * WinH
            WY6 := WinY + 4/4 * WinH
            If KeyLast != 1
                KeyToggle = 1
            KeyLast = 1
        }
        If ( KDE_Ctrl = "U" AND KDE_Shift = "D" ) {   ; draw 1/3 grid
            WX1 := WinX
            WX2 := WinX + 1/3 * WinW
            WX3 := WinX + 2/3 * WinW
            WX4 := WinX + 3/3 * WinW
            WX5 := WinX + 3/3 * WinW
            WX6 := WinX + 3/3 * WinW
            WY1 := WinY
            WY2 := WinY + 1/3 * WinH
            WY3 := WinY + 2/3 * WinH
            WY4 := WinY + 3/3 * WinH
            WY5 := WinY + 3/3 * WinH
            WY6 := WinY + 3/3 * WinH
            If KeyLast != 2
                KeyToggle = 1
            KeyLast = 2
        }
        If ( KDE_Shift = "D" AND KDE_Ctrl = "D" ) {   ; draw complex golden rule grid
            WX1 := WinX + 0.382 * WinW
            WX2 := WinX + 0.382*0.382 * WinW
            WX3 := WinX + 0.382*0.618 * WinW
            WX4 := WinX + (0.618 + 0.382*0.382) * WinW
            WX5 := WinX + (0.618 + 0.382*0.618) * WinW
            WX6 := WinX + 0.618 * WinW
            WY1 := WinY + 0.382 * WinH
            WY2 := WinY + 0.382*0.382 * WinH
            WY3 := WinY + 0.382*0.618 * WinH
            WY4 := WinY + (0.618 + 0.382*0.382) * WinH
            WY5 := WinY + (0.618 + 0.382*0.618) * WinH
            WY6 := WinY + 0.618 * WinH
            If KeyLast != 3
                KeyToggle = 1
            KeyLast = 3
        }
        If ( KDE_Ctrl = "U" AND KDE_Shift = "U" ) {   ; draw simple golden rule grid
            WX1 := WinX
            WX2 := WinX + 0.382 * WinW
            WX3 := WinX + 0.618 * WinW
            WX4 := WinX + 3/3 * WinW
            WX5 := WinX + 3/3 * WinW
            WX6 := WinX + 3/3 * WinW
            WY1 := WinY
            WY2 := WinY + 0.382 * WinH ; 1/3 * WinH
            WY3 := WinY + 0.618 * WinH ; 2/3 * WinH
            WY4 := WinY + 3/3 * WinH
            WY5 := WinY + 3/3 * WinH
            WY6 := WinY + 3/3 * WinH
            If KeyLast != 4
                KeyToggle = 1
            KeyLast = 4
        }

        Gui, 1: Show, % "x" WX1 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 2: Show, % "x" WX2 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 3: Show, % "x" WX3 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 4: Show, % "x" WX4 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 5: Show, % "x" WX5 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 6: Show, % "x" WX6 " y" WinY " w" DrawGridWidth " h" WinH " NoActivate"
        Gui, 7: Show, % "x" WinX " y" WY1 " h" DrawGridWidth " w" WinW " NoActivate"
        Gui, 8: Show, % "x" WinX " y" WY2 " h" DrawGridWidth " w" WinW " NoActivate"
        Gui, 9: Show, % "x" WinX " y" WY3 " h" DrawGridWidth " w" WinW " NoActivate"
        Gui,10: Show, % "x" WinX " y" WY4 " h" DrawGridWidth " w" WinW " NoActivate"
        Gui,11: Show, % "x" WinX " y" WY5 " h" DrawGridWidth " w" WinW " NoActivate"
        Gui,12: Show, % "x" WinX " y" WY6 " h" DrawGridWidth " w" WinW " NoActivate"

        If ( (DrawGridShowDistance AND NOT ButtonOnce) OR (DrawGridShowDistance AND KeyToggle) )
        {
            dist := Round( sqrt( WinH * WinH + WinW * WinW ), 2)
            ratio := WinW / WinH
            if (ratio < 1)
                ratio := WinH / WinW
            ratio1_1  := Round(ratio,   3)
            ratio3_2  := Round(2*ratio, 3)
            ratio4_3  := Round(3*ratio, 3)
            ratio16_9 := Round(9*ratio, 3)
            
            if (ShowMeasuresAsToolTip) {
                ToolTip, Grid Measures:`r`nX: %WinX%`, Y: %WinY% `r`nW: %WinW%`, H: %WinH% `r`nDiagonal: %dist%`r`nRatio: %ratio1_1%:1`, %ratio3_2%:2`, %ratio4_3%:3`, %ratio16_9%:9, %ShowMeasuresToolTip_X%, %ShowMeasuresToolTip_Y%
            } else
                Traytip Grid Measures, X: %WinX%`, Y: %WinY% `r`nW: %WinW%`, H: %WinH% `r`nDiagonal: %dist%`r`nRatio: %ratio1_1%:1`, %ratio3_2%:2`, %ratio4_3%:3`, %ratio16_9%:9, 100, 0

            Sleep, 10
            
            ; Refresh window under grid (required for GIMP). Workaround for WinSet, Redraw,, ahk_id %curwin_id% (didn't work)
            DllCall("RedrawWindow", "Uint", curwin_id , "Uint", 0, "Uint", 0, "Uint", 0x81)    ; Workaround for WinSet, Redraw,, ahk_id %curwin_id% (didn't work for Gimp)

            KeyToggle = 0
        }
        Sleep, 20
    }

    ; remove grid lines
    Loop, 12
        Gui, %A_Index%: Cancel

    DllCall("RedrawWindow", "Uint", curwin_id , "Uint", 0, "Uint", 0, "Uint", 0x81)    ; Workaround for WinSet, Redraw,, ahk_id %curwin_id% (didn't work for Gimp)

    ; save (new) tooltip position
    ; there seems no way to filter for our own tooltip, so we recognize it by height. Ours has 68 pixels.
    WinGetPos, WX, WY, WW, WH, ahk_class tooltips_class32
    if (DrawGridShowDistance AND ShowMeasuresAsToolTip AND WH = 68)
    {
        WinGetPos, WX, WY, WW, WH, ahk_class tooltips_class32
        ShowMeasuresToolTip_X = %WX%
        ShowMeasuresToolTip_Y = %WY%
        IniWrite, %ShowMeasuresTooltip_X%,     KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_X
        IniWrite, %ShowMeasuresTooltip_Y%,     KDE_Mover-Sizer.ini, Special, ShowMeasuresToolTip_Y
    }

    DisableGridButtonHotkey()    ; Disable catcher for %DrawGridOverlay_Mouse%

    Hotkey, Escape,  Off
    Traytip 
    ToolTip

    SetMouseCursorDefault()
    return


; ***************************************************************************************
; *************  ACTION: Do colour sampler, end with DrawGridButton or ESC **************
; ***************************************************************************************
; Colour Sampler: shows RGB+HSV colour of pixel(s) under cursor as tooltip or balloon (configurable)
;
; Keys:
; - Right mousebutton: copies colour to clipboard
; - ESC: abort
; - Control/Shift: change size of averaging area: get colour average of 3x3, 5x5 and 7x7 pixels around cursor

DoColourSampler()
{
    global ShowMeasuresAsToolTip, DrawGridOverlay_Mouse, FreezeSampler_Mouse

    SetMouseCursorCross()

    CatchGridButtonHotkey()   ; Catch %DrawGridOverlay_Mouse% mouse button and don't pass it to underlying app
        
    FreezeSamplerPosition := GetKeyState( FreezeSampler_Mouse ,"P")

    Loop
    {
        MouseGetPos, MXl, MYl
        KCtrl_last  := GetKeyState("Control","P")
        KShift_last := GetKeyState("Shift","P")

        Loop        ; wait until mouse moved or keys were pressed/released
        {
            MouseGetPos,MX,MY
            if ( MXl != MX or MYl != MY or GetKeyState(DrawGridOverlay_Mouse,"P") or GetKeyState("Escape","P") )
                break
            if ( GetKeyState("Control","P") != KCtrl_last or GetKeyState("Shift","P") != KShift_last or GetKeyState(FreezeSampler_Mouse,"P"))
                break
            Sleep, 20
        }
        if ( GetKeyState(DrawGridOverlay_Mouse,"P") or GetKeyState("Escape","P") )
            break

        AvgSize := 0
        if ( GetKeyState("Control","P") )
            AvgSize += 1
        if ( GetKeyState("Shift","P") )
            AvgSize += 2
            
        FreezeSamplerPosition := FreezeSamplerPosition OR GetKeyState(FreezeSampler_Mouse,"P")

        if ( NOT FreezeSamplerPosition )
           MouseGetPos, PosX, PosY
        
        mycolour := getAvgPixelGetColor( PosX, PosY, AvgSize )
        
        ; split color to RGB and convert RGB to HSV
        ;
        cR := (mycolour>>16) & 255
        cG := (mycolour>>8) & 255
        cB := mycolour & 255
        cH := 0
        cS := 0
        cMin := min(min(cR, cG), cB)
        cMax := max(max(cR, cG), cB)
        cChr := cMax - cMin

        if (cChr != 0) {
            if (cR = cMax) {
                cH := (cG - cB) / cChr
                if (cH < 0)
                    cH := cH + 6
            } else if (cG = cMax)
                cH := ((cB - cR) / cChr) + 2
            else
                cH := ((cR - cG) / cChr) + 4
            cH := cH * 60
            cS := cChr / cMax
        }
        cV := cMax / 2.55

        SetFormat, Integer, hex
        mycolour += 0
        mycolourhex := mycolour . ""
        SetFormat, Integer, d
        StringRight, mycolourhex, mycolourhex, StrLen(mycolourhex)-2
        mycolourhex := "00000000" . mycolourhex
        StringRight, mycolourhex, mycolourhex, 6

        str := "RGB: #" . mycolourhex . "`r`nR: " cR " G: " cG " B: " cB "`r`nH: " Round(cH) " S: " Round(cS*100) " V: " Round(cV)
        w := AvgSize*2 +1
        if ( ShowMeasuresAsToolTip ) {
            ToolTip Colour Sampler: (%w%x%w% pixel)`r`n%str%, % (PosX+1), % (PosY+1)
        } else
            Traytip Colour Sampler (%w%x%w% pixel), %str%, 100, 0
        Sleep, 20
    }

    if GetKeyState(DrawGridOverlay_Mouse,"P")
        clipboard := "#" . mycolourhex

    DisableGridButtonHotkey()    ; Disable catcher for GridButton 

    TrayTip
    ToolTip
    SetMouseCursorDefault()
    return
}

; helper function for DoColourSampler: gets the average pixel colour around MX/MY
; avg=0: 1x1 (single pixel), avg=1: 3x3 (9px), avg=2: 5x5 (25px), avg=3: 7x7 (49px), ...
getAvgPixelGetColor( MX, MY, avg )
{
    cR := 0
    cG := 0
    cB := 0

    Loop % (avg*2+1)
    {
        l = %A_Index%
        Loop % (avg*2+1)
        {
            m = %A_Index%
            PixelGetColor, mycolour, MX-avg+m-1, MY-avg+l-1, Slow|RGB
            cR := cR + ((mycolour>>16) & 255)
            cG := cG + ((mycolour>>8) & 255)
            cB := cB + (mycolour & 255)
        }
    }
    n := ( avg*2+1 ) * ( avg*2+1 )
    r := ((cR/n)<<16 | (cG/n)<<8 | (cB/n))
    return r
}


; ****************************************************************************************************************
; *************  ACTION Helper: Quickly position and resize window on edge/grid during Move/Resize ***************
; ****************************************************************************************************************

QuickPositionWindowOnEdge(ByRef X2, ByRef Y2, ByRef W2, ByRef H2)
{
    ; Resize&Snapping Areas:
    ; Off   X,Y  W,H  QkSize X,Y    W,H  Off_l
    ;  0    0    1/4   =[1]  [0]     [1]   1
    ;  1/16 0    1/3   =[2]  [0]     [2]   2
    ;  2/16 0    0.382 =[3]  [0]     [3]   3
    ;  3/16 0    1/2   =[4]  [0]     [4]   4
    ;  4/16 0    0.618       [0]   1-[3]   5
    ;  5/16 0    2/3         [0]   1-[2]   6
    ;  6/16 0    3/4         [0]   1-[1]   7
    ;  7/16 0      1         [0]   1-[0]   8
    ;  8/16 0      1       1-W,H   1-[0]   8
    ;  9/16 1/4   3/4      1-W,H   1-[1]   7
    ; 10/16 1/3   2/3      1-W,H   1-[2]   6
    ; 11/16 0.382 0.618    1-W,H   1-[3]   5
    ; 12/16 1/2   1/2      1-W,H     [4]   4
    ; 13/16 0.618 0.382    1-W,H     [3]   3
    ; 14/16 2/3   1/3      1-W,H     [2]   2
    ; 15/16 3/4   1/4      1-W,H     [1]   1

    QuickSize0 := 0
    QuickSize1 := 1/4
    QuickSize2 := 1/3
    QuickSize3 := 0.382
    QuickSize4 := 1/2

    ; Center: (at 7/16 <= .. < 9/16)
    ; Off X+Y  X=Y, W=H
    ;  outer:       1
    ;  middle:      0.66
    ;  inner:       0.333

    GetCurrentScreenBoarders(scrLeft, scrRight, scrTop, scrBottom)
    scrWidth  := scrRight - scrLeft
    scrHeight := scrBottom - scrTop
    MouseGetPos, WinCenterX,WinCenterY

    WinCenterXl := WinCenterX - scrLeft
    WinCenterYl := WinCenterY - scrTop
    
    OffX := Floor( (16 * WinCenterXl) / scrWidth)  ; floor divide to obtain OffX 0..15
    OffY := Floor( (16 * WinCenterYl) / scrHeight) ; floor divide to obtain OffY 0..15
    
    OffX_l := OffX + 1
    OffY_l := OffY + 1
    if ( OffX >= 8 )
        OffX_l := 16 - OffX
    if ( OffY >= 8 )
        OffY_l := 16 - OffY

    M8mOffX_l := 8 - OffX_l
    M8mOffY_l := 8 - OffY_l
    
    if (     abs(WinCenterXl - scrWidth /2) < scrWidth /16*0.33  
         AND abs(WinCenterYl - scrHeight/2) < scrHeight/16*0.33  )            ; is the inner center
    { 
        X2 := scrLeft + 0.33 * scrWidth
        Y2 := scrTop  + 0.33 * scrHeight
        W2 := scrWidth  * 0.33
        H2 := scrHeight * 0.33
    }
    else if (     abs(WinCenterXl - scrWidth /2) < scrWidth /16*0.66  
              AND abs(WinCenterYl - scrHeight/2) < scrHeight/16*0.66  )       ; is the middle center
    {
        X2 := scrLeft + 0.25 * scrWidth
        Y2 := scrTop  + 0.25 * scrHeight
        W2 := scrWidth  * 0.5
        H2 := scrHeight * 0.5
    }
    else if (     abs(WinCenterXl - scrWidth /2) < scrWidth /16*1 
              AND abs(WinCenterYl - scrHeight/2) < scrHeight/16*1  )       ; is the outer center
    {
        X2 := scrLeft + 0.382*0.382 * scrWidth
        Y2 := scrTop  + 0.382*0.382 * scrHeight
        W2 := scrWidth  * ( 1 - 2*0.382*0.382)
        H2 := scrHeight * ( 1 - 2*0.382*0.382)
    }
    else                                                                 ; is one of the outer squares
    {
        if ( OffX_l <= 4 )
            W2 := scrWidth * QuickSize%OffX_l%
        else
            W2 := scrWidth * (1 - QuickSize%M8mOffX_l%)
            
        if ( OffX < 8)
            X2 := scrLeft
        else
            X2 := scrLeft +  scrWidth - W2


        if ( OffY_l <= 4 )
            H2 := scrHeight * QuickSize%OffY_l%
        else
            H2 := scrHeight * (1 - QuickSize%M8mOffY_l%)
            
        if ( OffY < 8)
            Y2 := scrTop
        else
            Y2 := scrTop +  scrHeight - H2
    }
}

; ***********************************************************************************************************
; *************  ACTION: Scroll windows under mouse cursor, even if not active (shimanov, scoox) ********
; ***********************************************************************************************************

DoFocuslessScrollUp:
    FocuslessScroll( FocuslessScrollSpeed )
    return
DoFocuslessScrollDown:
    FocuslessScroll( -FocuslessScrollSpeed )
    return
    
FocuslessScroll(Scrollstep)
{
    Critical
    MouseGetPos, m_x, m_y, WinID, Control1
    MouseGetPos, m_x, m_y, , Control2, 2
    MouseGetPos,,,, Control3, 3
    ;TrayTip,, winid %WinID%   ctl1 _%Control1%_   ctl2 _%Control2%_   ctl3 _%Control3%_

    wParam := Scrollstep << 16
    If(GetKeyState("Shift","P"))
        wParam := wParam | 0x4
    If(GetKeyState("Ctrl","P"))
        wParam := wParam | 0x8

    If(Control2 = "")
    {
        PostMessage, 0x20A, wParam, (m_y << 16) | (m_x &0xFFFF),, ahk_id %WinID%  ; SendMessage does not work for TotalCommander Lister
        ;SendMessage, 0x1, wParam, (m_y << 16) | (m_x &0xFFFF),, ahk_id %WinID%
    }
    Else
    {
        If(Control2 != Control3)
            SendMessage, 0x20A, wParam, (m_y << 16) | (m_x &0xFFFF),, ahk_id %Control3%
        Else
            SendMessage, 0x20A, wParam, (m_y << 16) | (m_x &0xFFFF),, ahk_id %Control2%
    }
}


; *******************************************************
; *************  General Helper Functions ***************
; *******************************************************

; get current screen boarders for monitor where mouse cursor is
GetCurrentScreenBoarders(ByRef CurrentScreenLeft, ByRef CurrentScreenRight, ByRef CurrentScreenTop, ByRef CurrentScreenBottom)
{
    ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
    MouseGetPos,Mouse_X,Mouse_Y
    SysGet, MonitorCount, MonitorCount
    Loop,  %MonitorCount%
    {
        SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
        if (Mouse_X >= MonitorWorkAreaLeft) AND (Mouse_X <= MonitorWorkAreaRight) AND (Mouse_Y >= MonitorWorkAreaTop) AND (Mouse_Y <= MonitorWorkAreaBottom)
        {
            CurrentScreenLeft   := MonitorWorkAreaLeft
            CurrentScreenRight  := MonitorWorkAreaRight
            CurrentScreenTop    := MonitorWorkAreaTop
            CurrentScreenBottom := MonitorWorkAreaBottom
        }
    }
}

; Draw rectangular frame on screen - set attributes
DrawRectFrame_Prepare()
{
    global
    Loop, 4 {
        Gui, %A_Index%: -Caption +ToolWindow +AlwaysOnTOp +OwnDialogs %DrawGridGUIOptions%
        Gui, %A_Index%: Color, %DrawGridColour%
    }
}
; Draw rectangular frame on screen - do the actual drawing
DrawRectFrame_Show( KDE_WinX2, KDE_WinY2, KDE_WinW2, KDE_WinH2 )
{
    global
    Gui, 1: Show, % "x" KDE_WinX2-2 " y" KDE_WinY2-2 " w" DrawGridWidth+1 " h" KDE_WinH2     " NoActivate"
    Gui, 2: Show, % "x" KDE_WinX2-2 " y" KDE_WinY2-2 " w" KDE_WinW2     " h" DrawGridWidth+1 " NoActivate"
    Gui, 3: Show, % "x" KDE_WinX2+KDE_WinW2-2 " y" KDE_WinY2-2 " w" DrawGridWidth+1 " h" KDE_WinH2     " NoActivate"
    Gui, 4: Show, % "x" KDE_WinX2-2 " y" KDE_WinY2+KDE_WinH2-2 " w" KDE_WinW2     " h" DrawGridWidth+1 " NoActivate"
}
; Draw rectangular frame on screen - hide frame
DrawRectFrame_Cancel()
{
    global
    Loop, 4
        Gui, %A_Index%: Cancel
    ;DllCall("RedrawWindow", "Uint", curwin_id , "Uint", 0, "Uint", 0, "Uint", 0x81)    ; Workaround for WinSet, Redraw,, ahk_id %curwin_id% (didn't work for Gimp)
}

; returns 1 if Window at current Mouse position is in Window Ignore list
CheckIsWindowInIgnoreList(WindowIgnoreList)
{
    MouseGetPos,,,curwin_id
    WinGet currentwinname, ProcessName, ahk_id %curwin_id%
    res := (InStr( WindowIgnoreList, currentwinname, CaseSensitive = false ) != 0)
    return res
}

; returns the smaller of two values
min( a, b )
{
    minimum := a
    if (b < a)
        minimum := b
    return minimum
}
; returns the greater of two values
max( a, b )
{
    maximum := a
    if (b > a)
        maximum := b
    return maximum
}

; functions to change the mouse cursor to cross and restore it
SetMouseCursorCross()
{
    CursorHandle := DllCall( "LoadCursor", Uint,0, Int,32515 )    ; load new cursor (32515:Cross)
    DllCall( "SetSystemCursor", Uint,CursorHandle, Int,32512 )    ; overwrite arrow new cursor
}
SetMouseCursorDefault()
{
    DllCall( "SystemParametersInfo", UInt,0x57, UInt,0, UInt,0, UInt,0 ) ; restore systems cursors
}

; save current window state to allow restore on Escape
SaveOriginalWindowState()
{
    global orig_WinID,orig_isMax, orig_WinX,orig_WinY,orig_WinW,orig_WinH, orig_MouseX, orig_MouseY

    MouseGetPos, ,,orig_WinID
    WinGet,    orig_isMax,MinMax,ahk_id %orig_WinID%
    WinGetPos, orig_WinX,orig_WinY,orig_WinW,orig_WinH,ahk_id %orig_WinID%
    MouseGetPos, orig_MouseX,orig_MouseY

    Hotkey, !Escape, On
    Hotkey, Escape,  On
}
; restore saved window state on Escape
RestoreOriginalWindowState()
{
    global orig_WinID,orig_isMax, orig_WinX,orig_WinY,orig_WinW,orig_WinH, orig_MouseX, orig_MouseY

    WinMove ahk_id %orig_WinID%,, orig_WinX,orig_WinY,orig_WinW,orig_WinH
    WinGet, current_isMax,MinMax,ahk_id %orig_WinID%
    if current_isMax AND NOT orig_isMax
        WinRestore, ahk_id %orig_WinID%
    if ! current_isMax AND orig_isMax
        WinMaximize, ahk_id %orig_WinID%
}
; returns readable name for hotkey
strname( key )
{
    if (key = "!" )
        return "Alt"
    if (key = "!^" or key = "^!")
        return "Ctrl+Alt"
    if (key = "^" )
        return "Ctrl"
    if (key = "^+" )
        return "Ctrl+Shift"
    if (key = "^+" )
        return "Ctrl+Shift"
    if (key = "^!+" or key = "!^+")
        return "Ctrl+Shift+Alt"
    if (key = "#")
        return "LeftWin"
    if (key = "#^")
        return "Ctrl+LeftWin"
    if (key = "<^>!")
        return "AltGr"
    if (key = "<^>!+")
        return "AltGr+Shift"
    if (key = "LControl & ~RAlt")
        return "AltGr"
    if (key = "LButton")
        return "Left"
    if (key = "RButton")
        return "Right"
    if (key = "MButton")
        return "Middle"
    return key
}
DisableEscapeHotkey()
{
    Hotkey, !Escape, Off
    Hotkey, Escape, Off
}
CatchEscape1:
    return
CatchEscape2:
    return

CatchGridButtonHotkey()
{
    global ; DrawGridOverlay_Mouse

    if ( DoubleAltShortcuts )
        Hotkey, ~%DoubleKey_Hotkey2%, Off  ; stop the double-key from interfering with colour sampler

    Hotkey, %DrawGridOverlay_Mouse%, CatchGridButton, On
    Hotkey, ^%DrawGridOverlay_Mouse%, CatchGridButtonCtrl, On
    Hotkey, +%DrawGridOverlay_Mouse%, CatchGridButtonShift, On
    Hotkey, ^+%DrawGridOverlay_Mouse%, CatchGridButtonCtrlShift, On

}
DisableGridButtonHotkey()
{
    global DrawGridOverlay_Mouse
    Hotkey, %DrawGridOverlay_Mouse%, Off
    Hotkey, ^%DrawGridOverlay_Mouse%, Off
    Hotkey, +%DrawGridOverlay_Mouse%, Off
    Hotkey, ^+%DrawGridOverlay_Mouse%, Off

    Init_SetHotkeyHandler()     ; reenable original hotkeys

}
CatchGridButton:
    return
CatchGridButtonCtrl:
    return
CatchGridButtonShift:
    return
CatchGridButtonCtrlShift:
    return

; These are the labels required to handle SpecialCharacters key remapping
;
SpecialCharactersLbl_1:
    Send %SpecialCharactersChar_1%
    return
SpecialCharactersLbl_2:
    Send %SpecialCharactersChar_2%
    return
SpecialCharactersLbl_3:
    Send %SpecialCharactersChar_3%
    return
SpecialCharactersLbl_4:
    Send %SpecialCharactersChar_4%
    return
SpecialCharactersLbl_5:
    Send %SpecialCharactersChar_5%
    return
SpecialCharactersLbl_6:
    Send %SpecialCharactersChar_6%
    return
SpecialCharactersLbl_7:
    Send %SpecialCharactersChar_7%
    return
SpecialCharactersLbl_8:
    Send %SpecialCharactersChar_8%
    return
SpecialCharactersLbl_9:
    Send %SpecialCharactersChar_9%
    return
SpecialCharactersLbl_10:
    Send %SpecialCharactersChar_10%
    return
SpecialCharactersLbl_11:
    Send %SpecialCharactersChar_11%
    return
SpecialCharactersLbl_12:
    Send %SpecialCharactersChar_12%
    return
SpecialCharactersLbl_13:
    Send %SpecialCharactersChar_13%
    return
SpecialCharactersLbl_14:
    Send %SpecialCharactersChar_14%
    return
SpecialCharactersLbl_15:
    Send %SpecialCharactersChar_15%
    return

; One (static) hotkey must always be enabled - otherwise, (dynamic) mouse hotkeys won't work for some reason
; This hotkey Ctrl+Shift+Alt+F9 does nothing and is passed on, just makes sure dynamic mouse hotkeys don't disappear
~^!+F9::
    ;SendEvent {Blind}{F9 down}
    ;KeyWait F9, U
    ;SendEvent {Blind}{F9 up}
    return
~^!+MButton::
    return



;ProductName := "KDE Mover-Sizer"
;ProductVersion := 2.9
;ProductPublisher := "corz.org"
;ProductWebsite := "http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php"

