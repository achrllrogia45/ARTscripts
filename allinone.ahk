; ==============================================================================
; ALL-IN-ONE.AHK
; Merged: AltArrow, AlwaysOnTop, SpacePan, Fkey+Numpad, CursLock
; ==============================================================================

#NoEnv
#Persistent
#SingleInstance Force
SendMode Input
CoordMode, Mouse, Screen
SetWorkingDir %A_ScriptDir%

; --- Auto-elevate to Admin ---
if !A_IsAdmin {
    try {
        Run *RunAs "%A_ScriptFullPath%"
    }
    ExitApp
}

; ==============================================================================
; INITIALIZATION & SETTINGS
; ==============================================================================

IniFile := A_ScriptDir "\mode.ini"

; --- Load Module Toggles from INI ---
IniRead, Mod_AltArrow, %IniFile%, Toggles, Mod_AltArrow, 1
IniRead, Mod_AOT, %IniFile%, Toggles, Mod_AOT, 1
IniRead, Mod_SpacePan, %IniFile%, Toggles, Mod_SpacePan, 1
IniRead, Mod_FkeyNumpad, %IniFile%, Toggles, Mod_FkeyNumpad, 1
IniRead, Mod_CursLock, %IniFile%, Toggles, Mod_CursLock, 1

; --- Load Fkey/Numpad Mode ---
if FileExist(IniFile) {
    IniRead, Mode, %IniFile%, Settings, Mode, (F)KEY
} else {
    Mode := "(F)KEY"
}

; --- SpacePan: Adobe App Group ---
GroupAdd, AdobeMMButton, ahk_exe Photoshop.exe
GroupAdd, AdobeMMButton, ahk_exe InDesign.exe
GroupAdd, AdobeMMButton, ahk_exe AcroRD32.exe
GroupAdd, AdobeMMButton, ahk_exe Acrobat.exe
GroupAdd, AdobeMMButton, ahk_exe Muse.exe

; --- Variables ---
global Monitor1_W := 1920      
global Monitor1_H := 1080      
global Monitor2_Pos := "AUTO"  
global GuiScale := 0.8
global GuiX_Offset := 0
global GuiY_Offset := 0
global TimerInterval := 5000
global MaxMouseJump := 300
global LastMouseX := Monitor1_W / 2
global LastMouseY := Monitor1_H / 2
global PenActive := false
global prevX := 0
global prevY := 0
global LastCapsState := -1 ; Used to stop GUI spamming

; ==============================================================================
; TRAY MENU SETUP
; ==============================================================================
Menu, Tray, NoStandard
Menu, Tray, Add, Show Button, ShowPositionSelector
Menu, Tray, Add, Show Scripts List, ShowScriptsManager
Menu, Tray, Add
Menu, Tray, Add, Open (ListLines), InspectScripts
Menu, Tray, Add, Reload Scripts, ReloadScript
Menu, Tray, Add, Edit Scripts, EditScript
Menu, Tray, Add, Locate Scripts, LocateScript
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Show Scripts List

; ==============================================================================
; STARTUP ACTIONS
; ==============================================================================

; --- Restored & Bulletproofed Overlay GUI ---
Gui, Overlay:New, +AlwaysOnTop -Caption +ToolWindow +HwndOverlayHwnd
Gui, Overlay:Color, 000000
Gui, Overlay:Font, s9 c00FF00 Bold, Consolas
Gui, Overlay:Add, Text, vOverlayText Center BackgroundTrans, %Mode% MODE
Gui, Overlay:Show, y10 NoActivate AutoSize Hide
WinSet, Transparent, 25, ahk_id %OverlayHwnd%

; Start Timers
SetTimer, CheckCapsLock, 200
SetTimer, MonitorInput, 15

; Show Manager Table on Reload/Startup
GoSub, ShowScriptsManager

; End of Auto-Execute Section
return

; ==============================================================================
; SCRIPTS MANAGER GUI (TABLE / CHECKER)
; ==============================================================================
ShowScriptsManager:
    Gui, Manager:New, +SysMenu +AlwaysOnTop, Scripts Manager
    Gui, Add, Text, w200, Check the modules you want to enable:
    Gui, Add, CheckBox, vMod_AltArrow gSaveToggles Checked%Mod_AltArrow%, AltArrow
    Gui, Add, CheckBox, vMod_AOT gSaveToggles Checked%Mod_AOT%, AlwaysOnTop
    Gui, Add, CheckBox, vMod_SpacePan gSaveToggles Checked%Mod_SpacePan%, SpacePan
    Gui, Add, CheckBox, vMod_FkeyNumpad gSaveToggles Checked%Mod_FkeyNumpad%, Fkeys+Numpad
    Gui, Add, CheckBox, vMod_CursLock gSaveToggles Checked%Mod_CursLock%, CursLock
    Gui, Show,, Scripts Manager
return

SaveToggles:
    Gui, Manager:Submit, NoHide
    IniWrite, %Mod_AltArrow%, %IniFile%, Toggles, Mod_AltArrow
    IniWrite, %Mod_AOT%, %IniFile%, Toggles, Mod_AOT
    IniWrite, %Mod_SpacePan%, %IniFile%, Toggles, Mod_SpacePan
    IniWrite, %Mod_FkeyNumpad%, %IniFile%, Toggles, Mod_FkeyNumpad
    IniWrite, %Mod_CursLock%, %IniFile%, Toggles, Mod_CursLock
return

; ==============================================================================
; TRAY MENU FUNCTIONS
; ==============================================================================
InspectScripts:
    ListLines
return

ReloadScript:
    Reload
return

EditScript:
    Run, notepad.exe "%A_ScriptFullPath%"
return

LocateScript:
    Run, %A_ScriptDir%
return

ExitScript:
    ExitApp
return

; ==============================================================================
; TIMERS & BACKGROUND LOGIC
; ==============================================================================

CheckCapsLock:
    ; FIXED: Only triggers when CapsLock actually changes state, preventing GUI spam
    currentCaps := GetKeyState("CapsLock", "T")
    if (currentCaps != LastCapsState) {
        LastCapsState := currentCaps
        if (Mod_FkeyNumpad && currentCaps) {
            Gui, Overlay:Default
            GuiControl,, OverlayText, %Mode% MODE
            Gui, Overlay:Show, y10 NoActivate AutoSize
        } else {
            Gui, Overlay:Hide
        }
    }
return

MonitorInput:
    if (!Mod_CursLock)
        return

    MouseGetPos, cx, cy
    dx := Abs(cx - prevX), dy := Abs(cy - prevY)
    if (dx > MaxMouseJump || dy > MaxMouseJump) {
        PenActive := true
        if (IsOnMainScreen(prevX, prevY)) {
            LastMouseX := prevX, LastMouseY := prevY
        }
    }
    if (A_TimeIdlePhysical < 30) {
        if (PenActive && !IsOnMainScreen(cx, cy)) {
            MouseMove, %LastMouseX%, %LastMouseY%, 0
            PenActive := false
        }
        if (IsOnMainScreen(cx, cy)) {
            LastMouseX := cx, LastMouseY := cy, PenActive := false
        }
    }
    prevX := cx, prevY := cy
return

IsOnMainScreen(x, y) {
    if (Monitor2_Pos = "AUTO")
        return true
    if (Monitor2_Pos = "DOWN")
        return (y <= Monitor1_H)
    if (Monitor2_Pos = "TOP")
        return (y >= 0)
    if (Monitor2_Pos = "RIGHT")
        return (x <= Monitor1_W)
    if (Monitor2_Pos = "LEFT")
        return (x >= 0)
    return true
}

; ==============================================================================
; CURSLOCK GUI BUTTONS
; ==============================================================================
ShowPositionSelector:
    btnW := 70 * GuiScale
    btnH := 40 * GuiScale
    gap := 5 * GuiScale
    fontSize := Floor(11 * GuiScale)
    CustomColor := "00FF00"

    Gui, TabletSelector:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, Color, %CustomColor%
    WinSet, TransColor, %CustomColor%
    Gui, Font, s%fontSize% Bold cWhite, Segoe UI

    LeftY  := (btnH / 2) + (gap * 1.5)
    TopX   := btnW + (gap * 2)
    DownY  := btnH + (gap * 2)
    RightX := (btnW * 2) + (gap * 3)
    
    Gui, Add, Button, x%gap% y%LeftY% w%btnW% h%btnH% gSetLeft +Background000000, LEFT
    Gui, Add, Button, x%TopX% y%gap% w%btnW% h%btnH% gSetTop +Background000000, TOP
    Gui, Add, Button, x%TopX% y%DownY% w%btnW% h%btnH% gSetDown +Background000000, DOWN
    Gui, Add, Button, x%RightX% y%LeftY% w%btnW% h%btnH% gSetRight +Background000000, RIGHT

    winW := (btnW * 3) + (gap * 4)
    winH := (btnH * 2) + (gap * 3)
    GuiX := (Monitor1_W / 2) - (winW / 2) + GuiX_Offset
    GuiY := (Monitor1_H / 2) - (winH / 2) + GuiY_Offset

    Gui, TabletSelector:Show, x%GuiX% y%GuiY% w%winW% h%winH% NoActivate, Tablet Position Selector
    SetTimer, HideSelectorGui, %TimerInterval%
return

HideSelectorGui:
    Gui, TabletSelector:Destroy
return

SetTop:
    Monitor2_Pos := "TOP"
    GoSub, FinalizeChoice
return
SetDown:
    Monitor2_Pos := "DOWN"
    GoSub, FinalizeChoice
return
SetLeft:
    Monitor2_Pos := "LEFT"
    GoSub, FinalizeChoice
return
SetRight:
    Monitor2_Pos := "RIGHT"
    GoSub, FinalizeChoice
return

FinalizeChoice:
    ToolTip, 2nd Monitor: %Monitor2_Pos%
    SetTimer, RemoveToolTip, -1500
    Gui, TabletSelector:Destroy
return

RemoveToolTip:
    ToolTip
return

; ==============================================================================
; HOTKEYS: ALWAYS ON TOP
; ==============================================================================
#If Mod_AOT
F8::
    WinSet, AlwaysOnTop, Toggle, A
    SplashTextOn, 250, 30, AOT Status, Always On Top Toggled
    SetTimer, RemoveSplash, -1000
return

RemoveSplash:
    SplashTextOff
return
#If

; ==============================================================================
; HOTKEYS: SPACEPAN (ADOBE ONLY)
; ==============================================================================
#If Mod_SpacePan && WinActive("ahk_group AdobeMMButton")
MButton::
    Send, {Space Down}
    Send, {LButton Down}
    KeyWait, MButton
    Send, {LButton Up}
    Send, {Space Up}
return
#If

; ==============================================================================
; HOTKEYS: FKEYS + NUMPAD
; ==============================================================================
#If Mod_FkeyNumpad && GetKeyState("CapsLock", "T")
^!t::
    if (Mode = "(F)KEY") {
        Mode := "NUMPAD"
    } else {
        Mode := "(F)KEY"
    }
    IniWrite, %Mode%, %IniFile%, Settings, Mode
    Gui, Overlay:Default
    GuiControl,, OverlayText, %Mode% MODE
return
#If

; FIXED: Changed to SendInput so keys trigger distinctly instead of holding and activating system media keys
#If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="(F)KEY"
1::SendInput {F1}
2::SendInput {F2}
3::SendInput {F3}
4::SendInput {F4}
5::SendInput {F5}
6::SendInput {F6}
7::SendInput {F7}
8::SendInput {F8}
9::SendInput {F9}
0::SendInput {F10}
-::SendInput {F11}
=::SendInput {F12}
#If

#If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="NUMPAD"
1::SendInput {Numpad1}
2::SendInput {Numpad2}
3::SendInput {Numpad3}
4::SendInput {Numpad4}
5::SendInput {Numpad5}
6::SendInput {Numpad6}
7::SendInput {Numpad7}
8::SendInput {Numpad8}
9::SendInput {Numpad9}
0::SendInput {Numpad0}
/::SendInput {NumpadDiv}
-::SendInput {NumpadSub}
=::SendInput {NumpadAdd}
#If

; ==============================================================================
; HOTKEYS: ALTARROW
; ==============================================================================
#If Mod_AltArrow
!i::Send {UP}
!k::Send {DOWN}
!j::Send {LEFT}
!l::Send {RIGHT}
!h::Send {HOME}
!;::Send {END}
!u::Send ^{HOME}
!o::Send ^{END}

!^j::Send ^{LEFT}
!^l::Send ^{RIGHT}

!+i::Send +{UP}
!+k::Send +{DOWN}
!+j::Send +{LEFT}
!+l::Send +{RIGHT}
!+h::Send +{HOME}
!+;::Send +{END}
!+u::Send ^+{HOME}
!+o::Send ^+{END}

!+^j::Send +^{LEFT}
!+^l::Send +^{RIGHT}
!+^i::Send +!{UP}
!+^k::Send +!{DOWN}

+^i::Send +^{UP}
+^k::Send +^{DOWN}
#If