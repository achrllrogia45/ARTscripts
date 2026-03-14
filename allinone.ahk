; ==============================================================================
; ALL-IN-ONE.AHK
; Merged: AltArrow, AlwaysOnTop, SpacePan, Fkey+Numpad, CursLock
; Dynamic Hotkeys & INI Configuration Edition (Updated Structure)
; ==============================================================================

#NoEnv
#Persistent
#SingleInstance Force
SendMode Input
CoordMode, Mouse, Screen
SetWorkingDir %A_ScriptDir%

; --- SHIELDS: Prevent CapsLock flickering and ghost media keys ---
SetStoreCapslockMode, Off 
#MenuMaskKey vkE8         

; --- Auto-elevate to Admin ---
if !A_IsAdmin {
    try {
        Run *RunAs "%A_ScriptFullPath%"
    }
    ExitApp
}

; --- Explicitly declare Super-Globals so functions can see them ---
global Monitor1_W, Monitor1_H, Monitor2_Pos, GuiScale, GuiX_Offset, GuiY_Offset
global TimerInterval := 5000
global MaxMouseJump := 300
global LastMouseX, LastMouseY
global PenActive := false
global prevX := 0
global prevY := 0
global LastCapsState := -1
global Prev_CursLock

IniFile := A_ScriptDir "\mode.ini"

; ==============================================================================
; INI GENERATOR (Creates default mode.ini if it doesn't exist)
; ==============================================================================
if !FileExist(IniFile) {
    DefaultINI =
    (LTrim
    `; Hotkeys is From AutoHotkey v1 (Check Help inside AutoHotkey for more info)
    `; # = WIN
    `; ! = ALT
    `; ^ = CTRL
    `; + = SHIFT
    `; null = No hotkey assigned

    `; On Off Hotkeys for GUI (0 = disabled, 1 = enabled)
    [GUI Hotkeys]
    AlwaysOnTop=null
    FkeyNumpad=null
    Altarrow=null
    SpacePan=null
    Curslock=null

    [AlwaysOnTop_config]
    AlwaysOnTop_mode=F8 `; F8 to toggle AlwaysOnTop mode

    `; Toggle GUI (0 = disabled, 1 = enabled)
    [Toggles]
    Mod_AltArrow=0
    Mod_AOT=0
    Mod_SpacePan=0
    Mod_FkeyNumpad=0
    Mod_CursLock=0

    [Settings]
    FkeyNumpad_mode=(F)KEY

    `; GUI Settings for Curslock setting based your first monitor resolution
    [Curslock_config]
    Monitor1_W=1920
    Monitor1_H=1080
    Monitor2_Pos="DOWN"
    GuiScale=1
    GuiX_Offset=0
    GuiY_Offset=0
    )
    FileAppend, %DefaultINI%, %IniFile%
}

; ==============================================================================
; INITIALIZATION & SETTINGS
; ==============================================================================

; --- Load GUI Toggle Hotkeys ---
IniRead, HK_GUI_AOT, %IniFile%, GUI Hotkeys, AlwaysOnTop, null
IniRead, HK_GUI_FkeyNumpad, %IniFile%, GUI Hotkeys, FkeyNumpad, null
IniRead, HK_GUI_AltArrow, %IniFile%, GUI Hotkeys, Altarrow, null
IniRead, HK_GUI_SpacePan, %IniFile%, GUI Hotkeys, SpacePan, null
IniRead, HK_GUI_Curslock, %IniFile%, GUI Hotkeys, Curslock, null

; --- Load Action Hotkeys ---
IniRead, HK_AOT_Action, %IniFile%, AlwaysOnTop_config, AlwaysOnTop_mode, F8

; --- Load Toggles ---
IniRead, Mod_AltArrow, %IniFile%, Toggles, Mod_AltArrow, 0
IniRead, Mod_AOT, %IniFile%, Toggles, Mod_AOT, 0
IniRead, Mod_SpacePan, %IniFile%, Toggles, Mod_SpacePan, 0
IniRead, Mod_FkeyNumpad, %IniFile%, Toggles, Mod_FkeyNumpad, 0
IniRead, Mod_CursLock, %IniFile%, Toggles, Mod_CursLock, 0
Prev_CursLock := Mod_CursLock

; --- Load Settings ---
IniRead, Mode, %IniFile%, Settings, FkeyNumpad_mode, (F)KEY

; --- Load CursLock Configuration ---
IniRead, Monitor1_W, %IniFile%, Curslock_config, Monitor1_W, 1920
IniRead, Monitor1_H, %IniFile%, Curslock_config, Monitor1_H, 1080
IniRead, Monitor2_Pos, %IniFile%, Curslock_config, Monitor2_Pos, DOWN
IniRead, GuiScale, %IniFile%, Curslock_config, GuiScale, 1
IniRead, GuiX_Offset, %IniFile%, Curslock_config, GuiX_Offset, 0
IniRead, GuiY_Offset, %IniFile%, Curslock_config, GuiY_Offset, 0

; Strip rogue spaces/quotes from text, and force numbers for math
Monitor2_Pos := Trim(StrReplace(Monitor2_Pos, """", ""), " `t") 
Monitor1_W := Floor(Monitor1_W + 0)
Monitor1_H := Floor(Monitor1_H + 0)
GuiScale := GuiScale + 0.0
LastMouseX := Monitor1_W / 2
LastMouseY := Monitor1_H / 2

; --- SpacePan: Adobe App Group ---
GroupAdd, AdobeMMButton, ahk_exe Photoshop.exe
GroupAdd, AdobeMMButton, ahk_exe InDesign.exe
GroupAdd, AdobeMMButton, ahk_exe AcroRD32.exe
GroupAdd, AdobeMMButton, ahk_exe Acrobat.exe
GroupAdd, AdobeMMButton, ahk_exe Muse.exe

; ==============================================================================
; DYNAMIC HOTKEY REGISTRATION
; ==============================================================================

; Module Toggles (Turns features on/off)
if (HK_GUI_AOT != "null" && HK_GUI_AOT != "")
    Hotkey, %HK_GUI_AOT%, Toggle_AOT
if (HK_GUI_FkeyNumpad != "null" && HK_GUI_FkeyNumpad != "")
    Hotkey, %HK_GUI_FkeyNumpad%, Toggle_FkeyNumpad
if (HK_GUI_AltArrow != "null" && HK_GUI_AltArrow != "")
    Hotkey, %HK_GUI_AltArrow%, Toggle_AltArrow
if (HK_GUI_SpacePan != "null" && HK_GUI_SpacePan != "")
    Hotkey, %HK_GUI_SpacePan%, Toggle_SpacePan
if (HK_GUI_Curslock != "null" && HK_GUI_Curslock != "")
    Hotkey, %HK_GUI_Curslock%, Toggle_Curslock

; Actions
if (HK_AOT_Action != "null" && HK_AOT_Action != "")
    Hotkey, %HK_AOT_Action%, Action_AOT

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

; End of Auto-Execute Section
return

; ==============================================================================
; DYNAMIC HOTKEY ACTIONS & TOGGLES
; ==============================================================================

Action_AOT:
    if (!Mod_AOT)
        return
    WinSet, AlwaysOnTop, Toggle, A
    SplashTextOn, 250, 30, AOT Status, Always On Top Toggled
    SetTimer, RemoveSplash, -1000
return

Toggle_AOT:
    Mod_AOT := !Mod_AOT
    IniWrite, %Mod_AOT%, %IniFile%, Toggles, Mod_AOT
    GuiControl, Manager:, Mod_AOT, %Mod_AOT%
return

Toggle_FkeyNumpad:
    Mod_FkeyNumpad := !Mod_FkeyNumpad
    IniWrite, %Mod_FkeyNumpad%, %IniFile%, Toggles, Mod_FkeyNumpad
    GuiControl, Manager:, Mod_FkeyNumpad, %Mod_FkeyNumpad%
return

Toggle_AltArrow:
    Mod_AltArrow := !Mod_AltArrow
    IniWrite, %Mod_AltArrow%, %IniFile%, Toggles, Mod_AltArrow
    GuiControl, Manager:, Mod_AltArrow, %Mod_AltArrow%
return

Toggle_SpacePan:
    Mod_SpacePan := !Mod_SpacePan
    IniWrite, %Mod_SpacePan%, %IniFile%, Toggles, Mod_SpacePan
    GuiControl, Manager:, Mod_SpacePan, %Mod_SpacePan%
return

Toggle_Curslock:
    Mod_CursLock := !Mod_CursLock
    IniWrite, %Mod_CursLock%, %IniFile%, Toggles, Mod_CursLock
    GuiControl, Manager:, Mod_CursLock, %Mod_CursLock%
    if (Mod_CursLock)
        GoSub, ShowPositionSelector
    Prev_CursLock := Mod_CursLock
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
    
    ; --- Reload Button Centered at the bottom ---
    Gui, Add, Button, w100 x60 y+15 gReloadScript, Reload
    
    Gui, Show,, Scripts Manager
return

SaveToggles:
    Gui, Manager:Submit, NoHide
    IniWrite, %Mod_AltArrow%, %IniFile%, Toggles, Mod_AltArrow
    IniWrite, %Mod_AOT%, %IniFile%, Toggles, Mod_AOT
    IniWrite, %Mod_SpacePan%, %IniFile%, Toggles, Mod_SpacePan
    IniWrite, %Mod_FkeyNumpad%, %IniFile%, Toggles, Mod_FkeyNumpad
    IniWrite, %Mod_CursLock%, %IniFile%, Toggles, Mod_CursLock
    
    ; If CursLock was just turned ON, show the buttons
    if (Mod_CursLock && Mod_CursLock != Prev_CursLock) {
        GoSub, ShowPositionSelector
    }
    Prev_CursLock := Mod_CursLock
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
            LastMouseX := prevX
            LastMouseY := prevY
        }
    }
    if (A_TimeIdlePhysical < 30) {
        if (PenActive && !IsOnMainScreen(cx, cy)) {
            MouseMove, %LastMouseX%, %LastMouseY%, 0
            PenActive := false
        }
        if (IsOnMainScreen(cx, cy)) {
            LastMouseX := cx
            LastMouseY := cy
            PenActive := false
        }
    }
    prevX := cx
    prevY := cy
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
    btnW := Floor(70 * GuiScale)
    btnH := Floor(40 * GuiScale)
    gap := Floor(5 * GuiScale)
    fontSize := Floor(11 * GuiScale)
    CustomColor := "00FF00"

    Gui, TabletSelector:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, Color, %CustomColor%
    WinSet, TransColor, %CustomColor%
    Gui, Font, s%fontSize% Bold cWhite, Segoe UI

    LeftY  := Floor((btnH / 2) + (gap * 1.5))
    TopX   := Floor(btnW + (gap * 2))
    DownY  := Floor(btnH + (gap * 2))
    RightX := Floor((btnW * 2) + (gap * 3))
    
    Gui, Add, Button, x%gap% y%LeftY% w%btnW% h%btnH% gSetLeft +Background000000, LEFT
    Gui, Add, Button, x%TopX% y%gap% w%btnW% h%btnH% gSetTop +Background000000, TOP
    Gui, Add, Button, x%TopX% y%DownY% w%btnW% h%btnH% gSetDown +Background000000, DOWN
    Gui, Add, Button, x%RightX% y%LeftY% w%btnW% h%btnH% gSetRight +Background000000, RIGHT

    winW := Floor((btnW * 3) + (gap * 4))
    winH := Floor((btnH * 2) + (gap * 3))
    GuiX := Floor((Monitor1_W / 2) - (winW / 2) + GuiX_Offset)
    GuiY := Floor((Monitor1_H / 2) - (winH / 2) + GuiY_Offset)

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
    IniWrite, "%Monitor2_Pos%", %IniFile%, Curslock_config, Monitor2_Pos
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
RemoveSplash:
    SplashTextOff
return

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
    if (Mode = "(F)KEY")
        Mode := "NUMPAD"
    else
        Mode := "(F)KEY"
    IniWrite, %Mode%, %IniFile%, Settings, FkeyNumpad_mode
    Gui, Overlay:Default
    GuiControl,, OverlayText, %Mode% MODE
return
#If

#If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="(F)KEY"
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

#If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="NUMPAD"
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