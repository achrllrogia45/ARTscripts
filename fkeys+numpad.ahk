#NoEnv
#Warn
#Persistent
#SingleInstance Force
SendMode Input

; Auto-elevate the script to admin if not already
if !A_IsAdmin {
    try {
        Run *RunAs "%A_ScriptFullPath%"
    }
    ExitApp
}

Suspend
IniFile := A_ScriptDir "\mode.ini"

; Load last mode from file (default FKEY if none)
if FileExist(IniFile) {
    IniRead, Mode, %IniFile%, Settings, Mode, FKEY
} else {
    Mode := "(F)KEY"
}

; Overlay GUI
Gui, +AlwaysOnTop -Caption +ToolWindow
Gui, Color, 000000        ; black background
Gui, Font, s9 c00FF00 Bold, Consolas
Gui, Add, Text, vOverlayText Center BackgroundTrans, %Mode% MODE
Gui, Show, y10 NoActivate AutoSize Hide

; Apply transparency to the whole GUI (≈10% visible background)
; 255 = fully opaque, 25 ≈ 10% visible
WinSet, Transparent, 25, ahk_class AutoHotkeyGUI

SetTimer, CheckCapsLock, 200
return

CheckCapsLock:
    if GetKeyState("CapsLock", "T") {
        GuiControl,, OverlayText, %Mode% MODE
        Gui, Show, NoActivate
    } else {
        Gui, Hide
    }
return

; Toggle mode only when CapsLock is ON
^!t::
    if GetKeyState("CapsLock", "T") {
        if (Mode = "(F)KEY") {
            Mode := "NUMPAD"
        } else {
            Mode := "(F)KEY"
        }
        GuiControl,, OverlayText, %Mode% MODE
        IniWrite, %Mode%, %IniFile%, Settings, Mode
    }
return

; Remaps active only when CapsLock is ON
#If GetKeyState("CapsLock", "T") && Mode="(F)KEY"
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
#If

#If GetKeyState("CapsLock", "T") && Mode="NUMPAD"
1::Numpad1
2::Numpad2
3::Numpad3
4::Numpad4
5::Numpad5
6::Numpad6
7::Numpad7
8::Numpad8
9::Numpad9
0::Numpad0
/::NumpadDiv
-::NumpadSub
=::NumpadAdd
#If