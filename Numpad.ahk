Suspend
#NoEnv
SendMode Input

; Create overlay GUI
Gui, +AlwaysOnTop -Caption +ToolWindow +E0x20
Gui, Color, 000000  ; black background (invisible with BackgroundTrans)
Gui, Font, s9 c00FF00 Bold, Consolas

; Main text
Gui, Add, Text, vFKeyLabel BackgroundTrans, NUMPAD!

; Show hidden by default
Gui, Show, x10 y10 NoActivate AutoSize Hide

; Transparency for subtle glow
WinSet, Transparent, 220, ahk_class AutoHotkeyGUI

SetTimer, CheckCapsLock, 200
return

CheckCapsLock:
    if GetKeyState("CapsLock", "T")
        Gui, Show, NoActivate
    else
        Gui, Hide
return

; Script 2: Remap Numpad keys when Caps Lock is on
SetCapsLockState, AlwaysOff
#If GetKeyState("CapsLock", "T")
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
