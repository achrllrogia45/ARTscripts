; ==============================================================================
; ALWAYSONTOP MODULE - AHK v2
; ==============================================================================

/* [readme]
# ALWAYSONTOP MODULE - README
## FUNCTIONALITY
    - Toggles Always On Top for the active window.
    - Displays a temporary on-screen message confirming the action.
## REQUIREMENTS
    - Must have a global 'Toggles' object defined in Main.ahk.
    - Only works when 'AlwaysOnTop' key is set to 1.
## CONFIGURATION
    - Set the hotkey for toggling Always On Top in the INI file under [AlwaysOnTop_config] with the key 'AlwaysOnTop_mode'. Default is F8.
*/

; Declare for linter
global Toggles, IniFile

global HK_AOT_Action := ""

Init_AlwaysOnTop() {
    global HK_AOT_Action
    HK_AOT_Action := IniRead(IniFile, "AlwaysOnTop_config", "AlwaysOnTop_mode", "F8")
    if (HK_AOT_Action != "null" && HK_AOT_Action != "") {
        Hotkey(HK_AOT_Action, Action_AOT)
    }
}

Action_AOT(HotkeyName := "") {
    if !(IsSet(Toggles) && Toggles.Has("AlwaysOnTop") && Toggles["AlwaysOnTop"])
        return
        
    WinSetAlwaysOnTop(-1, "A")
    
    global SplashGui
    if IsSet(SplashGui) && SplashGui
        SplashGui.Destroy()
        
    SplashGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "AOT Status")
    SplashGui.Add("Text", "w250 h30 Center +0x200", "Always On Top Toggled")
    SplashGui.Show("NoActivate")
    
    SetTimer(RemoveSplash, -1000)
}

RemoveSplash() {
    global SplashGui
    if IsSet(SplashGui) && SplashGui
        SplashGui.Destroy()
    SetTimer(RemoveSplash, 0)
}