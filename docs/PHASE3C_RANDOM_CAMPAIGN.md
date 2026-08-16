# Phase 3C — Original Random Campaign Selection

Baseline: `5bbd4197e8f91a9785b6133affa3eb256c97dfc0` — Phase 3B milestone.

Phase 3C replaces Revival's temporary sequential `catalogIndex + 1` progression
with the family/variant selector recovered from AquaDot!Red's i386 executable.

## Binary-proven selector structure

Recovered landmarks:

- selector reset: `0x38a6c ... 0x38aaf`
- `selectRandomLevel2`: `0x38ab0 ... 0x38c42`
- selected-level count getter: `0x38c44`
- family/variant catalog mapping helper: `0x3f67e`
- gameplay selection caller: around `0x3fa28`
- base-difficulty progression: `0x27220`
- base-difficulty getter: `0x27568`

The new-game setup resets the selector's history before gameplay setup, and the
level-loading path calls `selectRandomLevel2`. The original therefore did not
walk the 205 standard files in fixed filename order.

## Catalog architecture

The full-version selector uses 41 base maze families and five variants per
family:

```text
205 = 41 × 5
catalogIndex = familyIndex * 5 + variantTier
```

Thus `Ewe (1)` ... `Ewe (5)` are five variants of the Ewe family rather than five
consecutive campaign stages.

## Variant selection

Difficulty is bucketed exactly as recovered:

```text
<= 0.25  -> tier 0
<= 0.50  -> tier 1
<= 0.75  -> tier 2
<= 1.00  -> tier 3
>  1.00  -> tier 4
```

The 25-value table at `0x81c80` is a cumulative-endpoint table:

```text
[1, 0, 0, 0, 0]
[1, 2, 0, 0, 0]
[1, 2, 4, 0, 0]
[1, 2, 4, 8, 0]
[1, 2, 4, 8, 16]
```

For tier 4, for example, the selector draws in `0..<16`:

```text
0       -> variant 0
1       -> variant 1
2...3   -> variant 2
4...7   -> variant 3
8...15  -> variant 4
```

If the selected variant equals the previous variant and is lower than the
currently highest unlocked tier, it is rerolled. Repeating the highest unlocked
tier is explicitly allowed.

## Family anti-repeat ring

The original keeps ten recent family IDs. A newly drawn family is rejected if it
appears in that ring. The duplicate retry counter is compared with `0x19`; after
26 duplicate rejections, the next draw is accepted as the escape path. An
accepted family replaces the next ring slot modulo ten.

## Difficulty progression

The preferences initializer stores numeric mode `1` by default. Phase 3C keeps
neutral internal names `mode0`, `mode1`, and `mode2` because this patch does not
claim historical UI labels that are not required by the selector.

With `n = number of mazes already selected` when choosing another maze:

```text
mode0:
  n <= 20: 0.05*n
  n >  20: 1.0 + 0.03*(n - 20)

mode1 (shipped default):
  n <= 7:  0.30 + 0.10*n
  n >  7:  1.0 + 0.05*(n - 7)

mode2:
  0.70 + 0.10*n
```

## Autosave integration

Checkpoint schema 2 adds the dedicated campaign-selector state:

- campaign RNG state
- ten-family recent-history ring and write cursor
- previous selected variant tier
- number of levels selected
- numeric difficulty mode

The already-selected next maze and selector state are saved **before** the
end-level tween. Quitting on the scoreboard therefore cannot reroll the next
maze. Resuming a schema-2 checkpoint continues the exact Revival sequence.

Schema-1 Phase-3 checkpoints remain readable. Since they never stored random
selector state, Phase 3C keeps their exact saved current maze, registers its
family/variant into a bootstrapped selector, and deterministically continues from
there.

## Fidelity boundary

The original executable used its libc random stream. Its exact historical seed
and PRNG bitstream have not been recovered. Phase 3C therefore uses a dedicated,
serialized Revival campaign RNG. It does not share state with bug or goodie
randomness and is **not** claimed to reproduce the exact historical sequence of
random numbers.

The recovered selection architecture, cumulative endpoint probabilities,
difficulty buckets, lower-variant repeat rule, ten-family ring, retry escape,
catalog mapping, and difficulty curves are preserved.
