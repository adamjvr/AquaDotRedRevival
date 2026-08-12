# AquaDotRedRevival — macOS + iPadOS Architecture

## Decision

AquaDotRedRevival should become a **single native SwiftUI multiplatform app target** with two first-class supported destinations:

- **Mac** — native macOS, not Mac Catalyst and not “Designed for iPad”
- **iPad** — native iPadOS

The current codebase is already a strong fit for this because the UI shell is SwiftUI and the game renderer is SpriteKit. The goal is one shared game implementation with platform-specific code only at the outer edges.

## Do not fork the game into Mac and iPad versions

Keep these layers shared:

```text
AquaDotRedRevival
│
├── Shared Core
│   ├── AquaDot maze parser + CRC
│   ├── Maze graph / pathfinding
│   ├── Dot state and powerups
│   ├── Enemy state / decisions / movement
│   ├── Score / lives / game state
│   └── Save data model
│
├── Shared SpriteKit Presentation
│   ├── Maze renderer
│   ├── Sprite animation
│   ├── Original graphics mode
│   ├── Remastered graphics mode
│   └── HUD presentation
│
├── Shared Audio
│   └── Original Ogg/Vorbis-derived resources + modern playback
│
├── Platform Boundary
│   ├── AquaDotPlatform.swift
│   └── AquaDotInput.swift
│
├── macOS Integration
│   ├── keyboard
│   ├── mouse / trackpad
│   ├── native menus
│   ├── resizable window / fullscreen
│   └── native file open/save where needed
│
└── iPadOS Integration
    ├── touch controls
    ├── keyboard / trackpad
    ├── controller support
    ├── orientation / size-class layout
    └── touch-oriented file/document UI where needed
```

## SpriteKit stays

Do **not** replace the existing SpriteKit renderer merely to gain Mac support. SpriteKit is available natively on both macOS and iPadOS and is already backed by Apple's modern GPU stack. It is a very good fit for this revival.

A later Metal renderer is only justified if profiling uncovers a real limitation. The historical SpriteWorld / BlitPixie / Hardwarie stack is architectural evidence, not a dependency we need to carry forward.

## Input rule

Gameplay consumes logical `AquaDotInputAction` values only.

Examples:

```text
Mac arrow key       ─┐
iPad touch swipe    ─┼─> moveLeft / moveRight / moveUp / moveDown
Game controller     ─┘
```

Do not let `NSEvent`, `UITouch`, AppKit, or UIKit types leak into maze, player, enemy, or game-state code.

## Layout rule

Do not hardcode “Mac layout” and “iPad layout” into gameplay. The current prototype scene has a fixed 1400x900 canvas. Keep a stable logical scene coordinate system initially, then make presentation respond to the available viewport:

- Mac: resizable window, fullscreen, keyboard/mouse/controller
- iPad: landscape-first presentation, touch/controller, Stage Manager/windowed sizing where applicable

The maze simulation stays identical.

## Graphics revival rule

The project should ship two selectable art paths:

```text
Assets/
├── Original/
│   └── losslessly preserved recovered graphics
└── Remastered/
    └── restored/upscaled replacements mapped 1:1 to original logical sprites
```

Upscaled art must not alter logical sprite bounds, maze coordinates, collision dimensions, pathfinding, or animation timing.

## Xcode project conversion

The repository's current target was created as iOS/iPadOS only. Convert the existing app target to a multiplatform target in Xcode rather than adding a Catalyst compatibility layer.

1. Select the `AquaDotRed!Revival` app target.
2. Open **General > Supported Destinations**.
3. Keep/add **iPad**.
4. Add **Mac > Mac** (native macOS).
5. Do **not** choose `Designed for iPad` as the Mac strategy.
6. Do **not** choose Mac Catalyst unless a later compatibility reason specifically demands it.
7. If the revival is intentionally iPad + Mac only, remove the iPhone destination.
8. Set deployment targets separately for iPadOS and macOS as appropriate for the project's actual minimum OS policy.

Xcode can share one SwiftUI `App` lifecycle and most project settings across these destinations. Use `#if os(macOS)` / `#if os(iOS)` only for genuine platform integration differences.

## File organization as the revival grows

A useful eventual structure is:

```text
AquaDotRed!Revival/
├── App/
│   ├── AquaDotRed_RevivalApp.swift
│   └── GameView.swift
├── Core/
│   ├── Game/
│   ├── Maze/
│   ├── Enemy/
│   └── Dots/
├── Rendering/
│   ├── MazeGameScene.swift
│   └── Assets/
├── Input/
│   ├── AquaDotInput.swift
│   ├── MacInput.swift
│   └── iPadInput.swift
├── Platform/
│   └── AquaDotPlatform.swift
├── Audio/
└── Resources/
    └── Mazes/
```

We do **not** need to perform that directory migration in the first parser patch. The important part now is keeping the new code portable so it can be moved cleanly as the architecture matures.
