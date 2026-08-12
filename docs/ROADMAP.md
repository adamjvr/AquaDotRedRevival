# AquaDotRedRevival Roadmap

The roadmap is intentionally organized around a few meaningful system milestones rather than dozens of tiny pseudo-phases.

## Phase 1 — Authentic Core Runtime ✅

**Goal:** prove the original game data can drive a modern native runtime.

Delivered:

- exact recovered maze parser and CRC validation;
- recovered wall-mask semantics;
- maze topology graph and wraps;
- fixed-step player movement;
- dot collection;
- original-level catalog/data assets;
- first original runtime graphics integration;
- native Mac + iPad architecture foundation.

## Phase 2 — Behavioral + Visual Reconstruction ✅

**Goal:** make the runtime actually feel like AquaDot rather than a parser demo.

Delivered:

- recovered/remastered AquaDot visual states;
- reconstructed dot/goodie/special systems;
- four bug personalities and pathfinding;
- bug state/movement/draw behavior;
- original audio preservation + runtime conversion;
- first OG wall-atlas integration;
- Original/Remastered visual modes.

## Phase 2.1 — Stabilization + OG Presentation ✅

**Goal:** fix the first-pass performance architecture and make the app launch/present like a real game.

Delivered:

- persistent pooled `AVAudioEngine` playback;
- incremental collectible rendering;
- cached shortest-path distances;
- corrected maze hierarchy (`X` glossy structures vs numeric thin-line walls);
- recovered original opening/title artwork;
- main menu and app navigation;
- options/preferences flow;
- pause/resume/return-to-opening flow;
- performance/debug instrumentation.

## Phase 2.1.1 — Playability Bugfix Milestone ✅

**Goal:** correct issues exposed by real playthrough testing before expanding scope.

Delivered:

- bug/player contact radius correction so visible collision causes damage;
- moving red AquaDot rotation;
- automatic next-level progression;
- run-level score/bonus/multiplier/lives carry between mazes;
- Phase 2.1 compile hotfix folded into source.

## Stabilization follow-up — NEXT 🔧

**Primary target:** fourth orange level wrap loop.

Work:

- trace all wrap transitions on the failing level;
- reconstruct/strengthen wrap entry/exit state semantics;
- prevent destination wrap re-trigger without changing maze geometry;
- regression-test all recovered wrap pairs;
- run longer multi-level playthroughs looking for progression, collision or pathfinding regressions.

This pass should stay narrow. No giant new subsystem until the current campaign path is stable.

## Phase 3 — Complete Content + Remaster 🧭

**Goal:** take the proven game runtime from “impressively faithful playable reconstruction” to “complete remaster presentation.”

Planned areas:

- deeper original wall-piece reconstruction, including remaining `9w/10w` selection behavior;
- full opening/menu/high-score/help presentation;
- wider original art/audio integration;
- systematic Retina remaster pass with preservation comparison tooling;
- campaign-wide behavior/timing validation;
- visual regression/reference captures;
- final handling for all recovered original content states.

## Phase 4 — Editor + Release Polish 🧭

**Goal:** finish the ecosystem rather than only the game scene.

Planned areas:

- revive the original maze-editor concepts in a modern native editor;
- save/preferences/high-score persistence;
- controller and touch polish;
- accessibility considerations that do not alter core gameplay;
- macOS/iPadOS release packaging;
- preservation/runtime content separation;
- final documentation and attribution/provenance cleanup.

## Project rule

At every phase:

> Recovered original data and behavior outrank convenience, and visual modernization is not allowed to silently redefine gameplay.
