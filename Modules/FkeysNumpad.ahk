; ==============================================================================
; FKEYS + NUMPAD MODULE - AHK v2
; ==============================================================================

/* [readme]
# FKEYS + NUMPAD MODULE - README
## FUNCTIONALITY
   <p> - Toggles number row keys between F1-F12 and Numpad 0-9, /, -, =. </p>
   <p> - Specifically designed for users who want to switch between function key and numpad functionality without needing a separate keyboard or remapping software. </p>
## REQUIREMENTS
   <p> - Must have a global 'Toggles' object defined in Main.ahk. </p>
   <p> - Only works when 'FkeysNumpad' key is set to 1. </p>
## CONFIGURATION
   <p> - Set the hotkey for toggling between modes in the INI file under [Settings]
        with the key 'FkeyNumpad_mode'. Default is Ctrl + Alt + T.
   </p>
   <p> - Set the X and Y position for the on-screen mode indicator in the INI file </p>
   <p>     under [FkeyNumpad_config] with the keys 'X' and 'Y'. Default is X: null (centered), Y: 10. </p>
   <p> - The on-screen indicator will only show when Caps Lock is on, serving as a visual reminder of the current mode. </p>
*/

; Declare for linter
global Toggles, IniFile

global Mode := ""
global FkeyX := ""
global FkeyY := ""

Init_FkeysNumpad() {
    global OverlayGui, OverlayText, FkeyOverlayPos, Mode, FkeyX, FkeyY

    Mode := IniRead(IniFile, "Settings", "FkeyNumpad_mode", "(F)KEY")
    FkeyX := IniRead(IniFile, "FkeyNumpad_config", "X", "null")
    FkeyY := IniRead(IniFile, "FkeyNumpad_config", "Y", "10")

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
    global LastCapsState, Mode, OverlayGui, OverlayText, FkeyOverlayPos
    static LastModState := -1

    currentCaps := GetKeyState("CapsLock", "T")
    currentMod := IsSet(Toggles) && Toggles.Has("FkeysNumpad") ? Toggles["FkeysNumpad"] : 0

    if (currentCaps != LastCapsState || currentMod != LastModState) {
        LastCapsState := currentCaps
        LastModState := currentMod

        if (currentMod && currentCaps) {
            OverlayText.Value := Mode " MODE"
            OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize")
        } else {
            OverlayGui.Hide()
        }
    }
}

#HotIf (IsSet(Toggles) && Toggles.Has("FkeysNumpad") && Toggles["FkeysNumpad"]) && GetKeyState("CapsLock", "T")
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

#HotIf (IsSet(Toggles) && Toggles.Has("FkeysNumpad") && Toggles["FkeysNumpad"]) && GetKeyState("CapsLock", "T") && Mode=="(F)KEY"
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

#HotIf (IsSet(Toggles) && Toggles.Has("FkeysNumpad") && Toggles["FkeysNumpad"]) && GetKeyState("CapsLock", "T") && Mode=="NUMPAD"
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
