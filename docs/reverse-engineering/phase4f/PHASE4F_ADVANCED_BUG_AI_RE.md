# Phase 4F Advanced Bug AI Reverse Engineering

## Evidence hierarchy

The implementation distinguishes three levels of evidence:

1. **Recovered numeric/state-machine behavior** — directly visible in shipped i386 machine code.
2. **Recovered algorithm translated onto Revival graph structures** — control flow is recovered, but original engine record types do not map 1:1.
3. **Guide-backed compatibility behavior** — explicitly retained where exact machine-level semantics are still unresolved.

## Personality IDs

The advanced original chooser/initializer paths establish:

- personality 5: Hermit
- personality 6: Protector
- personality 7: Mantis

These paths are gated by the full-version check. The shipped strategy guide independently states Protector, Mantis, Hermit and Neon are full-version bugs.

## Difficulty interpolation

Advanced initialization clamps the current difficulty to 1.0.

`0x27574` computes:

```text
min(start + D*(middle-start), cap)
```

`0x275a4` computes:

```text
max(start - D*(start-middle), floor)
```

The Revival uses the already-recovered current-level difficulty that also feeds original Skill logic.

## Enemy activity transition engine

`0x20cf6` stores low/high activity factors and clamps them to 0...10.

`0x20d92` transitions current enemy activity to low or high. When the current value is between the endpoints, the requested full transition duration is multiplied by the remaining fraction of the endpoint span. The original stores microsecond wall-clock transition state; the Revival uses deterministic fixed-step linear interpolation with the same target and duration rule.

## Protector details

The dot-eat handler:

- requires active Protector state;
- if already angry and the decision counter is <=4, refreshes it to 5;
- otherwise computes squared grid distance to the eaten dot;
- changes the threshold based on whether the eaten dot lies behind the current facing;
- uses strict thresholds `<100` front and `<25` behind;
- performs a 0.9 random notice test;
- enters angry state with decision counter 5;
- requests high activity over 2 seconds.

Angry direction selection decrements the decision counter first. Negative counter returns to patrol and requests low activity over 2 seconds. If the aggressive direction changes the bug's current direction, an early-release random test uses:

```text
0.30 - 0.03 * decisionsRemaining
```

The original patrol-target function sorts explicit intersections by remaining-dot counts, takes the top `floor(n*0.5)+1` records, removes zero-count tail entries and selects weighted by count. Revival graph intersections are a documented adapter for those original records.

## Mantis details

The player-motion event uses a 100,000 microsecond (0.1 second) gate. While wandering and player motion is present, Mantis uses directional squared ranges `<225` front / `<49` behind and a 0.3 notice probability. Notice enters attack, clears the interruption counter and requests high activity over 2 seconds.

While attacking, stopped player-update samples increment a counter. At the next direction decision, complete stillness immediately enters confusion; otherwise a nonzero counter applies `count*0.05` confusion probability. Confusion sets state 2, counter 5, and requests low activity over 1 second. The chooser decrements before selection and leaves confusion only after the counter becomes negative: six direction choices total.

## Hermit details

Hermit queries the shortest route and route distance. Route distance above 10 abandons the chase. Chase acquisition requests high activity over 0.5 seconds; abandonment requests low activity over 1 second.

The two original counters preserve a characteristic rhythm of random wandering and turn fatigue. Chase turns 1 through 4 are accepted. After that, continuation probability is:

```text
max(0, 1.0 - 0.1*(turnCounter - 4))
```

Thus turn counter 5 = 0.9, 6 = 0.8, etc.

## Translation boundaries

### Base physical bug speed

The recovered low/high activity factors multiply the Revival's existing `bugCellsPerSecond` value. Phase 4F restores the original *relative activity state and transitions*; it does not newly claim the pre-existing base cell-speed constant is historical.

### Shared aggressive chooser

The original `0x1bb6e` is not fully semanticized. Phase 4F maps it to the Revival's cached shortest-path direction. This preserves the recovered advanced state machine without inventing the original chooser internals.

### Protector intersection records

The original engine tracks explicit intersection records and per-direction dot counts. Revival derives candidate intersections from graph nodes with at least three corridor exits, assigns normal dots by cached shortest distance, and then applies the recovered top-half weighted-selection algorithm.

### Mantis confusion chooser

`0x1b478` has not yet been completely recovered. Revival uses `directionAway` as a guide-faithful adapter for the documented "turn away" behavior.

### Mantis sample cadence

The binary increments an interruption counter per stopped player-update callback. The exact historical outer update cadence is not proved. The deterministic Revival adapter normalizes to 60 samples/s.

### Hermit warp slowdown

The guide explicitly says Hermit is very slow through warps, but Phase 4F does not yet isolate the original special warp timing. Existing `hermitWarpSlowdown = 0.95` remains labeled compatibility tuning.

### Neon

The guide proves Neon chooses another strategy at level start and never Reaper. The Revival's existing per-level emulation remains in place. Exact original Neon dispatch and the complete original strategy taxonomy (including Lone Wolf/Reaper variants) are not claimed by Phase 4F.
