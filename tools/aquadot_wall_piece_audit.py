#!/usr/bin/env python3
"""Inventory the recovered 9w/10w wall-piece atlases used by _drawMazePiece.

This is a forensic helper, not a renderer claim. It reads the preserved graphics
ZIP already committed under preservation/ and reports the exact source dimensions
available for the four solid-piece families plus `(lines)`.
"""
from __future__ import annotations
import argparse, io, re, struct, zipfile
from collections import defaultdict
from pathlib import Path

PNG_SIG=b'\x89PNG\r\n\x1a\n'

def image_size(data: bytes):
    if data.startswith(PNG_SIG) and len(data)>=24:
        return struct.unpack('>II',data[16:24])
    if data[:2]==b'\xff\xd8':
        # minimal JPEG dimension scan
        i=2
        while i+9 < len(data):
            if data[i] != 0xFF: i+=1; continue
            marker=data[i+1]; i+=2
            if marker in (0xD8,0xD9): continue
            if i+2>len(data): break
            length=int.from_bytes(data[i:i+2],'big')
            if marker in range(0xC0,0xC4):
                return int.from_bytes(data[i+5:i+7],'big'), int.from_bytes(data[i+3:i+5],'big')
            i += length
    return None

def main():
    p=argparse.ArgumentParser()
    p.add_argument('zip', nargs='?', type=Path, default=Path('preservation/aquadot_graphical_assets.zip'))
    args=p.parse_args()
    families=defaultdict(list)
    with zipfile.ZipFile(args.zip) as z:
        for name in z.namelist():
            if '/Walls/' not in name or not re.search(r'Wall 001 .*\.(png|jpg|jpeg)$',name,re.I):
                continue
            if not any(tag in name for tag in ('9w x 9h','10w x 9h','9w x 10h','10w x 10h','(lines)')):
                continue
            data=z.read(name); size=image_size(data)
            theme=re.search(r'Walls (\d+)',name)
            family=next(tag for tag in ('9w x 9h','10w x 9h','9w x 10h','10w x 10h','(lines)') if tag in name)
            families[family].append((theme.group(1) if theme else '?',size,name))
    print('_drawMazePiece recovered source atlas inventory')
    for family in ('9w x 9h','10w x 9h','9w x 10h','10w x 10h','(lines)'):
        rows=sorted(families[family])
        sizes=sorted({size for _,size,_ in rows})
        print(f'{family:10} themes={len(rows):2} sizes={sizes}')
    print('\nNOTE: dimensions/provenance are recovered; exact mazePieceIndex selection is still under RE.')
    return 0 if all(families[f] for f in families) else 1
if __name__=='__main__': raise SystemExit(main())
