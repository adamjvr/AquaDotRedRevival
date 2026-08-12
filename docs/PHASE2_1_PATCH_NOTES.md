# Phase 2.1 patch notes

Target baseline: `a9d8b148` — **Phase 2 milestone: OG remaster gameplay pass**.

## Replaced

- `ContentView.swift` — app route shell instead of unconditional game launch.
- `GameView.swift` — attaches the retained current game scene.
- `AquaDotRed_RevivalApp.swift` — native Mac Game/View/Help commands.
- `MazeGameScene.swift` — incremental collectible renderer, pause overlay, performance instrumentation, preference integration.
- `Phase2/AquaDotAudioSystem.swift` — persistent AVAudioEngine and predecoded pooled playback.
- `Phase2/AquaDotPathfinding.swift` — lazy cached distance tables.
- `Phase2/AquaDotWallRenderer.swift` — corrected thin-line vs solid-wall renderer and batched solid geometry.
- `Phase1/AquaDotAssetProvider.swift` — explicit texture cache.
- top-level `README.md`.

## Added

- `Phase2_1/AquaDotPreferences.swift`
- `Phase2_1/AquaDotAppController.swift`
- `Phase2_1/AquaDotOpeningView.swift`
- `Phase2_1/AquaDotOptionsView.swift`
- `Phase2_1/AquaDotAuxiliaryViews.swift`
- `Phase2_1RuntimeAssets.xcassets/` containing OG opening/menu/help/quick-tip derivatives
- `Phase21StabilizationTests.swift`
- `docs/PHASE2_1_ARCHITECTURE.md`

## Expected user-visible changes

1. AquaDot launches to the original-art opening/menu instead of immediately loading Ewe (1).
2. Play starts a new game; returning to opening allows the current game to be resumed.
3. Options uses recovered original preference names plus a clearly separated Original/Remastered setting.
4. Maze rendering should immediately read closer to OG screenshots: large glossy solid walls plus thin line walls rather than thick tubes everywhere.
5. Long sessions should no longer progressively bog down from per-dot scene rebuilds and per-sound AVAudioPlayer allocation.
6. Backtick debug overlay reports measured FPS, total SpriteKit node count and active pooled audio voices.
