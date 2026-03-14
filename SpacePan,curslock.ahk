; ==============================================================================
; USER CONFIGURATION
; ==============================================================================
Global Monitor1_W    := 1920      ; Your main screen width
Global Monitor1_H    := 1080      ; Your main screen height

; SET TO "AUTO" TO SHOW BUTTONS. SET TO "TOP", "DOWN", "LEFT", "RIGHT" TO HIDE.
Global Monitor2_Pos := "AUTO"    

; --- GUI ADJUSTMENTS ---
Global GuiScale      := 0.8      ; 1.0 = Default, 1.5 = Larger, 0.8 = Smaller
Global GuiX_Offset   := 0         ; Move left (-) or right (+) from center
Global GuiY_Offset   := 0         ; Move up (-) or down (+) from center
Global TimerInterval := 5000      ; How many ms the buttons stay visible

; --- LOGIC ADJUSTMENTS ---
Global MaxMouseJump := 300       ; Sensitivity for Pen detection
; ==============================================================================

#NoEnv
#Persistent
#SingleInstance Force
SendMode Input
CoordMode, Mouse, Screen

; --- TRAY MENU CONFIGURATION ---
Menu, Tray, NoStandard 
Menu, Tray, Add, Inspect Scripts, OpenWindow
Menu, Tray, Add, Show Buttons, ShowPositionSelector
Menu, Tray, Add 
Menu, Tray, Add, Reload Script, ReloadScript
Menu, Tray, Add, Edit Script, EditScript
Menu, Tray, Add, Locate Script, LocateScript
Menu, Tray, Add, Exit, ExitScript
Menu, Tray, Default, Show Buttons 

Global LastMouseX := Monitor1_W / 2
Global LastMouseY := Monitor1_H / 2
Global PenActive  := false
Global prevX := 0
Global prevY := 0

if (Monitor2_Pos = "AUTO") {
    ShowPositionSelector()
}

SetTimer, MonitorInput, 15
return

; ==============================================================================
; GUI GENERATION (TRANSPARENT BACKGROUND & BLACK BUTTONS)
; ==============================================================================
ShowPositionSelector() {
    btnW := 70 * GuiScale
    btnH := 40 * GuiScale
    gap  := 5 * GuiScale
    fontSize := Floor(11 * GuiScale)
    
    ; "dummy" color for the background
    CustomColor := "00FF00" 
    
    Gui, TabletSelector:New, +AlwaysOnTop -Caption +ToolWindow +LastFound
    Gui, Color, %CustomColor%
    
    ; Makes the 'CustomColor' (Green) completely invisible
    WinSet, TransColor, %CustomColor%
    
    ; Set font to White for the buttons
    Gui, Font, s%fontSize% Bold cWhite, Segoe UI
    
    ; LEFT
    Gui, Add, Button, % "x" (gap) " y" (btnH / 2 + gap * 1.5) " w" btnW " h" btnH " gSetLeft +Background000000", LEFT
    
    ; TOP
    Gui, Add, Button, % "x" (btnW + gap * 2) " y" (gap) " w" btnW " h" btnH " gSetTop +Background000000", TOP
    
    ; DOWN
    Gui, Add, Button, % "x" (btnW + gap * 2) " y" (btnH + gap * 2) " w" btnW " h" btnH " gSetDown +Background000000", DOWN
    
    ; RIGHT
    Gui, Add, Button, % "x" (btnW * 2 + gap * 3) " y" (btnH / 2 + gap * 1.5) " w" btnW " h" btnH " gSetRight +Background000000", RIGHT
    
    winW := (btnW * 3) + (gap * 4)
    winH := (btnH * 2) + (gap * 3)
    
    GuiX := (Monitor1_W / 2) - (winW / 2) + GuiX_Offset
    GuiY := (Monitor1_H / 2) - (winH / 2) + GuiY_Offset
    
    Gui, Show, x%GuiX% y%GuiY% w%winW% h%winH% NoActivate, Tablet Position Selector
    SetTimer, HideGui, %TimerInterval%
}

HideGui:
    Gui, TabletSelector:Destroy
return

; ==============================================================================
; ACTIONS & LOGIC ENGINE
; ==============================================================================
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
    ToolTip, 2nd Monitor: %Monitor2_Pos%
    SetTimer, RemoveToolTip, -1500
    Gui, TabletSelector:Destroy
return

OpenWindow:
    ListLines
return

ReloadScript:
    Reload
return

EditScript:
    Edit
return

LocateScript:
    Run, %A_ScriptDir%
return

ExitScript:
    ExitApp
return

RemoveToolTip:
    ToolTip
return

MonitorInput:
    MouseGetPos, cx, cy
    dx := Abs(cx - prevX), dy := Abs(cy - prevY)
    if (dx > MaxMouseJump || dy > MaxMouseJump) {
        PenActive := true
        if (IsOnMainScreen(prevX, prevY)) {
            LastMouseX := prevX, LastMouseY := prevY
        }
    }
    if (A_TimeIdlePhysical < 30) {
        if (PenActive && !IsOnMainScreen(cx, cy)) {
            MouseMove, %LastMouseX%, %LastMouseY%, 0
            PenActive := false
        }
        if (IsOnMainScreen(cx, cy)) {
            LastMouseX := cx, LastMouseY := cy, PenActive := false
        }
    }
    prevX := cx, prevY := cy
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

; --- ADOBE SHORTCUTS ---
GroupAdd, AdobeMMButton, ahk_exe Photoshop.exe
GroupAdd, AdobeMMButton, ahk_exe InDesign.exe
GroupAdd, AdobeMMButton, ahk_exe AcroRD32.exe
GroupAdd, AdobeMMButton, ahk_exe Acrobat.exe
GroupAdd, AdobeMMButton, ahk_exe Muse.exe

#IfWinActive ahk_group AdobeMMButton
MButton::
    Send {Space Down}{LButton Down}
    Keywait, MButton
    Send {LButton Up}{Space Up}
return
#IfWinActive