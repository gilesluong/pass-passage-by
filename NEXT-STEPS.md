# Implementation update — initial separation slice

Implemented locally: PRODUCT-VISION.md records the full long-term direction. NotePresentation.swift stores an explicit document-ID/note-ID surface preference. Historical notes remain margin annotations regardless of kind. Comments.swift adds an independent right inspector, selected passage navigation and edit flow. New comments are routed only to the inspector. Move to comments/margin preserves the Note object. Margin cards are now compact, borderless and directly clickable; auto-save remains. Fixed the missing popover contentViewController assignment.

Validation: strict lint, core tests and native layout tests pass; preview build succeeds. Native tests cover legacy preservation, role persistence/document isolation, no duplicate margin rendering, edit, conversion, creation and document undo/redo. Offscreen render inspected. Live full-size interaction remains to be checked.

Limits before a public release: surface preferences live in UserDefaults, NOT in exported JSON/MD or a portable sidecar. The original note data is fully preserved, but importing on another machine returns to legacy margin presentation. Conversion is reversible via Move, not yet integrated into text undo history. No replies, authors, resolution or online collaboration yet. Inline brace notes cannot be moved until their materialization/anchor semantics are designed. Add portable metadata and roundtrip tests before shipping this separation in Sparkle. Current version remains 1.9.4; only preview build changed.

Next: (1) portable presentation sidecar + import/export/MCP contract, (2) conversion undo and dense/narrow-window interaction tests, (3) comment indicators in text and live keyboard/accessibility review. Do not advertise the roadmap as complete.

---

# PPB continuation — 17 September 2026, evening

## Verified baseline
HEAD before this pass: deb4372, version 1.9.4 (18). Read AGENTS.md and latest HANDOFF-ANTIGRAVITY.md. Antigravity's templates and modifier isolation are retained. This pass disables home wallpaper loading; it does not claim to have rebuilt the editor or separated comments yet. No new release/version is published by this pass. Validation: strict lint and test.sh passed; test-layout.sh passed with system dictionary access outside sandbox.

## Priority order
1. **P0: Separate annotation and comment interactions while preserving data.** This is editor architecture, not decorative styling. Passage.swift renderNotes currently sends every nonempty visible note to left/right columns and distinguishes comment only by kind/color/border. openCommentPopover shares all controls. That explains continued duplication.
2. **P0: Quiet workspace.** Wallpaper loading removed now. Next: neutral sidebar, one restrained header, readable document column, optional comments inspector, subtle dividers. Use the supplied ZCode screenshot as direction; do not copy a chat transcript layout into an editor. Keep semantic zoom and dictionary.
3. **P1: Reliable complete editor foundation.** Verify save/reopen/recovery, undo/redo across text and notes, selection/IME/Unicode anchor remapping, headings/lists/links/code/images, keyboard navigation, find/replace and consistent PDF plus MD/JSON export. Audit existing capabilities before building replacements.
4. **P2: Agent/human discussion.** Introduce explicit thread IDs, messages, author identity, timestamps and resolved state in a separate versioned sidecar after reviewing storage/export compatibility. Local replies are not multiplayer. Real collaboration requires identity, transport, access control and conflict handling; do not advertise it until implemented.
5. **P3: Templates, tag presets, Loom-specific polish and monetized showcase.** Defer until the editing and note flows are stable. Do not try to match all of Notion in one release.

## Interaction contract
- Annotation: short freeform context, state or quick observation. No objective/subjective requirement. Two quiet lines in the margin; click to edit inline or in a small anchored popover. One optional color/tag. No mandatory title, citation form, Save/Cancel or Read note button. Full existing content remains available without truncating stored text.
- Comment: selection action and Option-Command-M open a right inspector. Small anchor indicator/count in document; full feedback appears only in inspector, not duplicated across both margins. Clicking the indicator focuses its entry; clicking an entry reveals its anchor. Closing inspector restores editor space without losing the selection.
- Existing historical kind=comment includes earlier generic annotations. Do NOT bulk convert by kind or text length. Preserve records and provide an explicit reversible Move to annotation/comment action. Decide an ID-keyed presentation sidecar or another compatible mapping before coding; Model.swift remains frozen.
- Shared anchors are allowed (one passage may have both context and feedback). Duplication means duplicated UI/data instances, not simply equal anchor ranges.
- No new decorative wallpaper, gradients behind text, emoji-heavy borders or permanent floating controls. Covers may remain inside featured content cards.

## Implementation slices / acceptance
A. Extract a presentation policy outside Model.swift and test routing, legacy fallback, conversion and roundtrip. No document loss or automatic semantic reclassification.
B. Add comments inspector before removing margin comment UI. Reuse existing persistence initially; do not hide comments with no accessible replacement. Tests: create/edit/reopen/delete, two comments on same anchor, one annotation plus one comment, undo and Unicode edits.
C. Simplify margin annotation editing and layout. Test dense overlapping anchors, long stored notes, narrow window, task collapse/expand and scrolling. No layout loop or note-dependent movement of body text.
D. Apply neutral native surfaces and typography. Test light/dark, keyboard focus, Reduce Motion, Stage Manager/fullscreen and scaled displays. Screenshot tools have historically returned thumbnails; full-size manual visual QA remains outstanding.
E. Only then package a new numbered Sparkle update. bash lint.sh, bash test.sh, bash test-layout.sh must all pass before commit. Never overwrite installed Applications bundle.

## Design reference / MCP
Reviewed https://github.com/Nutlope/inspo : read-only design references via MCP, hosted endpoint https://inspomcp.dev/api/mcp. Not installed or invoked in this pass. Use for desktop workspace/sidebar/inspector references, not generic landing pages. No private essays or user documents should be sent as design queries. The ZCode screenshot is the concrete current visual reference; no claim that Prism was inspected.

## Handoff cautions
Old HANDOFF-TO-CODEX.md contains obsolete manual rsync installation instructions and fabricated partner claims; treat as historical only. AGENTS.md plus this file and newest HANDOFF-ANTIGRAVITY entry take precedence. Model/schema freeze remains. No Llama or Apple Intelligence package downloads over hotspot. Do not report all UI tests as proof of visual quality.
