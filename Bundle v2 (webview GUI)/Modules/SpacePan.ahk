; ==============================================================================
; SPACEPAN MODULE - AHK v2
; ==============================================================================

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