---
name: ppb
description: Create, evaluate, or annotate writing tasks for the native Pass Passage By! macOS app. Activated whenever the user mentions @PPB! in chat or asks for IELTS, Academic Research, or Essay evaluation.
---

# Pass Passage By! (@PPB!) Agent Harness

This skill is invoked whenever the user mentions `@PPB!` in agent conversation (e.g., `@PPB! evaluate this essay`, `@PPB! write an IELTS Task 2 response`, `@PPB! analyze this research methodology`).

## 1. Writing Genres & Annotation Taxonomies

Pass Passage By! supports three specialized annotation tracks:

### A. IELTS Academic Writing (`--task-type task1` or `--task-type task2`)
- **Task Response / Task Achievement (TR/TA)**: Tag `blue`. Address all prompts, avoid over-generalization, ensure clear overview/stance.
- **Coherence & Cohesion (CC)**: Tag `purple`. Topic progression, logical sequencing, cohesive discourse devices.
- **Lexical Resource (LR)**: Tag `green`. Precise collocations, academic register, eliminating repetitive terminology.
- **Grammatical Range & Accuracy (GRA)**: Tag `yellow` or `orange` (`kind: "correction"`). Complex sentence variety and error diagnosis.

### B. Research & Academic Writing (`--task-type research`)
- **Source & Literature Citations (`label: "Source Preview"` or `kind: "comment"`)**: Tag `orange`.
  - Format body to include standard bibliographic details and DOI:
    ```
    Author et al. (Year) · Journal / Venue
    DOI: 10.xxxx/yyyy
    Key evidence: [Summary of empirical finding or methodology]
    ```
  - Pass Passage By! automatically parses the DOI into an interactive `[DOI: 10.xxxx ↗]` browser button in the margin note!
- **Methodology & Empirical Evidence**: Tag `purple`. Research design, sample size, limitations, statistical robustness.

### C. Discursive & Argumentative Essays (`--task-type essay`)
- **Thesis Statement & Concession**: Tag `purple`. Central argument definition and balanced concession.
- **Rhetorical Strategies & Flow**: Tag `blue`. Topic sentences, dialectical transitions, persuasive framing.
- **Counter-Argument & Refutation**: Tag `red` or `orange`. Antagonist perspective and rebuttal.

## 2. Assembling and Exporting Documents

Always use `AgentKit/bridge.py` to assemble text and compute UTF-16 code unit offsets accurately for macOS:

```bash
# 1. Prepare essay.md and notes.json (with exact quotes)
# 2. Assemble and save directly into Pass Passage By! Library:
python3 AgentKit/bridge.py assemble essay.md notes.json --title "Essay Title" --task-type task2 --prompt task.txt --to-library

# 3. Validate existing file:
python3 AgentKit/bridge.py validate path/to/document.json
```

When `--to-library` is used, the document is written to `~/Library/Application Support/Passage/Library/<uuid>.json` and immediately shows up in the user's "My writing" library in the app.

## 3. Direct App Launch

Notify the user with the file path and the one-click macOS terminal command:
```bash
open -a "/Applications/Pass Passage By!.app" "path/to/document.json"
```
Or simply reveal the document in Finder. All schema contracts are validated against `schema.json`.
