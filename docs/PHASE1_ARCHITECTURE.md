# Phase 1 — Authentic Core Runtime

## Goal

Phase 1 turns AquaDotRedRevival from a visual mockup into the first playable preservation/remaster runtime. A successful Phase 1 build loads untouched original maze bytes, validates the original checksum, reconstructs the maze graph and wrap topology, draws the original level design, moves AquaDot through legal paths, consumes the original dot placements, and runs on native macOS and iPadOS from the same simulation.

## Source-of-truth policy

For the remaster, priority is:

1. shipped original maze/data bytes;
2. shipped original graphical assets;
3. behavior documented by the original manuals/editor;
4. behavior recovered from binary/disassembly evidence;
5. inference only where the above do not yet answer the question.

Modern APIs are an implementation detail. They do not redefine AquaDot's level geometry or visual identity.

## Runtime layers

```text
OriginalLevelData.xcassets
  205 untouched maze payloads
              │
              ▼
       AquaDotLevelLoader
              │
              ▼
       AquaDotMazeParser
        MacRoman + CRC16
              │
              ▼
          AquaDotMaze
       raw recovered tokens
              │
              ▼
      AquaDotMazeTopology
  vertices / edges / wraps / walls
              │
              ▼
      AquaDotGameSimulation
  movement / collection / completion
              │
              ▼
         MazeGameScene
   original assets + SpriteKit
```

## Exact recovered wall mask

The numeric wall value in an original maze is a compact four-direction bit field. It is **not** a sprite-frame index.

| Direction | Bit |
|---|---:|
| east | `0x01` |
| south | `0x02` |
| west | `0x04` |
| north | `0x08` |

This mapping was recovered twice: first statistically across the shipped maze corpus, then directly from the editor i386 neighbor-checking code. The editor's internal wall-selection frame mapping was also recovered:

| Editor frame | mask |
|---:|---:|
| 0 | `0x8` |
| 1 | `0x1` |
| 2 | `0x2` |
| 3 | `0x4` |
| 4 | `0x9` |
| 5 | `0x3` |
| 6 | `0x6` |
| 7 | `0xC` |
| 8 | `0x7` |
| 9 | `0xE` |
| 10 | `0xD` |
| 11 | `0xB` |
| 12 | `0x5` |
| 13 | `0xA` |
| 14 | `0xF` |

The shipped standard maze files use numeric masks 1 through 14; the editor also knows the full `0xF` cross/intersection form internally.

Special edge-row fields remain semantic rather than being forced into the bitmask:

- `_` — open/no wall cell;
- `X` — solid/blocked cell;
- `^` — wrap-boundary cell.

## Navigation topology recovered from the standard corpus

A traversable vertex is any original vertex token other than `:` (and unknown/unrecognized data). Cardinally adjacent traversable vertices form ordinary corridor edges. Each matching A-D pair adds its original wrap edge.

This was validated against every recovered standard level:

- **205/205** parse successfully;
- **205/205** pass their stored original CRC;
- **205/205** become one connected navigation graph when original A-D wrap pairs are included.

This separation matters: numeric wall-cell art describes the maze's visible solid geometry, while the vertex lattice describes where dots/actors can travel.

## Original start markers

The runtime preserves every `S`. Many shipped levels contain two adjacent `S` markers; Phase 1 uses that pair as the initial movement segment/orientation instead of discarding the second marker. Levels containing only one `S` are also accepted and begin stationary until input selects a legal direction.

`E F G H` enemy/lair positions are preserved in the topology now, even though enemy behavior belongs to Phase 2.

## Fixed-step simulation

SpriteKit render cadence is not game time. `MazeGameScene` accumulates real frame time and advances the game at a fixed 120 Hz simulation step. A 60 Hz Mac display and a high-refresh iPad therefore use the same logical movement rules.

Phase 1 scoring and movement-speed constants are deliberately isolated in `AquaDotGameSimulation.Tuning`. Exact original timing/scoring values remain reconstruction targets and can be replaced without changing file parsing or topology.

## Original artwork in Phase 1

Runtime image assets are derived only from recovered originals:

- red AquaDot underlay frame;
- extra-life AquaDot;
- basic dot;
- inert/static dot art for the Phase 1 Munch representation;
- wraparound warp frame + recovered alpha;
- original 800x50 status-panel artwork;
- original title artwork retained for presentation work.

The full recovered graphical-asset package is preserved unchanged under `preservation/aquadot_graphical_assets.zip` so later remaster passes can consume the complete Bugs, Play, Opening, Snow, Walls, icons, resource-fork PICT/cursor material, editor art, and documentation graphics without going back to the disk image.

### Wall artwork status

The original game contains fourteen wall visual themes (`Walls 000` through `Walls 013`) built from multiple grayscale/alpha sprite atlases. Phase 1 already uses the **exact recovered wall topology/masks**, and the renderer deliberately matches the green beveled style visible in the original strategy-guide gameplay captures.

Pixel-identical atlas-piece selection requires one remaining rendering-specific reconstruction: mapping the old 9w/10w atlas variants and frame-selection context used by `_drawMazePiece`. That is now isolated to the renderer and does not block authentic navigation or maze data. Once mapped, those original atlas pieces can replace the temporary procedural bevel without touching simulation code.

## Controls

### macOS

- arrows / WASD — movement
- space / P — pause
- `[` / `]` — previous / next recovered standard maze
- backtick — preservation debug overlay

### iPadOS

- swipe — movement
- hardware arrow keys / WASD — movement
- hardware space / P — pause

Controller mapping is already represented by the logical input layer and can be attached without modifying the simulation.

## Phase 1 validation gate

Before this patch was packaged, the pure Swift parser/topology code was compiled with Swift 6.2.1 on Linux and run against the 205 original standard maze files. Result:

```text
Swift Phase1 validation: parsed=205, CRC-valid=205, connected-with-wraps=205
```

SpriteKit/AppKit/UIKit source requires Xcode/Apple SDKs and therefore must be compiled on the target Mac after applying the patch.
