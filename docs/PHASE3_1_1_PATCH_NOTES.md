# Phase 3.1.1 — icon + spin corrective patch

This replaces the faulty first Phase 3.1 overlay.

## Fixes
- Restores the **actual Phase 3** `MazeGameScene.swift`, including campaign configuration, auto-save, Game Over, tween scoring, and high-score integration.
- Retains the requested all-state AquaDot spin behavior.
- Installs the recovered original application icon into the project's existing `Assets.xcassets/AppIcon.appiconset` rather than nesting/replacing the entire asset catalog.
- Removes the accidental `Assets.xcassets/Assets.xcassets` directory if the faulty 3.1 installer created it.

## Spin states
- normal: 5.4 rad/s forward
- munch: 7.9 rad/s forward
- yummy: 6.6 rad/s forward
- yuk: 4.3 rad/s reverse
- damaged: 8.8 rad/s reverse
