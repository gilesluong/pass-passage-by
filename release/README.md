# Pass Passage By! releases

The stable release-only repository is https://github.com/gilesluong/pass-passage-by-releases.
Sparkle 2.10.0 is embedded. The installed app reads:
https://github.com/gilesluong/pass-passage-by-releases/releases/latest/download/appcast.xml

## Stable identity
- Display/bundle name: Pass Passage By!.app
- Bundle ID: com.passage.editor; executable: Passage
- Installed location: ~/Applications/Pass Passage By!.app
- Existing data: ~/Library/Application Support/Passage
- Library: the Library subfolder; immutable document IDs map to SHA-256 filenames.

Do not copy new builds over the installed app. Subsequent updates must use Sparkle. /tmp/PPBPreview is for development only. Never publish different bytes under an existing version tag.

## Release workflow
1. Increase both CFBundleShortVersionString and CFBundleVersion in Info.plist; update release/notes.md.
2. Run bash test.sh and bash test-layout.sh. Vision needs normal macOS execution: restrictive automation sandboxes may reject CoreVideo buffers. Tests use isolated preferences and suppress draft writes.
3. Run bash build.sh. This uses cached Vendor; do not run dependency bootstrap on a hotspot without checking first.
4. Run bash release/prepare-update.sh. The official Sparkle tool signs using Keychain account com.passage.editor. The private key stays in Keychain. Independent CryptoKit verification checks the archive signature, version, length and URL.
5. Run bash release/publish.sh. Uploads archive and appcast together to a draft release, then publishes it as latest. It refuses existing release tags.
6. In the installed app choose Pass Passage By! > Check for Updates, install and relaunch. Verify the installed build and preservation of existing writing. Record the exact result in HANDOFF-ANTIGRAVITY.md.

## Signing and production status
Archives are Sparkle Ed25519-signed; the current arm64 macOS 13+ app is ad-hoc signed, not Developer ID signed/notarized. Developer ID, hardened runtime inside-out signing, notarization/stapling and Gatekeeper distribution checks remain required for a public commercial launch. Keep the same Sparkle signing key across versions. No automatic AI-model download is implemented. FoundationModels is weak-linked and used only on macOS 26+ when the system model reports available.

Official references:
- https://sparkle-project.org/documentation/code-signing/
- https://sparkle-project.org/documentation/publishing/

## Dependency provenance
Sparkle 2.10.0 official artifact:
https://github.com/sparkle-project/Sparkle/releases/download/2.10.0/Sparkle-for-Swift-Package-Manager.zip
SHA256: 17e28312b8e18ab7cdbbe09a6fb28cc55a5479ec6c371dbc07cdecd2a14fd959
Vendor is omitted from source handoff ZIP. Restore via release/bootstrap-sparkle.sh only when network use is appropriate.
