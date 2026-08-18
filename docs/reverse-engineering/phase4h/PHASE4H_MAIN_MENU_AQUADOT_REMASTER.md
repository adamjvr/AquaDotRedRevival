# Phase 4H — Main Menu AquaDot Remaster

## Baseline

Phase 4G commit: `bec844aa830a38b15c3a965dee99343aca719d22`

## Why this can be asset-only

`AquaDotOpeningView.swift` already resolves:

```swift
Image("P21_OpeningDot_\(suffix)")
```

where the suffix is `Original` or `Remastered`. The view also owns the existing rotation and placement. There is no technical reason to alter the SwiftUI shell to add the upgraded hero.

## Recovered visual evidence

Recovered game-art components include:

- `Aquadot-Spots-Alpha.jpg`
- `Aquadot-Ring&Spot-Colors.jpg`
- `Aquadot-Ring-Alphas.jpg`
- `Aquadot-Underlays.png`
- `Aquadot-Glows.png`

The recovered spot-alpha frames show the distinctive large circular/elliptical pads distributed around the AquaDot body. Phase 4H uses that pattern as its visual constraint.

See `evidence/PHASE4H_RECOVERED_SPOT_SOURCE_AUDIT.png`.

## New remastered master

`P21_OpeningDot_Remastered.png`

- 1024 × 1024
- RGBA8
- transparent canvas
- red/crimson spherical body
- large silver-white recovered-style pads
- cyan edge bloom/rim
- deterministic generator included under `tools/`

The image is intentionally bright and clean at source resolution because the shipping view presents it at 42% opacity behind the menu.

## Preservation boundary

This is not claimed to be a historical 1024×1024 asset. It is new remastered presentation artwork constrained by recovered AquaDot component art. `P21_OpeningDot_Original.png` is left untouched.

## Runtime changes

None. Menu controls, layout, title, quick tips, click-to-continue behavior, hero size, hero opacity, placement and rotation timing are unchanged.
