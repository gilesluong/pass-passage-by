#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
bash lint.sh
PPB_STAGE="$(mktemp -d /tmp/ppb-build.XXXXXX)"
PPB_APP="$PPB_STAGE/Pass Passage By!.app"
PPB_SPARKLE="Vendor/Sparkle-2.10.0/Sparkle.xcframework/macos-arm64_x86_64"
test -d "$PPB_SPARKLE/Sparkle.framework" || ./release/bootstrap-sparkle.sh
mkdir -p "$PPB_APP/Contents/MacOS" "$PPB_APP/Contents/Resources" "$PPB_APP/Contents/Frameworks" dist
python3 - "$PPB_APP/Contents/Resources/Samples" <<'PYSAMPLES'
from pathlib import Path
import sys
target=Path(sys.argv[1]);target.mkdir(parents=True,exist_ok=True)
import json
for source in [Path('Samples')/name for name in json.loads(Path('sample-manifest.json').read_text())]:(target/source.name).write_bytes(source.read_bytes())
PYSAMPLES
python3 - "$PPB_APP/Contents/Resources/AgentKit" <<'PYKIT'
from pathlib import Path
import sys
t=Path(sys.argv[1]);t.mkdir(parents=True,exist_ok=True)
for p in Path("AgentKit").iterdir():
 if p.is_file():(t/p.name).write_bytes(p.read_bytes())
PYKIT
mkdir -p "$PPB_APP/Contents/Resources/Reading"
cp Reading/*.json Reading/LICENSES.md "$PPB_APP/Contents/Resources/Reading/"
mkdir -p "$PPB_APP/Contents/Resources/Assets"
cp Assets/reading-cover.png Assets/home-background.jpg "$PPB_APP/Contents/Resources/Assets/"
cp example.breakdown.json ABOUT.txt PRIVACY.txt TERMS.txt "$PPB_APP/Contents/Resources/"
swiftc -module-cache-path /tmp/passage-swift-cache -target arm64-apple-macosx13.0 -swift-version 5 -O -parse-as-library Passage.swift NotePresentation.swift Comments.swift Model.swift Markup.swift Home.swift Capture.swift Library.swift ReadingControls.swift AgentConnection.swift Brand.swift Updater.swift Share.swift UlyssesWorkspace.swift -F "$PPB_SPARKLE" -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks -o "$PPB_APP/Contents/MacOS/Passage" -framework Vision -Xlinker -weak_framework -Xlinker FoundationModels -framework Cocoa -framework CoreServices -framework PDFKit
swift -module-cache-path /tmp/passage-swift-cache Icon.swift /tmp/Passage.iconset
python3 package-icon.py "$PPB_APP/Contents/Resources/Passage.icns"
cp Info.plist "$PPB_APP/Contents/Info.plist"
ditto --norsrc --noextattr "$PPB_SPARKLE/Sparkle.framework" "$PPB_APP/Contents/Frameworks/Sparkle.framework"
codesign --force --deep --sign - "$PPB_APP"
codesign --verify --deep --strict "$PPB_APP"
rm -rf '/tmp/PPBPreview/Pass Passage By!.app' 'dist/Pass Passage By!.app' dist/PPB-macOS.zip
mkdir -p /tmp/PPBPreview dist
ditto --norsrc --noextattr "$PPB_APP" '/tmp/PPBPreview/Pass Passage By!.app'
ditto --norsrc --noextattr "$PPB_APP" 'dist/Pass Passage By!.app'
ditto -c -k --norsrc --noextattr --keepParent "$PPB_APP" dist/PPB-macOS.zip
python3 - "$PPB_STAGE" <<'PY'
import pathlib,shutil,sys
p=pathlib.Path(sys.argv[1]);assert p.parent==pathlib.Path('/tmp') and p.name.startswith('ppb-build.')
shutil.rmtree(p)
PY
