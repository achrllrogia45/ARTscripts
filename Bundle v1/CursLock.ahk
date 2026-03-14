; ==============================================================================
; CURSLOCK MODULE
; ==============================================================================
Init_CursLock:
    SetTimer, MonitorInput, 15
return

MonitorInput:
    if (!Mod_CursLock)
        return

    MouseGetPos, cx, cy
    dx := Abs(cx - prevX), dy := Abs(cy - prevY)
    
    if (dx > MaxMouseJump || dy > MaxMouseJump) {
        PenActive := true
        if (IsOnMainScreen(prevX, prevY)) {
            LastMouseX := prevX
            LastMouseY := prevY
        }
    }
    if (A_TimeIdlePhysical < 30) {
        if (PenActive && !IsOnMainScreen(cx, cy)) {
            MouseMove, %LastMouseX%, %LastMouseY%, 0
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
return

IsOnMainScreen(x, y) {
    if (Monitor2_Pos = "AUTO")
        return true
    if (Monitor2_Pos = "DOWN")
        return (y <= Monitor1_H)
    if (Monitor2_Pos = "TOP")
        return (y >= 0)
    if (Monitor2_Pos = "RIGHT")
        return (x <= Monitor1_W)
    if (Monitor2_Pos = "LEFT")
        return (x >= 0)
    return true
}

ShowPositionSelector:
    btnW := Floor(70 * GuiScale)
    btnH := Floor(40 * GuiScale)
    gap := Floor(5 * GuiScale)
    fontSize := Floor(11 * GuiScale)
    CustomColor := "00FF00"

    Gui, TabletSelector:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, Color, %CustomColor%
    WinSet, TransColor, %CustomColor%
    Gui, Font, s%fontSize% Bold cWhite, Segoe UI

    LeftY  := Floor((btnH / 2) + (gap * 1.5))
    TopX   := Floor(btnW + (gap * 2))
    DownY  := Floor(btnH + (gap * 2))
    RightX := Floor((btnW * 2) + (gap * 3))
    
    Gui, Add, Button, x%gap% y%LeftY% w%btnW% h%btnH% gSetLeft +Background000000, LEFT
    Gui, Add, Button, x%TopX% y%gap% w%btnW% h%btnH% gSetTop +Background000000, TOP
    Gui, Add, Button, x%TopX% y%DownY% w%btnW% h%btnH% gSetDown +Background000000, DOWN
    Gui, Add, Button, x%RightX% y%LeftY% w%btnW% h%btnH% gSetRight +Background000000, RIGHT

    winW := Floor((btnW * 3) + (gap * 4))
    winH := Floor((btnH * 2) + (gap * 3))
    GuiX := Floor((Monitor1_W / 2) - (winW / 2) + GuiX_Offset)
    GuiY := Floor((Monitor1_H / 2) - (winH / 2) + GuiY_Offset)

    Gui, TabletSelector:Show, x%GuiX% y%GuiY% w%winW% h%winH% NoActivate, Tablet Position Selector
    SetTimer, HideSelectorGui, %TimerInterval%
return

HideSelectorGui:
    Gui, TabletSelector:Destroy
return

SetTop:
    Monitor2_Pos := "TOP"
    GoSub, FinalizeChoice
return
SetDown:
    Monitor2_Pos := "DOWN"
    GoSub, FinalizeChoice
return
SetLeft:
    Monitor2_Pos := "LEFT"
    GoSub, FinalizeChoice
return
SetRight:
    Monitor2_Pos := "RIGHT"
    GoSub, FinalizeChoice
return

FinalizeChoice:
    IniWrite, "%Monitor2_Pos%", %IniFile%, Curslock_config, Monitor2_Pos
    ToolTip, 2nd Monitor: %Monitor2_Pos%
    SetTimer, RemoveToolTip, -1500
    Gui, TabletSelector:Destroy
return

RemoveToolTip:
    ToolTip
return