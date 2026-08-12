# AquaDotRedRevival

A native macOS + iPadOS remaster/reconstruction of **aquadot!red**, built from the surviving original game data and static reverse-engineering evidence.

This project is deliberately **not** an AquaDot-inspired reinterpretation. The recovered maze files, artwork, data formats, manuals, binary behavior, and original asset geometry are the source of truth. Modern Swift, SwiftUI, SpriteKit, Metal-backed rendering, Apple Silicon support, touch input, and modern platform APIs replace obsolete Carbon/SpriteWorld/OpenGL plumbing around that original design.

## Current milestone: Phase 1 — Authentic Core Runtime

Phase 1 replaces the old hard-coded `TestLevels.levelOne` prototype path with a playable original-data runtime:

- all **205 recovered standard mazes** are preserved and included as untouched data assets;
- the original Maze Description Format 1.0 is parsed directly;
- the original CRC is verified before a level is accepted;
- exact wall bit directions recovered from the editor are implemented (`N=0x8 E=0x1 S=0x2 W=0x4`);
- the playable graph is reconstructed from original path vertices plus A-D wrap pairs;
- player movement is graph-based and fixed-step;
- normal dots and static Munch dots come from the original level data;
- the original status-panel, AquaDot, dot, wrap, and related art is used by the SpriteKit renderer;
- original graphical assets are kept intact in `preservation/` while runtime-ready derivatives remain traceable to them;
- native Mac keyboard and iPad touch/hardware-keyboard input feed the same logical actions.

The default preservation test level is **Ewe (1)**. On Mac, use arrow keys or WASD. `[` and `]` step through the recovered standard maze catalog. The backtick key toggles the topology/wall-mask debug overlay.

## Architecture

```text
Recovered original maze bytes
          │
          ▼
AquaDotMazeParser  ── CRC verification
          │
          ▼
     AquaDotMaze             archival/file model
          │
          ▼
 AquaDotMazeTopology         semantic graph + wraps + wall masks
          │
          ▼
AquaDotGameSimulation        platform-independent fixed-step rules
          │
          ▼
     MazeGameScene           SpriteKit presentation
          │
    ┌─────┴─────┐
    ▼           ▼
 native Mac    iPadOS
```

The important rule is **file format != simulation != renderer**. Remastered textures must never change maze coordinates, collisions, pathfinding, or timing.

See [`docs/PHASE1_ARCHITECTURE.md`](docs/PHASE1_ARCHITECTURE.md) for recovered wall semantics, topology evidence, current limitations, and validation results.

## Preservation note

The original proprietary first-party C/C++ source text was not recovered verbatim. Reconstruction code in this repository is new code based on the shipped data, manuals, binary/disassembly evidence, and recovered subsystem/function metadata. Historical binary/data findings should not be mislabeled as recovered original source.
