# AquaDotRedRevival Phase 1 patch

This overlay is intended for the current `main` branch after the native Mac+iPad destination commit.

## Replaces

- `MazeGameScene.swift` — removes `TestLevels.levelOne` from the running game and installs the authentic original-data scene.
- `GameView.swift` — changes the logical canvas to the recovered 800-pixel presentation basis and keeps one stable scene instance.
- `GridPosition.swift` — adds `Sendable` for the platform-independent simulation.
- `AquaDotMaze.swift` — keeps the recovered token model and adds a Corelibs MacRoman bullet fallback used only by command-line validation.
- top-level `README.md` — documents the remaster/preservation direction.

## Adds

- exact wall-mask semantics and recovered editor frame map;
- original maze topology graph + wrap edges;
- fixed-step player simulation;
- original level loader/catalog;
- all 205 standard mazes as Xcode data assets;
- original runtime graphics asset catalog;
- Phase 1 preservation tests;
- full recovered graphics archive and exact original-level archive under `preservation/`;
- Phase 1 architecture documentation.

## Deliberately not removed

`TestLevels.swift`, `Level.swift`, and `Tile.swift` are left in the repository for this patch so history/reference is preserved. The authentic scene no longer references them. They can be deleted in a cleanup commit once the Xcode build is confirmed on both Mac and iPad.
