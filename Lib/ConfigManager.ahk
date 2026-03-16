; ==============================================================================
; CONFIG MANAGER
; Handles all INI file reading, writing, sorting logic, and data models.
; ==============================================================================

; ==============================================================================
; GLOBAL FUNCTIONS
; ==============================================================================

; ===== Comment component v2. (Keep the comment always under Section) ===== 
/* 
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
  */

; ===== Comment component v2. (Keep the comment always under Section) ===== 
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
; ==============================================================================


; ==============================================================================
; POPULATE ACTIVE MODULES & KEEP INI CLEAN
; ==============================================================================
SyncConfig() {
  global ActiveModules, IniFile

  AvailableModules := []
  AvailableMap := Map()
  AvailableMap.CaseSense := false

  if !A_IsCompiled {
    loop read, A_ScriptDir "\modules.ahk" {
      if RegExMatch(A_LoopReadLine, "i)^\s*#Include\s+[`"']Modules[\\/](.*?)\.ahk[`"']", &match) {
        AvailableModules.Push(match[1])
        AvailableMap[match[1]] := true
      }
    }
  }

  AddedToActive := Map()
  AddedToActive.CaseSense := false

  ; 1. Read existing modules from mode.ini to preserve their specific order
  IniTogglesStr := ""
  try IniTogglesStr := IniRead(IniFile, "Toggles")

  if (IniTogglesStr != "") {
    loop parse, IniTogglesStr, "`n", "`r" {
      if (A_LoopField = "")
        continue
      parts := StrSplit(A_LoopField, "=", " `t", 2)
      modName := Trim(parts[1])
      if (modName = "")
        continue

      ; Keep it if compiled (we don't know better) or if it still exists in modules.ahk
      if (A_IsCompiled || AvailableMap.Has(modName)) {
        if !AddedToActive.Has(modName) {
          ActiveModules.Push(modName)
          AddedToActive[modName] := true
        }
      }
    }
  }

  ; 2. Add any new modules from modules.ahk that aren't in mode.ini
  if !A_IsCompiled {
    NewModules := []
    for _, modName in AvailableModules {
      if !AddedToActive.Has(modName) {
        NewModules.Push(modName)
      }
    }

    ; Sort new modules alphabetically first so they are processed in order
    if (NewModules.Length > 0) {
      strNew := ""
      for _, v in NewModules
        strNew .= v "`n"

      strNew := Sort(RTrim(strNew, "`n"))

      loop parse, strNew, "`n", "`r" {
        newMod := A_LoopField
        if (newMod = "")
          continue

        ; Insert the new module alphabetically into the existing ActiveModules
        inserted := false
        for i, existMod in ActiveModules {
          ; "Logical" compares alphabetically while treating numbers smartly (e.g., mod2 < mod10)
          if (StrCompare(newMod, existMod, "Logical") < 0) {
            ActiveModules.InsertAt(i, newMod)
            AddedToActive[newMod] := true
            inserted := true
            break
          }
        }

        ; If it's alphabetically greater than everything currently in the list, place at the bottom
        if !inserted {
          ActiveModules.Push(newMod)
          AddedToActive[newMod] := true
        }
      }
    }
  }

  ; 3. Rebuild the INI content strictly based on the new mode.ini determined order
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

  ; Deletes orphans AND prevents the section from jumping to the bottom
  if (sortedToggles != "")
    IniWrite(RTrim(sortedToggles, "`n"), IniFile, "Toggles")
  if (sortedHotkeys != "")
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
}