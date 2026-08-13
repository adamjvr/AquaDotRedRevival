# AquaDotRedRevival Phase 2.1.2 — Wrap / Teleport Stabilization

This is a deliberately narrow stabilization pass on top of the Phase 2.1.1 playable-remaster milestone and the documentation refresh at `445d40f`.

## Failure reproduced

The fourth orange level reached through normal Ewe progression is **Ewe (4)** (`ADL_049_Ewe_4`, original CRC `7381`). Its recovered maze data includes:

- `B`: left edge `(0,1)` ↔ right edge `(39,1)`;
- `A`: bottom edge `(12,30)` ↔ bottom edge `(27,30)`.

The Phase 2.1.1 simulation treated a wrap as an instantaneous change of `currentNode` while preserving the direction used to enter the source endpoint. That works by accident for opposite boundaries: entering a left-edge portal while moving left appears at a right-edge portal, where continuing left is inward. It fails for same-side pairs: entering the Ewe (4) bottom `A` while moving down appears at another bottom endpoint where `down` is still outward, so the next simulation iteration can wrap straight back.

## Fix

Wrap traversal now has explicit **destination-side semantics**:

1. teleport to the paired endpoint;
2. derive the destination endpoint's outward boundary direction;
3. select the opposite direction as the required inward exit;
4. schedule the destination's inward corridor as the next segment immediately;
5. for the player, gate a same-facing held outward request until another direction is chosen;
6. for bugs, set the inward segment directly before their normal decision logic resumes.

There is no arbitrary time-based cooldown and no original maze coordinate is modified.

## Corpus audit

The recovered 205-level standard corpus contains:

- **462 valid A/B/C/D wrap pairs**;
- **924 total wrap endpoints**;
- **93 same-boundary pairs** that can expose the Phase 2.1.1 failure class;
- **37 adjacent-boundary pairs**, which also benefit from explicit destination-side exit direction;
- **0 endpoints without a valid inward traversable neighbor**.

So the fix is intentionally global rather than a hard-coded Ewe (4) exception.

## Regression coverage

`Phase212WrapStabilizationTests.swift` creates a minimal bottom-to-bottom wrap maze that reproduces the old failure with a remembered `down` request. After fifty fixed simulation steps it asserts:

- exactly **one** `.wrapped` event fired;
- AquaDot emerged at the paired endpoint and moved inward;
- the old outward request remains remembered but is safely gated;
- topology reports deterministic outward/inward directions and an inward corridor edge.

`tools/aquadot_wrap_audit.py` makes the corpus audit reproducible on macOS or Linux using only the Python standard library.

## Deliberately unchanged

- recovered maze bytes and coordinates;
- campaign progression and run carry;
- collision tuning from Phase 2.1.1;
- renderer and remaster assets;
- audio engine;
- bug personalities/pathfinding goals outside immediate wrap-exit behavior;
- menu/options/pause architecture.

The next checkpoint is a multi-level soak through Ewe (3) → Ewe (4) → Ewe (5), deliberately exercising every visible wrap before expanding Phase 3 scope.
