; ==============================================================================
; ALWAYSONTOP MODULE - AHK v2
; ==============================================================================
Action_AOT(HotkeyName := "") {
    if (!Mod_AOT)
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