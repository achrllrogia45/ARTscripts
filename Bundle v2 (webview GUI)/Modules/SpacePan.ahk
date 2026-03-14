; ==============================================================================
; SPACEPAN MODULE - AHK v2
; ==============================================================================

/* [readme]
    # SPACEPAN MODULE - README

    ##FUNCTIONALITY:
    - Remaps MButton to Space + LButton.
    - Specifically designed for Adobe Suite panning.

    ## REQUIREMENTS:
    - Must have a global 'Toggles' object defined in Main.ahk.
    - Only works when 'SpacePan' key is set to 1.

    COMPATIBLE APPS:
    1. Photoshop
    2. InDesign
    3. Acrobat / Reader
    4. Muse
*/
Init_SpacePan() {
    GroupAdd("AdobeMMButton", "ahk_exe Photoshop.exe")
    GroupAdd("AdobeMMButton", "ahk_exe InDesign.exe")
    GroupAdd("AdobeMMButton", "ahk_exe AcroRD32.exe")
    GroupAdd("AdobeMMButton", "ahk_exe Acrobat.exe")
    GroupAdd("AdobeMMButton", "ahk_exe Muse.exe")
}

#HotIf IsSet(Toggles) && Toggles.Has("SpacePan") && Toggles["SpacePan"] && WinActive("ahk_group AdobeMMButton")
MButton:: {
    Send("{Space Down}")
    Send("{LButton Down}")
    KeyWait("MButton")
    Send("{LButton Up}")
    Send("{Space Up}")
}
#HotIf