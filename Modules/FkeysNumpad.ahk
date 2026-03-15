; ==============================================================================
; FKEYS + NUMPAD MODULE - AHK v2
; ==============================================================================

/* [readme]
# FKEYS + NUMPAD MODULE - README
## FUNCTIONALITY
   <p> - Toggles number row keys between F1-F12 and Numpad 0-9, /, -, =. </p>
   <p> - Specifically designed for users who want to switch between function key and numpad functionality without needing a separate keyboard or remapping software. </p>
## CONFIGURATION
   <p> - The activation condition is set in mode.ini under [FkeyNumpad_config] with FkeyNumpad_state (e.g., "toggle,CapsLock" or "press,RButton"). Default is "toggle,CapsLock".</p>
   <p> - Set the hotkey for toggling between modes in the INI file under [FkeyNumpad_config] with the key 'FkeyNumpad_key'. Default is ^+T.</p>
   <p> - Set the X and Y position for the on-screen mode indicator in the INI file </p>
        under [FkeyNumpad_config] with the keys 'X' and 'Y'. Default is X: null (centered), Y: 10.
   <p> - The on-screen indicator will only show when the activation condition is met, serving as a visual reminder of the current mode. </p>
*/

; Declare for linter
global Toggles, IniFile

global Mode := ""
global FkeyX := ""
global FkeyY := ""
global LastActivationState := -1
global FkeyNumpad_state_mode := "toggle"
global FkeyNumpad_state_key := "CapsLock"

fnumConf:= "FkeyNumpad_config"
    ; Comment component
; global commentComponent := UpdateIni



FkeyNumpad_IsActive() {
    global FkeyNumpad_state_mode, FkeyNumpad_state_key, Toggles
    if !(IsSet(Toggles) && Toggles.Has("FkeysNumpad") && Toggles["FkeysNumpad"])
        return false
    mode_char := (FkeyNumpad_state_mode = "press") ? "P" : "T"
    return GetKeyState(FkeyNumpad_state_key, mode_char)
}

Init_FkeysNumpad() {
    global OverlayGui, OverlayText, FkeyOverlayPos, Mode, FkeyX, FkeyY, FkeyNumpad_state_mode, FkeyNumpad_state_key
    
    commentSection(IniFile, fnumConf, "; {'P' or press, 'T' or toggle}, {key}")

    ; Activation state
    state_config := IniRead(IniFile, fnumConf, "FkeyNumpad_state", "toggle,CapsLock")
    IniWrite(state_config, IniFile, fnumConf, "FkeyNumpad_state")
    state_parts := StrSplit(state_config, ",")
    if (state_parts.Length >= 2) {
        FkeyNumpad_state_mode := Trim(state_parts[1])
        FkeyNumpad_state_key := Trim(state_parts[2])
    }
    
 ; Toggle hotkey
    key_config := IniRead(IniFile, fnumConf, "FkeyNumpad_key", "^+T")
    IniWrite(key_config, IniFile, fnumConf, "FkeyNumpad_key")

    if (key_config != "" && key_config != "null") {
        Hotkey(key_config, FkeyNumpad_ToggleMode)
    }

    if (IniRead(IniFile, fnumConf, "FkeyNumpad_mode", "") = "") {
        IniWrite("(F)KEY", IniFile, fnumConf, "FkeyNumpad_mode")
    }

    ; Position config
    if (IniRead(IniFile, fnumConf, "X", "") = "") {
        IniWrite("null", IniFile, fnumConf, "X")
        IniWrite("10", IniFile, fnumConf, "Y")
    }

    Mode := IniRead(IniFile, fnumConf, "FkeyNumpad_mode", "(F)KEY")
    FkeyX := IniRead(IniFile, fnumConf, "X", "null")
    FkeyY := IniRead(IniFile, fnumConf, "Y", "10")

    

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

    SetTimer(CheckActivationState, 200)
}

CheckActivationState() {
    global LastActivationState, Mode, OverlayGui, OverlayText, FkeyOverlayPos
    static LastModState := -1

    currentActiveState := FkeyNumpad_IsActive()
    currentMod := IsSet(Toggles) && Toggles.Has("FkeysNumpad") ? Toggles["FkeysNumpad"] : 0

    if (currentActiveState != LastActivationState || currentMod != LastModState) {
        LastActivationState := currentActiveState
        LastModState := currentMod

        if (currentMod && currentActiveState) {
            OverlayText.Value := Mode " MODE"
            OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize")
        } else {
            OverlayGui.Hide()
        }
    }
}

FkeyNumpad_ToggleMode(*) {
    if (!FkeyNumpad_IsActive()) {
        return
    }

    global Mode, OverlayGui, OverlayText, FkeyOverlayPos

    if (Mode == "(F)KEY")
        Mode := "NUMPAD"
    else
        Mode := "(F)KEY"

    IniWrite(Mode, IniFile, fnumConf, "FkeyNumpad_mode")
    if IsSet(OverlayText) {
        OverlayText.Value := Mode " MODE"
        OverlayGui.Show(FkeyOverlayPos "NoActivate AutoSize")
    }
}

#HotIf FkeyNumpad_IsActive() && Mode=="(F)KEY"
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

#HotIf FkeyNumpad_IsActive() && Mode=="NUMPAD"
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

#HotIf FkeyNumpad_IsActive()
/::NumpadDiv
#HotIf
