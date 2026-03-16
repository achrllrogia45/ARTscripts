; ==============================================================================
/*
  Import modules from here. for cleaner code and easier maintenance.
  The order of these includes determines the order of the modules in the GUI,
  so arrange them as desired. Each module should have a corresponding section
  in the INI file for toggles and hotkeys, which will be automatically managed
  by the main script.
*/
; ==============================================================================
#Include "modules.ahk"

; ==============================================================================
; MAIN.AHK (CORE CONTROLLER) - AHK v2
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

Persistent() ; <--- CRITICAL: Prevents script from closing immediately upon loading

; --- Global Variables ---
global IniFile := A_ScriptDir "\mode.ini"

global SettingsGui := false
global Toggles := Map()
global ActiveModules :=[]
global ManagerGui
global ReadmeTooltipGui := false
  
CoordMode("Mouse", "Screen")
SetWorkingDir(A_ScriptDir)

; Check if the script was run without arguments OR with the wrong argument
if (A_Args.Length = 0 || A_Args[1] != "from_launcher") {
  MsgBox("Run launcher.exe!", "Notice")
  ExitApp()
}

; Prevent CapsLock flickering and ghost media keys 
SetStoreCapsLockMode(false)
A_MenuMaskKey := "vkE8"

; Auto-elevate to Admin 
if not A_IsAdmin {
  try {
    Run('*RunAs "' A_ScriptFullPath '"' "from_launcher")
  }
  ExitApp()
}

; ==============================================================================
; INITIALIZATION & DYNAMIC HOTKEYS
; ==============================================================================

; Sync INI and load ActiveModules (Function from ConfigManager.ahk)
SyncConfig()



for i, moduleName in ActiveModules {
  Toggles[moduleName] := Integer(IniRead(IniFile, "Toggles", moduleName, "0"))

  hk := IniRead(IniFile, "GUI Hotkeys", moduleName, "null")
  commentSection(IniFile, "GUI Hotkeys", "; Setting Hotkey for On/Off GUI Check ")
  
  if (hk != "null" && hk != "") {
    Hotkey(hk, ToggleModule.Bind(moduleName))
  }
}

ToggleModule(moduleName, HotkeyName := "") {
  global Toggles, IniFile
  Toggles[moduleName] := !Toggles[moduleName]
  IniWrite(Toggles[moduleName], IniFile, "Toggles", moduleName)
  UpdateWebViewToggleUI()

  ; Call module-specific listener if it exists
  fn := "OnToggle_" moduleName
  if IsSet(%fn%) && Type(%fn%) == "Func"
    %fn%(Toggles[moduleName])
}

; Reload component
reloadScript() {
  Run("launcher.ahk")
  ExitApp()
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
A_TrayMenu.Add("Reload Scripts", (*) => reloadScript())
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
; INCLUDE LIBRARIES DON'T TOUCH BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
; ==============================================================================
#Include "lib\UIManager.ahk"
#Include "lib\ConfigManager.ahk"
#Include "Lib\WebViewToo.ahk"
#Include "Lib\markdown.ahk"