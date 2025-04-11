; add to startup:
;
; <ctrl-c> on .ahk
; <win-r> shell:startup
; right-click in startup folder, "paste shortcut"

; emulate term
; TEMP: disabled because it interferes with Notion ^[ ^] hotkeys :(
;^[::Send {Esc}

; capslock-shift state management
; (credit: https://autohotkey.com/board/topic/51959-using-capslock-as-another-modifier-key/)
;
$*Capslock::
    if (A_PriorHotkey = "$*Capslock" and A_TimeSincePriorHotkey < 300) { ; Detect double-tap on Caps Lock
        SetCapsLockState, % GetKeyState("CapsLock", "T") ? "Off" : "On"
        return
    }
    Gui, 99:+ToolWindow
    Gui, 99:Show, NoActivate, Capslock Is Down
    keywait, Capslock
    Gui, 99:Destroy
return

; capslock-shifted hotkeys
;
#IfWinExist, Capslock Is Down

    ; vimish
    [::Esc
    h::Left
    j::Down
    k::Up
    l::Right
    ; could try to be vimish on these, but can't really do $ ctrl-b etc. with left pinky already on capslock
    u::Home
    m::End
    i::PgUp
    ,::PgDn
    BackSpace::Del

    ; other fun
    '::`

    ; match the keychron
    b::`

    ; multimedia
    q::Media_Prev
    w::Media_Play_Pause
    e::Media_Next
    ; pick new ones
    ;1::Volume_Down
    ;2::Volume_Mute
    ;3::Volume_Up

    ; f keys
    1::F1
    2::F2
    3::F3
    4::F4
    5::F5
    6::F6
    7::F7
    8::F8
    9::F9
    0::F10
    -::F11
    =::F12

#IfWinExist
