# Current: Pass Passage By! 1.8.1 (13) — 17 September 2026

Fixes from user feedback: nested shelves forward vertical scroll directly to HomePageScrollView; carousel locks gesture axis and accepts at most one transition per gesture, ignoring momentum. There was no auto-advance timer; repeated inertia was the cause. All New Document types now create blank writing and no preset prompt. The obsolete baked-in IELTS/discursive examples have been removed from creation handlers; bundled samples remain.

Build and native regression tests pass, including horizontal swipe/momentum, vertical axis lock, and blank creation for all three typed documents. Installed update must use Sparkle, never manual overwrite. Release verification to follow. Full-size Stage Manager gesture QA remains a limitation of the current screenshot tool.

---

# Current: Pass Passage By! 1.8.0 (12) — 17 September 2026

Prepared update: horizontal page lock, live full-text search, direct task editing, tighter Discover cards and four open-license PLOS reading selections. See design-qa.md for verified behavior and visual QA limits. Release v1.8.0 is public. The installed app upgraded from 1.7.0 through Sparkle and relaunched successfully; Info.plist reports 1.8.0 (12), and the executable SHA-256 matches the release build.

Reading/assemble.py regenerates JSON offline from checked-in official PLOS XML. Reading/LICENSES.md preserves authors, DOI, license and selection details. Review article license is CC BY with no version specified in the source; do not invent a version. User text, library, bundle ID and data paths remain unchanged. Do not manually overwrite the installed app; use Sparkle only. No Llama or Apple Intelligence downloads on hotspot.

Both test suites passed. Live native search for interpolated returned the correct full-text result. Full-size screenshot capture was unavailable (Stage Manager thumbnail); do not describe the entire UI as visually certified. All four readings contain five validated notes each. Existing IELTS samples are unchanged.

---

# Current: Pass Passage By! 1.7.0 (11) — 17 September 2026

Release v1.7.0 is live at https://github.com/gilesluong/pass-passage-by/releases/tag/v1.7.0. On 17 September the user changed the canonical repository to PUBLIC. Both the canonical and legacy redirected feed URLs return HTTP 200 without authentication. The installed app updated through Sparkle from 1.6.0 (9) to 1.7.0 (11), relaunched successfully, passed codesign --verify --deep --strict, and its executable SHA-256 matches the release build. No manual overwrite or separate public repository was needed. The installed SUFeedURL now points to the canonical repository. This supersedes the previous private-feed blocker and all historical release/installation instructions below.

## Product direction and implementation
- Native AppKit remains the editor. Antigravity changes from a32c0dc and its uncommitted Home/Passage work were preserved.
- Apple TV-style Home: fixed sidebar, large photographic carousel, horizontal shelves, functional category/search filtering, compact-window wrapping. Cards use actual document titles and notes. No invented teachers, institutions, scores or studies. Pin saved library writing to Home; future paid placements are not implemented.
- Hover highlight defaults to holding Option. Option-H switches persistent highlight on/off. The pointer still selects the zoom target. Selection reveals a floating Comment action; Option-Command-M adds a comment.
- Settings: 760×540 sidebar, theme previews, appearance, typography, zoom, dictionary, tags, updates and intelligence controls. Zoom chips move between active path and available steps; Essay and Word are required. Reduce Motion respected.
- AgentConnection.swift and AgentKit/mcp_server.py expose explicit shared snapshots via stdio MCP and place newly generated JSON in Inbox. No library-wide access, API account, model download, or silent document replacement. Copy MCP setup, share current writing, then review/import Inbox. File skill/prompt exchange remains available for hosts without local MCP. Third-party host end-to-end setup is not yet verified; subscription support varies by host.
- Research creation now uses an honest blank notes template. Model.swift, Markup.swift, all 20 samples and existing user documents were preserved.

## Build and release invariants
- Bundle ID com.passage.editor, name Pass Passage By!.app, Application Support/Passage data path remain stable.
- bash build.sh builds only dist and /tmp/PPBPreview. NEVER overwrite ~/Applications manually: installed updates must go through Sparkle.
- Sparkle 2.10.0, Ed25519 signing key stays in Keychain account com.passage.editor. Canonical feed: https://github.com/gilesluong/pass-passage-by/releases/latest/download/appcast.xml.
- bash release/prepare-update.sh verifies the archive and signature; bash release/publish.sh publishes a new immutable version. Never replace an existing release tag/archive.
- Development ad-hoc signing only. Developer ID/notarization still pending user account. Do not present as notarized production software.
- User is on hotspot: do not install/download Llama or Apple Intelligence model packages.

## Verification and follow-up
- bash test.sh PASS: model/Unicode edits, markup and routes, all 20 samples, PDF, stdio MCP handshake/scoped context/quote validation/non-overwrite.
- bash test-layout.sh PASS outside sandbox: native OCR/dictionary, task/annotation geometry, all settings, compact Home, pointer policy/search restoration/tap zoom/student navigation.
- Native UI: Home, Settings Appearance and Zoom visually inspected in the running preview. Zoom chip interaction checked via accessibility and mouse. Agent connection controls verified through accessibility; its screenshot was a Stage Manager thumbnail.
- Agent kit uses Python 3 standard library; a compatible MCP host plus Python 3 is needed. No host configuration is silently modified.
- Next polish: per-document showcase cover management, real host MCP session validation, dense annotation and Stage Manager visual QA. Current carousel deliberately reuses one original illustration.

## Asset provenance
Assets/reading-cover.png was generated with imagegen on 16 September 2026 for this app: an open book and lamp in a forest-toned reading room, with negative space for the carousel title. Existing user-approved logo unchanged.

---

# Current: Pass Passage By! 1.5.0 (8) — 16 September 2026

## Summary of Changes
- **Crash Fix on Launch**: Guarded `root` in `Passage.swift`'s `updateRootBackground()` (`guard let r = root else { return }`). Previously, `applicationDidFinishLaunching` called `applyAppearance()` before `showHome()` -> `base()` initialized `root`, which unwrapped `root!` on `nil` and threw `SIGTRAP`.
- **Prevent Crash Recovery Loops**: Added `<key>ApplePersistenceIgnoreState</key><true/>` and `<key>NSQuitAlwaysKeepsWindows</key><false/>` in `Info.plist` to stop macOS from restoring broken window state alerts.
- **Apple Liquid Glass Redesign (Home.swift)**:
  - `SidebarItemButton`: Replaced the hardcoded width-194 gray rectangle block with clean, transparent sidebar items featuring medium-weight SF Symbols, `.labelColor` text, and smooth 8pt rounded hover highlights via `mouseEntered`/`mouseExited`.
  - `CardActionPill`: Replaced full-width stretched dark button with an Apple-grade centered 180pt capsule button ("Read annotations  →") with specular rim stroke and high-contrast electric accent tint.
  - `GlassPillButton`: Frosted glass capsule pill for "Explore all 20 practice essays →", "About", and "Quick setup".
  - `HomeCard`: 18pt super-ellipse corners, specular rim stroke, Georgia font excerpt, bright electric cyan badge.
  - `truncateWords`: Replaced blunt mid-word cutoffs with clean word-boundary truncation with `…`.
- **Dynamic Appearance & Backdrop**:
  - `Brand.swift` `PaperBackdrop.draw(_ dirtyRect: NSRect)` dynamically fills `#1c1f26` (Dark) or `#f5f5f7` (Light) based on `effectiveAppearance`.
  - `Passage.swift` `isDarkMode()` coordinates system appearance with user preferences across all components.
- **Automated Layout Tests**:
  - `NativeLayoutTests.swift` captures both Dark Mode (`/tmp/ppb-home-layout.png`) and Light Mode (`/tmp/ppb-home-layout-light.png`).
- **Sparkle 2.10.0 Distribution**:
  - Appcast updated in `dist/updates/1.5.0/appcast.xml` with Ed25519 signature.
  - Binaries synced to `/tmp/PPBPreview/Pass Passage By!.app`, `/Users/roastmetoasty/Applications/Pass Passage By!.app`, and `dist/Pass Passage By!.app`. Zip at `dist/PPB-macOS.zip`.

## Frozen Invariants (Strictly Do NOT Modify)
- Document models: `Model.swift`, `ielts-semantic-breakdown/version1`, `example.breakdown.json`, and all 20 sample files in `Samples/` are frozen and must remain 100% untouched.
- Bundle ID: `com.passage.editor`.
- macOS target: macOS 13.0+ native arm64 (Swift 5, Cocoa / TextKit / PDFKit / Sparkle).

This section supersedes the historical sections below.

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

# Current: PPB! 1.3.1 (5) — 15 September 2026

Task brief and images now live in a bounded scrollable panel pinned above the writing area; no automatic Task images popup. Add/drop/remove refreshes that panel. Its height is capped at 32% of the window (240 points maximum), and resize recomputes text wrapping. Quick Setup has Done and Escape, closes its sheet without loading/replacing an essay.

Logo: user-supplied p/page design edited with image_gen into forest teal, ivory and brass; no corner watermark. Assets/ppb-icon.png is the selected asset. Icon.swift packages it; provenance/prompt in Assets/LOGO-PROVENANCE.md. Input image was not overwritten.

Library: 105 documents. 100 existing Task 1 chart drills now include rendered bar charts, task headings, timing and minimum-length instructions. 5 individually written Task 2 essays cover opinion, discussion, causes/solutions, outweigh and qualified agreement, with four specific argumentative annotations each. Task 1 now includes an additional comparison annotation. These are original practice materials, not official IELTS questions or band-scored answers. The Task 1 drills still share templates; do not present them as 100 independently authored varied exams. Keep this distinction visible.

Reference for task format: https://ielts.org/take-a-test/test-types/ielts-academic-test/ielts-academic-format-writing . Source papers were consulted for format only, not copied into the library. The user's supplied Cambridge sample image remains a reference, not bundled content.

Rebuild library with bash rebuild-samples.sh (generator, curated task2, native chart rendering, anchored annotations fixture). Tests: bash test.sh. Current tests passed model/markup, 105 sample min lengths/anchors and PDF extraction. Task 1 chart rendered and visually checked. Native build and ad-hoc signature verification passed. Native UI automation is unavailable in this continuation, so pinned panel and Done/Esc still need physical UI QA; do not claim tested clicks or Stage Manager gestures. Sparkle remains unconfigured as agreed. Download dist/PPB-macOS.zip, preview /tmp/PPBPreview/PPB!.app.

This section supersedes the historical sections below.

# Current build — 15 September 2026, 1.3.0 (4)

Latest user iteration: direct Add image opens NSOpenPanel, file URL drop receivers exist on WritingView and PaperBackdrop; valid images are stored in JSON and shown beside the writing in the reference window. Share opens native PDFKit preview, native sharing picker, PDF export or a folder containing essay.md + annotations.json. PDF uses fixed writing column and both note margins; full note details and images are appended so long annotations are retained. See Share.swift.

Annotation popover now auto-persists body/title/tag changes. No Save/Cancel buttons. TextView delegate callbacks MUST check editor identity so comment typing never modifies essay text. Persistence is debounced 300ms; closing popover flushes and redraws margin notes without replacing the essay. Remove action remains. Appearance is the first Settings tab; theme/dark controls are visible and dark hover alpha is stronger. Native popover motion honors Reduce Motion.

100 synthetic Task 1 practice answers bundled under Samples (20 topics x 5 numerical patterns), each with data table prompt and two annotations. These are original controlled-template learning examples, not official IELTS questions, scores, nor 100 independently researched essays; Task 2 library remains future expansion. Home Example library opens these; selecting one opens its task data reference window.

Validation: bash test.sh passed model/markup/PDF tests, 100 JSON and source-anchor checks. PDF first page rendered and visually inspected with both margins. App build and ad-hoc signature verification passed. Settings AX confirmed Appearance, Dark mode, Theme, Font and Hover effect. Native capture intermittently failed with ScreenCaptureKit -3811; drag/drop and full native share handoff need physical end-to-end QA. No public release feed/signing configured, as agreed. See release/README.md. Sources remain AppKit/TextKit, not a web wrapper.

Build: bash build.sh. Tests: bash test.sh. Current artifact: dist/PPB-macOS.zip. Preserve com.passage.editor and Application Support/Passage. Prior notes below are historical and superseded where contradictory.

# Current build — 15 September 2026, 1.2.0 (3)

Native AppKit/TextKit. Current download: dist/PPB-macOS.zip; preview: /tmp/PPBPreview/PPB!.app. Run bash build.sh. Stable bundle ID com.passage.editor preserves local drafts and preferences.

Implemented: existing and brace-derived annotation edit popover (double-click marked text or click margin title), editable title/body, color flags and renameable Tags settings. Brace annotation body is independent of anchored text; deleting it unwraps braces. Metadata changes preserve scroll origin; text styling/notes refresh is debounced 120ms. Task images can be added/removed in a separate native reference window and persist in JSON (12 images, 8MB each, 48MB total). MD/TXT is text only, stated in export UI. Sparkle 2.10.0 is embedded but inactive until configured; see release/README.md.

Validation: release-preview compilation and ad-hoc deep signature verification passed. Model and markup tests passed, including old JSON compatibility, image/tag roundtrip, brace override deduplication and custom zoom routes. Native UI: opened existing annotation, changed body via AX, saved and verified new margin text. Task image window and image open panel verified. End-to-end image selection via automation hit clipboard timeout; physical gesture/double-click and dense-note layout still need manual QA. Do not claim production readiness: no Developer ID, notarization, feed, or public key. User explicitly chose release preparation only. Dictionary private APIs need distribution review.

Old workspace app bundles/ZIPs were moved to outputs/archive outside this source directory. Do not delete Application Support/Passage, drafts, or unrelated apps. Source handoff excludes Vendor and app artifacts; release/bootstrap-sparkle.sh restores the checksum-pinned framework. Legacy handoff below is historical; this section takes precedence.

## 15 September — Pass Passage By!
Rebranded display name/icon/home/about; bundle ID and data paths retained. New deliverable Pass-Passage-By-macOS.zip. Read BRAND.md. Brace-note ordering corrected (inline notes now sort with persisted notes by source offset); source text no longer turns orange. Margin cards constrained to viewport, dense collisions still warrant visual QA. Custom checkbox edits select Custom automatically, update route preview, clear stale pointer/gesture state, reset to Essay. Native UI verified Student → Custom and Essay → Sentence → Word after unchecking Paragraph. Later CUA timeout prevented final gesture verification. Regression tests cover mixed note order and every custom route.

## 15 September — active implementation
Read COMPATIBILITY.md first. Toolbar removed entirely. Settings is now a native window, numeric controls, General/Styles/Zoom/Dictionary. Markup.swift adds source styling, inline brace annotations and configurable semantic routes; compiled via build.sh. MarkupTests.swift is a separate test target, not part of the app. Older descriptions below are historical and superseded. User asked for Ulysses compatibility; full Ulysses features are NOT all implemented—see explicit gaps. Latest tests/build passed; final UI QA interrupted by user interaction.

## Current polish
Annotation background removed: persistent marks are underlines. Pointer highlight offers Solid, Gradient, Stardust, with Reduce Motion respected and timer only while hovering. Settings grouped Appearance/Reading/Dictionary. Home labels restored and recent opened files recorded through NSDocumentController. Dictionary list filtered using actual Contents/Resources/Body.data; UI verified reduced list with Lạc Việt/Oxford. Old Swift rewrites and duplicate Passage 2.app moved to ../Passage-legacy-archive.zip (verified archive). Physical animated hover and recent-file reopening remain for manual QA.

## Pointer zoom correction
WritingView now stores pointerIndex separately from insertion focus. Every zoom gesture event updates the pointer target (including phase-less mouse wheels); zoom-in and level dock consume it before rendering. Rendering clears obsolete local offsets. Hover uses a purple outline drawn after text, never a temporary background attribute, so annotation backgrounds remain visible. Build/signature verified; physical hover and trackpad validation remains pending.

## Latest follow-up
Native welcome screen replaces web upload hero. Duplicate dock Settings removed; Word heading deduplicated. Window event monitor handles zoom outside editable text. Dictionary chooser added in Settings and Quick setup; native runtime lists installed dictionaries. Gesture feel and selected-dictionary lookup need further hands-on verification; UI QA interrupted by user interacting with app.

# Latest restoration — 14 September 2026

Read DESIGN-REFERENCE.md first. The user rejected the previous Antigravity visual redesign. Active native source has now restored the original serif canvas hierarchy, bottom dock, presentation, visible anchored margin notes and concise Word dictionary view. Antigravity-before-restore.swift is an archive and must not be compiled.

Build and signature verification succeeded. Native UI was opened and checked for Essay annotations and automatic Word lookup. Model tests are rerun with the bundled example. Physical Stage Manager, trackpad hover/zoom feel and import/export dialogs still require hands-on verification. Do not represent earlier launch rejection as an active blocker: later native launches succeeded.

# Passage native macOS — Antigravity handoff

## User goal
Priority 1: REAL native macOS editor, not a WKWebView wrapper. Priority 2: automatically show macOS dictionary definitions on entering Word zoom, no shortcut. Preserve four semantic levels, editing, MD/TXT literal text, annotation JSON, Settings, sample essay. User explicitly asked to prioritize a handoff before Codex usage runs out. Continue autonomously within this scope.

## Locations
This directory `outputs/passage-macos` holds native source. Sibling `../semantic-editor` is the working React website with its own Git repository; do not modify or redeploy it for native work.

- Passage.swift: active AppKit UI, NSTextView/TextKit editor, NO WKWebView.
- Model.swift: Codable JSON schema, UTF-16 validation/rebasing, semantic ranges.
- ModelTests.swift: standalone model tests.
- Hybrid-archived.swift: OLD WKWebView wrapper, NOT compiled.
- build.sh: native compile + icon + ad-hoc-sign + ZIP.
- Icon.swift, package-icon.py: vector icon drawing and ICNS packing.
- Info.plist: com.passage.editor, Apple Silicon, macOS 13+.
- Passage.app here is an intermediate build. Signed app is staged at /tmp/PassageNativeBuild/Passage.app because Documents file-provider FinderInfo attributes break codesigning.
- Passage-macOS.zip MUST be regenerated before delivery; may still contain OLD hybrid build until build.sh completes.

## Implementation
Native AppKit window/home/settings, NSOpenPanel/NSSavePanel, NSTextView editing, annotation sidebar and edit sheet, four zoom levels, UserDefaults settings. Draft: ~/Library/Application Support/Passage/native-draft.json. No network/server/React/WebKit dependency in active source.

Dictionary: DCSCopyTextDefinition automatically queried 180ms after Word entry, with cache and cancellation of queued obsolete work. Main-queue lookup may need a serial worker if slow. Word definition panel replaces note pane.

Zoom: magnify and Command-scroll accumulated deltas, 400ms cooldown; segmented control and Cmd+/- fallback. Fade/scale animation is an initial transition, NOT yet verified smooth anchor-preserving zoom. Do not claim physical trackpad performance.

MD/TXT stays literal UTF-8. JSON format ielts-semantic-breakdown/version1 contains source and notes. Exact UTF-16 [start,end) quote anchors. Sample copied from ../semantic-editor/public/example.breakdown.json.

## Build and model tests
From this directory:

    bash build.sh
    swiftc -module-cache-path /tmp/passage-swift-cache Model.swift ModelTests.swift -o /tmp/passage-model-tests
    /tmp/passage-model-tests ../semantic-editor/public/example.breakdown.json
    codesign --verify --deep --strict /tmp/PassageNativeBuild/Passage.app
    otool -L /tmp/PassageNativeBuild/Passage.app/Contents/MacOS/Passage

Uses Swift 6.4 with Swift5 language mode, arm64 macOS13 target. Writable module cache avoids sandbox errors. Python3 packs ICNS because iconutil failed. No npm step needed anymore.

## Validation and launch restriction
- Native Swift compiles (only string Selector warnings).
- Staged native codesign verification passed.
- Model tests were launched but result was not collected before a session interruption; rerun.
- Native app NOT interactively tested yet.
- Earlier HYBRID launch was rejected by auto-review: self-built macOS software needs confirmation immediately before execution. Do not bypass via shell open/direct executable/alternate path. User subsequently requested native plan, said autopilot, then continue and handoff. Use normal UI tool and existing authorization if permitted; if rejected again, finish unaffected work and ask for explicit first-run approval with stated reason. Model tests are independent of UI launch.

## Next actions / known risks
1. Verify model tests and complete build.sh. Confirm ZIP has native executable, no WebKit/Web assets.
2. Launch via approved UI tool; if first-run approval is required, ask once.
3. Layout QA: vertical NSStackView alignment .width compiles but may need .leading plus explicit width constraints. NSTextView/scroll document sizing (especially zero-frame dictionary view) needs verification. Notes document needs fitting height.
4. Test new essay, typing, selection, undo/redo, B/I/U/highlight, comments add/edit/delete, JSON import, all exports, relaunch persistence.
5. Test Word automatic definitions, unknown/empty words, switching words, dark mode and preferences.
6. Verify focus and selection across zoom/edit; improve native animation based on actual gestures. Current layer fade/scale is basic, not the web FLIP implementation.
7. Current home is functional native controls, not visually polished like web purple upload card. Notes are right-sidebar only. Suggestion field is preserved in model but omitted from card text; add it. Check import replacement preserves previous draft/history appropriately.
8. Replace README (still old hybrid/shortcut description) with native behavior and accurate QA status.
9. Deliver final ZIP with absolute path Markdown link; local ad-hoc signature, no notarization/Intel claims. Do not disable Gatekeeper.

## Reference
Web files: ../semantic-editor/src/App.tsx, src/document-model/breakdown.ts, src/zoom/transition.ts, src/styles/app.css. IELTS skill installed at ~/.codex/skills/ielts-breakdown; copy in ../ielts-breakdown. It outputs pure MD/TXT + annotation JSON; compatible schema should remain stable.

## Latest progress
Native port authored and compiled; WebKit removed. Staged signing passed. Handoff created before first native UI test. Append further verified results below.

- Model tests rerun and PASS: JSON roundtrip, five sample annotations, Unicode offsets, insertion/replacement/deletion rebasing, semantic ranges, empty text and invalid quote rejection.
- Explicit text-view sizes added to Dictionary and note editor; suggestion text now shown in note cards. README replaced with native description.

## VERIFIED NATIVE UI UPDATE (supersedes earlier launch blocker)
- Normal cua.getApp('/tmp/PassageNativeBuild/Passage.app') was approved and successfully launched the native app in the latest turn. Do not keep treating first launch as blocked.
- Opened annotated example; accessibility confirms native NSTextView with full essay, 5 note cards, B/I/U/highlight/comment controls and 4 level radio buttons.
- Clicked Word; native text became `As` and Dictionary pane automatically displayed a local Vietnamese definition. Automatic dictionary integration is verified, no shortcut.
- This exposed dictionary case ambiguity (`As` matched arsenic). Code now lowercases lookup input; displayed source remains unchanged. Rebuild/retest pending this last patch.
- Native screenshot exposed dark root behind black controls. Removed manually resolved root.layer background color; let window appearance draw background. Rebuild/retest pending.
- CUA selectText on 'education' failed despite essay containing it; no data changed. Use click/keyboard selection as fallback if needed.
- build.sh completed, signing verified, ZIP now contains the native app. Last two source patches require another build before final delivery.

## Final checkpoint for this handoff
- Latest native build.sh succeeded after lowercased dictionary lookup and root background fix; final ZIP is native, not hybrid.
- Bundled example copied into this native directory; build.sh is now self-contained and no longer requires sibling web files.
- Native Save panel opens and shows annotation JSON selection. End-to-end saved file verification NOT completed: CUA input interactions unexpectedly dismiss the sheet and the expected /tmp file was not present. Investigate UI automation focus and Save callback before marking export verified. Do not claim data was saved.
- App was launched from /tmp/PassageNativeBuild/Passage.app. A running process may still be the earlier binary (before last fixes); quit and relaunch normally to test latest build.
- Remaining priority: UI layout/contrast verification, actual editing and file roundtrip, focus-preserving zoom polish. Current app is a native development checkpoint, not a finished production release.

## Latest UX revision (user screenshot feedback)
- Native window now supports full-screen primary behavior, 640x520 minimum, resize delegate and adaptive layout under 1000pt (annotation panes stack vertically; edit tools stack).
- Presentation mode (Present button / View menu / Cmd+P) hides header and editing tools, makes editor read-only, increases text/note sizes. End presentation remains visible. Native full-screen via green window button or View/Full Screen.
- WritingView uses tracking areas + TextKit temporary background attributes for pointer hover of next semantic unit; does not alter stored highlights. Range bounds guarded after edits.
- Word mode now vertically stacks large source word and wide Dictionary pane. Default definition is an explicitly labeled 480-character excerpt; full entry toggle; bullet and numbered-sense paragraph spacing; original sentence shown. This is presentation formatting, NOT contextual sense disambiguation. macOS returned arsenic for As even with lowercased input; known upstream dictionary ambiguity.
- Annotation cards now 15pt body/16pt semibold title (17/19 in presentation), rounded border and accent colors; suggestions visible.
- Four bundled native palette themes in Settings: Paper, Sepia, Forest, Midnight. No external image downloads or GitHub dependencies. Dark mode takes precedence over light paper palette.
- UI QA passed: launched new app, resumed draft, toggled Word and saw excerpt + context, toggled presentation, entered native full-screen and captured screenshot showing accessible zoom/exit controls.
- Physical Stage Manager window resizing and pointer-hover behavior have not been manually verified. Full-screen presentation verified. No change to earlier unresolved export automation verification.
- Final tiny patch refreshes definition typography on presentation toggle; build again before delivery.
