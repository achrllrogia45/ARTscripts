; ==============================================================================
; ALTARROW MODULE
; ==============================================================================
#If Mod_AltArrow
!i::Send {UP}
!k::Send {DOWN}
!j::Send {LEFT}
!l::Send {RIGHT}
!h::Send {HOME}
!;::Send {END}
!u::Send ^{HOME}
!o::Send ^{END}

!^j::Send ^{LEFT}
!^l::Send ^{RIGHT}

!+i::Send +{UP}
!+k::Send +{DOWN}
!+j::Send +{LEFT}
!+l::Send +{RIGHT}
!+h::Send +{HOME}
!+;::Send +{END}
!+u::Send ^+{HOME}
!+o::Send ^+{END}

!+^j::Send +^{LEFT}
!+^l::Send +^{RIGHT}
!+^i::Send +!{UP}
!+^k::Send +!{DOWN}

+^i::Send +^{UP}
+^k::Send +^{DOWN}
#If