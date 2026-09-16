# Current: Pass Passage By! 1.4.1 (7) — 16 September 2026

Task text defaults to 19 pt, with a separate Task size control (17–28 pt) under Settings → Typography. The native task editor uses 18 pt. Header text buttons explicitly show Add task for a new essay, Edit task when one exists, and Hide task / Show task when relevant. Saving a new task reveals it; deleting clears prompt/images and preserves the essay, with document undo available.

Annotation geometry: task visibility/content changes invalidate old connectors immediately and schedule a fresh TextKit layout after Auto Layout settles. Connector overlay also observes its frame changes, clips drawing to the editor viewport, and converts both note and text anchor points into its own coordinates. Toggling preserves the essay scroll origin. This fixes stale lines appearing in the prompt area. Dense overlapping notes remain a separate manual QA concern.

Settings now uses a compact 700×480 native window with left navigation: Appearance, Typography, Zoom, Dictionary and Tags. Theme/dark mode remain in Appearance; separate essay/task sizes are in Typography. Tag fields have an explicit 270-point width. Numeric fields and steppers stay synchronized. The window factory is testable without showing it.

Validation: bash test.sh covers model, markup, 20 curated sample anchors/word counts and PDF. bash test-layout.sh creates isolated UserDefaults and suppresses draft writes; it exercises task toggling, Add task/save/delete, prompt font, all settings sections and tag input widths with real offscreen AppKit views. Rendered task and Tags layouts were inspected. This is offscreen layout verification, not physical mouse, trackpad, Stage Manager or interactive sheet QA. Build is native arm64 macOS13+, ad-hoc signed; Developer ID, notarization and update feed remain unconfigured as agreed.

Canonical bundle: Pass Passage By!.app; identifier com.passage.editor and Application Support/Passage remain stable. Download dist/PPB-macOS.zip; preview /tmp/PPBPreview/Pass Passage By!.app. Sources include NativeLayoutTests.swift and test-layout.sh. Restore Sparkle via release/bootstrap-sparkle.sh if Vendor is absent from the handoff archive. The 20-sample library and AgentKit behavior below are unchanged.

This section supersedes the historical UI dimensions and QA notes below.

# Current: Pass Passage By! 1.4.0 (6)

Canonical bundle filename is now Pass Passage By!.app, identifier remains com.passage.editor. Preview: /tmp/PPBPreview/Pass Passage By!.app. Download dist/PPB-macOS.zip. Finder adds suffixes when extracting beside existing bundles; app branding never uses PPB! 2. Existing user-installed duplicates have not been deleted.

Task brief: doc.text toggles visibility without deleting data, Edit task opens a compact editor with Done and Delete task. Delete removes prompt and task images, with normal document undo available. Image/text display uses bounded side-by-side layout on wide windows; it no longer stretches children with document-view resizing. Native task view and Quick Setup still require hands-on QA.

Settings: stable 300-point tag inputs and 500-point groups, compact 400-point window, redundant title removed. Quick Setup 460-point height with tighter spacing. Home icon 64 points and masked; native iconset now clips corners to alpha. Alpha tested: corner transparent, centre opaque. The imagegen attempt at transparent background produced holes and was rejected; retained original recolored source and applied a native rounded mask in Icon.swift and home NSImageView. No bitmap retouch of source.

Library now exactly 20: 10 selected Task 1 charts with revised numerical prose and 4 targeted notes each, 10 independently written Task 2 answers with 4 notes each. sample-manifest.json is authoritative. Removed drills and old generator scripts live in outputs/archive, not the shipped app. Edit curated JSON directly and run test.sh; do not run historical generators over this library.

Agent tools on Home: Get skill kit exports AgentKit to a chosen folder; Add skill stores Markdown under Application Support/Passage/Skills (does not execute it); Import result loads agent JSON. AgentKit contains SKILL.md, schema.json, bridge.py and example.json. Bridge assembles quotes with UTF-16 offsets and validates imports. JSON can also be dropped or opened with the app. This is file interoperability, not an in-app LLM or live file watcher. No secret/account required.

Validation: model, markup, 20 sample min-word/anchor tests and PDF tests passed. Agent bridge tested all 20 imports plus repeated Vietnamese quote after emoji. Native build and ad-hoc signature checks passed. No native CUA tool available this turn; do not claim interactive verification or production readiness. Sparkle feed/signing remain unconfigured as agreed. Packaging retains historical ID/draft path to protect existing work.

Build: bash build.sh; test: bash test.sh. Read AgentKit/SKILL.md to generate arbitrary topics and annotation goals. This section supersedes historical notes below.

