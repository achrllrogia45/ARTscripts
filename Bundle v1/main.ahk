; ==============================================================================
; MAIN.AHK (CORE CONTROLLER)
; Run this file! It will automatically load the other modules.
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
; INI GENERATOR
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

    `; F8 to toggle AlwaysOnTop mode
    [AlwaysOnTop_config]
    AlwaysOnTop_mode=F8 

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

; Load GUI Toggle Hotkeys
IniRead, HK_GUI_AOT, %IniFile%, GUI Hotkeys, AlwaysOnTop, null
IniRead, HK_GUI_FkeyNumpad, %IniFile%, GUI Hotkeys, FkeyNumpad, null
IniRead, HK_GUI_AltArrow, %IniFile%, GUI Hotkeys, Altarrow, null
IniRead, HK_GUI_SpacePan, %IniFile%, GUI Hotkeys, SpacePan, null
IniRead, HK_GUI_Curslock, %IniFile%, GUI Hotkeys, Curslock, null

; Load Action Hotkeys
IniRead, HK_AOT_Action, %IniFile%, AlwaysOnTop_config, AlwaysOnTop_mode, F8

; Load Toggles
IniRead, Mod_AltArrow, %IniFile%, Toggles, Mod_AltArrow, 0
IniRead, Mod_AOT, %IniFile%, Toggles, Mod_AOT, 0
IniRead, Mod_SpacePan, %IniFile%, Toggles, Mod_SpacePan, 0
IniRead, Mod_FkeyNumpad, %IniFile%, Toggles, Mod_FkeyNumpad, 0
IniRead, Mod_CursLock, %IniFile%, Toggles, Mod_CursLock, 0
Prev_CursLock := Mod_CursLock

; Load Settings
IniRead, Mode, %IniFile%, Settings, FkeyNumpad_mode, (F)KEY

; Load CursLock Configuration
IniRead, Monitor1_W, %IniFile%, Curslock_config, Monitor1_W, 1920
IniRead, Monitor1_H, %IniFile%, Curslock_config, Monitor1_H, 1080
IniRead, Monitor2_Pos, %IniFile%, Curslock_config, Monitor2_Pos, DOWN
IniRead, GuiScale, %IniFile%, Curslock_config, GuiScale, 1
IniRead, GuiX_Offset, %IniFile%, Curslock_config, GuiX_Offset, 0
IniRead, GuiY_Offset, %IniFile%, Curslock_config, GuiY_Offset, 0

Monitor2_Pos := Trim(StrReplace(Monitor2_Pos, """", ""), " `t") 
Monitor1_W := Floor(Monitor1_W + 0)
Monitor1_H := Floor(Monitor1_H + 0)
GuiScale := GuiScale + 0.0
LastMouseX := Monitor1_W / 2
LastMouseY := Monitor1_H / 2

; ==============================================================================
; DYNAMIC HOTKEY REGISTRATION
; ==============================================================================
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
; BOOT UP MODULES
; ==============================================================================
GoSub, Init_SpacePan
GoSub, Init_FkeysNumpad
GoSub, Init_CursLock
GoSub, ShowScriptsManager

; *** END OF AUTO-EXECUTE SECTION ***
return

; ==============================================================================
; MANAGER GUI & TOGGLE LOGIC
; ==============================================================================
ShowScriptsManager:
    Gui, Manager:New, +SysMenu +AlwaysOnTop, Scripts Manager
    Gui, Add, Text, w200, Check the modules you want to enable:
    Gui, Add, CheckBox, vMod_AltArrow gSaveToggles Checked%Mod_AltArrow%, AltArrow
    Gui, Add, CheckBox, vMod_AOT gSaveToggles Checked%Mod_AOT%, AlwaysOnTop
    Gui, Add, CheckBox, vMod_SpacePan gSaveToggles Checked%Mod_SpacePan%, SpacePan
    Gui, Add, CheckBox, vMod_FkeyNumpad gSaveToggles Checked%Mod_FkeyNumpad%, Fkeys+Numpad
    Gui, Add, CheckBox, vMod_CursLock gSaveToggles Checked%Mod_CursLock%, CursLock
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
    
    if (Mod_CursLock && Mod_CursLock != Prev_CursLock)
        GoSub, ShowPositionSelector
    Prev_CursLock := Mod_CursLock
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
; EXTERNAL MODULE INCLUDES
; ==============================================================================
#Include AltArrow.ahk
#Include AlwaysOnTop.ahk
#Include SpacePan.ahk
#Include FkeysNumpad.ahk
#Include CursLock.ahk