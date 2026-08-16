# Phase 3 — Campaign Authenticity: First Build

Base milestone: **Phase 2.1.2 wrap / teleport stabilization** (`683c769`).

## Added

- Real **Game Over** state: zero lives now ends the run instead of respawning forever.
- Recovered Game Over artwork in Original and Retina-remastered form.
- End-level accounting using the documented `(Bonus + Skill) × Multiplier` structure.
- Explicitly isolated provisional Skill weights, based only on factors named by the shipped strategy guide.
- Recovered tween-level labels and 30-frame end-level exclamation atlas in the live runtime.
- Level-local Bonus semantics: Bonus is consumed by the end-level calculation and resets for the next maze.
- Original-style auto-save/checkpoint persistence across app launches.
- Resume semantics matching recovered binary strings: mid-level resumes at that level's beginning; post-level resumes at the next level's beginning.
- Durable **Today's Best / Best Scores Ever** high-score tables using recovered heading artwork.
- Persistent Game Over score recording (`anonymous` until the recovered name-entry UI is reconstructed).
- Campaign-wide 205-level audit tool.
- Recovered solid-wall atlas inventory/audit tool and deeper `_drawMazePiece` documentation.

## Preserved

- Phase 2.1.2 wrap stabilization and same-side portal behavior.
- Current Ewe (1)-based preservation/campaign start while exact original random-level sequencing remains under RE.
- Existing four reconstructed bug personalities.
- Original/Remastered gameplay equivalence.
- Persistent pooled audio engine and incremental SpriteKit renderer.

## Still deliberately incomplete

- Exact original Skill numeric weights.
- Exact original random level-selection progression.
- Full `9w/10w` `mazePieceIndex[4]` solid-wall selection table.
- Original high-score name-entry flow.
- Remaining four full-version bug types (Protector, Mantis, Hermit, Neon).
- Complete infection/sprout/cure reconstruction.
- Full end-level audio mapping; existing runtime audio set does not yet contain all recovered tween resources.

Those are Phase 3 targets, not things this patch pretends are solved.
