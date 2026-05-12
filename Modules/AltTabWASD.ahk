; ==============================================================================
; ALTTABWASD MODULE - AHK v2
; ==============================================================================

/* [readme]
# ALTTABWASD MODULE - README
## FUNCTIONALITY
   <p> - Maps WASD to Arrow keys while the Alt+Tab switcher is visible. </p>
   <p> - W = Up, A = Left, S = Down, D = Right. </p>
   <p> - Only active while Alt is held after pressing Alt+Tab. </p>
   <p> - Releasing Alt deactivates WASD mapping and returns keys to normal. </p>
   <p> - Includes a configurable runtime toggle hotkey to enable/disable WASD navigation without restarting. </p>
## CONFIGURATION
    <p> - Set the runtime toggle hotkey in mode.ini under [AltTabWASD] with 'AltTabWASD_key'. Default is #^+\ (Win+Ctrl+Shift+\). </p>
    <p> - The toggle hotkey enables/disables the WASD feature at runtime. The module toggle in the GUI controls whether the module is loaded at all. </p>
*/

#Requires AutoHotkey v2.0

; Declare for linter (Main script provides the actual objects)
global Toggles, IniFile

; --- Module State ---
global AltTabWASD_altTabActive := false
global AltTabWASD_wasdEnabled := true

; --- INI Section ---
atConf := "AltTabWASD"

; ==============================================================================
; INITIALIZATION
; ==============================================================================

Init_AltTabWASD() {
    global AltTabWASD_wasdEnabled

    ; Add comment to INI section
    commentSection(IniFile, atConf, "; Win+Ctrl+Shift+\ to toggle WASD navigation on/off at runtime")

    ; Read toggle hotkey from INI (default: Win+Ctrl+Shift+\)
    key_config := IniRead(IniFile, atConf, "AltTabWASD_key", "#^+\")

    ; Write default if section/key is missing
    if (IniRead(IniFile, atConf, "AltTabWASD_key", "") = "") {
        IniWrite("#^+\", IniFile, atConf, "AltTabWASD_key")
    }

    ; Register the runtime toggle hotkey
    if (key_config != "" && key_config != "null") {
        Hotkey(key_config, AltTabWASD_ToggleWasd)
    }
}

; ==============================================================================
; RUNTIME TOGGLE (separate from GUI module toggle)
; ==============================================================================

AltTabWASD_ToggleWasd(*) {
    global AltTabWASD_wasdEnabled
    if !(IsSet(Toggles) && Toggles.Has("AltTabWASD") && Toggles["AltTabWASD"])
        return
    AltTabWASD_wasdEnabled := !AltTabWASD_wasdEnabled
    ToolTip("WASD Nav: " (AltTabWASD_wasdEnabled ? "ON" : "OFF"))
    SetTimer(() => ToolTip(), -1500)
}

; ==============================================================================
; CONDITION FUNCTIONS
; ==============================================================================

; Full condition: module ON + WASD enabled + Alt+Tab active
AltTabWASD_IsActive() {
    global AltTabWASD_altTabActive, AltTabWASD_wasdEnabled, Toggles
    if !(IsSet(Toggles) && Toggles.Has("AltTabWASD") && Toggles["AltTabWASD"])
        return false
    return AltTabWASD_altTabActive && AltTabWASD_wasdEnabled
}

; Module ON + WASD enabled (for intercepting Alt+Tab itself)
AltTabWASD_ModuleReady() {
    global AltTabWASD_wasdEnabled, Toggles
    if !(IsSet(Toggles) && Toggles.Has("AltTabWASD") && Toggles["AltTabWASD"])
        return false
    return AltTabWASD_wasdEnabled
}

; Module ON only (for Alt Up detection — must fire even if wasdEnabled is off
; to properly clean up state)
AltTabWASD_ModuleOn() {
    global Toggles
    return IsSet(Toggles) && Toggles.Has("AltTabWASD") && Toggles["AltTabWASD"]
}

; ==============================================================================
; DEACTIVATION — Clean release of any held arrow keys
; ==============================================================================

AltTabWASD_Deactivate() {
    global AltTabWASD_altTabActive
    if (!AltTabWASD_altTabActive)
        return
    AltTabWASD_altTabActive := false

    ; Release any arrow keys that might be held from WASD mapping
    ; Check physical state of WASD keys — if user is still holding them,
    ; the corresponding arrow key needs to be released
    if GetKeyState("w", "P")
        SendInput("{Up Up}")
    if GetKeyState("a", "P")
        SendInput("{Left Up}")
    if GetKeyState("s", "P")
        SendInput("{Down Up}")
    if GetKeyState("d", "P")
        SendInput("{Right Up}")
}

; ==============================================================================
; ALT+TAB INTERCEPTION — Detect when switcher opens
; ==============================================================================

; Intercept Alt+Tab: set state flag, pass through to OS
#HotIf AltTabWASD_ModuleReady()
$!Tab:: {
    global AltTabWASD_altTabActive
    AltTabWASD_altTabActive := true
    SendInput("{Blind}{Tab}")
}

; Intercept Alt+Shift+Tab (reverse cycling): same state, pass through
$!+Tab:: {
    global AltTabWASD_altTabActive
    AltTabWASD_altTabActive := true
    SendInput("{Blind}{Tab}")
}
#HotIf

; ==============================================================================
; ALT RELEASE DETECTION — Detect when switcher closes
; ==============================================================================

; When Alt is released, deactivate WASD mapping
; Using ~ (pass-through) so Alt Up still reaches the OS to finalize the switch
; Using * so it fires regardless of other modifiers (Shift, Ctrl, etc.)
#HotIf AltTabWASD_ModuleOn()
~*Alt Up:: {
    AltTabWASD_Deactivate()
}
~*LAlt Up:: {
    AltTabWASD_Deactivate()
}
#HotIf

; ==============================================================================
; WASD → ARROW REMAPPING (only while Alt+Tab is active)
; ==============================================================================

; Using * prefix: fires regardless of modifier state (Alt is held)
; Using SendInput for lowest latency
; Explicit keydown and keyup handlers for proper hold/repeat behavior

#HotIf AltTabWASD_IsActive()

; --- Key Down (press and auto-repeat) ---
*w::SendInput("{Blind}{Up}")
*a::SendInput("{Blind}{Left}")
*s::SendInput("{Blind}{Down}")
*d::SendInput("{Blind}{Right}")

; --- Key Up (release) ---
*w Up::SendInput("{Blind}{Up Up}")
*a Up::SendInput("{Blind}{Left Up}")
*s Up::SendInput("{Blind}{Down Up}")
*d Up::SendInput("{Blind}{Right Up}")

; --- Escape dismisses Alt+Tab and deactivates WASD ---
*Escape:: {
    AltTabWASD_Deactivate()
    SendInput("{Blind}{Escape}")
}

; --- Tab still works for cycling forward while WASD is active ---
*Tab::SendInput("{Blind}{Tab}")

#HotIf
