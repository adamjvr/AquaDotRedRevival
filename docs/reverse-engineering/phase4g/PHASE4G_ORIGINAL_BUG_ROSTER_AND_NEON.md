# Phase 4G — Original Bug Roster and Neon Architecture

Baseline: `b7157eb49a4e6071816cee139d6ea86971b99622` (Phase 4F).

## What this phase proves

The shipped i386 executable does **not** implement Neon as a ninth AI strategy. `setupEnemy` stores the chosen underlying enemy colour first, then—unless the enemy is colour 8/Reaper—may substitute draw colour 11 (Neon) after a probability test. Strategy dispatch still uses the original colour.

The eight ordinary strategy mappings recovered from the `setupEnemy` dispatch are:

| Original colour | Sprite source | Strategy |
|---|---|---|
| 0 Red | `Red-Bugs.png` | Hunter |
| 1 Blue | `Blue-Bugs.png` | Blocker |
| 2 Yellow | `Yellow-Bugs.png` | Sneaker |
| 3 Orange | `Orange-Bugs.png` | Hound Dog |
| 4 Magenta | `Magenta-Bugs.png` | Protector |
| 5 Cyan | `Cyan-Bugs.png` | Mantis |
| 6 Green | `Green-Bugs.png` | Hermit |
| 7 Indigo | `Indigo-Bugs.png` | Lone Wolf |

Colour 8 is the special Night/Reaper path. It is deliberately not generated in Phase 4G because the guide and binary both prove Reaper has special movement/contact behavior; assigning ordinary bug collision damage would be a false restoration.

## Corrections to the Revival

Phase 3B had modeled Neon as a permanent `AquaDotBugPersonality` that chose an emulated personality. Phase 4G changes new level creation to store the real strategy directly and adds a separate `isNeonAppearance` flag. The legacy `.neon` enum case remains only so older source/state can still decode.

Phase 3B also omitted Lone Wolf. It is restored as a real strategy. The guide describes Lone Wolf as taking the shortest route to AquaDot; the Revival therefore targets the player with the existing cached shortest-path graph. This restores the named strategy contract, but does not claim every unrecovered original intersection-choice nuance is bit-identical.

Phase 4D's reconstructed advanced sprite identities were also shifted. Phase 4G corrects them to the recovered original colour mapping:

- Protector → Magenta
- Mantis → Cyan
- Hermit → Green
- Lone Wolf → Indigo

The new 64×64 Original PNGs are **reconstructed static runtime composites** from the preserved body/alpha/wing component sheets, not recovered historical flattened PNGs. The 512×512 Remastered files use the same preserved components at high resolution.

## Recovered availability

For the full version, Red/Blue/Yellow/Orange are always available. Additional colours are enabled by the original probability helper:

- Indigo / Lone Wolf: `D >= 0.1`, probability `D * 4.0`
- Green / Hermit: `D >= 0.3`, probability `D * 1.5`
- Magenta / Protector: `D >= 0.5`, probability `D * 1.5`
- Cyan / Mantis: `D >= 0.7`, probability `D`
- Night / Reaper: `D >= 0.7`, probability `D` — recovered but deliberately deferred

Neon appearance probability is independent of strategy selection:

- `D < 0.5` → `0`
- otherwise → `min(D * 0.2, 0.2)`

The executable's probability helper normalizes `rand()` and returns true when `p >= sample`. The Revival preserves the recovered probability/distribution structure but continues to use its deterministic RNG; libc `rand()` bitstream identity is not claimed.

## Recovered four-enemy composition

The original clamps only this composition calculation to `min(D, 1.0)` and draws from:

`1 ... min(16, floor(8 + 10*D))`

The draw selects:

- 1–8: `A B C D`
- 9–11: `A A B C`
- 12–13: `A A B B`
- 14–15: `A A A B`
- 16: `A A A A`

For draws 9–15 the executable then calls its peculiar shuffle helper: **exactly 10 swaps**, with each swap choosing two different indices from 0…3. It is not Fisher–Yates.

## Explicit remaining boundaries

Phase 4G does **not** claim:

1. libc-rand sequence identity;
2. complete Reaper behavior;
3. every deeper Lone Wolf turn/intersection detail beyond the recovered strategy ID and guide-confirmed shortest-route behavior;
4. that reconstructed flattened Original/Remastered PNGs are original shipping flattened assets.

These boundaries are intentional so later phases can replace them with evidence instead of accumulating plausible guesses.
