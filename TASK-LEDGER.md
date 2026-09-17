# Active delivery ledger — 17 September 2026

Read this file first when resuming. Long-term vision: PRODUCT-VISION.md. Stable release baseline: 1.9.4 (18); source already contains unreleased comment separation. Do not overwrite installed app.

## Current batch (user: clean ZCode-style UI and continue outstanding work)
1. DONE — Neutral shell, compact editor header, document-details disclosure, readable editable prompt and restrained native motion.
   Files: Brand.swift (WorkspaceStyle, InspectorSurface, ClipScrollView, BrandMotion.disclosure/smoothOut), Passage.swift (16pt title, 30pt borderless header controls, ClipScrollView task brief, DOCUMENT DETAILS disclosure with animated chevron toggle, editable taskPromptField, centered 920pt max prompt column), NativeLayoutTests.swift (taskPromptField assertions replace removed label scan).
   Checks: bash lint.sh clean; bash test.sh PASS; bash test-layout.sh PASS (incl. disclosure toggle, connector suppression during animation, 19pt editable prompt<=920pt, layer clipping); bash build.sh preview at /tmp/PPBPreview/Pass Passage By!.app.
2. NEXT — Portable annotation/comment presentation metadata and undoable conversion, preserving frozen Model.swift.
3. NEXT — Comments inspector polish, readable anchors and action behavior; prevent duplicated note UI.
4. NEXT — Review Home/Settings density, remove remaining decorative chrome and misleading copy.
5. NEXT — Strict lint, core/native tests, light/dark renders, build, new Sparkle release only after portability gate passes; refresh source ZIP and handoff.

## Guardrails
Update this ledger after each completed task with files, checks and next action. Never describe future collaboration or the full Notion-level roadmap as finished. Remote collaboration, Developer ID/notarization and real external MCP host validation have dependencies beyond this UI batch. No AI model downloads. Do not erase legacy notes or infer their purpose from `kind=comment`.
