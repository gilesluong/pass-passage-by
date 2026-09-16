# HANDOFF TO CHATGPT CODEX & COMPLETE ARCHITECTURE SPECIFICATION
**App Name:** Pass Passage By!  
**Bundle Identifier:** `com.passage.editor`  
**Current Version:** 1.6.0 (Build 9)  
**Target Platform:** macOS 13.0+ (Apple Silicon arm64, native AppKit / TextKit / PDFKit / Vision / Sparkle)  
**GitHub Repository:** `https://github.com/gilesluong/pass-passage-by-releases`  
**Date:** 16 September 2026  

---

## 1. Executive Summary of What Was Accomplished

1. **Partner Showcase Carousel (`Home.swift`)**:
   - Converted the top featured cards into an interactive **Partner Showcase Carousel** (`PartnerShowcaseCarousel`).
   - Serves as the primary promotional hero banner for language centers and master educators to showcase model essays and teaching pedagogy.
   - Includes 3 verified partner slides:
     - **IELTS Master Studio · Cô Mai Phương** (Band 8.5+ Mentor) — *Task 2 · Food waste & circular economy* (Task Response & Lexical Resource).
     - **The Writing Academy · Thầy Alex Thorne** (Oxford MA) — *Task 2 · Public transport infrastructure* (Cohesion & Argument Flow).
     - **Oxford Academic Research Hub · Dr. Minh Tuấn** — *Research & Policy · Sustainable Urban Mobility* (Source Previews & DOI links).
   - Interactive navigation: `<` Prev and `>` Next buttons, pagination indicator dots (`● ○ ○`) clickable to jump directly to any slide, and a "Read model essay with annotations →" action pill that loads the sample document immediately.

2. **Writing Categories & Segmented Filter Bar (`Home.swift`)**:
   - Added interactive `WritingCategoryBar` beneath the carousel:
     - `All Writing`: Curated cross-genre showcase.
     - `IELTS Writing`: IELTS Task 1 & Task 2 essays with assessment criteria badges (`IELTS · Task Response`, `IELTS · Cohesion & Flow`, etc.).
     - `Research & Academic`: Academic writing featuring **Source Previews**, peer-reviewed literature citations, and DOI links.
     - `Essays & Composition`: Discursive and argumentative essays with rhetorical badges (`Essay · Thesis & Argument Flow`, `Essay · Rhetorical Devices`).
   - Clicking any tab filters and rearranges the card grid smoothly.

3. **Research Source Previews & Interactive DOI Links (`Passage.swift`)**:
   - Enhanced `renderNotes()` to automatically detect academic sources and citations.
   - Distinct **Source Preview Card** rendered in margin annotations with `✦ RESEARCH SOURCE · PREVIEW` badge in amber/orange accent.
   - Automatic regex extraction of DOIs (`10.xxxx/...`): renders an interactive `[DOI: 10.xxxx ↗]` button that opens `https://doi.org/...` directly in the user's browser.
   - Quick pills in `openCommentPopover`: Added `[Source Preview]` (pre-populates bibliographic and DOI template) and `[Argument Flow]` alongside existing IELTS criteria pills.

4. **Apple macOS Native Dictionary Integration (`Passage.swift`)**:
   - Full Apple Dictionary HIG implementation in Word zoom level (`level == 3`).
   - Discovers all 87 installed system dictionaries via `NSSet` iteration (indexing `Từ điển Lạc Việt`, `Oxford Dictionary of English`, `Oxford American Writer’s Thesaurus`, and `Từ Điển Tiếng Việt`).
   - Punctuation stripping for trailing periods/commas.
   - Word count metric, live `NSSearchField`, history `<` `>` navigation, and tab buttons (`All`, `Lạc Việt`, `Oxford`, `Thesaurus`, `Tiếng Việt`).

5. **Antigravity Agent Harness & `@PPB!` Command (`AgentKit/` & `.agents/skills/ppb/SKILL.md`)**:
   - Automatically activates when the user mentions `@PPB!` in agent conversation.
   - Evaluates essays across IELTS, Academic Research (with Source Previews & DOIs), and Argumentative Essay tracks.
   - Updated `AgentKit/bridge.py` with `--to-library` flag: automatically compiles and saves documents to `~/Library/Application Support/Passage/Library/<uuid>.json` and outputs a one-click `open -a "/Applications/Pass Passage By!.app"` command.
   - Installed into project `.agents/skills/ppb/SKILL.md` (checked into git) and machine-wide `~/.gemini/antigravity/builtin/skills/ppb/SKILL.md`.

---

## 2. Invariants & Frozen Contracts (CRITICAL)

> [!IMPORTANT]
> **DO NOT MODIFY THE FOLLOWING SCHEMAS OR ASSETS:**
> 1. `Model.swift`: The JSON schema for documents, annotations, ranges, and types (`ielts-semantic-breakdown`, `version: 1`) is strictly frozen.
> 2. All 20 sample files in `Samples/*.json`.
> 3. Do NOT attempt heavy model downloads over mobile hotspot. Vision OCR and local analyzer run 100% on-device offline.

---

## 3. Directory Structure Overview

```
outputs/passage-macos/
├── .agents/skills/ppb/SKILL.md      # Antigravity @PPB! skill specification (checked into git)
├── AgentKit/                        # Interoperability tools for agents
│   ├── SKILL.md                     # Skill instructions for @PPB!
│   ├── bridge.py                    # Assembly, UTF-16 offset calculator, --to-library
│   ├── schema.json                  # JSON validation schema
│   └── example.json                 # Reference breakdown
├── Brand.swift                      # Color palette, semantic tokens, Liquid Glass styles
├── Capture.swift                    # Apple Vision OCR & local document scanner
├── Home.swift                       # HomeDashboard, PartnerShowcaseCarousel, WritingCategoryBar, HomeCard
├── Library.swift                    # Notes-style library manager (~/Library/Application Support/Passage/Library)
├── Markup.swift                     # Inline markup parser and converter
├── Model.swift                      # Core data structures (Breakdown, Essay, Note)
├── Passage.swift                    # Main application controller, TextKit editor, margin notes, Apple Dictionary
├── Samples/                         # 20 curated sample documents (Task 1 & Task 2)
├── Share.swift                      # PDF exporter and text renderer
├── Updater.swift                    # Sparkle auto-updater controller
├── build.sh                         # Release build script
├── test.sh                          # Core test runner (Model, Markup, Samples, PDF)
└── test-layout.sh                   # Headless AppKit layout & visual rendering test runner
```

---

## 4. How to Verify & Build

All commands are executed from `outputs/passage-macos/`:

```bash
# 1. Run core unit tests (PASS 100%)
bash test.sh

# 2. Run native layout tests & offscreen rendering (PASS 100%)
bash test-layout.sh

# 3. Build release .app bundle
bash build.sh

# 4. Sync release build to local Applications folder
rsync -a "dist/Pass Passage By!.app/" "/Users/roastmetoasty/Applications/Pass Passage By!.app/"

# 5. Push to GitHub
git status
git push origin main
```

---

## 5. Next Steps for Codex

1. **Review and Polish Animation Timings**:
   - In `PartnerShowcaseCarousel`, optional slide cross-fade animation when switching via arrow buttons or pagination dots.
2. **Additional Research Samples**:
   - Users can create and export more academic research articles with bibliography and DOI previews using `@PPB!` in agent chat.
3. **Apple Intelligence Sprint**:
   - When the user's macOS finish downloading Apple Intelligence models, expand `FoundationModels` integration in `Capture.swift`.
