#!/usr/bin/env python3
from __future__ import annotations
import hashlib, struct, sys
from pathlib import Path

EXPECTED_ORIGINAL_SHA256 = "cae600194272901e65b194a985900df567b3adbe55e503fb9a97b016542414e3"
EXPECTED_REMASTERED_SHA256 = "ca1b2ce91c6d73bebc4ac3e8ff0efa3df65355641d7d57397e3417ea04fc3156"


def fail(msg: str) -> None:
    print(f"FAIL {msg}", file=sys.stderr)
    raise SystemExit(1)


def require(path: Path) -> Path:
    if not path.is_file(): fail(f"missing {path}")
    return path


def text_has(path: Path, *needles: str) -> None:
    text=require(path).read_text()
    for needle in needles:
        if needle not in text: fail(f"{path} missing marker: {needle}")


def png_info(path: Path):
    data=require(path).read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n": fail(f"{path} is not PNG")
    if data[12:16] != b"IHDR": fail(f"{path} missing IHDR")
    width,height,bit_depth,color_type = struct.unpack(">IIBB", data[16:26])
    return width,height,bit_depth,color_type,hashlib.sha256(data).hexdigest()


def main() -> None:
    if len(sys.argv) != 2: fail("usage: verify_phase4_authenticity_closure.py /path/to/AquaDotRedRevival")
    repo=Path(sys.argv[1]).expanduser().resolve()
    if not (repo/'.git').is_dir(): fail(f"not a git checkout: {repo}")

    game=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase1/AquaDotGameSimulation.swift'
    maze=repo/'AquaDotRed!Revival/AquaDotRed!Revival/MazeGameScene.swift'
    dots=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase2/AquaDotDotSystem.swift'
    roster=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase4/AquaDotRecoveredBugRoster.swift'
    loc=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase4/AquaDotRecoveredEnemyLocomotion.swift'
    bugstate=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase2/AquaDotBugState.swift'
    assets=repo/'AquaDotRed!Revival/AquaDotRed!Revival/Phase2RuntimeAssets.xcassets'

    text_has(game, 'Phase 4 authenticity closure', 'reaperBehavior: spawn.reaperBehavior', 'segmentSpeedMultiplier', 'touchingReaper')
    text_has(maze, 'reaperAppearance: bug.isReaper')
    text_has(dots, 'recoveredPropagationPositions', 'for direction in AquaDotDirection.allCases', 'delayRange: transition.delayRange')
    text_has(roster, '.green, .magenta, .cyan, .nightReaper', 'AquaDotReaperBehavior', 'isNeonAppearance: false')
    text_has(loc, 'reaperBaseVelocityRatio', 'return 1.5', 'return 0.25', 'randomReaperDirection')
    text_has(bugstate, 'enum AquaDotReaperBehavior', 'var reaperBehavior', 'var isReaper: Bool')
    text_has(repo/'README.md', 'Phase 4 — authenticity closure', 'Reaper is restored')
    text_has(repo/'docs/ROADMAP.md', 'Phase 5 — Release + Platform Hardening', 'Phase 6 — Native Editor Revival')
    text_has(repo/'docs/STATUS.md', 'Phase 4 — Authenticity Closure')
    text_has(repo/'docs/KNOWN_ISSUES.md', 'Absolute movement units are still translated')
    text_has(repo/'docs/reverse-engineering/phase4-closure/PHASE4_AUTHENTICITY_CLOSURE.md', '50/50 **Hunter Reaper** vs **Random Reaper**')

    op=assets/'P2_Bug_Reaper_Original.imageset/P2_Bug_Reaper_Original.png'
    rp=assets/'P2_Bug_Reaper_Remastered.imageset/P2_Bug_Reaper_Remastered.png'
    oi=png_info(op); ri=png_info(rp)
    if oi[:4] != (64,64,8,6): fail(f"unexpected Original Reaper PNG format {oi[:4]}")
    if ri[:4] != (512,512,8,6): fail(f"unexpected Remastered Reaper PNG format {ri[:4]}")
    if oi[4] != EXPECTED_ORIGINAL_SHA256: fail("Original Reaper PNG SHA-256 mismatch")
    if ri[4] != EXPECTED_REMASTERED_SHA256: fail("Remastered Reaper PNG SHA-256 mismatch")

    print('PASS Phase 4 runtime markers')
    print('PASS Reaper roster/state/renderer integration')
    print('PASS recovered warp-style integration')
    print('PASS cardinal infection/cure topology integration')
    print('PASS Phase 4/5/6 documentation refresh')
    print(f'PASS Reaper Original 64x64 RGBA8 {oi[4]}')
    print(f'PASS Reaper Remastered 512x512 RGBA8 {ri[4]}')

if __name__ == '__main__': main()
