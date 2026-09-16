"""Check appcast identity, immutable URL, size and Ed25519 archive signature."""
from pathlib import Path
import sys,plistlib,xml.etree.ElementTree as ET,subprocess,tempfile
feed,archive=map(Path,sys.argv[1:])
info=plistlib.loads((Path(__file__).resolve().parent.parent/'Info.plist').read_bytes())
ns={'s':'http://www.andymatuschak.org/xml-namespaces/sparkle'}
item=ET.parse(feed).find('channel/item')
assert item is not None
enclosure=item.find('enclosure')
version=item.findtext('s:version',namespaces=ns) or enclosure.get('{'+ns['s']+'}version')
assert version==info['CFBundleVersion']
assert int(enclosure.get('length'))==archive.stat().st_size
assert enclosure.get('url')==f"https://github.com/gilesluong/pass-passage-by-releases/releases/download/v{info['CFBundleShortVersionString']}/{archive.name}"
signature=enclosure.get('{'+ns['s']+'}edSignature');assert signature
swift='''import Foundation
import CryptoKit
let key=try Curve25519.Signing.PublicKey(rawRepresentation:Data(base64Encoded:CommandLine.arguments[1])!)
let signature=Data(base64Encoded:CommandLine.arguments[2])!
let bytes=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[3]))
guard key.isValidSignature(signature,for:bytes) else {exit(1)}
'''
with tempfile.TemporaryDirectory(prefix='ppb-signature-') as folder:
 source=Path(folder)/'verify.swift';source.write_text(swift)
 subprocess.run(['swift','-module-cache-path','/tmp/passage-swift-cache',str(source),info['SUPublicEDKey'],signature,str(archive)],check=True)
print('PASS: Sparkle identity, build, download URL, length and Ed25519 signature')
