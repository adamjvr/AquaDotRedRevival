import Foundation

/// Runtime platform identity for the AquaDot!red revival.
///
/// The revival intentionally treats native macOS and iPadOS as equal first-class
/// targets. Game rules, maze parsing, assets, animation state, and SpriteKit scene
/// logic should not depend on this enum. Keep platform checks at the edges of the
/// application (input, menus, windows, file pickers, pointer/touch affordances).
enum AquaDotRuntimePlatform: String, Codable, Sendable {
    case macOS
    case iPadOS
    case unsupported

    static var current: AquaDotRuntimePlatform {
        #if os(macOS)
        return .macOS
        #elseif os(iOS)
        // The shipping revival target is intended for iPadOS, not iPhone.
        return .iPadOS
        #else
        return .unsupported
        #endif
    }
}

/// Describes capabilities that can influence presentation and input without
/// contaminating the platform-independent game simulation with AppKit/UIKit code.
struct AquaDotPlatformCapabilities: Equatable, Sendable {
    let platform: AquaDotRuntimePlatform
    let hasTouch: Bool
    let hasMouseOrTrackpad: Bool
    let hasHardwareKeyboard: Bool
    let supportsResizableWindows: Bool
    let supportsGameControllers: Bool

    static var current: AquaDotPlatformCapabilities {
        switch AquaDotRuntimePlatform.current {
        case .macOS:
            return AquaDotPlatformCapabilities(
                platform: .macOS,
                hasTouch: false,
                hasMouseOrTrackpad: true,
                hasHardwareKeyboard: true,
                supportsResizableWindows: true,
                supportsGameControllers: true
            )

        case .iPadOS:
            return AquaDotPlatformCapabilities(
                platform: .iPadOS,
                hasTouch: true,
                hasMouseOrTrackpad: true,
                hasHardwareKeyboard: true,
                supportsResizableWindows: false,
                supportsGameControllers: true
            )

        case .unsupported:
            return AquaDotPlatformCapabilities(
                platform: .unsupported,
                hasTouch: false,
                hasMouseOrTrackpad: false,
                hasHardwareKeyboard: false,
                supportsResizableWindows: false,
                supportsGameControllers: false
            )
        }
    }
}
