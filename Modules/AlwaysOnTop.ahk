; ==============================================================================
; ALWAYSONTOP MODULE - AHK v2
; ==============================================================================

/* [readme]
# ALWAYSONTOP MODULE - README
## FUNCTIONALITY
   <p> - Toggles Always On Top for the active window. </p>
   <p> - Displays a temporary on-screen message confirming the action. </p>
## CONFIGURATION
    <p> - Set the hotkey for toggling Always On Top in the INI file under [AlwaysOnTop_config] with the key 'AlwaysOnTop_key'. Default is F8. </p>
*/

; Declare for linter
global Toggles, IniFile

global HK_AOT_Action := ""

aotConf := "AlwaysOnTop_config"


Init_AlwaysOnTop() {
    global HK_AOT_Action
    HK_AOT_Action := IniRead(IniFile, aotConf, "AlwaysOnTop_key", "F8")
    if (HK_AOT_Action != "null" && HK_AOT_Action != "") {
        Hotkey(HK_AOT_Action, Action_AOT)
    }
    if (IniRead(IniFile, aotConf, "AlwaysOnTop_key", "NOT_FOUND") = "NOT_FOUND") {
        IniWrite("F8", IniFile, aotConf, "AlwaysOnTop_key")
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