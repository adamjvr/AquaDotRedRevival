import Foundation

/// Logical controls understood by the game simulation.
///
/// Platform-specific input code translates keyboard, touch, mouse/trackpad,
/// and GameController events into these actions. Enemy logic and player movement
/// should never depend directly on UIKit, AppKit, NSEvent, or UITouch.
enum AquaDotInputAction: String, Codable, CaseIterable, Sendable {
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    case pause
    case confirm
    case cancel
}

enum AquaDotInputSource: String, Codable, Sendable {
    case keyboard
    case touch
    case pointer
    case gameController
}

struct AquaDotInputEvent: Equatable, Sendable {
    let action: AquaDotInputAction
    let isPressed: Bool
    let source: AquaDotInputSource
}

/// Small protocol boundary so the SpriteKit scene can consume logical actions
/// while macOS and iPadOS provide different physical control implementations.
protocol AquaDotInputSink: AnyObject {
    func handleAquaDotInput(_ event: AquaDotInputEvent)
}
