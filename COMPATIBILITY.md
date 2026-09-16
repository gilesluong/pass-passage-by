# Passage writing compatibility

Reference: https://help.ulysses.app/general/keyboard-shortcuts-mac-ipad and https://help.ulysses.app/introduction/markdown-xl (consulted 14 September 2026).

## Implemented
Native source editing with styling for headings, strong, emphasis, code, quotes, lists, links, highlight, comment, redaction and brace annotations. Delimiters stay in editable MD/TXT source; this is not Ulysses' concealed text-object model. JSON source/annotation compatibility remains intact.

`{note}` is recognized outside code and escaped braces, displayed as an underlined source span and connected to alternating margins. Clicking its margin note selects the editable body inside the braces. Derived inline notes are regenerated from source, not duplicated into JSON annotation records.

Command-B and Command-I toggle source delimiters; Command-K inserts a Markdown link. Command-backslash inserts a heading. Command-L clears supported formatting in the selected source. Command-9 opens the markup menu. Command-F/G/Shift-G use native find. Command-S saves the draft. Command-6 opens export. Command-3 focuses writing; Command-4 toggles margin annotations. Command-period toggles presentation. Control-Command-F toggles fullscreen. Command-plus/minus/zero adjust text size. Option-Command-plus/minus control semantic zoom. Option-Command-L toggles dark appearance. Standard native editing keys remain available.

Settings is a separate fixed-size window: General, Styles, Zoom, Dictionary. General offers numeric size, line spacing, paragraph gap, first-line indentation and text width. Student zoom uses Essay → Word; Teacher uses all four levels; Custom optionally includes paragraph/sentence. Pointer hover follows the next configured step.

## Not full Ulysses compatibility
No Ulysses library/groups/filters, multiple document tabs, split editors, revision history browser, publishing, table-cell navigation, embedded media/text objects, equation rendering or styled PDF/DOCX export. Image/footnote/equation/raw/TOC menu items insert source templates only. Smart lists and tag completion are not implemented. This is a native writing compatibility layer, not a clone of all Ulysses features or its file format. Do not describe it as complete Markdown XL support.

## Validation
Build and ad-hoc signature verification pass. MarkupTests covers Unicode brace anchors, code/escaped-brace exclusion, formatting toggle and configurable routes. ModelTests covers JSON and annotation rebasing. Settings window and Zoom preset controls were inspected through native UI. Final editor shortcut/gesture QA was interrupted by the user interacting with the app; don't claim that end-to-end test passed.
