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

; ; 1. Define the "Block of Code" as a function
; UpdateIni(IniFile, Section, Comment) {
;   if !FileExist(IniFile)
;     return

;   FileContent := FileRead(IniFile)

;   ; Check if comment already exists to avoid duplicates
;   if !InStr(FileContent, Comment) {
;     ; Logic: Find [Section] and add the comment underneath it
;     Target := "[" Section "]"
;     NewContent := StrReplace(FileContent, Target, Target "`n" Comment)

;     FileObj := FileOpen(IniFile, "w")
;     FileObj.Write(NewContent)
;     FileObj.Close()
;   }
; }

; --- 1. THE TEMPLATE (Define this once) ---
commentSection(TargetFile, Section, CommentText) {
  if !FileExist(TargetFile)
    return

  FileContent := FileRead(TargetFile)
  CommentString := CommentText

  if !InStr(FileContent, CommentText) {
    Target := "[" Section "]"
    NewContent := StrReplace(FileContent, Target, Target "`n" CommentText)

    FileObj := FileOpen(TargetFile, "w")
    FileObj.Write(NewContent)
    FileObj.Close()
  }
}


; --- Global Variables ---
global IniFile := A_ScriptDir "\mode.ini"

global Toggles := Map()
global ActiveModules := []
global ManagerGui
  
if !A_IsCompiled {
  loop read, A_ScriptDir "\modules.ahk" {
    if RegExMatch(A_LoopReadLine, "i)^\s*#Include\s+[`"']Modules[\\/](.*?)\.ahk[`"']", &match) {
      ActiveModules.Push(match[1])
    }
  }
}

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
  loop parse keyList, "`n", "`r" {
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
  

  if IsSet(ManagerGui) && ManagerGui {
    ManagerGui.Show()
    return
  }

  if (A_IsCompiled) {
    WebViewCtrl.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll", WebViewCtrl.TempDir)
    WebViewSettings := { DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll" }
  } else {
    WebViewSettings := {}
  }

  ManagerGui := WebViewGui.Call("+AlwaysOnTop -Caption -Resize", "Scripts Manager", , WebViewSettings)
  ManagerGui.OnEvent("Close", (*) => ManagerGui.Hide())

  ManagerGui.AddCallbackToScript("GetModules", WebGetModules)
  ManagerGui.AddCallbackToScript("GetToggles", WebGetToggles)
  ManagerGui.AddCallbackToScript("GetReadmes", WebGetReadmes)
  ManagerGui.AddCallbackToScript("ShowReadme", WebShowReadme)
  ManagerGui.AddCallbackToScript("HideReadme", WebHideReadme)
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
    filePath := A_ScriptDir "\Modules\" moduleName ".ahk"
    hasReadme := 0
    if FileExist(filePath) {
      content := FileRead(filePath)
      if RegExMatch(content, "(?si)/\*\s*\[readme\](.*?)\*/")
        hasReadme := 1
    }
    jsonStr .= '"' moduleName '": ' hasReadme (i < ActiveModules.Length ? "," : "")
  }
  jsonStr .= "}"
  return jsonStr
}

global ReadmeTooltipGui := false

#HotIf ReadmeTooltipGui
~LButton:: {
  global ReadmeTooltipGui
  if ReadmeTooltipGui {
    MouseGetPos(,, &hoverWin)
    if (hoverWin != ReadmeTooltipGui.Hwnd) {
      WebHideReadme()
    }
  }
}
#HotIf

WebShowReadme(WebView, mod) {
  global ReadmeTooltipGui
  filePath := A_ScriptDir "\Modules\" mod ".ahk"
  if !FileExist(filePath)
    return

  content := FileRead(filePath)
  if !RegExMatch(content, "(?si)/\*\s*\[readme\](.*?)\*/", &match)
    return
  
  cleanText := Trim(match[1], "`r`n ")

  html := ParseMarkdownToHTML(cleanText)

  if ReadmeTooltipGui {
    ReadmeTooltipGui.Destroy()
    ReadmeTooltipGui := false
  }

  ReadmeTooltipGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", mod " - Readme")
  ReadmeTooltipGui.BackColor := "1e1e1e"
  ReadmeTooltipGui.MarginX := 0
  ReadmeTooltipGui.MarginY := 0
  
  ; Use ActiveX to render HTML/Markdown
  wb := ReadmeTooltipGui.Add("ActiveX", "w400 h300", "Shell.Explorer").Value
  wb.Navigate("about:blank")
  while wb.readyState != 4
    Sleep 10
  wb.document.write(html)
  wb.document.close()
  
  MouseGetPos(&mX, &mY)
  dispX := mX + 25
  dispY := mY + 25
  ReadmeTooltipGui.Show("NoActivate x" dispX " y" dispY " w400 h300")
}

WebHideReadme(WebView := unset) {
  global ReadmeTooltipGui
  if ReadmeTooltipGui {
    ReadmeTooltipGui.Destroy()
    ReadmeTooltipGui := false
  }
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
        )"
    )
  }
}


