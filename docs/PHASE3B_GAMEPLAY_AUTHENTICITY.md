# Phase 3B — Gameplay & Renderer Authenticity Completion

Baseline: `0ce5eb40135371293dece123b70f9aff2fa23101`.

## What is evidence-backed

### Named bug roster
The shipped strategy guide documents Hunter (red), Blocker (blue), Sneaker
(yellow), Hound Dog (orange), Protector (magenta), Mantis (cyan), Hermit (green),
and Neon (`Neon-Bugs.png`). Phase 3B implements all eight named strategies.

`EnemyDecide.cc` reconstruction exposes the original personality state machine,
including `setTemporaryEnemyPersonality`, random-toward-AquaDot, return-home,
random-prefer-less-used, Hound Dog, and the central choose-direction dispatcher.
The binary directly confirms Hound Dog personality value 4. The complete numeric
enum-to-name mapping is not asserted here because the remaining values have not
all been proven.

### Protector / Mantis / Hermit / Neon guide contracts
- Protector patrols remaining normal-dot territory, becomes aggressive when dots
  nearby are eaten, then eventually gives up after AquaDot reaches cleared space.
- Mantis reacts to *motion* nearby and becomes confused/turns away when AquaDot
  stops completely.
- Hermit wanders until AquaDot is nearby, then attacks very quickly for a limited
  period; repeated turns make it give up faster; it is unusually slow in warps.
- Neon chooses another bug strategy at level start and never emulates Reaper.

Exact speed multipliers, alert radii and alert durations are still reconstructed
`tuning` values. The behavior contracts are guide-backed; the numeric constants
remain isolated for future binary matching.

### MazeSprouts / infection-cure bridge
Deep call-site analysis showed that MazeSprouts is not an unrelated random hazard:
MazeDots calls `infectDot` while processing the Yummy/Yuk goodie-dot paths. That
matches the existing Normal→Candy and Normal→Crusty runtime transformations.

Recovered `MazeSprouts.cc` facts now used directly:
- maximum 200 simultaneously active sprout sprites;
- maximum 1000 infection/cure records;
- `cureDot` samples random(0.75, 1.25) and multiplies by either 0.1 or 0.75 sec,
  yielding exact ranges 0.075–0.125 sec and 0.5625–0.9375 sec.

The mapping of the fast/slow branch to “parent vanished” versus “parent eaten” is
a guide+binary reconstruction, not a recovered variable name. Phase 3B documents
that distinction instead of pretending it is proven.

### Difficulty function
`_updateLevelDifficulty` at i386 0x274c6 is locked as:
- 1 → 0.05
- 2 → 0.25
- 3 → 0.45
- >3 → 0.45 + 0.20 × (value−3)

The campaign meaning of the input value is still unresolved, so Phase 3B exposes
and tests the exact function but deliberately does **not** apply it blindly to the
205-maze campaign.

### Tween-level audio
Original resource paths prove five tween tracks:
`tween_yuk`, `tween_okay`, `tween_good`, `tween_veryGood`, `tween_wowBest`, plus
`gameOver` and `highScore` speech. Phase 3B includes lossless ALAC runtime copies
converted from the preserved Ogg/Vorbis resources and makes the tween screen last
for the actual recovered track duration.

## Solid wall selector status
The original `_drawMazePiece` consumes four `mazePieceType` and four
`mazePieceIndex` values and selects among 9×9, 10×9, 9×10 and 10×10 wall sheets.
The caller in `_loadMaze` builds those arrays from a large neighborhood/boundary
state machine. Recovered index bands include roughly 0–15, 24–35, 44–55 and
64–75, which explains the tall 10×10 atlas.

The complete flag→quadrant→frame mapping is **not yet proved**. Phase 3B therefore
keeps the working Phase 3.2 scalable wall renderer rather than replacing it with a
guessed atlas selector. This is intentional authenticity discipline, not omitted
work.
