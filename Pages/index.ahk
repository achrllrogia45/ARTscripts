; ==============================================================================
; CYBERKINETIC OPERATOR THEME
; ==============================================================================

Theme_Init(GuiObj, WindowType) {
  ; Remove Win11 rounded corners
  if (VerCompare(A_OSVersion, "10.0.22000") >= 0) {
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", GuiObj.Hwnd, "int", 34, "int*", 0xFFFFFFFE, "int", 4)
  }

  ; Attach the Resize event
  GuiObj.OnEvent("Size", Theme_ApplyShape)

  ; Initial cut with 50ms delay for safety
  SetTimer(() => Theme_ApplyShape(GuiObj, 0, 0, 0), -50)
}

Theme_ApplyShape(GuiObj, MinMax := 0, W := 0, H := 0) {
  if (MinMax == -1)
    return

  ; Use GetClientPos to ignore invisible OS resize margins
  if (!W || !H)
    GuiObj.GetClientPos(, , &W, &H)

  ; Ensure strict Integers for WinSetRegion
  W := Integer(W), H := Integer(H)

  ; Your original working 25px cut path
  RegionStr := "0-25 25-0 " W "-0 " W "-" (H - 25) " " (W - 25) "-" H " 0-" H " 0-25"

  try WinSetRegion(RegionStr, "ahk_id " GuiObj.Hwnd)
}