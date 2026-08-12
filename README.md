# AquaDotRedRevival

A native macOS + iPadOS remaster/reconstruction of **aquadot!red**, built from the surviving original game data and static reverse-engineering evidence.

This project is deliberately **not** an AquaDot-inspired reinterpretation. The recovered maze files, artwork, data formats, manuals, binary behavior, and original asset geometry are the source of truth. Modern Swift, SwiftUI, SpriteKit, Metal-backed rendering, Apple Silicon support, touch input, and modern platform APIs replace obsolete Carbon/SpriteWorld/OpenGL plumbing around that original design.

## Current milestone: Phase 2.1 — Stabilization + OG Presentation

Phase 1 established the authentic-data runtime and Phase 2 added the first behavioral/remaster pass. Phase 2.1 freezes that working milestone and addresses the two biggest issues found on real hardware: progressive performance degradation and the remaining mismatch in maze-wall presentation.

- the app now launches into a real opening/main menu built from the **recovered original Main-Title artwork**, with Play/Resume, Scores, Options, Help, About and native Mac commands;
- the recovered original options vocabulary is restored, including sound/music levels, mute/disable-music, wall color families, QuickTips, wait-for-click, pretapping, higher-framerate and Let it Snow preferences;
- the Phase 2 per-dot `AVAudioPlayer` churn is replaced with one persistent `AVAudioEngine`, predecoded buffers and a reusable ten-voice one-shot pool;
- collectible rendering is incremental: eating one dot removes one SpriteKit node rather than rebuilding the entire remaining dot field;
- shortest-path distances are cached lazily per source node, matching the recovered original `setupDistanceMatrix` architecture much more closely than repeated BFS calls;
- maze rendering now distinguishes the two visual systems visible in original screenshots: **numeric wall codes use the recovered thin `(lines)` frames**, while contiguous `X` geometry becomes the large glossy/solid wall structure;
- solid maze geometry is batched into four bevel paths instead of thousands of per-cell shape nodes (Ewe (1): roughly 1,092 wall-render nodes in the Phase 2 first pass versus about 12 static wall nodes/sprites in Phase 2.1);
- Original and Remastered modes remain gameplay-identical and the four original wall-palette families from the Carbon options dialog are now selectable;
- a real in-game pause overlay can resume, open options or return to the original opening screen without throwing away the current game session.

The default preservation test level remains **Ewe (1)**. Arrows/WASD move, Space activates an available Yummy power, P/Escape pauses, `[` and `]` cycle original mazes, and backtick toggles the reconstruction/performance overlay.

See [`docs/PHASE2_1_ARCHITECTURE.md`](docs/PHASE2_1_ARCHITECTURE.md) for the performance redesign, recovered opening/options evidence, and the corrected maze renderer.

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
