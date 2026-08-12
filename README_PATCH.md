# AquaDotRedRevival — Original Maze Format + Multiplatform Foundation Patch

This patch is the first foundation layer for turning `adamjvr/AquaDotRedRevival` into a faithful AquaDot!red revival for **native macOS and iPadOS**.

## What this patch adds

### Authentic AquaDot maze support
- `AquaDotMaze.swift`
- `AquaDotMazeParser.swift`

These implement the recovered AquaDot!red **Maze Description Format Version 1.0** in Swift, including the recovered CRC behavior.

### Mac + iPad architecture boundaries
- `AquaDotPlatform.swift`
- `AquaDotInput.swift`
- `AquaDotGraphicsMode.swift`
- `docs/PLATFORM_ARCHITECTURE.md`

These files make the direction explicit before gameplay code grows:

- macOS and iPadOS are equal first-class targets.
- shared game logic remains platform-independent.
- SpriteKit remains the shared renderer.
- keyboard/touch/pointer/controller input is translated into common logical actions.
- recovered artwork and future upscaled artwork use the same logical game geometry.

## Validation

The recovered format/checksum implementation was validated against the forensic AquaDot corpus: **207/207 supplied/sample mazes pass**.

## Repository state this patch is correcting

The current project is an iOS-family target and the prototype level system uses a simplified invented wall/path grid. That was fine for the original GUI mockup, but it must no longer be the authoritative game-data model now that the original maze format has been recovered.

## Xcode target direction

Convert the existing application target into a **single SwiftUI multiplatform target** with:

- native **Mac** destination
- native **iPad** destination
- no requirement for Mac Catalyst
- no dependence on “Designed for iPad” Mac execution

See `docs/PLATFORM_ARCHITECTURE.md` for the Xcode setup and code-boundary rules.

## Intended repository paths

Swift files:

`AquaDotRed!Revival/AquaDotRed!Revival/`

Architecture documentation:

`docs/PLATFORM_ARCHITECTURE.md`

## Next implementation pass

1. Bundle a real recovered maze as a development fixture.
2. Load it with `AquaDotMazeParser` instead of `TestLevels.levelOne`.
3. Render the real interleaved vertex/edge maze geometry in `MazeGameScene`.
4. Complete the 1...14 wall-code directional mapping from the recovered binary/editor behavior.
5. Add `Original` and `Remastered` texture namespaces.
6. Add keyboard/controller input on Mac and touch/controller input on iPad through the shared `AquaDotInputAction` layer.

The rule going forward is simple: **same AquaDot game, same data, same simulation — native presentation and controls on both Mac and iPad.**
