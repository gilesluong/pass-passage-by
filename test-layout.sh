#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
python3 - <<'PY'
from pathlib import Path
Path('/tmp/PassageLayoutSource.swift').write_text(Path('Passage.swift').read_text().replace('@main',''))
PY
swiftc -module-cache-path /tmp/passage-swift-cache -swift-version 5 /tmp/PassageLayoutSource.swift NotePresentation.swift Comments.swift Model.swift Markup.swift Home.swift Capture.swift Library.swift ReadingControls.swift AgentConnection.swift Brand.swift Updater.swift Share.swift UlyssesWorkspace.swift NativeLayoutTests.swift -F Vendor/Sparkle-2.10.0/Sparkle.xcframework/macos-arm64_x86_64 -framework Sparkle -Xlinker -rpath -Xlinker "$PWD/Vendor/Sparkle-2.10.0/Sparkle.xcframework/macos-arm64_x86_64" -framework Vision -Xlinker -weak_framework -Xlinker FoundationModels -framework Cocoa -framework PDFKit -o /tmp/ppb-native-layout-tests
/tmp/ppb-native-layout-tests Samples/001-career-preparation.json
