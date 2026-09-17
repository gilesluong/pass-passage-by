# 1.8.1 interaction correction

User screenshots and feedback exposed nested scroll competition and repeated carousel advances. Shelves now forward vertical gestures to the page; carousel direction is locked and momentum never advances a second slide. Native regression tests assert horizontal advance, inertia suppression, axis lock, and all typed new-document flows produce empty text/prompt/annotations. Full physical-trackpad stress testing remains unverified.

# Design verification — 1.8.0 (12)

User screenshot: horizontal page drift concealed the sidebar. The page clip now fixes x=0 for constraints, direct scrolling and bounds changes; shelves retain their independent horizontal scrolling.

Changes: restrained sidebar selection, Discover heading, shorter featured titles, readable multi-line card titles, compact metadata, clean excerpts without Markdown heading tokens, search result grids/counts, removal of nonfunctional section chevrons and decorative background arcs. The editor remains intact; task prompts are directly editable and autosave.

Verification: model/markup/Unicode, 20 IELTS anchors, PDF, MCP, OCR and AppKit layout suites passed. Regression checks cover direct horizontal scrolling, sidebar visibility, live search delegate, deep body-text search, empty results, clear restoration, editable task prompts and all settings pages. Four CC BY reading documents and all 20 new anchors validate.

Native interaction: typing interpolated immediately found the workplace research article, as expected. Settings and Home controls were inspected through accessibility. Current screenshot capture returns a Stage Manager thumbnail or a blank miniature, so a complete full-size visual audit of every window and real trackpad stress test cannot be claimed. Offscreen Home rendering identified title clipping and Markdown excerpt artifacts; both were corrected. Offscreen Settings rendering does not accurately reproduce native controls and was not used as visual approval.

Remaining: full-size multi-display/Stage Manager visual QA, dense annotation stress, per-document carousel artwork and actual third-party MCP-host onboarding. Settings are not claimed to have received a new full redesign in this release.
