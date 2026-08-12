import Foundation

/// Both platforms use the same logical game geometry. Graphics mode changes the
/// texture source, not collision/pathfinding coordinates or animation timing.
enum AquaDotGraphicsMode: String, Codable, CaseIterable, Sendable {
    /// Exact recovered artwork where practical, preserving the historical look.
    case original

    /// Upscaled/restored artwork derived from the recovered originals.
    case remastered
}

/// Stable names for asset roots. Keeping these names platform-neutral lets the
/// same asset catalog/resource bundle ship on macOS and iPadOS.
enum AquaDotAssetNamespace {
    static let original = "Original"
    static let remastered = "Remastered"
}
