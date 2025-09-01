#Requires AutoHotkey v2.0
#SingleInstance Force

TraySetIcon(A_ScriptDir "\scokeymap.ico")

; to add to windows startup:
;
; <ctrl-c> on .ahk
; <win-r> shell:startup
; right-click in startup folder, "paste shortcut"

; emulate term
^[::Send("{Esc}")

; capslock-shift state management
; (credit: https://autohotkey.com/board/topic/51959-using-capslock-as-another-modifier-key/)
;
$*Capslock::
{
    myGui := Gui("+ToolWindow")
    myGui.Title := "Capslock Is Down"
    myGui.Show("NoActivate")
    KeyWait("Capslock")
    myGui.Destroy()
}

; capslock-shifted hotkeys
;
#HotIf WinExist("Capslock Is Down")

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

#HotIf
