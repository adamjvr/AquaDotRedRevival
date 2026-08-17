# Phase 4A — Original Solid-Wall Restoration

Phase 4A replaces the procedural contiguous-`X` wall network **only in Original graphics mode** with the preserved AquaDot wall sheets and the recovered i386 selector/draw path. Remastered mode intentionally keeps the scalable Phase 2 renderer.

## Recovered binary contract

- `_loadMaze` enters the solid selector only when the current edge cell is `0x10` (`X`).
- The call at `0x3E053` enters `_drawMazePiece` at `0x37878`.
- `_drawMazePiece` consumes four wall types and four frame indices and draws quadrants clockwise: top-left, top-right, bottom-right, bottom-left.
- Wall types 0/1/2/3 correspond to the preserved `9w x 9h`, `10w x 9h`, `9w x 10h`, and `10w x 10h` sheets.
- The SpriteWorld loader arguments recover frame size/gap/count as 9x9+36/36 (16), 10x9+40/36 (20), 9x10+36/40 (20), and 10x10+40/40 (92). Option `0x40` centers each small frame inside the gap; its SpriteWorld constant is exactly 0.5.
- `_loadMazeWalls` expands source rectangles by 10 pixels for 10x9 indices 8..11, 9x10 indices 8..11, and 10x10 bands 4..19, 24..39, 44..59, 64..79 with the recovered directional mutations.
- `_drawMazePiece` mirrors those expanded dimensions in its destination rectangles.
- The float used as the solid-wall maze step is exactly **18.0** (`0x76D98`); the one-pixel 10-wide/10-high overhang constant is exactly **1.0** (`0x76984`).

## Selector recovery

The original selector is a large i386 branch tree. Phase 4A does not hand-invent a simplified mapping. The machine-code region was executed exhaustively over the complete reduced eight-neighbor raw-state domain. That produced 25,889 reachable 16-bit selector keys and 1,442 unique packed outputs. The runtime stores the result in a 65,536-entry, five-byte-per-key lookup table.

Selector blob SHA-256: `d1170adb33882ffbed518df76edd75b38f05ced8f254fbce6fef781645bc11c9`

Two high-value direct checks:

- isolated `X`: types `[3,3,3,3]`, frames `[3,23,43,63]`
- `X` with all four cardinal neighbors solid: types `[0,0,0,0]`, frames `[0,1,2,3]`

## Preserved assets

The package contains 52 RGBA wall sheets: 13 shipped runtime themes x four solid sheet types. RGB pixels come directly from the preserved JPEG resources. Alpha is the exact inversion of the shared legacy GIF masks, matching the conversion already used by the Phase 2 recovered `(lines)` atlases.

## Scope boundary

Recovered in this phase: selector states, frame-sheet layout, source-rect expansions, destination-rect expansions, 18-pixel wall-grid geometry, draw order, and original wall pixels/alpha.

Still **not** claimed as recovered here: the exact legacy color-processing function invoked after wall sprite setup. Until that is disassembled separately, Original mode retains Revival's current wall-palette tint on top of the recovered grayscale material/light maps.

Malformed/custom wall arrangements that lead to a selector state the historical routine did not initialize fall back to the previous procedural solid network rather than crash. Standard shipped mazes are expected to remain on the recovered path.
