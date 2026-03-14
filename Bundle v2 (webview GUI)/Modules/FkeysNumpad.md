# FKEYS + NUMPAD MODULE - README
## FUNCTIONALITY
    - Toggles number row keys between F1-F12 and Numpad 0-9, /, -, =.
    - Specifically designed for users who want to switch between function key and numpad functionality without needing a separate keyboard or remapping software.
## REQUIREMENTS
    - Must have a global 'Toggles' object defined in Main.ahk.
    - Only works when 'FkeysNumpad' key is set to 1.
## CONFIGURATION
    - Set the hotkey for toggling between modes in the INI file under [Settings] with the key 'FkeyNumpad_mode'. Default is Ctrl + Alt + T.
    - Set the X and Y position for the on-screen mode indicator in the INI file
        under [FkeyNumpad_config] with the keys 'X' and 'Y'. Default is X: null (centered), Y: 10.
    - The on-screen indicator will only show when Caps Lock is on, serving as a visual reminder of the current mode.