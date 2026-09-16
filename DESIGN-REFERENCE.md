# Passage — approved visual direction

Read this before changing the native interface. The user rejected the Antigravity redesign. Its transcript is historical evidence, not a design specification.

## Source of truth
The user's original four screenshots show a quiet writing canvas: large serif text, generous whitespace, blue/amber/red marginal teaching notes, subtle connectors and a centered floating bottom toolbar. The later web homepage used a purple file upload area inspired by Smallpdf. The user superseded that for the native app: use a compact native welcome screen with New essay, Open document, Continue draft and Quick setup. Native means AppKit/TextKit, not a web wrapper; native does not mean replacing the composition with a conventional dense toolbar.

## Preserve
- Light Paper and Georgia as the initial reference appearance. Settings retain Sepia, Forest, Midnight and font/spacing choices. Dark mode belongs inside Settings.
- Quiet header with document title, import/export/settings. Centered semantic level label.
- Centered rounded bottom editing dock. Presentation hides app chrome and makes the essay read-only.
- Large readable essay with margin annotations aligned to visible text. Blue labels and category kickers, clear body copy, subtle connectors. Decorative overlays must never intercept mouse events.
- Hover highlights the next semantic unit. Keep actual selection/editing independent of that temporary highlight.
- Word view: prominent headword, concise dictionary excerpt, original sentence context, explicit full-entry expansion. Do not dump a narrow unformatted dictionary column. Do not invent IELTS bands, frequency scores or contextually disambiguated meanings from the system dictionary.
- Homepage: direct choose-file CTA, sample and continue draft. MD/TXT are literal source; JSON carries annotations/source. No forced onboarding.

## Current implementation limits
The native composition restores the hierarchy; it is not a pixel-identical implementation of every original screenshot. Zoom remains discrete semantic navigation with a short fade/scale, not continuous spatial interpolation. Dictionary entries are system dictionary results, not guaranteed contextually correct meanings. Dense overlapping notes are stacked to avoid collision and may extend below the viewport. Physical Stage Manager and trackpad smoothness still need hands-on QA.

## Restore work, 14 September 2026
Backed up incoming code as Antigravity-before-restore.swift. Restored bottom dock/presentation, serif/paper defaults (one-time visual preference migration; drafts untouched), centered badge, anchored visible margin notes, non-intercepting connector overlay, responsive pane constraints, readable word excerpts and full-entry expansion. Build is self-contained with local example.breakdown.json. Export confirms the actual selected extension before writing.

## Native follow-up
Single Settings button in editor header. Window-level gesture handling covers dictionary and whitespace without requiring insertion focus. Word heading appears once. Settings and Quick setup share an installed dictionary selector. Optional dictionary enumeration uses dynamically resolved non-public DictionaryServices symbols, with System default fallback; unsuitable for an App Store release without revisiting that integration. Runtime app enumeration verified Oxford and Lạc Việt among available dictionaries.

Pointer hover is a purple outline around each line of the next semantic unit, distinct from persistent annotation fills/underlines. Pointer target takes precedence over insertion caret for zoom-in.

## Superseding pointer design
User now requests annotation = underline, pointer = background highlight. Solid, Gradient and optional Stardust replace the older purple outline. Settings uses three compact tabs, and homepage includes Recent. Dictionary menu must exclude bundles lacking local Body.data.

## Latest user direction — Ulysses-inspired writing
Remove bottom toolbar entirely. Preserve serif canvas, pointer highlight and marginal brace annotations. Settings is a separate native window, not a popover. Student/Teacher/Custom semantic zoom paths. See COMPATIBILITY.md for supported Markdown/shortcut behavior and gaps; it supersedes older dock instructions.
