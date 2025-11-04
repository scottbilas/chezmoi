#Requires AutoHotkey v2.0+
#SingleInstance Force
CoordMode "Mouse", "Screen"

; show tray icon next to script name (expects a .ico next to the .ahk)
TraySetIcon(A_ScriptDir . "\" . RegExReplace(A_ScriptName, "\.ahk$", ".ico"))

state := {target:0}

!+LButton:: {
    Start()
}

!+LButton up:: {
    Stop()
}

!#LButton:: {
    Start("move")
}

!#LButton up:: {
    Stop()
}

hook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", CallbackCreate(MouseProc), "Ptr", 0, "UInt", 0, "Ptr")
MouseProc(nCode, wParam, lParam) {
    global hook, state
    if (nCode >= 0 && wParam == 0x0200 && state.target)
        Move()
    return DllCall("CallNextHookEx", "Ptr", hook, "Int", nCode, "Ptr", wParam, "Ptr", lParam)
}

Start(mode := "") {
    global state
    MouseGetPos(&x, &y, &t)
    if (!t)
        return
    WinGetPos(&wx, &wy, &ww, &wh, t)
    state := {target:t, mouse:{x:x,y:y}, win:{x:wx,y:wy,w:ww,h:wh}}
    if (mode = "move") {
        state.mode := "move"
        return
    }
    relx := x - wx
    rely := y - wy
    col := Floor(relx / Max(1, ww/3))
    row := Floor(rely / Max(1, wh/3))
    col := col < 0 ? 0 : col > 2 ? 2 : col
    row := row < 0 ? 0 : row > 2 ? 2 : row
    if (col == 1 && row == 1)
        state.mode := "move"
    else {
        state.mode := "resize"
        state.r := {l: col == 0, r: col == 2, t: row == 0, b: row == 2}
    }
}

Move() {
    global state
    MouseGetPos(&x, &y)
    dx := x - state.mouse.x
    dy := y - state.mouse.y
    if (state.mode = "move") {
        DllCall("SetWindowPos", "Ptr", state.target, "Ptr", 0, "Int", state.win.x + dx, "Int", state.win.y + dy, "Int", 0, "Int", 0, "UInt", 0x0001)
        return
    }
    nw := state.win.w
    nh := state.win.h
    nx := state.win.x
    ny := state.win.y
    if (state.r.l) {
        nx := state.win.x + dx
        nw := state.win.w - dx
    }
    if (state.r.r)
        nw := state.win.w + dx
    if (state.r.t) {
        ny := state.win.y + dy
        nh := state.win.h - dy
    }
    if (state.r.b)
        nh := state.win.h + dy
    if (nw < 100) {
        if (state.r.l)
            nx := state.win.x + (state.win.w - 100)
        nw := 100
    }
    if (nh < 40) {
        if (state.r.t)
            ny := state.win.y + (state.win.h - 40)
        nh := 40
    }
    DllCall("SetWindowPos", "Ptr", state.target, "Ptr", 0, "Int", nx, "Int", ny, "Int", nw, "Int", nh, "UInt", 0)
}

Stop() {
    global state
    state := {target:0}
}
