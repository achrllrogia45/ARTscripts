; ==============================================================================
; SPACEPAN MODULE - AHK v2
; ==============================================================================

/* [readme]
# SPACEPAN MODULE - README
## FUNCTIONALITY:
<p> - Remaps MButton to Space + LButton. </p>
<p> - Specifically designed for Adobe panning using Middle Mouse Button. </p>
## COMPATIBLE APPS:
<p> 1. Photoshop </p>
<p> 2. InDesign </p>
<p> 3. Acrobat / Reader </p>
<p> 4. Muse </p>
*/

#Requires AutoHotkey v2.0

; Declare for linter
global Toggles, IniFile
global Spacepan_key := "MButton"
spacePanConf := "SpacePan_config"

Init_SpacePan() {
    GroupAdd("AdobeMMButton", "ahk_exe Photoshop.exe")
    GroupAdd("AdobeMMButton", "ahk_exe InDesign.exe")
    GroupAdd("AdobeMMButton", "ahk_exe AcroRD32.exe")
    GroupAdd("AdobeMMButton", "ahk_exe Acrobat.exe")
    GroupAdd("AdobeMMButton", "ahk_exe Muse.exe")

    key_config := IniRead(IniFile, spacePanConf, "SpacePan_key", Spacepan_key)
    IniWrite(key_config, IniFile, spacePanConf, "SpacePan_key")
    
    ; ET THE CONTEXT FOR THE DYNAMIC HOTKEY
    HotIf (*) => IsSet(Toggles) && Toggles.Has("SpacePan") && Toggles["SpacePan"] && WinActive("ahk_group AdobeMMButton")

    ; REGISTER THE HOTKEY
    if (key_config != "" && key_config != "null") {
        Hotkey(key_config, SpacePan_Action)
    }

    ; RESET HOTIF (prevents this condition from bleeding into other scripts)
    HotIf()
}

SpacePan_Action(ThisHotkey) {
    Send("{Space Down}")
    Send("{LButton Down}")
    
    ; Strip any modifiers (like ^ or +) from the hotkey string so KeyWait works perfectly
    cleanKey := RegExReplace(ThisHotkey, "[\*\~\$\^!+#]")
    KeyWait(cleanKey)
    
    Send("{LButton Up}")
    Send("{Space Up}")
}

/* Unused Code

Raw Code:

#HotIf IsSet(Toggles) && Toggles.Has("SpacePan") && Toggles["SpacePan"] && WinActive("ahk_group AdobeMMButton")
MButton:: {
    Send("{Space Down}")
    Send("{LButton Down}")
}
*/