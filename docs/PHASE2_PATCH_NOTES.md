# Phase 2 patch notes

## What this patch is

This is the first broad **remaster/behavior** pass after Phase 1 proved the authentic maze runtime. It makes the game much more visibly and mechanically AquaDot-specific without replacing the preservation architecture.

## Major changes

- five OG AquaDot visual states rebuilt directly from recovered underlay/ring/spot assets (normal, Munch, Yummy, Yuk, damage), plus 4x remastered derivatives.
- Four guide-confirmed original bug appearances added with 4x remastered derivatives.
- scalable, Retina-clean beveled/tubular wall renderer driven by recovered wall masks;
- exact `_drawLineIntersections` frame map recovered and used to overlay the original per-theme `(lines)` atlas frame on each scalable wall junction;
- 13 colorized wall materials matching the shipped game's grayscale-atlas/colorized-wall approach and guide presentation;
- dynamic Normal/Candy/Crusty/Petrified dot states;
- Yummy/Yuk/Bonus/Multiplier goodie system;
- Yummy and Yuk special-power state, guide-matched pulse colors, Blind visibility, Sick collection restriction, and original per-power audio loops;
- Munch mode and edible bugs;
- four evidence-backed bug personalities using wrap-aware BFS/pathfinding;
- energy, lives, bonus, multiplier and documented score/extra-life rules;
- event bus from simulation to presentation/audio;
- 44 lossless original-audio runtime copies played through AVFoundation, including the six level tracks and all Yummy/Yuk start+loop power sounds;
- all shipped `.adrs` audio preserved byte-for-byte in a ZIP;
- Original/Remastered runtime graphics switch (`O` / `R` on Mac);
- expanded preservation/debug overlay;
- Phase 2 tests and corpus validation.

## Important honesty boundary

This is not being mislabeled as a cycle-exact port. The original rules and subsystem shape are reconstructed from shipped evidence, but some numeric timing constants remain approximations until individual disassembly paths are matched. They are isolated in tuning structures so they can be corrected without redesigning the engine.

The exact old 9w/10w wall-atlas piece-selection logic also remains an active reconstruction target. Phase 2 **does** use the exact recovered game `(lines)`-atlas frame index for every numeric wall mask, layered over an OG-derived scalable bevel body; it does not pretend that the still-unmapped 9w/10w piece-selection path is solved.
