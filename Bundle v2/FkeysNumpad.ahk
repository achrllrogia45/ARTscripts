; ==============================================================================
; FKEYS + NUMPAD MODULE - AHK v2
; ==============================================================================
Init_FkeysNumpad() {
    global OverlayGui, OverlayText, FkeyOverlayPos
    
    ; Construct the display position string dynamically
    FkeyOverlayPos := ""
    if (FkeyX != "null" && FkeyX != "")
        FkeyOverlayPos .= "x" FkeyX " "
    if (FkeyY != "null" && FkeyY != "")
        FkeyOverlayPos .= "y" FkeyY " "
        
    OverlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    OverlayGui.BackColor := "000000"
    OverlayGui.SetFont("s9 c00FF00 Bold", "Consolas")
    
    OverlayText := OverlayGui.Add("Text", "Center BackgroundTrans", Mode " MODE")
    
    OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize Hide")
    
    WinSetTransparent(225, OverlayGui)

    SetTimer(CheckCapsLock, 200)
}

CheckCapsLock() {
    global LastCapsState, Mod_FkeyNumpad, Mode, OverlayGui, OverlayText, FkeyOverlayPos
    static LastModState := -1 

    currentCaps := GetKeyState("CapsLock", "T")
    
    if (currentCaps != LastCapsState || Mod_FkeyNumpad != LastModState) {
        LastCapsState := currentCaps
        LastModState := Mod_FkeyNumpad

        if (Mod_FkeyNumpad && currentCaps) {
            OverlayText.Value := Mode " MODE"
            OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize")
        } else {
            OverlayGui.Hide()
        }
    }
}

#HotIf Mod_FkeyNumpad && GetKeyState("CapsLock", "T")
^!t:: {
    global Mode, OverlayGui, OverlayText, FkeyOverlayPos
    
    if (Mode == "(F)KEY")
        Mode := "NUMPAD"
    else
        Mode := "(F)KEY"
        
    IniWrite(Mode, IniFile, "Settings", "FkeyNumpad_mode")
    
    if IsSet(OverlayText) {
        OverlayText.Value := Mode " MODE"
        OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize")
    }
}
#HotIf

#HotIf Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode=="(F)KEY"
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
#HotIf

#HotIf Mod_FkeyNumpad && GetKeyState("CapsLock", "T") && Mode=="NUMPAD"
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
#HotIf