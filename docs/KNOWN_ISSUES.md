# Known Issues

This file tracks observed runtime failures separately from longer-term reverse-engineering targets.

## P0/P1 — observed gameplay bugs

### Fourth orange level: wrap / teleport loop

**Status:** open  
**Observed in:** Phase 2.1.1 milestone

On the fourth level reached through normal automatic progression, some wrap/teleport entries can place AquaDot into a repeated teleport loop.

Important observation: pause and return-to-opening remain responsive while the loop is happening. That strongly suggests the application and fixed-step simulation are still running; the player is repeatedly satisfying wrap-trigger conditions rather than the game entering a hard lock.

Likely investigation path:

1. Identify the exact level record and all `A/B/C/D` wrap pairs.
2. Log source wrap, destination wrap, player node/progress and movement direction for each transition.
3. Verify whether the destination position lands inside the paired wrap's immediate trigger condition.
4. Compare against recovered `MazeWraps.cc` behavior and original wrap validation logic.
5. Prefer an explicit wrap state such as **must leave destination trigger region before another wrap can fire** over a blind cooldown timer.
6. Regression-test every wrap pair in the recovered standard maze corpus.

Do not “fix” this by changing original maze coordinates.

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
