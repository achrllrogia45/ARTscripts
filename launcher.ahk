#Requires AutoHotkey v2.0
#SingleInstance Force

UpdateAndLaunch()

UpdateAndLaunch() {
  ModulesFile := A_ScriptDir "\modules.ahk"
  ModulesDir := A_ScriptDir "\Modules"

  ; Mandatory Lib includes
  NewContent := "#Requires AutoHotkey v2.0`n`n"
  ; NewContent .= "; ==============================================================================`n"
  ; NewContent .= '#Include "Lib\WebViewToo.ahk"`n'
  ; NewContent .= '#Include "Lib\markdown.ahk"`n'
  ; NewContent .= '#Include "lib\ConfigManager.ahk"`n'
  ; NewContent .= '#Include "lib\UIManager.ahk"`n'
  ; NewContent .= "; ==============================================================================`n`n"

  ; Scan current modules 
  if DirExist(ModulesDir) {
    loop files, ModulesDir "\*.ahk" {
      NewContent .= '#Include "Modules/' A_LoopFileName '"`n'
    }
  }

  ; Write the clean list to modules.ahk
  FileObj := FileOpen(ModulesFile, "w")
  FileObj.Write(NewContent)
  FileObj.Close()

  #Requires AutoHotkey v2.0

; Run main.ahk and pass "from_launcher" as an argument
; (The extra quote marks ensure it works even if your folder path has spaces)
Run('"' A_ScriptDir '\main.ahk" "from_launcher"')


  ; Launch main.ahk and instantly exit this launcher
  ExitApp()
}