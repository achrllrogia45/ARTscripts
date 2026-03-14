; ==============================================================================
; MARKDOWN PARSER LIBRARY - AHK v2
; ==============================================================================

ParseMarkdownToHTML(markdownText) {
    html := "<!DOCTYPE html><html><head><meta http-equiv='X-UA-Compatible' content='IE=edge'><style>"
    html .= "
    (
        body { 
            background-color: #1e1e1e; 
            color: #e0e0e0; 
            font-family: 'Inter', 'Segoe UI', sans-serif; 
            font-size: 13px; 
            margin: 15px; 
            overflow-y: auto; 
            overflow-x: hidden; 
            border: none; 
        }
        h1 { 
            font-size: 18px; 
            color: #00ff88; 
            margin-top: 0; 
        }
        h2 { 
            font-size: 14px; 
            color: #00ff88; 
            border-bottom: 1px solid #333; 
            padding-bottom: 4px; 
            margin-top: 16px; 
        }
        h3 { 
            font-size: 13px; 
            color: #00ff88; 
        }
        p { 
            line-height: 1.4; 
            margin-top: 4px; 
            margin-bottom: 8px; 
        }
        ul { 
            padding-left: 20px; 
            margin-top: 4px; 
        }
        li { 
            margin-bottom: 4px; 
        }
        code { 
            background-color: #2b2b2b; 
            padding: 2px 4px; 
            border-radius: 4px; 
            font-family: Consolas, monospace; 
            color: #ff88a0; 
            font-size: 12px; 
        }
        
        /* Webkit Scrollbar (if modern control is used) */
        ::-webkit-scrollbar { 
            width: 4px; 
        } 
        ::-webkit-scrollbar-track {
            background: rgba(0, 0, 0, 0.1);
        }
        ::-webkit-scrollbar-thumb {
            background: #333;
            border-radius: 4px;
        }
        ::-webkit-scrollbar-thumb:hover {
            background: #00ff88;
        }

        /* IE/ActiveX Fallback Scrollbar */
        body { 
            scrollbar-face-color: #333333; 
            scrollbar-track-color: #161618; 
            scrollbar-arrow-color: #00ff88; 
            scrollbar-shadow-color: #333333;
            scrollbar-darkshadow-color: #161618;
            scrollbar-highlight-color: #161618;
            scrollbar-3dlight-color: #333333;
        }
    )"
    html .= "</style></head><body>"

    ; Convert Markdown Headings
    parsedText := RegExReplace(markdownText, "m)^# (.*?)\s*$", "<h1>$1</h1>")
    parsedText := RegExReplace(parsedText, "m)^## (.*?)\s*$", "<h2>$1</h2>")
    parsedText := RegExReplace(parsedText, "m)^### (.*?)\s*$", "<h3>$1</h3>")
    
    ; Convert Bold and Italics
    parsedText := RegExReplace(parsedText, "\*\*(.*?)\*\*", "<strong>$1</strong>")
    parsedText := RegExReplace(parsedText, "\*(.*?)\*", "<em>$1</em>")
    
    ; Convert Inline Code (using hex for backticks \x60 to prevent escaping issues)
    parsedText := RegExReplace(parsedText, "\x60(.*?)\x60", "<code>$1</code>")

    html .= parsedText . "</body></html>"

    return html
}
