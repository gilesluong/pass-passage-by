import struct, sys
from pathlib import Path
chunks=[]
for code,name in [('icp4','icon_16x16.png'),('icp5','icon_32x32.png'),('icp6','icon_32x32@2x.png'),('ic07','icon_128x128.png'),('ic08','icon_256x256.png'),('ic09','icon_512x512.png'),('ic10','icon_512x512@2x.png')]:
 data=Path('/tmp/Passage.iconset',name).read_bytes()
 chunks.append(code.encode()+struct.pack('>I',len(data)+8)+data)
body=b''.join(chunks)
Path(sys.argv[1] if len(sys.argv)>1 else 'Passage.app/Contents/Resources/Passage.icns').write_bytes(b'icns'+struct.pack('>I',len(body)+8)+body)
