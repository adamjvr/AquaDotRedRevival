# Known Issues / Explicit Reconstruction Boundaries

## Phase 4 authenticity closure

### Absolute movement units are still translated
The executable exposes exact relative enemy setup and warp factors, but the historical movement unit has not been proven one-for-one against Revival's fixed-step cells/second coordinate system. Phase 4 therefore restores the exact **ratios and strategy-specific warp factors** without falsely labeling the absolute SpriteKit speed as recovered.

### Reaper contact is a modern fixed-step translation
The executable has a dedicated Reaper-danger path and the shipped guide describes Reaper contact as almost immediately lethal. Revival maps the recovered fast contact transition onto the Energy-drain model; the legacy status-animation unit and modern Energy/second unit are not claimed identical.

### Infection/cure timing envelope is not fully binary-matched
The important spatial rule is now recovered: infection/cure records propagate to immediate orthogonal dot neighbors rather than through maze shortest paths or wraps. Goodie lifecycle timing still supplies a modern envelope around that recovered propagation topology until the old per-record timing calculation is completely mapped.

### RNG bitstream identity
Campaign/bug/goodie control-flow distributions preserve recovered selector structure where known, but Revival uses deterministic project-local RNG streams. It does not claim libc `rand()` seed or bitstream identity with the original executable.

### Remaining AI/presentation adapters
A few advanced-AI helper choosers and historical presentation edge cases are still translated through Revival's graph/SwiftUI/SpriteKit abstractions. These are documented in the relevant reverse-engineering notes instead of being labeled exact.

### High-score name entry
Persistent Today’s Best / Best Scores Ever tables work, but the original interactive type-your-name flow remains a Phase 4/5 presentation target; runs may still be recorded as `anonymous`.

### iPadOS regression depth
The runtime architecture is shared with macOS, but broader physical-device input/layout testing remains Phase 5 work.

## Fixed / superseded historical issues

- Phase 2 progressive CoreAudio/render slowdown — fixed by pooled audio + incremental rendering.
- Visible bug overlap without damage — fixed in Phase 2.1.1.
- Clearing a maze without progressing — fixed in Phase 2.1.1.
- Same-side wrap ping-pong — fixed structurally in Phase 2.1.2.
- Zero-life infinite respawn — fixed in Phase 3.
- Bonus leaking across levels — fixed in Phase 3.
- Skill scoring described as provisional — superseded by Phase 4B executable recovery.
- “Only four bugs implemented” — superseded by Phase 4F/4G and the Phase 4 Reaper closure.
- Neon treated as its own AI personality — superseded by the recovered appearance-wrapper architecture.
- Generic guessed bug warp delay — superseded by recovered shared warp-style multipliers in Phase 4 closure.

## Reporting a regression
Include maze name, graphics mode, movement/action leading into the failure, whether pause/menu remains responsive, backtick FPS/node/audio values, terminal/Xcode log, and a screenshot/capture when visual state matters.
