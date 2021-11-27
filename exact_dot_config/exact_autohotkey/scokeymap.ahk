; add to startup:
;
; <ctrl-c> on .ahk
; <win-r> shell:startup
; right-click in startup folder, "paste shortcut"

; emulate term
; TEMP: disabled because it interferes with Notion ^[ ^] hotkeys :(
;^[::Send {Esc}

; below is adapted from https://autohotkey.com/board/topic/51959-using-capslock-as-another-modifier-key/

$*Capslock::
Gui, 99:+ToolWindow
Gui, 99:Show, NoActivate, Capslock Is Down
keywait, Capslock
Gui, 99:Destroy
return

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

; multimedia
q::Media_Prev
w::Media_Play_Pause
e::Media_Next
1::Volume_Down
2::Volume_Mute
3::Volume_Up

#IfWinExist

; work around accidental ctrl-shift-q in firefox
#IfWinActive ahk_exe firefox.exe
^+q::
#IfWinActive

; use ctrl-shift-a instead of ctrl-a in miro (prevent accidental select-all+do-something-stupid-to-big-doc)
#IfWinActive ahk_exe miro.exe
^+a::Send ^a
^a::
#IfWinActive

; dumb notion hotkeys..
; TODO: this does not work
;#IfWinActive ahk_exe notion.exe
;Browser_Back::^[
;Browser_Foward::^]
;#IfWinActive
