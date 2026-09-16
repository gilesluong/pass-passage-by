#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swiftc -module-cache-path /tmp/passage-swift-cache Model.swift ModelTests.swift -o /tmp/ppb-model-tests
/tmp/ppb-model-tests example.breakdown.json
swiftc -module-cache-path /tmp/passage-swift-cache Model.swift Markup.swift MarkupTests.swift -o /tmp/ppb-markup-tests
/tmp/ppb-markup-tests
python3 - <<'PY'
from pathlib import Path
import json
Path('/tmp/PPBPDFCore.swift').write_text(Path('Share.swift').read_text().split('extension Passage')[0])
files=list(Path('Samples').glob('*.json'));assert len(files)==20
for file in files:
 d=json.loads(file.read_text());text=d['document']['text'];assert len(text.split()) >= (250 if d["document"]["taskType"]=="task2" else 150)
 for note in d['annotations']:assert text[note['start']:note['end']]==note['quote']
print('PASS: 20 sample documents and annotation anchors')
PY
swiftc -module-cache-path /tmp/passage-swift-cache Model.swift Markup.swift /tmp/PPBPDFCore.swift PDFTests.swift -framework Cocoa -framework PDFKit -o /tmp/ppb-pdf-tests
/tmp/ppb-pdf-tests example.breakdown.json

python3 AgentKit/test_mcp.py
