; ==============================================================================
; ALWAYSONTOP MODULE
; ==============================================================================
Action_AOT:
    if (!Mod_AOT)
        return
    WinSet, AlwaysOnTop, Toggle, A
    SplashTextOn, 250, 30, AOT Status, Always On Top Toggled
    SetTimer, RemoveSplash, -1000
return

RemoveSplash:
    SplashTextOff
return