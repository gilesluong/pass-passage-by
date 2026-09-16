#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
PPB_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
PPB_BUILD=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' Info.plist)
PPB_REPO=gilesluong/pass-passage-by-releases
PPB_DIR="dist/updates/$PPB_VERSION"
mkdir -p "$PPB_DIR"
python3 - <<'PY'
import plistlib,zipfile
from pathlib import Path
expected=plistlib.loads(Path('Info.plist').read_bytes())
with zipfile.ZipFile('dist/PPB-macOS.zip') as z:
 actual=plistlib.loads(z.read('Pass Passage By!.app/Contents/Info.plist'))
 for k in ['CFBundleIdentifier','CFBundleVersion','CFBundleShortVersionString','SUPublicEDKey','SUFeedURL']:assert actual[k]==expected[k],f'Stale build: {k}'
 assert actual['CFBundleIdentifier']=='com.passage.editor'
PY
cp dist/PPB-macOS.zip "$PPB_DIR/Pass-Passage-By-$PPB_VERSION.zip"
cp release/notes.md "$PPB_DIR/Pass-Passage-By-$PPB_VERSION.md"
Vendor/Sparkle-2.10.0/bin/generate_appcast --account com.passage.editor --maximum-deltas 0 --embed-release-notes --download-url-prefix "https://github.com/$PPB_REPO/releases/download/v$PPB_VERSION/" "$PPB_DIR"
python3 release/verify-update.py "$PPB_DIR/appcast.xml" "$PPB_DIR/Pass-Passage-By-$PPB_VERSION.zip"
printf 'Prepared Sparkle release %s (%s) in %s\n' "$PPB_VERSION" "$PPB_BUILD" "$PPB_DIR"
