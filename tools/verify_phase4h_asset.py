#!/usr/bin/env python3
from pathlib import Path
import argparse, hashlib, struct, subprocess, sys

TARGET=Path(r"AquaDotRed!Revival/AquaDotRed!Revival/Phase2_1RuntimeAssets.xcassets/P21_OpeningDot_Remastered.imageset/P21_OpeningDot_Remastered.png")
NEW_SHA="d5c0903839711779960f8e9ac98da2722ba0f5dcbcedb4cdfaac67973ced2d71"
NEW_BLOB="b8d4aa2daea9b96a3eda0d431d2a19b65da4b3ff"
SOURCE=Path(r"AquaDotRed!Revival/AquaDotRed!Revival/Phase2_1/AquaDotOpeningView.swift")
SOURCE_BLOB="5ce0deb097e76a52c3e3649c79cf0de0957b3cfd"
CONTENTS=Path(r"AquaDotRed!Revival/AquaDotRed!Revival/Phase2_1RuntimeAssets.xcassets/P21_OpeningDot_Remastered.imageset/Contents.json")
CONTENTS_BLOB="3245286ed3aba7de4dbe32e0f6bb6c84392613ea"
ORIGINAL=Path(r"AquaDotRed!Revival/AquaDotRed!Revival/Phase2_1RuntimeAssets.xcassets/P21_OpeningDot_Original.imageset/P21_OpeningDot_Original.png")
ORIGINAL_BLOB="148d92807e44c835b6d01073740d727ac4446ab2"

def die(msg):
    print(f"FAIL: {msg}",file=sys.stderr); raise SystemExit(1)
def blob(repo,p):
    return subprocess.check_output(["git","hash-object",str(repo/p)],cwd=repo,text=True).strip()
def sha(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for c in iter(lambda:f.read(1<<20),b""): h.update(c)
    return h.hexdigest()
def png_ihdr(p):
    b=p.read_bytes()[:33]
    if len(b)<33 or b[:8]!=b"\x89PNG\r\n\x1a\n" or b[12:16]!=b"IHDR": die("target is not a valid PNG with IHDR")
    w,h,depth,ctype,comp,filt,interlace=struct.unpack(">IIBBBBB",b[16:29])
    return w,h,depth,ctype,interlace

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("repo",type=Path); a=ap.parse_args()
    repo=a.repo.expanduser().resolve()
    t=repo/TARGET
    if not t.is_file(): die(f"missing {TARGET}")
    if sha(t)!=NEW_SHA: die("Phase 4H target SHA-256 mismatch")
    if blob(repo,TARGET)!=NEW_BLOB: die("Phase 4H target Git blob mismatch")
    w,h,d,c,i=png_ihdr(t)
    if (w,h,d,c)!=(1024,1024,8,6): die(f"PNG format mismatch: {w}x{h} depth={d} colorType={c}")
    if blob(repo,SOURCE)!=SOURCE_BLOB: die("opening-view Swift source changed; Phase 4H expects it untouched")
    if blob(repo,CONTENTS)!=CONTENTS_BLOB: die("Remastered imageset Contents.json changed; Phase 4H expects it untouched")
    if blob(repo,ORIGINAL)!=ORIGINAL_BLOB: die("Original-mode opening asset changed; preservation check failed")
    print("PASS Phase 4H target: 1024x1024 RGBA8")
    print("PASS target SHA-256 / Git blob")
    print("PASS opening-view source unchanged")
    print("PASS imageset Contents.json unchanged")
    print("PASS Original-mode opening asset unchanged")
if __name__=="__main__": main()
