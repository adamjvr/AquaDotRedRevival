# AquaDotRedRevival Status

**Current milestone:** Phase 3 — Campaign Authenticity Foundation  
**Base:** Phase 2.1.2 (`683c769`)  
**Primary runtime target:** native macOS  
**Shared platform target:** iPadOS

## Working

- All **205 recovered standard mazes** are bundled and CRC-verifiable.
- Fixed-step topology, collisions, bug movement, same/adjacent-side wraps and automatic progression work.
- Recovered/remastered player, bug, collectible, wall, HUD and opening/menu graphics are live.
- Persistent pooled AVAudioEngine playback and incremental rendering remain stable.
- Normal/Munch dots and reconstructed Yummy/Yuk/Bonus/Multiplier systems are playable.
- Bug contact drains Energy; zero Energy costs a life.
- **Zero lives now ends the run with a recovered-art Game Over presentation.**
- End-level Score now uses the documented **(Bonus + Skill) × Multiplier** structure.
- Bonus is consumed per level instead of leaking into later mazes.
- Recovered tween-level label/exclamation artwork is used for the level summary.
- Original-style beginning-of-level auto-save/resume persists across app launches.
- Post-level checkpoints target the next maze immediately, matching recovered resume strings.
- New Game erases the previous auto-save.
- High scores persist and populate recovered **Today’s Best / Best Scores Ever** presentation.
- `tools/aquadot_campaign_audit.py` validates the whole recovered campaign corpus.
- `tools/aquadot_wall_piece_audit.py` inventories the four recovered `_drawMazePiece` atlas families.

## Known incomplete / reconstructed

- Exact original numeric Skill weights are not yet recovered; current weights are isolated and explicitly provisional.
- Exact original random level-selection sequence is still under binary RE; the current Ewe-based progression path remains deterministic for testing.
- Full `9w/10w` solid-wall `mazePieceIndex[4]` selection is not yet solved.
- High-score name entry is not reconstructed yet; current Game Over runs record as `anonymous`.
- Only four of the eight guide-documented bug types are implemented.
- Infection/sprout/cure systems remain a major Phase 3 target.
- Some timing/energy constants remain tuned reconstructions.
- iPadOS needs broader device/input/layout regression testing.

## Current quality bar

The project now has a persistent campaign lifecycle, not just a collection of playable mazes. The next Phase 3 work should deepen authenticity without weakening the preservation/regression boundary.
