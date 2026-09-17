# AGENTS.md — Pass Passage By! (PPB)

Welcome to Pass Passage By! This repository is a shared workspace maintained cooperatively by **Antigravity**, **Codex**, and **ZCode (z.ai)**.

> [!IMPORTANT]
> **FIRST ACTION REQUIRED**: Before modifying any code, read the latest entries in [`HANDOFF-ANTIGRAVITY.md`](HANDOFF-ANTIGRAVITY.md). It contains the complete architectural log, user product vision, and active roadmap.

---

## 1. Workspace Paths (Local Directory)
- **Primary Canonical Directory**:
  `/Users/roastmetoasty/Documents/Codex/2026-09-13/https-stitch-withgoogle-com-projects-3243549993640558333/outputs/passage-macos`
- **Convenient Symlink (for easy navigation in IDEs and file pickers)**:
  `/Users/roastmetoasty/Documents/pass-passage-by`
  *(Both paths map directly to the identical Git repository on disk)*

---

## 2. Strict Project Invariants
All agents must respect the following constraints to prevent regressions:
1. **SwiftLint Compliance**: Zero warnings and zero errors required.
   ```bash
   bash lint.sh
   ```
   Do not suppress lint rules globally; adhere strictly to SwiftLint guidelines.
2. **Schema Freeze**:
   - `Model.swift` schema is frozen. Do not alter existing data structures or serialized field definitions.
   - The 20 curated practice samples in `Samples/` must not be deleted or structurally broken.
   - Any new document types for Administrative (NĐ 30) or SOPs live in `AgentKit/` and are imported dynamically.
3. **Automated Verification**:
   Before committing any work, all test suites must pass:
   ```bash
   bash test.sh
   bash test-layout.sh
   ```
4. **App Delivery & Sparkle Updates**:
   - **Local Preview**: `bash build.sh` compiles and places the preview binary at `/tmp/PPBPreview/Pass Passage By!.app`.
   - **Production Updates**: Never manually overwrite `/Applications/Pass Passage By!.app` or `~/Applications/Pass Passage By!.app`. Updates are distributed strictly via Sparkle using:
     ```bash
     bash release/prepare-update.sh
     bash release/publish.sh
     ```

---

## 3. Product Vision & Architecture Highlights
- **Close Reading & Structured Document Studio**:
  - **Vietnamese Administrative Documents (Nghị định 30/2020/NĐ-CP)**: Structured drafting blocks (Quốc hiệu, Tiêu ngữ, Căn cứ pháp lý, Điều khoản, Nơi nhận) replacing Word formatting friction.
  - **Corporate SOP & Employee Onboarding**: Interactive procedures and financial thresholds paired with Loom screen recordings.
  - **Speech & Rhetorical Analysis**: Dissection of Pathos, Logos, Ethos, and historical context.
- **Annotation vs Comment — updated user direction (17 September, evening)**:
  - Annotation: a short contextual note, reminder, state or observation in the margin. It need not be objective or legal/structural. Keep it lightweight.
  - Comment: richer feedback and eventual human/agent discussion, shown in a dedicated inspector/thread surface, not another full margin card.
  - Version 1.9.4 only distinguishes border/color/labels; the shared margin renderer is NOT a completed separation.
  - Read `NEXT-STEPS.md` before implementing this change. Preserve existing note IDs, text, anchors and exports; no silent kind-based reclassification of historical notes.
- **Visual direction**: quiet neutral workspace inspired by the supplied ZCode screenshot; remove decorative wallpaper. Reserve imagery for actual document covers. Editor clarity precedes new showcase/template features.
- **$0 Subscription Model**:
  - Native on-device Apple Intelligence, Apple Dictionaries, and BYO AI agent connection via stdio MCP. No recurring subscription for reading tools.

---

## 4. Current State & Handoff
- **Version**: 1.9.4 (18)
- **Branch**: `main`
- Detailed handoff and next tasks: see [`HANDOFF-ANTIGRAVITY.md`](HANDOFF-ANTIGRAVITY.md).
