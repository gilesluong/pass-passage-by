## Pass Passage By! 1.9.8

- Apple HIG Liquid Glass Button Kit:
  - Custom `GlassCircleButton` and `GlassCapsuleSegment` with continuous squircle/circular curvature (`cornerCurve = .continuous`).
  - Specular gradient rims, translucent glass materials, hover refraction brightening, and active macOS system blue states.
- Permanent Column Toggles:
  - `sidebar.left` and `sidebar.right` toggle buttons remain permanently accessible in the top bar even when sidebars are collapsed.
- Ulysses Suggestions & Grammar Inspector (✦ Tab):
  - Direct ✦ Suggestions inspector panel with category radio filters: All, Spelling, Capitalization.
  - Apple Intelligence / `NSSpellChecker` integration detecting issues (e.g. `{âss}`) with on-demand guess popups and one-click replacement.
  - AI Agent Harness Card: "Copy Prompt & Guide Agent" generates full instructions guiding AI agents to find, read, and annotate the exact document file, plus "Reveal in Finder".
- Hover Popover & Margin Deduplication:
  - Hover popover strictly requires `fn` (or `Option`) held down; casual mouse movement never triggers popovers. Single click on text opens popover.
  - Cleaned margin note cards duplication, leaving writing canvas clean and minimal like Ulysses.
- New Standardized Sample Fixtures:
  - 2 new pristine sample documents matching Ulysses screenshots: `001-career-preparation.json` and `002-welcome-stranger.json`.

## Pass Passage By! 1.9.7

- Minimalist Ulysses Studio Architecture:
  - 3/4-Column Studio Workspace: Library Sidebar (All, Inbox, Getting Started, Projects), Sheet List with snippet previews, distraction-free Editor Canvas, and Inspector Dashboard.
  - Direct studio launch: opens straight into the writing canvas.
  - Full keyboard shortcuts: ⌘1 (Library), ⌘2 (Sheet List), ⌘3 (Editor), ⌘4 (Inspector), ⌘N (New Sheet), ⌘L / ⌃⌘A (Add Annotation), ⌃⌘2 (Progress), ⌃⌘3 (Outline), ⌃⌘5 (Annotations).
- Unified Inline Annotations & Comments:
  - Single unified feature: inline curly brace `{anchor}` and `{anchor|note}` syntax for instant annotation creation by users and AI agents.
  - Ulysses-style soft blue highlight pill and underline styling.
  - Floating popover with note editor, separator, and Remove Annotation button.
- Fn + Hover Instant Annotation Popover:
  - Holding `fn` (or `Option`) and hovering over an annotated span highlights the text and immediately displays the annotation popover without clicking.
- Smooth Transition for Chevron:
  - Animated fade transition on the document task prompt disclosure chevron button.
- Clean Terminology:
  - Completely eliminated the word "essay" across all UI labels, menus, badges, placeholders, and preferences in favor of "Document" and "Sheet".
- 100% strict SwiftLint compliance (0 warnings, 0 errors) and all native layout test suites pass.

Apple Silicon, macOS 13+. Sparkle-signed update; development ad-hoc app signing, not Apple-notarized.

