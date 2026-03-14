; ==============================================================================
; SPACEPAN MODULE - AHK v2
; ==============================================================================

/* [readme]
# SPACEPAN MODULE - README
## FUNCTIONALITY:
<p> - Remaps MButton to Space + LButton. </p>
<p> - Specifically designed for Adobe Suite panning. </p>
## REQUIREMENTS:
<p> - Must have a global 'Toggles' object defined in Main.ahk. </p>
<p> - Only works when 'SpacePan' key is set to 1. </p>
## COMPATIBLE APPS:
<p> 1. Photoshop </p>
<p> 2. InDesign </p>
<p> 3. Acrobat / Reader </p>
<p> 4. Muse </p>
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