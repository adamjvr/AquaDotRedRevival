# AquaDotRedRevival Phase 2.1 — Stabilization + OG Presentation

Phase 2.1 starts from milestone commit `a9d8b148be8aa50fc7ddde311da677a78812d2d1` and deliberately does **not** redesign the gameplay simulation. It stabilizes the real-hardware implementation and moves the presentation closer to the shipped AquaDot!red 1.5 application.

## 1. Why this pass exists

The Phase 2 milestone proved that original level data, bugs, dot mechanics, recovered artwork and original audio could run together. A real Apple Silicon test then exposed two issues:

1. play began fast and progressively became sluggish;
2. the maze was topologically correct but its wall presentation still looked like a modern approximation rather than the OG game.

The console showed repeated CoreAudio HAL interaction and eventual `IOWorkLoop: skipping cycle due to overload` messages. Code inspection also showed that one eaten dot caused the entire remaining collectible layer to be destroyed/recreated.

## 2. Persistent audio architecture

Phase 2:

```text
one dot event
    -> construct AVAudioPlayer
    -> open/prepare file
    -> play
    -> retain until finished
```

Phase 2.1:

```text
launch game session
    -> preload lossless original-runtime audio into AVAudioPCMBuffer
    -> start one AVAudioEngine
    -> attach music node + special-loop node + 10 one-shot nodes

one dot event
    -> select next pooled AVAudioPlayerNode
    -> schedule cached buffer
    -> play
```

No original `.adrs` preservation bytes are modified. The existing lossless ALAC runtime copies remain the source used by AVFoundation.

## 3. Incremental collectible presentation

Phase 2 compared whole dot dictionaries every frame and called `removeAllChildren()` whenever anything changed. On a level with hundreds of remaining dots that meant continuous allocation, texture lookup, action construction and scene-tree churn.

Phase 2.1 keeps stable dictionaries of SpriteKit nodes:

```text
GridPosition -> dot node
GridPosition -> Munch node
current goodie -> one node
```

Eating a dot removes exactly one node. Dynamic Candy/Crusty/Petrified transformations only update the texture/size of nodes whose kind changed. A throttled 10 Hz reconciliation catches low-frequency goodie transformation/expiration state without rebuilding the layer.

## 4. Cached graph distances

Recovered first-party symbols include `setupDistanceMatrix`, `_initDistanceMatix`, `_copyDistanceMatrixToPaths` and predecessor/shortest-path query helpers. That strongly supports an original architecture that prepared reusable path data rather than recomputing BFS for every enemy decision.

`AquaDotPathfinding` is now a reference object with lazy per-source distance tables. The first query from a source node runs BFS once; subsequent Hunter/Blocker/Sneaker/Hound Dog and dot-system distance queries reuse that table.

## 5. Maze renderer correction

This is the major visual change.

The Phase 2 first pass treated both numeric wall descriptors and `X` fields as variants of a thick tubular wall. Original strategy-guide gameplay captures show that this is not the original visual hierarchy:

- numeric `1...14` geometry is the **thin line-wall system**;
- `X` geometry forms the large **solid/glossy wall structures**;
- the shipped wall resources mirror that split: a `(lines)` atlas plus separate 9w/10w solid-wall fragment atlases.

Phase 2.1 therefore renders:

```text
numeric wall mask
    -> exact recovered _drawLineIntersections frame index
    -> exact recovered (lines) atlas pixels
    -> OG colorization / Retina filtering

X cells
    -> find contiguous X network
    -> batch all connected segments into one scalable path
    -> apply OG-style shadow/body/top-left highlight/lower shade
```

This is both more faithful and dramatically cheaper to render. In Ewe (1), the Phase 2 renderer created roughly 1,092 wall-related nodes (348 X cells × three nodes plus numeric-wall layers). Phase 2.1 uses four batched solid-wall paths plus the eight recovered numeric line sprites: about 12 wall-render nodes/sprites.

The remaining forensic target is the complete exact `mazePieceIndex[4]` mapping used by `_drawMazePiece` to select every 9w/10w fragment. Phase 2.1 does **not** falsely claim that mapping is finished. The important semantic split and exact thin-line frame map are already applied, while the solid-wall surface remains a scalable reconstruction derived from the OG material.

## 6. Opening/menu architecture

Recovered `aquadot--Opening.cc` function evidence includes `initOpeningScreenSprites`, `setButtonFrame`, `showOpeningScreen`, `_returnToOpeningScreen`, `showAboutOrHelpOrScoresScreen` and `_askToResumeGame`.

The shipped `Opening/Main-Title.png` is a 21-frame menu atlas: seven cyan frames, seven red frames and seven green frames for Play, Scores, Options, Help, Quit, AquaDot title and Buy Me. Phase 2.1 extracts those original pixels into transparent runtime assets and uses them as the primary menu controls.

App flow:

```text
launch
  -> Opening
       -> Play / Resume
       -> Scores
       -> Options
       -> Help
       -> About
       -> Quit (Mac)
  -> Game
       -> Pause
            -> Resume
            -> Options
            -> Return to Opening
```

The active SpriteKit scene is retained when leaving for Options or the opening screen so the current game can be resumed.

## 7. Recovered options

The original Carbon NIB exposes these controls, now represented in the modern options shell:

- `Mute all game sounds/music`
- `Disable Music & Ambient Sounds`
- Sound Effects volume
- Music/Ambient Sounds volume
- `Bright Pastels`, `Vivid`, `Medium Tones`, `Dark Tones`
- `Show QuickTips while starting up`
- `Wait for click to continue`
- `Attempt Higher Framerate`
- `Allow direction “pretapping”`
- `Let it Snow!`, `Rainbow snow`, amount-of-snow control

Modern-only `Original / Remastered` graphics selection is kept in a separate section so it is not confused with an original preference.

## 8. Evidence boundary

Confirmed from shipped bytes/data:

- original opening/menu atlas and menu names;
- original Help/About/QuickTip art;
- original options-control wording;
- exact `(lines)` frame mapping;
- maze tokens and X/numeric distinction in data;
- original gameplay screenshots showing thin and solid wall systems;
- original distance-matrix function architecture.

Reconstruction in this pass:

- scalable bevel profile used for contiguous X solid-wall regions;
- modern SwiftUI layout around the original menu images;
- modern preference persistence;
- pooled AVAudioEngine backend;
- performance/cache implementation details.

The old 9w/10w `_drawMazePiece` index-selection table remains a forensic target for a later pixel-exact solid-wall renderer.
