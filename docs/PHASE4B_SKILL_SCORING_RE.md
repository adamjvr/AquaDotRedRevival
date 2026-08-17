# Phase 4B — Original Skill Scoring Reconstruction

Baseline: `c3f648e59e87819f691b30d5a1f06df2f625b3bf` — Phase 4A milestone.

Phase 4B replaces the provisional Phase 3 Skill estimator with the arithmetic
executed by the shipped AquaDot!Red i386 game. This phase deliberately separates
**the recovered scoring function** from still-reconstructed gameplay systems that
produce some of its inputs.

## Evidence sources

Primary binary evidence is preserved in `evidence/`:

- `original_skill_calculation_i386.asm` — complete `0x5f3c2...0x5f824` routine.
- `original_skill_state_mutators_i386.asm` — Skill state reset, flags, counters,
  and damage-measurement helpers around `0x5c944...0x5cb99`.
- `original_skill_level_complete_callsite_i386.asm` — the level-completion caller
  and the two output pointers for integer Skill + quality band.
- `original_skill_level_difficulty_i386.asm` — level-difficulty storage/getter and
  normal campaign progression path.
- `strategy_guide_skill_section.txt` — the shipped guide's qualitative list of
  Skill factors.

No guessed numeric weight is retained in `AquaDotSkillScoring` after this phase.

## Output contract

The original routine writes two values:

1. `floorf(rawSkill)` as the integer Skill value (`0x1d9618`), and
2. a quality index 0...4 (`0x1d9614`).

The existing recovered end-level relationship remains:

```text
(Bonus + Skill) × Multiplier
```

Phase 4B leaves that outer relationship unchanged and replaces only Skill.

## Exact quality thresholds

The final floating Skill value is classified before `floorf`:

| Raw Skill | Band | Revival enum |
|---:|---:|---|
| `< 500` | 0 | `yuk` |
| `500 ..< 1250` | 1 | `okay` |
| `1250 ..< 2500` | 2 | `good` |
| `2500 ..< 3500` | 3 | `veryGood` |
| `>= 3500` | 4 | `wowBest` |

These replace Phase 3's provisional 700 / 1500 / 2700 / 4200 boundaries.

## Recovered state block

The Skill state around `0x1d9600` is reset at the beginning of a level. Important
members used by the final calculation are:

| Address | Type | Recovered use |
|---|---|---|
| `0x1d9600` | float | normalized goodie-age sample sum |
| `0x1d9604` | float | Energy snapshot at damage-measurement start |
| `0x1d9608` | float | cumulative measured Energy loss |
| `0x1d960c` | float | minimum/retained Energy measurement |
| `0x1d9610` | float | special-power meter remaining at level end |
| `0x1d9614` | int | quality band 0...4 |
| `0x1d9618` | int | floored Skill |
| `0x1d961c` | int | goodie-age sample count |
| `0x1d9620` | int | active Munch/pulsing dots at level end |
| `0x1d9624` | int | deaths during the level |
| `0x1d9628` | int | active Yuk dots at level end |
| `0x1d962c` | int | Munch windows that cleared every eligible bug |

Flags `0x1d9630...0x1d9639` encode all-or-nothing Skill conditions. Their
semantic names below are used only where mutation call sites and/or the guide make
the meaning defensible.

## Munch component

The total Munch count comes from `0x959c0`; the active/remaining count comes from
`0x959bc`. `_incrementActiveDotsLeft` and the pulsing-dot creation path tie these
counters to Munch dots.

The exact initial component is:

```text
total = 0: 40

total = 1:
  remaining 1 -> 40

total = 2:
  remaining 1 -> 10
  remaining 2 -> 40

total = 3:
  remaining 1 -> 7
  remaining 2 -> 15
  remaining 3 -> 40

total > 3:
  ratio = 4 / total
  remaining 1 -> ratio * 5
  remaining 2 -> ratio * 10
  remaining 3 -> ratio * 20
  remaining 4 -> ratio * 40
  all other remaining counts -> 0
```

The unusual `remaining > 4 -> 0` behavior for mazes containing more than four
Munch dots is preserved because that is what the machine code does.

Additional Munch terms:

- no bug ever eaten through a Munch window: `+10`
- every consumed Munch ate at least one bug: `+20`
- number of Munch windows that ate every currently eligible bug:
  - 1 -> `+5`
  - 2 -> `+10`
  - 3 -> `+30`
  - 4 -> `+100`
  - other counts -> no additional component

The "every consumed Munch" flag is vacuously true if no Munch is consumed, matching
the original reset/clear behavior.

## Goodie lifecycle timing

When a Yummy, Bonus, or Multiplier goodie is eaten, the original adds this sample:

```text
ageFraction = 1 - remainingLifetime / originalLifetime
```

Samples are accumulated as a float sum plus integer sample count. At level end:

```text
averageAge = sampleCount > 0 ? sampleSum / sampleCount : 0
timingSkill = averageAge³ × 100
```

Yuk does **not** feed this continuous timing sample; it has separate binary/end-state
rules. This matches the guide's qualitative "later" rule for Yummy/Bonus/Multiplier
without inventing a continuous Yuk formula.

## Damage measurement

The original does not use a flat damage subtraction.

`skill_startDamageMeasurment` snapshots the Energy status bar when dangerous
contact begins. The matching stop routine compares current Energy with the snapshot:

```text
if currentEnergy <= startEnergy:
    cumulativeDamage += startEnergy - currentEnergy
    minimumEnergy = min(minimumEnergy, currentEnergy)
```

Death explicitly ends an active damage measurement before resetting the player.
The level-completion Skill routine also finalizes a still-open measurement.

Skill then adds:

```text
D = levelDifficulty + 1

if no damage contact occurred:
    + 100 × D
else if cumulativeDamage < 1:
    + (1 - cumulativeDamage)² × 100 × D

always:
    + minimumEnergy² × 100 × D
```

This replaces the Phase 3 provisional `damageTaken × 1800` subtraction.

## Yummy / special-power terms

Binary mutation paths establish these all-or-nothing terms:

- never activating a Yummy power: `+20`
- special meter remaining at level end:
  `specialRemaining² × 50 × (levelDifficulty + 1)`
- no Yummy dot eaten: `+50`
- no Yummy dot expired / remained outstanding at level completion: `+15`

Yummy/Bonus/Multiplier age samples are handled separately by the lifecycle timing
component above.

## Yuk terms

The Yuk drawing path clears the original "no Yuk spawned" flag. At level end:

```text
if no Yuk ever spawned:
    +5
else if exactly 1 Yuk remains active:
    +40
else if more than 1 Yuk remains active:
    +100
```

Independent flags add:

- no Yuk eaten: `+10`
- no Yuk naturally expired: `+20`

A life loss removes an active goodie without treating it as natural expiration.
Phase 4B mirrors that distinction.

## Unsemanticized legacy +15

Flag `0x1d9639` is initialized true in the recovered Skill reset and contributes
`+15` when true. No direct runtime write to that byte was found in the shipped
binary corpus used for this phase.

The contribution is therefore preserved exactly but named only as an
**unsemanticized legacy flag contribution**. Phase 4B does not fabricate a gameplay
meaning for it.

## Global scale and death penalty

After all components above:

```text
skill *= 10
```

Death count then scales the result:

| deaths | factor |
|---:|---:|
| 0 | 1.0 |
| 1 | 0.8 |
| 2 | 0.5 |
| >= 3 | 0.2 |

This replaces the Phase 3 flat `-1100 × livesLost` penalty.

Finally the complete Skill is multiplied again by:

```text
levelDifficulty + 1
```

Then quality is selected and `floorf` produces integer Skill.

## Level difficulty input

The Skill routine calls the getter at `0x27568`, which returns the float stored at
`0x81c28`. The normal new-game progression path (`0x27220`) derives the selected
level's value from `getNumberLevelsSelected() - 1` and the Easy/Normal/Expert mode.

For normal gameplay (the special SDE path starts disabled on a new game), the
progression matches the already-recovered campaign formulas:

```text
mode 0:
  n <= 20 -> 0.05 n
  n > 20  -> 1 + 0.03 (n - 20)

mode 1 (shipped default):
  n <= 7 -> 0.30 + 0.10 n
  n > 7  -> 1 + 0.05 (n - 7)

mode 2:
  0.70 + 0.10 n
```

Phase 4B therefore passes the difficulty belonging to the **already selected
current level** from `MazeGameScene` into `AquaDotGameSession` and then the
simulation. It does not ask the scoring function to guess campaign position.

## Runtime integration

Phase 4B adds/restores these measurements in Revival:

- damage-contact measurement windows with start/stop semantics;
- Munch eligible-bug count and full-clear count;
- normalized lifecycle-age samples for Yummy/Bonus/Multiplier;
- Yummy eaten / natural-expiry / active-at-end state;
- Yuk spawned / eaten / natural-expiry / active-at-end state;
- selected-level difficulty stored with level stats.

The outer end-level award remains `(Bonus + Skill) × Multiplier`.

## Fidelity boundary

This phase recovers the **Skill scoring arithmetic and its observed input-state
semantics**. It does not retroactively make every system that produces those inputs
bit-identical to the 2000s game. Earlier Revival phases still contain explicitly
reconstructed values for, among other things, goodie spawn timing, some bug AI
tuning, and some movement/damage rates.

Consequently:

- the scoring function itself is binary-reconstructed;
- the quality thresholds and death factors are binary-reconstructed;
- the measurement bookkeeping added here mirrors observed mutation paths;
- a run can still produce different measurements from the original if an upstream
  reconstructed gameplay system behaves differently.

That distinction is intentional and documented rather than hidden.
