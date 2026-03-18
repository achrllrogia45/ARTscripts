; ==============================================================================
; UI MANAGER - AHK v2
; Handles all WebView2 GUI logic, Tooltips, and JS-to-AHK Callbacks.
; ==============================================================================

; THEME TOGGLE LISTENER (Handle Read and Write Theme)
OnToggle_Theme(val) {
  global IniFile
  modeString := (val == 1) ? "dark" : "light"
  IniWrite(modeString, IniFile, "Setting", "mode")
}

ShowScriptsManager(*) {
  global ManagerGui

  if IsSet(ManagerGui) && ManagerGui {
    try {
      ManagerGui.Show()
      return
    }
  }

  if (A_IsCompiled) {
    WebViewCtrl.CreateFileFromResource((A_PtrSize * 8) "bit\WebView2Loader.dll", WebViewCtrl.TempDir)
    WebViewSettings := { DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll" }
  } else {
    WebViewSettings := {}
  }

  ; Create Window (Removed buggy transparency keys, keeping it standard)
  ManagerGui := WebViewGui.Call("+AlwaysOnTop -Caption -Border +Resize +MinSize", "Scripts Manager", , WebViewSettings)

  if (VerCompare(A_OSVersion, "10.0.22000") >= 0) {
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", ManagerGui.Hwnd, "int", 34, "int*", 0xFFFFFFFE, "int", 4)
  }

  ; Map Events
  ManagerGui.OnEvent("Close", (*) => ManagerGui.Hide())
  ManagerGui.OnEvent("Size", ApplyWindowShape) ; <--- Hook window reshaping on resize

  ManagerGui.AddCallbackToScript("GetModules", WebGetModules)
  ManagerGui.AddCallbackToScript("GetToggles", WebGetToggles)
  ManagerGui.AddCallbackToScript("GetReadmes", WebGetReadmes)
  ManagerGui.AddCallbackToScript("ShowReadme", WebShowReadme)
  ManagerGui.AddCallbackToScript("HideReadme", WebHideReadme)
  ManagerGui.AddCallbackToScript("UpdateToggle", WebUpdateToggle)
  ManagerGui.AddCallbackToScript("UpdateModuleOrder", WebUpdateModuleOrder)
  ManagerGui.AddCallbackToScript("ReloadScript", WebReloadScript)
  ManagerGui.AddCallbackToScript("ShowSettings", WebShowSettings)

  ManagerGui.Navigate("Pages/index.html")

  ManagerGui.Show("w400 h600")
  ApplyWindowShape(ManagerGui) ; <--- Physically cut corners immediately after showing
}

WebShowSettings(WebView := "", *) {
  SetTimer(LaunchSettingsGui, -1)
}

LaunchSettingsGui() {
  global SettingsGui, ManagerGui, IniFile

  DynamicBase := A_ScreenWidth / 120

  if !FileExist(IniFile) || IniRead(IniFile, "SettingsGui", "OffsetX", "") = "" {
    IniWrite("20em", IniFile, "SettingsGui", "OffsetX")
    IniWrite("6.9em", IniFile, "SettingsGui", "OffsetY")
    IniWrite("360", IniFile, "SettingsGui", "Width")
    IniWrite("600", IniFile, "SettingsGui", "Height")
  }

  commentSection(IniFile, "SettingsGui",
    "; --- Positioning can be set in em (relative to screen width) or px (absolute). E.g. 20em or 300px. Default is 20em for X and 6.9em for Y (roughly center on 1080p)."
  )

  ParseUnit(val) {
    if IsNumber(val)
      return val
    unit := RegExReplace(val, "i)[0-9.\-]", "")
    numStr := RegExReplace(val, "i)[^0-9.\-]", "")
    if (numStr = "")
      return 0
    num := Float(numStr)
    if (unit = "em")
      return num * DynamicBase
    return num
  }

  OffsetX_Raw := IniRead(IniFile, "SettingsGui", "OffsetX", "20em")
  OffsetY_Raw := IniRead(IniFile, "SettingsGui", "OffsetY", "6.9em")
  GuiWidth_Raw := IniRead(IniFile, "SettingsGui", "Width", "360")
  GuiHeight_Raw := IniRead(IniFile, "SettingsGui", "Height", "600")

  OffsetX := Round(ParseUnit(OffsetX_Raw))
  OffsetY := Round(ParseUnit(OffsetY_Raw))
  GuiWidth := Round(ParseUnit(GuiWidth_Raw))
  GuiHeight := Round(ParseUnit(GuiHeight_Raw))

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

  if IsSet(SettingsGui) && SettingsGui {
    try {
      SettingsGui.Show(ShowOptions)
      return
    }
  }

  if (A_IsCompiled) {
    WebViewSettings := { DllPath: WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll" }
  } else {
    WebViewSettings := {}
  }

  SettingsGui := WebViewGui.Call("+AlwaysOnTop -Caption -Border +Resize +MinSize360x600", "Edit mode.ini", ,
    WebViewSettings)

  if (VerCompare(A_OSVersion, "10.0.22000") >= 0) {
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", SettingsGui.Hwnd, "int", 34, "int*", 0xFFFFFFFE, "int", 4)
  }

  SettingsGui.OnEvent("Close", (*) => SettingsGui.Hide())
  SettingsGui.OnEvent("Size", ApplyWindowShape) ; <--- Hook window reshaping on resize

  SettingsGui.AddCallbackToScript("GetIniContent", WebGetIniContent)
  SettingsGui.AddCallbackToScript("SaveIniContent", WebSaveIniContent)

  SettingsGui.Navigate("Pages/settings.html")

  SettingsGui.Show(ShowOptions)
  ApplyWindowShape(SettingsGui) ; <--- Physically cut corners immediately after showing
}

; ==============================================================================
; WINDOW SHAPER (Native OS Cut instead of bugged WebView Transparency)
; ==============================================================================
ApplyWindowShape(GuiObj, MinMax := 0, W := 0, H := 0) {
  if (MinMax == -1) ; Skip if window is minimized
    return

  ; If dimensions weren't passed by the Size event, grab them manually
  if (!W || !H)
    GuiObj.GetClientPos(, , &W, &H)

  ; Creates a 6-point polygon matching CSS clip-path exactly (15px cut top-left/bottom-right)
  RegionStr := "0-25 25-0 " W "-0 " W "-" (H - 25) " " (W - 25) "-" H " 0-" H " 0-25"

  try WinSetRegion(RegionStr, "ahk_id " GuiObj.Hwnd)
}

; ==============================================================================
; WEB-TO-AHK CALLBACKS
; ==============================================================================

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
  jsonStr := "["
  for i, moduleName in ActiveModules {
    filePath := A_ScriptDir "\Modules\" moduleName ".ahk"
    filePathForJson := StrReplace(filePath, "\", "\\")
    fileSize := "N/A"
    if FileExist(filePath) {
      sizeBytes := FileGetSize(filePath)
      fileSize := Round(sizeBytes / 1024, 1) . "kb"
    }

    jsonStr .= '{"name": "' moduleName '", "path": "' filePathForJson '", "size": "' fileSize '"}'
    if (i < ActiveModules.Length) {
      jsonStr .= ","
    }
  }
  jsonStr .= "]"
  return jsonStr
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

; ==============================================================================
; README POPUP WINDOW LOGIC
; ==============================================================================

; Accurately verify if the popup window is physically rendered on screen
IsReadmeVisible() {
  global ReadmeTooltipGui
  if IsSet(ReadmeTooltipGui) && ReadmeTooltipGui {
    return DllCall("IsWindowVisible", "Ptr", ReadmeTooltipGui.Hwnd)
  }
  return false
}

#HotIf IsReadmeVisible()
~LButton:: {
  global ReadmeTooltipGui
  try {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " ReadmeTooltipGui.Hwnd)

    ; If click is outside the physical bounds of the WebView popup window
    if (mX < winX || mX > (winX + winW) || mY < winY || mY > (winY + winH)) {
      WebHideReadme()
    }
  }
}
#HotIf

global PendingReadmeMod := ""
global ReadmeDispX := 0
global ReadmeDispY := 0

; Triggered by Javascript, MUST use SetTimer to prevent WebView2 thread deadlocking
WebShowReadme(WebView, mod) {
  global PendingReadmeMod, ReadmeDispX, ReadmeDispY
  PendingReadmeMod := mod

  CoordMode("Mouse", "Screen")
  MouseGetPos(&mX, &mY)

  ; Offset the popup slightly away from the mouse cursor
  ReadmeDispX := mX + 20
  ReadmeDispY := mY + 20

  ; Escapes the WebView callback thread
  SetTimer(LaunchReadmeGui, -1)
}

LaunchReadmeGui() {
  global PendingReadmeMod, ReadmeDispX, ReadmeDispY, ReadmeTooltipGui, ManagerGui
  mod := PendingReadmeMod

  if (!mod || !FileExist(filePath := A_ScriptDir "\Modules\" mod ".ahk"))
    return

  ; 1. AHK only extracts the Raw Text
  content := FileRead(filePath)
  if !RegExMatch(content, "(?si)/\*\s*\[readme\](.*?)\*/", &match)
    return

  ; Convert Markdown to HTML (AHK handles the logic, but not the 'look')
  try {
    htmlContent := ParseMarkdownToHTML(Trim(match[1], "`r`n "))
  } catch {
    htmlContent := "<pre>" Trim(match[1], "`r`n ") "</pre>"
  }

  ; 2. Load the Template file
  TemplatePath := A_ScriptDir "\Pages\readme_template.html"
  if !FileExist(TemplatePath) {
    MsgBox("Error: Missing Pages/readme_template.html")
    return
  }

  ; 3. Swap the placeholder for the content
  FullHtml := StrReplace(FileRead(TemplatePath), "AHK_CONTENT_PLACEHOLDER", htmlContent)

  ; 4. Create the temporary page file
  TempFile := A_Temp "\WebView_Readme_" mod ".html"
  FileOpen(TempFile, "w", "UTF-8").Write(FullHtml)

  ; Window Positioning logic
  dispX := ReadmeDispX, dispY := ReadmeDispY
  if (dispX + 400 > A_ScreenWidth)
    dispX := A_ScreenWidth - 420
  if (dispY + 350 > A_ScreenHeight)
    dispY := A_ScreenHeight - 370

  SafeUrl := "file:///" StrReplace(TempFile, "\", "/")

  if (!IsSet(ReadmeTooltipGui) || !ReadmeTooltipGui) {
    WebViewSettings := { Url: SafeUrl }
    if (A_IsCompiled)
      WebViewSettings.DllPath := WebViewCtrl.TempDir "\" (A_PtrSize * 8) "bit\WebView2Loader.dll"

    ownerStr := (IsSet(ManagerGui) && ManagerGui) ? " +Owner" ManagerGui.Hwnd : ""
    ReadmeTooltipGui := WebViewGui.Call("+AlwaysOnTop -Caption -Border +ToolWindow" ownerStr, mod " - Readme", ,
      WebViewSettings)
    ReadmeTooltipGui.OnEvent("Close", (*) => ReadmeTooltipGui.Hide())
    ReadmeTooltipGui.Show("NoActivate x" dispX " y" dispY " w400 h350")
  } else {
    try ReadmeTooltipGui.Title := mod " - Readme"
    ReadmeTooltipGui.Navigate(SafeUrl)
    ReadmeTooltipGui.Show("NoActivate x" dispX " y" dispY " w400 h350")
  }
}

WebHideReadme(WebView := unset) {
  global ReadmeTooltipGui
  if IsSet(ReadmeTooltipGui) && ReadmeTooltipGui {
    ; Use Hide instead of Destroy so the WebView2 instance persists for fast successive clicks
    try ReadmeTooltipGui.Hide()
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

WebUpdateModuleOrder(WebView, newOrderJson) {
  global IniFile, ActiveModules

  newOrder := StrSplit(Trim(newOrderJson, "[]"), ",", "")

  sortedToggles := ""
  for index, moduleName in newOrder {
    currentModuleName := Trim(moduleName, " `t`"")
    if (currentModuleName = "")
      continue
    currentToggle := IniRead(IniFile, "Toggles", currentModuleName, "0")
    sortedToggles .= currentModuleName "=" currentToggle "`n"
  }

  if (sortedToggles != "") {
    IniWrite(RTrim(sortedToggles, "`n"), IniFile, "Toggles")
  }

  newActiveModules := []
  for _, moduleName in newOrder {
    newActiveModules.Push(Trim(moduleName, " `t`""))
  }
  ActiveModules := newActiveModules
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