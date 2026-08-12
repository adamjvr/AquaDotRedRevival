# AquaDotRedRevival

A native macOS + iPadOS remaster/reconstruction of **aquadot!red**, built from the surviving original game data and static reverse-engineering evidence.

This project is deliberately **not** an AquaDot-inspired reinterpretation. The recovered maze files, artwork, data formats, manuals, binary behavior, and original asset geometry are the source of truth. Modern Swift, SwiftUI, SpriteKit, Metal-backed rendering, Apple Silicon support, touch input, and modern platform APIs replace obsolete Carbon/SpriteWorld/OpenGL plumbing around that original design.

## Current milestone: Phase 2 — OG-derived Remaster + Behavioral Reconstruction

Phase 1 established a playable authentic-data runtime. Phase 2 now makes that runtime visibly and mechanically AquaDot-specific:

- all **205 recovered standard mazes** remain untouched, CRC-verified source data;
- the scalable wall renderer is driven by the exact recovered wall masks **and overlays the exact recovered original `(lines)`-atlas frame mapping** on its Retina-clean bevel body;
- recovered AquaDot/player, bug, dot and goodie artwork is used as the authority for Original and restored Remastered assets, including direct recovered player-state colors for normal/Munch/Yummy/Yuk/damage;
- the first four original bug color/personality roles are reconstructed as Hunter, Blocker, Sneaker and Hound Dog, assigned as a distinct roster to the E-H start slots and driven by the wrap-aware recovered maze graph;
- Normal/Candy/Crusty/Petrified dots, Yummy/Yuk/Bonus/Multiplier goodies, special powers and Munch mode are implemented from the shipped strategy-guide behavior;
- recovered scoring values, Munch bug values, multiplier behavior and extra-life thresholds are implemented;
- all 81 original `.adrs` Ogg/Vorbis assets are preserved byte-for-byte; 44 Phase 2 runtime sounds are losslessly decoded to ALAC, including level music and every Yummy/Yuk special-power loop, for AVFoundation on modern Apple platforms;
- Original (`O`) and Remastered (`R`) graphics modes share the exact same game simulation;
- Mac keyboard and iPad touch/hardware-keyboard controls feed that same simulation.

The default preservation test level remains **Ewe (1)**. Arrows/WASD move, Space activates an available Yummy power, P/Escape pauses, `[` and `]` cycle original mazes, and backtick toggles the reconstruction overlay.

See [`docs/PHASE2_ARCHITECTURE.md`](docs/PHASE2_ARCHITECTURE.md) for the evidence boundary, renderer policy, dynamic dot rules and constants still awaiting exact binary timing matches.

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

See the Phase 1 and Phase 2 architecture documents under `docs/` for recovered wall semantics, topology evidence, behavior provenance, current limitations, and validation results.

## Preservation note

The original proprietary first-party C/C++ source text was not recovered verbatim. Reconstruction code in this repository is new code based on the shipped data, manuals, binary/disassembly evidence, and recovered subsystem/function metadata. Historical binary/data findings should not be mislabeled as recovered original source.
