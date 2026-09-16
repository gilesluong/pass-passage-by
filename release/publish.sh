#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
PPB_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
PPB_REPO=gilesluong/pass-passage-by-releases
PPB_DIR="dist/updates/$PPB_VERSION"
python3 release/verify-update.py "$PPB_DIR/appcast.xml" "$PPB_DIR/Pass-Passage-By-$PPB_VERSION.zip"
# Never replace an existing release asset; a new build must have a new version.
if gh release view "v$PPB_VERSION" --repo "$PPB_REPO" >/dev/null 2>&1; then
 echo 'Release already exists. Increase version and build before publishing.' >&2;exit 1
fi
gh release create "v$PPB_VERSION" "$PPB_DIR/Pass-Passage-By-$PPB_VERSION.zip" "$PPB_DIR/appcast.xml" --repo "$PPB_REPO" --target main --title "Pass Passage By! $PPB_VERSION" --notes-file release/notes.md --draft
# Complete both uploads in a draft before moving the stable latest feed.
gh release edit "v$PPB_VERSION" --repo "$PPB_REPO" --draft=false --latest
