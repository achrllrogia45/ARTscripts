; ==============================================================================
; UI MANAGER - AHK v2
; Handles all WebView2 GUI logic, Tooltips, and JS-to-AHK Callbacks.
; ==============================================================================

ShowScriptsManager(*) {
  global ManagerGui ; CRITICAL: Forces AHK to remember the window



  if IsSet(ManagerGui) && ManagerGui {
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
  global SettingsGui, ManagerGui, IniFile

  ; =========================================
  ; GUI SETTINGS POSITIONING VARIABLES
  ; =========================================
  ; --- Dynamic Scaling Math ---
  ; 1920 / 120 = 16px (Standard).
  ; On a 4K screen: 3840 / 120 = 32px.
  DynamicBase := A_ScreenWidth / 120
  

  ; Auto-populate the .ini file with default overrides so the user can see them
  if !FileExist(IniFile) || IniRead(IniFile, "SettingsGui", "OffsetX", "") = "" {
    IniWrite("20em", IniFile, "SettingsGui", "OffsetX")
    IniWrite("6.9em", IniFile, "SettingsGui", "OffsetY")
    IniWrite("360", IniFile, "SettingsGui", "Width")
    IniWrite("600", IniFile, "SettingsGui", "Height")
  }

  commentSection(IniFile, "SettingsGui",
    "; --- Positioningcan be set in em (relative to screen width) or px (absolute). E.g. 20em or 300px. Default is 20em for X and 6.9em for Y (roughly center on 1080p)."
  )

  ParseUnit(val) {
    if IsNumber(val)
      return val

    ; Safely escape the hyphen \- in RegEx to prevent range errors
    unit := RegExReplace(val, "i)[0-9.\-]", "")
    numStr := RegExReplace(val, "i)[^0-9.\-]", "")

    ; FIX: If the INI returned an empty string, prevent Float() from crashing
    if (numStr = "")
      return 0

    num := Float(numStr)

    if (unit = "em")
      return num * DynamicBase
    return num
  }

  ; Read directly from IniFile. If the file/key is missing, it defaults to the 4th parameter.
  OffsetX_Raw := IniRead(IniFile, "SettingsGui", "OffsetX", "20em")
  OffsetY_Raw := IniRead(IniFile, "SettingsGui", "OffsetY", "6.9em")
  GuiWidth_Raw := IniRead(IniFile, "SettingsGui", "Width", "360")
  GuiHeight_Raw := IniRead(IniFile, "SettingsGui", "Height", "600")

  ; Parse the units and Round() them to integers (GUI coordinates shouldn't be decimals)
  OffsetX := Round(ParseUnit(OffsetX_Raw))
  OffsetY := Round(ParseUnit(OffsetY_Raw))
  GuiWidth := Round(ParseUnit(GuiWidth_Raw))
  GuiHeight := Round(ParseUnit(GuiHeight_Raw))

  ; =========================================

  ; Default fallback
  ShowOptions := "xCenter yCenter w" GuiWidth " h" GuiHeight

  try {
    if WinExist("Scripts Manager") {
      WinGetPos(&mX, &mY, &mW, &mH, "Scripts Manager")

      mCenterX := mX + (mW // 2)
      mCenterY := mY + (mH // 2)

      newX := mCenterX - (GuiWidth // 2) + OffsetX
      newY := mCenterY - (GuiHeight // 2) + OffsetY

      ShowOptions := "x" newX " y" newY " w" GuiWidth " h" GuiHeight
    }
  }

  ; Duplicate prevention
  if IsSet(SettingsGui) && SettingsGui {
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
  global Toggles, IniFile
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