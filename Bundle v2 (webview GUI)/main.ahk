; ==============================================================================
; EXTERNAL MODULE INCLUDES
; ==============================================================================
#Include "Lib\WebViewToo.ahk"
#Include "Modules\AltArrow.ahk"
#Include "Modules\SpacePan.ahk"
#Include "Modules\AlwaysOnTop.ahk"
#Include "Modules\FkeysNumpad.ahk"
#Include "Modules\CursLock.ahk"
#Include "Modules\a.ahk"
#Include "Modules\b.ahk"
#Include "Modules\c.ahk"
#Include "Modules\d.ahk"

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
global TimerInterval := 5000
global MaxMouseJump := 300
global LastMouseX := 0
global LastMouseY := 0
global PenActive := false
global prevX := 0
global prevY := 0
global LastCapsState := -1

global IniFile := A_ScriptDir "\mode.ini"

global ActiveModules := []
if !A_IsCompiled {
    Loop Read, A_ScriptFullPath {
        if RegExMatch(A_LoopReadLine, "i)^\s*#Include\s+[`"']Modules[\\/](.*?)\.ahk[`"']", &match) {
            ActiveModules.Push(match[1])
        }
    }
}
global Toggles := Map()

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
    FkeysNumpad=null
    AltArrow=null
    SpacePan=null
    CursLock=null

    [AlwaysOnTop_config]
    AlwaysOnTop_mode=F8 ; F8 to toggle AlwaysOnTop mode

    ; Toggle GUI (0 = disabled, 1 = enabled)
    [Toggles]
    AltArrow=0
    AlwaysOnTop=0
    SpacePan=0
    FkeysNumpad=0
    CursLock=0

    [Settings]
    FkeyNumpad_mode=(F)KEY

    ; GUI Settings for Curslock setting based your first monitor resolution
    [Curslock_config]
    Monitor1_W=1920
    Monitor1_H=1080
    Monitor2_Pos="DOWN"
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
; KEEP INI CLEAN & SORTED
; ==============================================================================

ActiveModuleMap := Map()
for _, moduleName in ActiveModules
    ActiveModuleMap[moduleName] := true

; 1. Delete orphaned keys
for _, section in ["Toggles", "GUI Hotkeys"] {
    try {
        keyList := IniRead(IniFile, section)
    } catch {
        continue
    }
    Loop Parse keyList, "`n", "`r" {
        if (A_LoopField == "")
            continue
        keyName := StrSplit(A_LoopField, "=")[1]
        if !ActiveModuleMap.Has(keyName)
            IniDelete(IniFile, section, keyName)
    }
}

; 2. Enforce exact sorting based on `#Include` order
sortedToggles := ""
sortedHotkeys := ""

for _, moduleName in ActiveModules {
    ; Read existing or use defaults
    currentToggle := IniRead(IniFile, "Toggles", moduleName, "0")
    currentHotkey := IniRead(IniFile, "GUI Hotkeys", moduleName, "null")
    
    ; Delete the existing ones so we can rewrite them in perfect order
    IniDelete(IniFile, "Toggles", moduleName)
    IniDelete(IniFile, "GUI Hotkeys", moduleName)

    ; Build sorted blocks
    sortedToggles .= moduleName "=" currentToggle "`n"
    sortedHotkeys .= moduleName "=" currentHotkey "`n"
}

IniWrite(RTrim(sortedToggles, "`n"), IniFile, "Toggles")
IniWrite(RTrim(sortedHotkeys, "`n"), IniFile, "GUI Hotkeys")


; ==============================================================================
; INITIALIZATION & DYNAMIC HOTKEYS
; ==============================================================================

for i, moduleName in ActiveModules {
    ; Load toggles dynamically
    Toggles[moduleName] := Integer(IniRead(IniFile, "Toggles", moduleName, "0"))
    
    ; Load and register GUI Toggle Hotkeys
    hk := IniRead(IniFile, "GUI Hotkeys", moduleName, "null")
    if (hk != "null" && hk != "") {
        Hotkey(hk, ToggleModule.Bind(moduleName))
    }
}

ToggleModule(moduleName, HotkeyName := "") {
    Toggles[moduleName] := !Toggles[moduleName]
    IniWrite(Toggles[moduleName], IniFile, "Toggles", moduleName)
    UpdateWebViewToggleUI()
    
    ; Call module-specific listener if it exists
    fn := "OnToggle_" moduleName
    if IsSet(%fn%) && Type(%fn%) == "Func"
        %fn%(Toggles[moduleName])
}

; ==============================================================================
; TRAY MENU SETUP
; ==============================================================================
A_TrayMenu.Delete()
if IsSet(ShowPositionSelector)
    A_TrayMenu.Add("Show Button", (*) => ShowPositionSelector())
A_TrayMenu.Add("Show Scripts List", (*) => ShowScriptsManager())
A_TrayMenu.Add()
A_TrayMenu.Add("Open (ListLines)", (*) => ListLines())
A_TrayMenu.Add("Reload Scripts", (*) => Reload())
A_TrayMenu.Add("Edit Scripts", (*) => Run('notepad.exe "' A_ScriptFullPath '"'))
A_TrayMenu.Add("Locate Scripts", (*) => Run(A_ScriptDir))
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show Scripts List"

; ==============================================================================
; BOOT UP MODULES
; ==============================================================================

; Call initialization functions if they exist
for i, moduleName in ActiveModules {
    fn := "Init_" moduleName
    if IsSet(%fn%) && Type(%fn%) == "Func"
        %fn%()
}

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

    ManagerGui := WebViewGui.Call("+AlwaysOnTop -Caption -Resize", "Scripts Manager",, WebViewSettings)
    ManagerGui.OnEvent("Close", (*) => ManagerGui.Hide())
    
    ManagerGui.AddCallbackToScript("GetModules", WebGetModules)
    ManagerGui.AddCallbackToScript("GetToggles", WebGetToggles)
    ManagerGui.AddCallbackToScript("GetReadmes", WebGetReadmes)
    ManagerGui.AddCallbackToScript("ShowReadme", WebShowReadme)
    ManagerGui.AddCallbackToScript("UpdateToggle", WebUpdateToggle)
    ManagerGui.AddCallbackToScript("ReloadScript", WebReloadScript)

    ManagerGui.Navigate("Pages/index.html")
    ManagerGui.Show("w260 h380")
}

WebReloadScript(WebView) {
    Reload()
}

WebGetModules(WebView) {
    global ActiveModules
    arrStr := "["
    for i, moduleName in ActiveModules {
        arrStr .= '"' moduleName '"' (i < ActiveModules.Length ? "," : "")
    }
    arrStr .= "]"
    return arrStr
}

WebGetToggles(WebView) {
    global ActiveModules, Toggles
    jsonStr := "{"
    for i, moduleName in ActiveModules {
        jsonStr .= '"' moduleName '": ' Toggles[moduleName] (i < ActiveModules.Length ? "," : "")
    }
    jsonStr .= "}"
    return jsonStr
}

WebGetReadmes(WebView) {
    global ActiveModules
    jsonStr := "{"
    for i, moduleName in ActiveModules {
        filePath := A_ScriptDir "\Modules\" moduleName ".md"
        hasReadme := FileExist(filePath) ? 1 : 0
        jsonStr .= '"' moduleName '": ' hasReadme (i < ActiveModules.Length ? "," : "")
    }
    jsonStr .= "}"
    return jsonStr
}

WebShowReadme(WebView, mod) {
    filePath := A_ScriptDir "\Modules\" mod ".md"
    if !FileExist(filePath)
        return
        
    content := FileRead(filePath)
    
    ReadmeGui := Gui("+AlwaysOnTop +Resize -MaximizeBox", mod " - Readme")
    ReadmeGui.BackColor := "1e1e1e"
    ReadmeGui.SetFont("cWhite s10", "Consolas")
    Edt := ReadmeGui.Add("Edit", "x0 y0 w400 h300 ReadOnly Background1e1e1e", content)
    
    ReadmeGui.OnEvent("Size", (GuiObj, MinMax, Width, Height) => (
        MinMax != -1 ? Edt.Move(0, 0, Width, Height) : ""
    ))
    
    ReadmeGui.Show("w400 h300")
}

WebUpdateToggle(WebView, name, value) {
    global Toggles
    Toggles[name] := Integer(value)
    IniWrite(Toggles[name], IniFile, "Toggles", name)
    
    fn := "OnToggle_" name
    if IsSet(%fn%) && Type(%fn%) == "Func"
        %fn%(Toggles[name])
}

UpdateWebViewToggleUI() {
    global ManagerGui
    if IsSet(ManagerGui) && ManagerGui {
        ManagerGui.ExecuteScriptAsync("
        (
            if (typeof initCheckboxes === 'function') {
                initCheckboxes();
            }
        )")
    }
}


