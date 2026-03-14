; ==============================================================================
; CURSLOCK MODULE - AHK v2
; ==============================================================================

/* [readme]
# CURSLOCK MODULE - README
## FUNCTIONALITY
   <p> - Locks cursor to main screen. </p>
   <p> - Specifically designed for tablet/2nd screen use. </p>
## REQUIREMENTS
   <p> - Must have a global 'Toggles' object defined in Main.ahk. </p>
   <p> - Only works when 'CursLock' key is set to 1. </p>

*/

; Declare for linter
global Toggles, IniFile

global Monitor1_W := 1920
global Monitor1_H := 1080
global Monitor2_Pos := "DOWN"
global GuiScale := 1
global GuiX_Offset := 0
global GuiY_Offset := 0

Init_CursLock() {
    global Monitor1_W, Monitor1_H, Monitor2_Pos, GuiScale, GuiX_Offset, GuiY_Offset
    
    Monitor1_W := Integer(IniRead(IniFile, "Curslock_config", "Monitor1_W", "1920"))
    Monitor1_H := Integer(IniRead(IniFile, "Curslock_config", "Monitor1_H", "1080"))
    Monitor2_Pos := Trim(StrReplace(IniRead(IniFile, "Curslock_config", "Monitor2_Pos", '"DOWN"'), '"', ""), " `t")
    GuiScale := Float(IniRead(IniFile, "Curslock_config", "GuiScale", "1"))
    GuiX_Offset := Integer(IniRead(IniFile, "Curslock_config", "GuiX_Offset", "0"))
    GuiY_Offset := Integer(IniRead(IniFile, "Curslock_config", "GuiY_Offset", "0"))
    
    SetTimer(MonitorInput, 15)
}

MonitorInput() {
    global prevX, prevY, PenActive, LastMouseX, LastMouseY
    
    if !(Toggles.Has("CursLock") && Toggles["CursLock"])
        return

    MouseGetPos(&cx, &cy)
    dx := Abs(cx - prevX)
    dy := Abs(cy - prevY)
    
    if (dx > MaxMouseJump || dy > MaxMouseJump) {
        PenActive := true
        if (IsOnMainScreen(prevX, prevY)) {
            LastMouseX := prevX
            LastMouseY := prevY
        }
    }
    
    if (A_TimeIdlePhysical < 30) {
        if (PenActive && !IsOnMainScreen(cx, cy)) {
            MouseMove(LastMouseX, LastMouseY, 0)
            PenActive := false
        }
        if (IsOnMainScreen(cx, cy)) {
            LastMouseX := cx
            LastMouseY := cy
            PenActive := false
        }
    }
    
    prevX := cx
    prevY := cy
}

IsOnMainScreen(x, y) {
    if (Monitor2_Pos == "AUTO")
        return true
    if (Monitor2_Pos == "DOWN")
        return (y <= Monitor1_H)
    if (Monitor2_Pos == "TOP")
        return (y >= 0)
    if (Monitor2_Pos == "RIGHT")
        return (x <= Monitor1_W)
    if (Monitor2_Pos == "LEFT")
        return (x >= 0)
    return true
}

ShowPositionSelector() {
    global TabletSelectorGui
    
    if IsSet(TabletSelectorGui) && TabletSelectorGui
        TabletSelectorGui.Destroy()

    btnW := Integer(70 * GuiScale)
    btnH := Integer(40 * GuiScale)
    gap := Integer(5 * GuiScale)
    fontSize := Integer(11 * GuiScale)
    CustomColor := "00FF00"

    TabletSelectorGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    TabletSelectorGui.BackColor := CustomColor
    WinSetTransColor(CustomColor, TabletSelectorGui.Hwnd)
    TabletSelectorGui.SetFont("s" fontSize " Bold cWhite", "Segoe UI")

    LeftY  := Integer((btnH / 2) + (gap * 1.5))
    TopX   := Integer(btnW + (gap * 2))
    DownY  := Integer(btnH + (gap * 2))
    RightX := Integer((btnW * 2) + (gap * 3))
    
    BtnLeft := TabletSelectorGui.Add("Button", "x" gap " y" LeftY " w" btnW " h" btnH, "LEFT")
    BtnLeft.OnEvent("Click", (*) => FinalizeChoice("LEFT"))
    
    BtnTop := TabletSelectorGui.Add("Button", "x" TopX " y" gap " w" btnW " h" btnH, "TOP")
    BtnTop.OnEvent("Click", (*) => FinalizeChoice("TOP"))
    
    BtnDown := TabletSelectorGui.Add("Button", "x" TopX " y" DownY " w" btnW " h" btnH, "DOWN")
    BtnDown.OnEvent("Click", (*) => FinalizeChoice("DOWN"))
    
    BtnRight := TabletSelectorGui.Add("Button", "x" RightX " y" LeftY " w" btnW " h" btnH, "RIGHT")
    BtnRight.OnEvent("Click", (*) => FinalizeChoice("RIGHT"))

    winW := Integer((btnW * 3) + (gap * 4))
    winH := Integer((btnH * 2) + (gap * 3))
    GuiX := Integer((Monitor1_W / 2) - (winW / 2) + GuiX_Offset)
    GuiY := Integer((Monitor1_H / 2) - (winH / 2) + GuiY_Offset)

    TabletSelectorGui.Show("x" GuiX " y" GuiY " w" winW " h" winH " NoActivate")
    SetTimer(HideSelectorGui, TimerInterval)
}

HideSelectorGui() {
    global TabletSelectorGui
    if IsSet(TabletSelectorGui) && TabletSelectorGui
        TabletSelectorGui.Destroy()
    SetTimer(HideSelectorGui, 0)
}

FinalizeChoice(choice) {
    global Monitor2_Pos := choice
    IniWrite('"' Monitor2_Pos '"', IniFile, "Curslock_config", "Monitor2_Pos")
    
    ; Call the Premium status display instead of ToolTip
    ShowPremiumStatus("2nd Monitor: " Monitor2_Pos "`nResolution: " Monitor1_W "x" Monitor1_H)
    
    global TabletSelectorGui
    if IsSet(TabletSelectorGui) && TabletSelectorGui
        TabletSelectorGui.Destroy()
}

ShowPremiumStatus(text) {
    global StatusGui
    if IsSet(StatusGui) && StatusGui
        StatusGui.Destroy()

    ; --- Design Settings ---
    CustomColor := "1A1A1A"  ; Dark background
    AccentColor := "00FF00"  ; Neon Green
    fontSize := Integer(12 * GuiScale)

    StatusGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
    StatusGui.BackColor := CustomColor
    StatusGui.SetFont("s" fontSize " Bold c" AccentColor, "Segoe UI")
    
    ; Add text with a bit of padding
    StatusGui.Add("Text", "Center w250", text)
    
    ; Make the dark background slightly transparent for a "glass" look
    WinSetTransparent(220, StatusGui.Hwnd)
    
    ; Show in center of Monitor 1
    StatusGui.Show("AutoSize NoActivate")
    
    ; Use Timer to auto-destroy
    SetTimer(() => (IsSet(StatusGui) && StatusGui ? StatusGui.Destroy() : ""), -1000)
}
OnToggle_CursLock(state) {
    if (state)
        ShowPositionSelector()
}

