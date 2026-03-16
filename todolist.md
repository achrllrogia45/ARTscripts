# To-Do List & Project Roadmap

## 🚀 1. Core Features & UI Integration

*This section tracks user-fa  cing features and GUI implementation in the WebView.*

- [ ] **Add Version Display**
    - [ ] Add version number (e.g., v2.0.0) in the `index.html` footer or navbar.
    - [ ] Fetch the version dynamically from `main.ahk` or hardcode it in the HTML.
- [ ] **About / Profile Section** (Create a dedicated modal or separate view)
    - [ ] GitHub profile: Add a badge or link with an icon.
    - [ ] Reddit profile: Add link/contact info.
    - [ ] LinkedIn profile: Add professional networking link.
- [ ] **GUI Enhancements (Bootstrap)**
    - [x] Implement responsive sidebar navigation (utilizing `sidebars.js`/`sidebars.css`).
    - [ ] Redesign total UI integrated with Bootstrap.
    - [ ] Enable theme toggling (Dark/Light mode) using the included `color-modes.js`.
    - [ ] Enable new icon for manual reorder list integrated with `mode.ini` 

## ⚙️ 2. Architecture & Modularity

*This section focuses on how the AHK scripts interact with each other and the WebView.*

- [ ] **Module Organization**
    - [ ] Rename placeholder scripts (`a.ahk`, `b.ahk`, ..., `g.ahk`) in the `Modules/` folder to descriptive names (e.g., `WindowSnapper.ahk`).
    - [x] Implement a dynamic loader in `modules.ahk` to include all scripts in the `Modules/` directory automatically or via an array.
- [x] **State & Configuration Management (mode.ini)**
    - [x] Write a robust function to read/write settings to `mode.ini`.
    - [x] Sync `mode.ini` settings with the Webview interface on load so checkboxes/switches reflect the actual saved state.
- [x] **AHK <-> JS Communication**
    - [x] Standardize the message-passing system using `WebViewToo.ahk` and `Promise.ahk`.
    - [x] Use `ComVar.ahk` securely if passing large objects or arrays between AHK and JS is required.

## 🧹 3. Refactoring & Cleanup

*Items to keep the codebase clean and avoid technical debt.*

- [x] **Code Refactoring**
    - [x] Add automatic config making into 'mode.ini' (for each file inside main.ahk detecting #include) if it doesn't exist, instead of relying on manual creation and hard code inside the main script.
    - [x] Consolidate overlapping logic between `AltArrow`, `CursLock`, and `FkeysNumpad`.
    - [x] Add standard Header Comments and inline documentation to all custom AHK files.
- [x] **Asset Management**
    - [x] Optimize Bootstrap assets (if custom icons or fonts are added to `Pages/Bootstrap/fonts/`).

## 🗑️ Tasks to Avoid / Remove (Anti-Goals)

*Things to explicitly NOT track here to prevent clutter:*

- ❌ Micro UI tweaks (e.g., "change button padding from 5px to 8px"). Handle these iteratively during a design session.
- ❌ "Fix bugs" without specifying *which* bug. Always document the specific reproduction steps for a bug instead of a generic task.
- ❌ Deprecated Bundle v1 features that won't make it to v2. 