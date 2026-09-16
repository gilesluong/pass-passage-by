# Pass Passage By!

Native macOS writing, annotation and semantic zoom. Apple TV-inspired discovery with a fixed sidebar, featured writing carousel and local shelves. Hold Option to preview the text under your pointer; use Option-H for persistent highlight. Configure a Teacher, Student or custom zoom path in Settings.

## Agent connection

Open **Connect your AI** on Home. Copy the MCP setup into a compatible host, explicitly share a document, then review the result from Inbox. PPB provides document tools and presentation; the selected AI host provides its own model and subscription. There is no paid API connection or bundled model. Hosts without local MCP can use the exported skill and JSON import workflow. See [AgentKit/CONNECT.md](AgentKit/CONNECT.md).

## Development

Run `bash test.sh`, `bash test-layout.sh`, then `bash build.sh`. Native layout tests need normal macOS dictionary access. Build output is `dist/Pass Passage By!.app`; preview is `/tmp/PPBPreview/Pass Passage By!.app`. Installed updates go through Sparkle only. See [release/README.md](release/README.md).

Version 1.7.0 (11), arm64 macOS 13+. Bundle ID and data directory remain stable. Sparkle archives are Ed25519 signed; the development app is ad-hoc signed, not Developer ID signed or notarized.

Read [HANDOFF-ANTIGRAVITY.md](HANDOFF-ANTIGRAVITY.md) before continuing work. Twenty curated original practice samples are bundled; they are not official IELTS questions or certified band scores.
