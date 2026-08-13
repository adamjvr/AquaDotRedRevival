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

## Phase 2.1.2 — Wrap / Teleport Stabilization ✅

**Goal:** fix the orange Ewe (4) loop at the actual simulation boundary instead of hiding it with a timer.

Delivered:

- traced Ewe (4) to a same-bottom `A` wrap pair;
- made every wrap destination expose an explicit inward direction;
- force AquaDot through one inward corridor segment after materializing at a wrap destination;
- gate same-facing held player input until a different direction is chosen;
- force bugs inward after wraps as well, preventing AI reverse-avoidance from repeatedly selecting the portal;
- audited the recovered standard corpus: **462 wrap pairs / 924 endpoints**, including **93 same-side pairs**;
- verified every recovered endpoint has a valid inward traversable neighbor;
- added a synthetic regression that reproduces the old same-bottom loop and proves only one wrap event fires.

## Stabilization soak — NEXT 🔧

Work:

- play Ewe (3), Ewe (4), Ewe (5) through naturally and deliberately exercise every visible wrap;
- run longer multi-level playthroughs looking for progression, collision, audio or pathfinding regressions;
- only then open the Phase 3 scope.

No giant new subsystem until this campaign path is stable.

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
