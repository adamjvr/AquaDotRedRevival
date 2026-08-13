# Known Issues

This file tracks observed runtime failures separately from longer-term reverse-engineering targets.

## P0/P1 — observed gameplay bugs

### Fourth orange level: wrap / teleport loop

**Status:** fixed in Phase 2.1.2; soak testing ongoing  
**Observed in:** Phase 2.1.1 milestone

The failure was reproduced from the recovered maze geometry rather than treated as a random runtime hang. **Ewe (4)** contains a bottom-to-bottom `A` wrap pair at `(12,30)` and `(27,30)`. Phase 2.1.1 teleported the player to the paired endpoint while preserving the entry direction. Because both endpoints face `down`, that direction was still the destination's outward wrap direction, so the next fixed-step iteration could immediately teleport back.

Phase 2.1.2 changes wrap semantics to:

1. materialize at the paired endpoint;
2. determine that endpoint's outer-boundary direction;
3. force the first segment **inward** into the maze;
4. if held player input still points outward on a same-facing pair, suppress only that direction until the player chooses another;
5. apply the same forced-inward exit rule to bugs.

This is structural rather than Ewe-specific. A corpus audit found **462 wrap pairs / 924 endpoints** in the 205 recovered standard mazes, including **93 pairs whose endpoints share the same boundary**. Every recovered endpoint has a valid inward traversable neighbor.

Remaining work is playthrough/soak validation, not changing original maze coordinates.

---

## Reverse-engineering / fidelity targets

### Exact solid-wall sub-piece selection

The corrected renderer now distinguishes large `X` structures from numeric thin-line walls, but the complete historical `9w/10w` `_drawMazePiece` selection table is not yet reconstructed.

Current behavior is a faithful scalable reconstruction, not a claim of pixel-exact equivalence for every solid-wall sub-piece.

### Exact gameplay constants

Several speed, timer, energy and behavior constants are reconstructed from observed behavior and surviving evidence. They should remain isolated/tunable until stronger binary evidence is recovered.

### Bug AI tuning

The architectural behavior is in place, but the four personalities should be validated across a wider sample of original levels, especially around wraps, intersections, Munch recovery and trail-following behavior.

---

## Presentation / app completeness

- High-score persistence and complete Scores presentation are not finished.
- Help/About text/presentation is functional but not final-release quality.
- Menu/front-end animation can still be pushed closer to the original.
- iPad layout/touch/controller behavior needs wider hardware testing.
- Final save/preferences/controller/accessibility/release packaging work remains future work.

---

## Reporting a regression

Useful bug reports include:

- maze name / progression number;
- graphics mode;
- exact movement direction into the failure;
- whether pause/menu remains responsive;
- backtick overlay FPS/node/audio values;
- terminal/Xcode runtime log;
- screenshot or short capture when visual state matters.
