; ==============================================================================
; TouchPAN MODULE - AHK v2
; ==============================================================================

/* [readme]
# TouchPAN MODULE - README
## FUNCTIONALITY:
<p> - Remaps MButton to Space + LButton. </p>
<p> - Specifically designed for Adobe panning using Middle Mouse Button. </p>
## COMPATIBLE APPS:
<p> 1. Photoshop </p>
<p> 2. InDesign </p>
<p> 3. Acrobat / Reader </p>
<p> 4. Muse </p>
*/
; Declare for linter
global Toggles
; global Spacepan_key := "MButton"
; spacePanConf := "SpacePan_config"

Init_TouchPan() {
    GroupAdd("AdobeGesture", "ahk_exe Photoshop.exe")
    GroupAdd("AdobeGesture", "ahk_exe InDesign.exe")
    GroupAdd("AdobeGesture", "ahk_exe AcroRD32.exe")
    GroupAdd("AdobeGesture", "ahk_exe Acrobat.exe")
    GroupAdd("AdobeGesture", "ahk_exe Muse.exe")
    GroupAdd("AdobeGesture", "ahk_exe msedge.exe")
}

#HotIf IsSet(Toggles) && Toggles.Has("SpacePan") && Toggles["SpacePan"] && WinActive("ahk_group AdobeMMButton")

; Tilde lets a single 2-finger tap act normally (open brush menu)
~RButton:: {
    ; Check if you did a second 2-finger tap within 400 milliseconds
    if (A_PriorHotkey == "~RButton" && A_TimeSincePriorHotkey < 400) {

        ; Send Esc to close the brush menu that the first tap accidentally opened
        Send("{Esc}")
        Sleep(50)

        ; Send Undo
        Send("^{z}")

        ; Reset the key so a third tap doesn't trigger it again
        KeyWait("RButton")
    }
}
#HotIf