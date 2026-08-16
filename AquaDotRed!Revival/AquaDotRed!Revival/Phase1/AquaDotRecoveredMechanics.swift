import Foundation

/// Small binary-confirmed mechanics that Phase 3B can state exactly without
/// guessing at the original campaign's higher-level scheduling semantics.
enum AquaDotRecoveredDifficulty {
    /// `_updateLevelDifficulty` at i386 0x274c6 uses these exact factors.
    ///
    /// The meaning of the *input* difficulty value in the 205-level campaign is
    /// still being recovered, so this helper intentionally does not auto-scale a
    /// level. It only locks the proven native function in one testable place.
    static func factor(forDifficultyValue value: Int) -> Double {
        precondition(value >= 1, "original AquaDot difficulty value zero asserts")
        switch value {
        case 1: return 0.05
        case 2: return 0.25
        case 3: return 0.45
        default: return 0.45 + 0.20 * Double(value - 3)
        }
    }
}

/// Constants recovered from MazeSprouts.cc. The original engine maintained up
/// to 200 simultaneous sprout sprites and 1000 infection/cure records.
enum AquaDotRecoveredSproutMechanics {
    static let maximumActiveSproutSprites = 200
    static let maximumInfectionRecords = 1000

    /// `cureDot` multiplies random(0.75, 1.25) by either 0.1 or 0.75 sec.
    static let fastCureDelay: ClosedRange<Double> = 0.075 ... 0.125
    static let slowCureDelay: ClosedRange<Double> = 0.5625 ... 0.9375
}
