// REDESIGNED: Single-State Left-to-Right Parser
CodeMirror.defineSimpleMode("ini-colorful", {
    start: [
        // 1. Comments (Using AHK-style semicolons)
        { regex: /^[ \t]*;.*/, token: "comment" },
        
        // 2. Section Headers [Section]
        { regex: /^[ \t]*\[[^\]]+\]/, token: "header" },
        
        // 3. Keys and '=' Sign - Only triggers at the START (^) of a line
        { regex: /^([ \t]*)([^=]+?)([ \t]*=[ \t]*)/, token: [null, "keyword", "operator"] },
        
        // --- EVERYTHING BELOW RUNS ON THE "VALUE" SIDE OF THE LINE ---
        
        // 4. Inline comments
        { regex: /;.*/, token: "comment" },
        
        // 5. Strings enclosed in Quotes (e.g., "AUTO")
        { regex: /"(?:[^\\]|\\.)*?(?:"|$)/, token: "string" },
        { regex: /'(?:[^\\]|\\.)*?(?:'|$)/, token: "string" },
        
        // 6. Special keywords
        { regex: /\b(?:true|yes|on)\b/i, token: "bool-true" },
        { regex: /\b(?:false|no|off)\b/i, token: "bool-false" },
        { regex: /\b(?:null|toggle)\b/i, token: "atom" },
        
        // 7. Numbers
        { regex: /[-+]?\d+(?:\.\d+)?/, token: "number" },
        
        // 8. AutoHotkey Hotkey Modifiers (^ = Ctrl, ! = Alt, + = Shift, # = Win)
        { regex: /[\^!+#]+/, token: "builtin" },
        
        // 9. Catch-all: Any remaining text becomes standard string
        { regex: /[^;\s]+/, token: "string" },
        
        // 10. Whitespace consumer
        { regex: /[ \t]+/, token: null }
    ]
});

const editorElement = document.getElementById('editor');

// Initialize CodeMirror
const cm = CodeMirror.fromTextArea(editorElement, {
    mode: 'ini-colorful',
    theme: 'darcula', // Base theme, mostly overridden by our style.css
    lineNumbers: true,
    indentUnit: 4,
    scrollbarStyle: 'native' // Allows our custom CSS scrollbars to work!
});

// Load the initial file via AutoHotkey
async function loadFile() {
    if (window.ahk) {
        try {
            const content = await ahk.GetIniContent();
            cm.setValue(content);
            // Wait slightly for DOM to render, then refresh CM so height calculates perfectly
            setTimeout(() => cm.refresh(), 50);
        } catch (e) {
            console.error("Failed to load INI:", e);
        }
    }
}

// Save File function
function saveFile(btn) {
    if (window.ahk) {
        ahk.SaveIniContent(cm.getValue());
        
        // Visual feedback for the custom save button
        if (btn) {
            const oldHtml = btn.innerHTML;
            btn.innerHTML = '<span>SAVED</span>';
            btn.style.background = 'var(--accent)';
            btn.style.color = 'var(--basalt-900)';
            
            setTimeout(() => {
                btn.innerHTML = oldHtml;
                btn.style.background = '';
                btn.style.color = '';
            }, 1000);
        }
    }
}

// Global hotkey for Ctrl+S inside the editor
document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.key.toLowerCase() === 's') {
        e.preventDefault();
        const btn = document.getElementById('saveBtn');
        saveFile(btn);
    }
});

// Run load on start
window.addEventListener('DOMContentLoaded', loadFile);