# Phase 3 Wall Renderer Reverse-Engineering Notes

The remaining major visual-authenticity target is the original solid-wall `_drawMazePiece` path.

## Confirmed architecture

Recovered i386 disassembly shows `_drawMazePiece` receiving two four-element concepts:

```text
mazePieceType[4]
mazePieceIndex[4]
```

Each `mazePieceType` value is asserted to be in `0...3`. The four types correspond to the four recovered solid-wall sprite families:

```text
0/1/2/3 -> one of:
  9w x 9h
  10w x 9h
  9w x 10h
  10w x 10h
```

The function draws four local pieces/quarters and uses `mazePieceIndex` to select a frame from the chosen family's frame array. The separate `(lines)` atlas is the thin numeric-wall system already mapped in Phase 2/2.1.

## Recovered source atlas dimensions

Across all 14 recovered wall themes, the source files are consistently:

| Family | Source dimensions |
|---|---:|
| 9w × 9h | 180 × 180 |
| 10w × 9h | 200 × 225 |
| 9w × 10h | 180 × 250 |
| 10w × 10h | 200 × 1150 |
| lines | 160 × 520 |

The unusually tall 10×10 atlas strongly indicates a much larger frame vocabulary than a simple 16-way connectivity mask.

## What remains unsolved

The call site inside the original maze-loading path computes the four type/index pairs before calling `_drawMazePiece`. That selection logic still needs to be reduced into a trustworthy modern table/algorithm.

Until that is decoded, the current scalable glossy `X` renderer remains a **faithful reconstruction** rather than a pixel-exact claim.

Run:

```bash
python3 tools/aquadot_wall_piece_audit.py
```

from the repo root to inventory the preserved sources on macOS or Linux.
