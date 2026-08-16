# Known Issues

## Current Phase 3 fidelity targets

### Skill weights are reconstructed, not yet exact
The strategy guide explicitly provides the end-level formula and the factors that raise/lower Skill, but not every original numeric weight. `AquaDotSkillScoring` keeps the provisional weights isolated until binary evidence can replace them.

### Original level-selection sequencing
The original binary contains weighted/random level-selection machinery. Some tables/constants are recovered, but the full progression contract is not yet proven. The current deterministic Ewe-based progression remains useful for regression testing and is not labeled as the final historical sequence.

### Exact solid-wall sub-piece selection
The four `9w/10w` source atlas families and `_drawMazePiece` type/index architecture are recovered, but the complete call-site selection logic is not yet reduced to a trustworthy modern table.

### Four bug types remain missing
Hunter, Blocker, Sneaker and Hound Dog are live. Protector, Mantis, Hermit and Neon remain Phase 3 reconstruction work.

### Infection / sprout / cure systems
Recovered `MazeSprouts.cc` / `MazeDots.cc` evidence proves these systems existed, but they are not yet fully implemented in the revival.

### High-score name entry
Scores now persist and the original Today’s Best / Best Scores Ever headings are live. Until the original type-your-name flow is reconstructed, completed runs are recorded as `anonymous`.

## Fixed observed gameplay failures

- Phase 2 progressive CoreAudio/render slowdown: fixed by Phase 2.1 architecture.
- Visible bug overlap without damage: fixed in Phase 2.1.1.
- Clearing a maze without progressing: fixed in Phase 2.1.1.
- Ewe (4) same-bottom wrap ping-pong loop: fixed structurally in Phase 2.1.2.
- Zero-life infinite respawn: fixed in Phase 3.
- Bonus leaking into later levels instead of being consumed at end-of-level: fixed in Phase 3.

## Reporting a regression
Include maze name, graphics mode, movement/action leading into the failure, whether pause/menu remains responsive, backtick FPS/node/audio values, terminal/Xcode log, and a screenshot/capture when visual state matters.
