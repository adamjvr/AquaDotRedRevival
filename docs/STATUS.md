# AquaDotRedRevival — Current Status

**Current milestone:** Phase 2.1.2 — Wrap Stabilization  
**Patch base:** `445d40fa58718bd060858efe4f9dd2968ec23d20`  
**Primary runtime target:** native macOS  
**Shared platform target:** iPadOS

## Working

- Recovered standard maze corpus is bundled and loadable.
- Original maze CRC/checksum verification is implemented.
- Maze topology, corridor movement, intersections and wrap edges are active.
- Wrap transitions now force an inward exit segment at the destination endpoint; same-facing held input is gated so a paired endpoint cannot immediately re-trigger itself.
- Player movement and dot collection work.
- Normal red AquaDot spins while moving.
- Bug collision drains energy after the Phase 2.1.1 contact-radius correction.
- Four reconstructed bug personalities are live.
- Normal dots, Munch dots and reconstructed special/goodie systems are present.
- Clearing the required dot field triggers automatic next-level progression.
- Score, bonus, multiplier and lives carry across normal level transitions.
- Original and Remastered graphics modes are available.
- Recovered player, bug, dot, HUD, opening/menu and wall artwork is integrated.
- Corrected maze visual hierarchy: large glossy `X` structures + recovered thin numeric wall frames.
- Opening/main menu, pause, options, help/about routes and return-to-opening flow work.
- Persistent pooled `AVAudioEngine` runtime replaces per-dot `AVAudioPlayer` allocation.
- Collectible rendering is incremental.
- Pathfinding distance results are cached.
- Debug overlay exposes FPS, SpriteKit node count and pooled audio voice activity.

## Known broken / incomplete

- The Phase 2.1.1 Ewe (4) orange-level teleport loop is fixed in Phase 2.1.2; campaign-wide wrap soak testing is still ongoing.
- Exact historical `9w/10w` solid-wall piece selection remains incomplete.
- Some original numeric movement/timing/energy constants remain reconstructed/tuned rather than proven exact.
- Bug behavior is substantially reconstructed but still needs broad level-by-level tuning/validation.
- Scores route exists, but complete high-score persistence/presentation is not finished.
- Help/About/options presentation still needs final release polish.
- Full campaign-wide regression testing is ongoing.
- iPadOS requires broader device/layout/input validation.
- Editor revival has not started as a production feature.

## Current quality bar

The macOS build is now a **playable preservation/remaster milestone**, not merely a rendering prototype. The next work should favor regression fixes and authenticity over piling on unrelated features.
