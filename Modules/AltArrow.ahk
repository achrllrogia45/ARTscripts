; ==============================================================================
; ALTARROW MODULE - AHK v2
; ==============================================================================

/* [readme]
# ALTARROW MODULE - README
## FUNCTIONALITY
   <p> - Remaps Alt + Arrow keys to function as Home/End and Ctrl + Home/End. </p>
   <p> - Specifically designed for users who prefer using the arrow keys for navigation but want quick access to Home/End functionality. </p>
## REQUIREMENTS
   <p> - Must have a global 'Toggles' object defined in Main.ahk. </p>
   <p> - Only works when 'AltArrow' key is set to 1. </p>
## CONFIGURATION
    <p> - Set the hotkeys for toggling this module in the INI file under [AltArrow_config] with the key 'AltArrow_mode'. Default is Alt + Arrow keys. </p>
*/

; Declare for linter (Main script provides the actual object)
global Toggles

#HotIf IsSet(Toggles) && Toggles.Has("AltArrow") && Toggles["AltArrow"]
!i::Send("{UP}")
!k::Send("{DOWN}")
!j::Send("{LEFT}")
!l::Send("{RIGHT}")
!h::Send("{HOME}")
!;::Send("{END}")
!u::Send("^{HOME}")
!o::Send("^{END}")

!^j::Send("^{LEFT}")
!^l::Send("^{RIGHT}")

!+i::Send("+{UP}")
!+k::Send("+{DOWN}")
!+j::Send("+{LEFT}")
!+l::Send("+{RIGHT}")
!+h::Send("+{HOME}")
!+;::Send("+{END}")
!+u::Send("^+{HOME}")
!+o::Send("^+{END}")

!+^j::Send("+^{LEFT}")
!+^l::Send("+^{RIGHT}")
!+^i::Send("+!{UP}")
!+^k::Send("+!{DOWN}")

+^i::Send("+^{UP}")
+^k::Send("+^{DOWN}")
#HotIf