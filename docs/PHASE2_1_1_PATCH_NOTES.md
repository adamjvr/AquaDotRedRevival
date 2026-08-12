# AquaDotRedRevival Phase 2.1.1 bugfix checkpoint

This is a deliberately narrow correction pass on top of the working Phase 2.1 milestone.

## Fixed

- **Bug contact damage**: the Phase 2/2.1 collision test used a 0.40-cell center radius, far smaller than the rendered AquaDot/bug silhouettes. The collision radius is now an isolated tuning value (`0.92` logical cells) so visible contact actually drains energy and emits damage events.
- **AquaDot movement animation**: the normal red AquaDot now spins while traversing maze segments and stops rotating when movement stops. This is presentation-only and does not alter collision/topology.
- **Level progression**: clearing the required dot field now shows a short `maze complete` transition and automatically loads the next recovered original maze.
- **Run continuity**: score, bonus, multiplier and lives carry into the next level; maze-local state is rebuilt.
- **Phase 2.1 compile hotfix folded in**: the pause-overlay helper now explicitly uses `self.size.width`, eliminating the `CGFloat has no member width` shadowing error.

## Deliberately unchanged

- Enemy personalities/pathfinding reconstruction.
- Exact damage/timing constants beyond the collision-contact correction.
- Original/remastered artwork and wall renderer.
- Opening/options/pause architecture.

The goal is to freeze a known-good Phase 2.1 milestone, apply these observed gameplay fixes, validate them, and only then scope the next phase.
