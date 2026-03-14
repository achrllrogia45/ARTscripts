; ==============================================================================
; FKEYS + NUMPAD MODULE
; ==============================================================================
Init_FkeysNumpad:
  Gui, Overlay: New, +AlwaysOnTop - Caption + ToolWindow + HwndOverlayHwnd
  Gui, Overlay: Color, 000000
  Gui, Overlay: Font, s9 c00FF00 Bold, Consolas
  Gui, Overlay: Add, Text, vOverlayText Center BackgroundTrans, %Mode% MODE
  Gui, Overlay: Show, y10 NoActivate AutoSize Hide
  WinSet, Transparent, 25, ahk_id %OverlayHwnd%

  SetTimer, CheckCapsLock, 200
  return

CheckCapsLock:
  currentCaps := GetKeyState("CapsLock", "T")
  if (currentCaps != LastCapsState) {
    LastCapsState := currentCaps
    if (Mod_FkeyNumpad && currentCaps) {
      Gui, Overlay: Default
      GuiControl, , OverlayText, %Mode% MODE
      Gui, Overlay: Show, y10 NoActivate AutoSize
    } else {
      Gui, Overlay: Hide
    }
  }
  return

  #If Mod_FkeyNumpad && GetKeyState("CapsLock", "T")
  ^!t::
  if (Mode = "(F)KEY")
    Mode := "NUMPAD"
  else
    Mode := "(F)KEY"
  IniWrite, %Mode%, %IniFile%, Settings, FkeyNumpad_mode
  Gui, Overlay: Default
  GuiControl, , OverlayText, %Mode% MODE
  return
  #If

  #If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="(F)KEY"
  1::F1
  2::F2
  3::F3
  4::F4
  5::F5
  6::F6
  7::F7
  8::F8
  9::F9
  0::F10
  -::F11
  =::F12
  #If

  #If Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode="NUMPAD"
  1::Numpad1
  2::Numpad2
  3::Numpad3
  4::Numpad4
  5::Numpad5
  6::Numpad6
  7::Numpad7
  8::Numpad8
  9::Numpad9
  0::Numpad0
  /::NumpadDiv
  -::NumpadSub
  =::NumpadAdd
  #If