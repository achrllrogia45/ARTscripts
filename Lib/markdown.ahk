; ==============================================================================
; MARKDOWN PARSER LIBRARY - AHK v2
; ==============================================================================

ParseMarkdownToHTML(markdownText) {
    global IniFile
    ; 1. Read the theme directly from mode.ini [Setting]
    themeMode := IniRead(IniFile, "Setting", "mode", "dark")

    ; 2. Inject a tiny script to force the theme immediately upon loading
    html := "<script>document.documentElement.className = '" themeMode "';</script>`n"

    ; 3. Convert Markdown (No HTML boilerplate needed)
    parsedText := RegExReplace(markdownText, "m)^# (.*?)\s*$", "<h1>$1</h1>")
    parsedText := RegExReplace(parsedText, "m)^## (.*?)\s*$", "<h2>$1</h2>")
    parsedText := RegExReplace(parsedText, "m)^### (.*?)\s*$", "<h3>$1</h3>")
    parsedText := RegExReplace(parsedText, "\*\*(.*?)\*\*", "<strong>$1</strong>")
    parsedText := RegExReplace(parsedText, "\*(.*?)\*", "<em>$1</em>")
    parsedText := RegExReplace(parsedText, "\x60(.*?)\x60", "<code>$1</code>")
    parsedText := StrReplace(parsedText, "`n", "<br>")

    return html . parsedText
}