; ---------------------------------------------------------------------------
; Combined AutoHotkey v1 Script
; Features:
; - F8 toggles "Always On Top" for the active window with a splash confirmation
; - Middle mouse button acts as hand tool in Adobe apps (Photoshop, InDesign, Acrobat, etc.)
; ---------------------------------------------------------------------------

#NoEnv
#SingleInstance, Force
SendMode Input

; --- Adobe App Group Definition ---
GroupAdd, AdobeMMButton, ahk_exe Photoshop.exe
GroupAdd, AdobeMMButton, ahk_exe InDesign.exe
GroupAdd, AdobeMMButton, ahk_exe AcroRD32.exe
GroupAdd, AdobeMMButton, ahk_exe Acrobat.exe
GroupAdd, AdobeMMButton, ahk_exe Muse.exe
; Add more Adobe apps here if needed

; --- Hotkey: F8 - Toggle Always On Top ---
F8::
{
    WinSet, AlwaysOnTop, Toggle, A
    SplashTextOn, 250, 30, AOT Status, Always On Top Toggled
    SetTimer, RemoveSplash, -1000
}
return

RemoveSplash:
{
    SplashTextOff
}
return

; --- Context-Sensitive Hotkey: MButton in Adobe Apps ---
#IfWinActive ahk_group AdobeMMButton
MButton::
    Send {Space Down}{LButton Down}
    KeyWait, MButton
    Send {LButton Up}{Space Up}
return
#IfWinActive