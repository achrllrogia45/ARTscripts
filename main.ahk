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

; --- Global Variables ---
global IniFile := A_ScriptDir "\mode.ini"

global SettingsGui := false
global Toggles := Map()
global ActiveModules := []
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
; GLOBAL FUNCTIONS
; =============================================================================

; Comment component v1
/* commentSection(TargetFile, Section, CommentText) {
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
  */

; Comment component v2. (Keep the comment always under Section)
commentSection(TargetFile, Section, CommentText) {
  if !FileExist(TargetFile)
    return

  FileContent := FileRead(TargetFile)
  Target := "[" Section "]"

  ; If the section doesn't exist at all,  can't add a comment to it
  if !InStr(FileContent, Target)
    return

  ; Check if the comment is already perfectly placed directly under the [Section]
  ; (check for both `r`n and `n` to ensure it works on all Windows line endings)
  if InStr(FileContent, Target "`r`n" CommentText) || InStr(FileContent, Target "`n" CommentText)
    return

  ; If the code reaches here, it means the comment is missing OR it drifted to the bottom.
  ; First, wipe the comment out from wherever it is to prevent duplicates:
  FileContent := StrReplace(FileContent, "`r`n" CommentText, "")
  FileContent := StrReplace(FileContent, "`n" CommentText, "")
  FileContent := StrReplace(FileContent, CommentText, "")

  ; Finally, forcefully inject it exactly one line below our target [Section]
  NewContent := StrReplace(FileContent, Target, Target "`n" CommentText)

  ; Save the file (Using UTF-8 so special characters don't break)
  FileObj := FileOpen(TargetFile, "w", "UTF-8")
  FileObj.Write(NewContent)
  FileObj.Close()
}

; Reload component
reloadScript() {
  Run("launcher.ahk")
  ExitApp()
}
; =============================================================================

if !A_IsCompiled {
  loop read, A_ScriptDir "\modules.ahk" {
    if RegExMatch(A_LoopReadLine, "i)^\s*#Include\s+[`"']Modules[\\/](.*?)\.ahk[`"']", &match) {
      ActiveModules.Push(match[1])
    }
  }
}

; ==============================================================================
; KEEP INI CLEAN & SORTED
; ==============================================================================

sortedToggles := ""
sortedHotkeys := ""

for _, moduleName in ActiveModules {
  ; Read existing or use defaults
  currentToggle := IniRead(IniFile, "Toggles", moduleName, "0")
  currentHotkey := IniRead(IniFile, "GUI Hotkeys", moduleName, "null")

  ; Build sorted blocks
  sortedToggles .= moduleName "=" currentToggle "`n"
  sortedHotkeys .= moduleName "=" currentHotkey "`n"
}

; deletes orphans, AND prevents the section from jumping to the bottom
IniWrite(RTrim(sortedToggles, "`n"), IniFile, "Toggles")
IniWrite(RTrim(sortedHotkeys, "`n"), IniFile, "GUI Hotkeys")

commentSection(IniFile, "GUI Hotkeys", "; Setting Hotkey for On/Off GUI Check ")

FileContent := FileExist(IniFile) ? FileRead(IniFile) : ""
if !InStr(FileContent, "; Hotkeys is From AutoHotkey v2") {
  DefaultINI := "; Hotkeys is From AutoHotkey v2 (Check Help inside AutoHotkey for more info)`n"
    . "; # = WIN`n"
    . "; ! = ALT`n"
    . "; ^ = CTRL`n"
    . "; + = SHIFT`n"

  ; Manually overwrite the file to prepend the header
  FileObj := FileOpen(IniFile, "w", "UTF-8")
  FileObj.Write(DefaultINI . FileContent)
  FileObj.Close()
}

; ==============================================================================
; INITIALIZATION & DYNAMIC HOTKEYS
; ==============================================================================

for i, moduleName in ActiveModules {
  Toggles[moduleName] := Integer(IniRead(IniFile, "Toggles", moduleName, "0"))

  hk := IniRead(IniFile, "GUI Hotkeys", moduleName, "null")
  commentSection(IniFile, "GUI Hotkeys", "; Setting Hotkey for On/Off GUI Check ")
  

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
; MANAGER GUI & TOGGLE LOGIC
; ==============================================================================
ShowScriptsManager(*) {
  global ManagerGui ; CRITICAL: Forces AHK to remember the window

  if IsSet(ManagerGui) {
    try {
      ManagerGui.Show() 
      return ;
    }
  }

  ; --- CREATION CODE (Only runs the very first time) ---

  if (A_IsCompiled) {
    WebViewCtrl.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll", WebViewCtrl.TempDir)
    WebViewSettings := { DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll" }
  } else {
    WebViewSettings := {}
  }

  ManagerGui := WebViewGui.Call("+AlwaysOnTop -Caption +Resize", "Scripts Manager", , WebViewSettings)

  ; This keeps the object alive in the background when the user closes it
  ManagerGui.OnEvent("Close", (*) => ManagerGui.Hide())

  ManagerGui.AddCallbackToScript("GetModules", WebGetModules)
  ManagerGui.AddCallbackToScript("GetToggles", WebGetToggles)
  ManagerGui.AddCallbackToScript("GetReadmes", WebGetReadmes)
  ManagerGui.AddCallbackToScript("ShowReadme", WebShowReadme)
  ManagerGui.AddCallbackToScript("HideReadme", WebHideReadme)
  ManagerGui.AddCallbackToScript("UpdateToggle", WebUpdateToggle)
  ManagerGui.AddCallbackToScript("ReloadScript", WebReloadScript)
  ManagerGui.AddCallbackToScript("ShowSettings", WebShowSettings)

  ManagerGui.Navigate("Pages/index.html")
  ManagerGui.Show("w260 h380")
}


WebShowSettings(WebView := "", *) {
  SetTimer(LaunchSettingsGui, -1)
}

LaunchSettingsGui() {
  global SettingsGui, ManagerGui

  ; =========================================
  ; GUI SETTINGS POSITIONING VARIABLES
  ; =========================================
  OffsetX := "20em" ; em / px hybrid offset system.
  OffsetY := "6.9em"
  GuiWidth := 360
  GuiHeight := 600

  ; --- Dynamic Scaling Math ---
  ; 1920 / 120 = 16px (Standard).
  ; On a 4K screen: 3840 / 120 = 32px.
  DynamicBase := A_ScreenWidth / 120

  ParseUnit(val) {
    if IsNumber(val)
      return val

    unit := RegExReplace(val, "i)[0-9.-]", "")
    num := Float(RegExReplace(val, "i)[^0-9.-]", ""))

    if (unit = "em")
      return num * DynamicBase
    return num
  }
  ; =========================================

  FinalOffsetX := ParseUnit(OffsetX)
  FinalOffsetY := ParseUnit(OffsetY)

  ; Default fallback
  ShowOptions := "xCenter yCenter w" GuiWidth " h" GuiHeight

  try {
    if WinExist("Scripts Manager") {
      WinGetPos(&mX, &mY, &mW, &mH, "Scripts Manager")

      mCenterX := mX + (mW // 2)
      mCenterY := mY + (mH // 2)

      newX := mCenterX - (GuiWidth // 2) + FinalOffsetX
      newY := mCenterY - (GuiHeight // 2) + FinalOffsetY

      ShowOptions := "x" newX " y" newY " w" GuiWidth " h" GuiHeight
    }
  }

  ; Duplicate prevention (same as before)
  if IsSet(SettingsGui) {
    try {
      SettingsGui.Show(ShowOptions)
      return
    }
  }

  ; Creation logic
  if (A_IsCompiled) {
    WebViewSettings := { DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll" }
  } else {
    WebViewSettings := {}
  }

  SettingsGui := WebViewGui.Call("+AlwaysOnTop -Caption +Resize", "Edit mode.ini", , WebViewSettings)
  SettingsGui.OnEvent("Close", (*) => SettingsGui.Hide())
  SettingsGui.AddCallbackToScript("GetIniContent", WebGetIniContent)
  SettingsGui.AddCallbackToScript("SaveIniContent", WebSaveIniContent)
  SettingsGui.Navigate("Pages/settings.html")
  SettingsGui.Show(ShowOptions)
}

WebGetIniContent(WebView) {
  global IniFile
  if FileExist(IniFile)
    return FileRead(IniFile)
  return ""
}

WebSaveIniContent(WebView, content) {
  global IniFile
  try {
    f := FileOpen(IniFile, "w", "UTF-8")
    f.Write(content)
    f.Close()
  }
}

WebReloadScript(WebView) {
  Run("launcher.ahk")
  ExitApp()
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


#HotIf IsSet(ReadmeTooltipGui) && ReadmeTooltipGui
~LButton:: {
  global ReadmeTooltipGui
  try {
    MouseGetPos(, , &hoverWin)
    ; If we clicked outside the tooltip, hide it
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

  ; SAFELY DESTROY OLD GUI TO PREVENT MEMORY LEAKS
  if IsSet(ReadmeTooltipGui) && ReadmeTooltipGui {
    try ReadmeTooltipGui.Destroy()
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

  ; SAFELY CHECK IF IT EXISTS BEFORE DESTROYING
  if IsSet(ReadmeTooltipGui) && ReadmeTooltipGui {
    try ReadmeTooltipGui.Destroy()
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