# Pass Passage By!

## Direction
An editorial native writing workspace, informed by Ulysses' focus on source and typography. Evergreen ink (#14403d), ivory (#f7f2de), brass (#c79240). The original logo combines a folded page, an archway and a bookmark. Home has quiet path-line artwork; the writing canvas remains uncluttered. Assets are original vector/AppKit drawings, not generated photographs or copied Ulysses assets.

## Skill review
Installed transitions-dev and transitions-polish from Jakubantalik/transitions.dev using the Codex skill installer. Read both SKILL.md files and text-state-swap reference. These are CSS/web recipes; this app stays AppKit. BrandMotion maps the relevant timing principles into native animation: 150ms text change and 250ms page change, reduced motion preserved. No CSS runtime or extra motion library was added.

Read the Composio design-skills roundup and theme-factory SKILL.md. Theme-factory targets deck/artifact themes, so its slideshow workflow was not applied to the app. Chose a small consistent native palette and editorial hierarchy rather than importing a web component system. Sources:
https://transitions.dev/skill.html
https://github.com/Jakubantalik/transitions.dev
https://composio.dev/content/top-design-skills
https://github.com/ComposioHQ/awesome-codex-skills/tree/master/theme-factory

## Brand assets and copy
Assets/brand-mark.svg and Assets/brand-mark.png: app mark.
Assets/paper-paths.svg and Brand.swift: subtle welcome background.
Icon.swift: rasterizes the native icon at all macOS sizes during build.
ABOUT.txt, PRIVACY.txt, TERMS.txt: bundled app information, reachable from Home. Terms is explicitly a local-preview draft pending publisher details and legal review; no invented corporate identity or jurisdiction.

## Compatibility
Display name and distributed bundle renamed. Keep com.passage.editor, executable/resource names and Application Support/Passage so existing preferences/drafts remain available. Deliver Pass-Passage-By-macOS.zip; Passage-macOS.zip remains a compatibility output.
