; ==============================================================================
; MAIN.AHK (CORE CONTROLLER) - AHK v2
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode("Mouse", "Screen")
SetWorkingDir(A_ScriptDir)

; --- SHIELDS: Prevent CapsLock flickering and ghost media keys ---
SetStoreCapsLockMode(false)
A_MenuMaskKey := "vkE8"

; --- Auto-elevate to Admin ---
if not A_IsAdmin {
    try {
        Run('*RunAs "' A_ScriptFullPath '"')
    }
    ExitApp()
}

; --- Global Variables ---
global Monitor1_W, Monitor1_H, Monitor2_Pos, GuiScale, GuiX_Offset, GuiY_Offset
global FkeyX, FkeyY
global TimerInterval := 5000
global MaxMouseJump := 300
global LastMouseX, LastMouseY
global PenActive := false
global prevX := 0
global prevY := 0
global LastCapsState := -1
global Prev_CursLock
global Mode

global IniFile := A_ScriptDir "\mode.ini"

; ==============================================================================
; INI GENERATOR
; ==============================================================================
if !FileExist(IniFile) {
    DefaultINI := "
    (
    ; Hotkeys is From AutoHotkey v2 (Check Help inside AutoHotkey for more info)
    ; # = WIN
    ; ! = ALT
    ; ^ = CTRL
    ; + = SHIFT
    ; null = No hotkey assigned

    ; On Off Hotkeys for GUI (0 = disabled, 1 = enabled)
    [GUI Hotkeys]
    AlwaysOnTop=null
    FkeyNumpad=null
    Altarrow=null
    SpacePan=null
    Curslock=null

    [AlwaysOnTop_config]
    AlwaysOnTop_mode=F8 ; F8 to toggle AlwaysOnTop mode

    ; Toggle GUI (0 = disabled, 1 = enabled)
    [Toggles]
    Mod_AltArrow=0
    Mod_AOT=0
    Mod_SpacePan=0
    Mod_FkeyNumpad=0
    Mod_CursLock=0

    [Settings]
    FkeyNumpad_mode=(F)KEY

    ; GUI Settings for Curslock setting based your first monitor resolution
    [Curslock_config]
    Monitor1_W=1920
    Monitor1_H=1080
    Monitor2_Pos=""DOWN""
    GuiScale=1
    GuiX_Offset=0
    GuiY_Offset=0

    [FkeyNumpad_config]
    X=null
    Y=50
    )"
    
    FileAppend(DefaultINI, IniFile)
}

; ==============================================================================
; INITIALIZATION & SETTINGS
; ==============================================================================

; Load GUI Toggle Hotkeys
global HK_GUI_AOT := IniRead(IniFile, "GUI Hotkeys", "AlwaysOnTop", "null")
global HK_GUI_FkeyNumpad := IniRead(IniFile, "GUI Hotkeys", "FkeyNumpad", "null")
global HK_GUI_AltArrow := IniRead(IniFile, "GUI Hotkeys", "Altarrow", "null")
global HK_GUI_SpacePan := IniRead(IniFile, "GUI Hotkeys", "SpacePan", "null")
global HK_GUI_Curslock := IniRead(IniFile, "GUI Hotkeys", "Curslock", "null")

; Load Action Hotkeys
global HK_AOT_Action := IniRead(IniFile, "AlwaysOnTop_config", "AlwaysOnTop_mode", "F8")

; Load Toggles
global Mod_AltArrow := IniRead(IniFile, "Toggles", "Mod_AltArrow", 0)
global Mod_AOT := IniRead(IniFile, "Toggles", "Mod_AOT", 0)
global Mod_SpacePan := IniRead(IniFile, "Toggles", "Mod_SpacePan", 0)
global Mod_FkeyNumpad := IniRead(IniFile, "Toggles", "Mod_FkeyNumpad", 0)
global Mod_CursLock := IniRead(IniFile, "Toggles", "Mod_CursLock", 0)
Prev_CursLock := Mod_CursLock

; Load Settings
Mode := IniRead(IniFile, "Settings", "FkeyNumpad_mode", "(F)KEY")

; Load FkeyNumpad Configuration
FkeyX := IniRead(IniFile, "FkeyNumpad_config", "X", "null")
FkeyY := IniRead(IniFile, "FkeyNumpad_config", "Y", "10")

; Load CursLock Configuration
Monitor1_W := Integer(IniRead(IniFile, "Curslock_config", "Monitor1_W", "1920"))
Monitor1_H := Integer(IniRead(IniFile, "Curslock_config", "Monitor1_H", "1080"))
Monitor2_Pos := IniRead(IniFile, "Curslock_config", "Monitor2_Pos", '"DOWN"')
GuiScale := Float(IniRead(IniFile, "Curslock_config", "GuiScale", "1"))
GuiX_Offset := Integer(IniRead(IniFile, "Curslock_config", "GuiX_Offset", "0"))
GuiY_Offset := Integer(IniRead(IniFile, "Curslock_config", "GuiY_Offset", "0"))

Monitor2_Pos := Trim(StrReplace(Monitor2_Pos, '"', ""), " `t") 
LastMouseX := Monitor1_W // 2
LastMouseY := Monitor1_H // 2

; ==============================================================================
; DYNAMIC HOTKEY REGISTRATION
; ==============================================================================
if (HK_GUI_AOT != "null" && HK_GUI_AOT != "")
    Hotkey(HK_GUI_AOT, Toggle_AOT)
if (HK_GUI_FkeyNumpad != "null" && HK_GUI_FkeyNumpad != "")
    Hotkey(HK_GUI_FkeyNumpad, Toggle_FkeyNumpad)
if (HK_GUI_AltArrow != "null" && HK_GUI_AltArrow != "")
    Hotkey(HK_GUI_AltArrow, Toggle_AltArrow)
if (HK_GUI_SpacePan != "null" && HK_GUI_SpacePan != "")
    Hotkey(HK_GUI_SpacePan, Toggle_SpacePan)
if (HK_GUI_Curslock != "null" && HK_GUI_Curslock != "")
    Hotkey(HK_GUI_Curslock, Toggle_Curslock)

if (HK_AOT_Action != "null" && HK_AOT_Action != "")
    Hotkey(HK_AOT_Action, Action_AOT)

; ==============================================================================
; TRAY MENU SETUP
; ==============================================================================
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Button", (*) => ShowPositionSelector())
A_TrayMenu.Add("Show Scripts List", (*) => ShowScriptsManager())
A_TrayMenu.Add()
A_TrayMenu.Add("Open (ListLines)", (*) => ListLines())
A_TrayMenu.Add("Reload Scripts", (*) => Reload())
A_TrayMenu.Add("Edit Scripts", (*) => Run("notepad.exe `"" A_ScriptFullPath "`""))
A_TrayMenu.Add("Locate Scripts", (*) => Run(A_ScriptDir))
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show Scripts List"

; ==============================================================================
; BOOT UP MODULES
; ==============================================================================
Init_SpacePan()
Init_FkeysNumpad()
Init_CursLock()
ShowScriptsManager()

; ==============================================================================
; MANAGER GUI & TOGGLE LOGIC
; ==============================================================================
ShowScriptsManager(*) {
    global ManagerGui
    
    if IsSet(ManagerGui) && ManagerGui {
        ManagerGui.Show()
        return
    }

    if (A_IsCompiled) {
        WebViewCtrl.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll", WebViewCtrl.TempDir)
        WebViewSettings := {DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll"}
    } else {
        WebViewSettings := {}
    }

    ManagerGui := WebViewGui("+AlwaysOnTop -Caption -Resize", "Scripts Manager",, WebViewSettings)
    ManagerGui.OnEvent("Close", (*) => ManagerGui.Hide())
    
    ManagerGui.AddCallbackToScript("GetToggles", WebGetToggles)
    ManagerGui.AddCallbackToScript("UpdateToggle", WebUpdateToggle)
    ManagerGui.AddCallbackToScript("ReloadScript", WebReloadScript)

    ManagerGui.Navigate("Pages/index.html")
    ManagerGui.Show("w260 h380")
}

WebReloadScript(WebView) {
    Reload()
}

WebGetToggles(WebView) {
    global Mod_AltArrow, Mod_AOT, Mod_SpacePan, Mod_FkeyNumpad, Mod_CursLock
    return '{"Mod_AltArrow": ' Mod_AltArrow ', "Mod_AOT": ' Mod_AOT ', "Mod_SpacePan": ' Mod_SpacePan ', "Mod_FkeyNumpad": ' Mod_FkeyNumpad ', "Mod_CursLock": ' Mod_CursLock '}'
}

WebUpdateToggle(WebView, name, value) {
    global Mod_AltArrow, Mod_AOT, Mod_SpacePan, Mod_FkeyNumpad, Mod_CursLock, Prev_CursLock
    
    if (name == "altArrow")
        Mod_AltArrow := value, IniWrite(Mod_AltArrow, IniFile, "Toggles", "Mod_AltArrow")
    else if (name == "alwaysOnTop")
        Mod_AOT := value, IniWrite(Mod_AOT, IniFile, "Toggles", "Mod_AOT")
    else if (name == "spacePan")
        Mod_SpacePan := value, IniWrite(Mod_SpacePan, IniFile, "Toggles", "Mod_SpacePan")
    else if (name == "fkeys")
        Mod_FkeyNumpad := value, IniWrite(Mod_FkeyNumpad, IniFile, "Toggles", "Mod_FkeyNumpad")
    else if (name == "cursLock") {
        Mod_CursLock := value, IniWrite(Mod_CursLock, IniFile, "Toggles", "Mod_CursLock")
        if (Mod_CursLock && Mod_CursLock != Prev_CursLock)
            ShowPositionSelector()
        Prev_CursLock := Mod_CursLock
    }
}

UpdateWebViewToggleUI() {
    global ManagerGui, Mod_AltArrow, Mod_AOT, Mod_SpacePan, Mod_FkeyNumpad, Mod_CursLock
    if IsSet(ManagerGui) && ManagerGui {
        ManagerGui.ExecuteScriptAsync("
        (
            if (typeof initCheckboxes === 'function') {
                initCheckboxes();
            }
        )")
    }
}

Toggle_AOT(HotkeyName := "") {
    global Mod_AOT := !Mod_AOT
    IniWrite(Mod_AOT, IniFile, "Toggles", "Mod_AOT")
    UpdateWebViewToggleUI()
}
Toggle_FkeyNumpad(HotkeyName := "") {
    global Mod_FkeyNumpad := !Mod_FkeyNumpad
    IniWrite(Mod_FkeyNumpad, IniFile, "Toggles", "Mod_FkeyNumpad")
    UpdateWebViewToggleUI()
}
Toggle_AltArrow(HotkeyName := "") {
    global Mod_AltArrow := !Mod_AltArrow
    IniWrite(Mod_AltArrow, IniFile, "Toggles", "Mod_AltArrow")
    UpdateWebViewToggleUI()
}
Toggle_SpacePan(HotkeyName := "") {
    global Mod_SpacePan := !Mod_SpacePan
    IniWrite(Mod_SpacePan, IniFile, "Toggles", "Mod_SpacePan")
    UpdateWebViewToggleUI()
}
Toggle_Curslock(HotkeyName := "") {
    global Mod_CursLock := !Mod_CursLock
    global Prev_CursLock
    IniWrite(Mod_CursLock, IniFile, "Toggles", "Mod_CursLock")
    UpdateWebViewToggleUI()
    if (Mod_CursLock)
        ShowPositionSelector()
    Prev_CursLock := Mod_CursLock
}

; ==============================================================================
; EXTERNAL MODULE INCLUDES
; ==============================================================================
#Include "Lib\WebViewToo.ahk"
#Include "AltArrow.ahk"
#Include "AlwaysOnTop.ahk"
#Include "SpacePan.ahk"
#Include "FkeysNumpad.ahk"
#Include "CursLock.ahk"