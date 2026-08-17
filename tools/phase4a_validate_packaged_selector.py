#!/usr/bin/env python3
"""Phase 4A packaged selector/asset structural validation."""
from pathlib import Path
import base64, hashlib, re, sys
ROOT=Path(__file__).resolve().parents[1]
swift=ROOT/'AquaDotRed!Revival/AquaDotRed!Revival/Phase4/AquaDotOriginalSolidWallRenderer.swift'
text=swift.read_text()
m=re.search(r'let encoded = """\n(.*?)\n"""', text, re.S)
assert m, 'selector Base64 not found'
blob=base64.b64decode(''.join(m.group(1).split()))
assert len(blob)==65536*5, len(blob)
assert hashlib.sha256(blob).hexdigest()=='d1170adb33882ffbed518df76edd75b38f05ced8f254fbce6fef781645bc11c9'
def decode(k):
    p=int.from_bytes(blob[k*5:k*5+5],'little')
    if p==(1<<40)-1:return None
    return [((p>>(q*9))&3,(p>>(q*9+2))&0x7f) for q in range(4)]
assert decode(0)==[(3,3),(3,23),(3,43),(3,63)]
assert decode(0x000f)==[(0,0),(0,1),(0,2),(0,3)]
assets=list((ROOT/'AquaDotRed!Revival/AquaDotRed!Revival/Phase4RuntimeAssets.xcassets').glob('P4A_SolidWall_*_Original.imageset'))
assert len(assets)==52, len(assets)
print('PASS selector blob:',len(blob),'bytes SHA-256 d1170adb33882ffbed518df76edd75b38f05ced8f254fbce6fef781645bc11c9')
print('PASS known selector states: isolated + four-cardinal')
print('PASS solid wall asset sets:',len(assets),'(13 themes x 4 SpriteWorld sheet types)')
