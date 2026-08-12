import Foundation
import SwiftUI

/// The four wall-colour families exposed by the original Carbon options dialog.
/// Names are preserved verbatim from the recovered NIB controls.
enum AquaDotWallPalette: String, Codable, CaseIterable, Identifiable, Sendable {
    case brightPastels
    case vivid
    case mediumTones
    case darkTones

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brightPastels: return "Bright Pastels"
        case .vivid: return "Vivid"
        case .mediumTones: return "Medium Tones"
        case .darkTones: return "Dark Tones"
        }
    }
}

/// Modern persistence shell around preferences recovered from the original game.
///
/// Phase 2.1 deliberately preserves the old preference vocabulary instead of
/// inventing a generic modern settings page. Remaster-only choices (graphics
/// mode) are kept in a clearly separate section in the UI.
final class AquaDotPreferences: ObservableObject {
    static let shared = AquaDotPreferences()

    private enum Key {
        static let graphicsMode = "revival.graphicsMode"
        static let muteAll = "audio.muteAll"
        static let disableMusic = "audio.disableMusic"
        static let soundEffectsVolume = "audio.soundEffectsVolume"
        static let musicVolume = "audio.musicVolume"
        static let wallPalette = "video.wallPalette"
        static let showQuickTips = "opening.showQuickTips"
        static let waitForClick = "opening.waitForClick"
        static let allowPretapping = "controls.allowPretapping"
        static let attemptHigherFramerate = "video.attemptHigherFramerate"
        static let rainbowSnow = "opening.rainbowSnow"
        static let snowAmount = "opening.snowAmount"
    }

    private let defaults: UserDefaults

    @Published var graphicsMode: AquaDotGraphicsMode { didSet { save() } }
    @Published var muteAll: Bool { didSet { save() } }
    @Published var disableMusic: Bool { didSet { save() } }
    @Published var soundEffectsVolume: Double { didSet { save() } }
    @Published var musicVolume: Double { didSet { save() } }
    @Published var wallPalette: AquaDotWallPalette { didSet { save() } }
    @Published var showQuickTips: Bool { didSet { save() } }
    @Published var waitForClick: Bool { didSet { save() } }
    @Published var allowPretapping: Bool { didSet { save() } }
    @Published var attemptHigherFramerate: Bool { didSet { save() } }
    @Published var rainbowSnow: Bool { didSet { save() } }
    @Published var snowAmount: Int { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        graphicsMode = AquaDotGraphicsMode(rawValue: defaults.string(forKey: Key.graphicsMode) ?? "") ?? .remastered
        muteAll = defaults.object(forKey: Key.muteAll) as? Bool ?? false
        disableMusic = defaults.object(forKey: Key.disableMusic) as? Bool ?? false
        soundEffectsVolume = Self.clamp(defaults.object(forKey: Key.soundEffectsVolume) as? Double ?? 1.0)
        musicVolume = Self.clamp(defaults.object(forKey: Key.musicVolume) as? Double ?? 1.0)
        wallPalette = AquaDotWallPalette(rawValue: defaults.string(forKey: Key.wallPalette) ?? "") ?? .vivid
        showQuickTips = defaults.object(forKey: Key.showQuickTips) as? Bool ?? true
        waitForClick = defaults.object(forKey: Key.waitForClick) as? Bool ?? false
        allowPretapping = defaults.object(forKey: Key.allowPretapping) as? Bool ?? true
        attemptHigherFramerate = defaults.object(forKey: Key.attemptHigherFramerate) as? Bool ?? true
        rainbowSnow = defaults.object(forKey: Key.rainbowSnow) as? Bool ?? false
        snowAmount = max(0, min(3, defaults.object(forKey: Key.snowAmount) as? Int ?? 0))
    }

    func restoreDefaults() {
        graphicsMode = .remastered
        muteAll = false
        disableMusic = false
        soundEffectsVolume = 1.0
        musicVolume = 1.0
        wallPalette = .vivid
        showQuickTips = true
        waitForClick = false
        allowPretapping = true
        attemptHigherFramerate = true
        rainbowSnow = false
        snowAmount = 0
    }

    private func save() {
        defaults.set(graphicsMode.rawValue, forKey: Key.graphicsMode)
        defaults.set(muteAll, forKey: Key.muteAll)
        defaults.set(disableMusic, forKey: Key.disableMusic)
        defaults.set(Self.clamp(soundEffectsVolume), forKey: Key.soundEffectsVolume)
        defaults.set(Self.clamp(musicVolume), forKey: Key.musicVolume)
        defaults.set(wallPalette.rawValue, forKey: Key.wallPalette)
        defaults.set(showQuickTips, forKey: Key.showQuickTips)
        defaults.set(waitForClick, forKey: Key.waitForClick)
        defaults.set(allowPretapping, forKey: Key.allowPretapping)
        defaults.set(attemptHigherFramerate, forKey: Key.attemptHigherFramerate)
        defaults.set(rainbowSnow, forKey: Key.rainbowSnow)
        defaults.set(max(0, min(3, snowAmount)), forKey: Key.snowAmount)
    }

    private static func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}
