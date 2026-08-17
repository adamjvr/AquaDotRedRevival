import Foundation

/// End-of-level quality bands recovered from the original tween-level path.
/// Phase 4B also recovers the exact numeric thresholds used to select them.
enum AquaDotLevelQuality: String, Codable, CaseIterable, Sendable {
    case yuk
    case okay
    case good
    case veryGood
    case wowBest

    var displayName: String {
        switch self {
        case .yuk: return "yuk"
        case .okay: return "okay"
        case .good: return "good"
        case .veryGood: return "very good"
        case .wowBest: return "wow! best"
        }
    }

    /// Five recovered visual/audio bands, in the same order written by the
    /// original Skill routine at 0x5f79a...0x5f7f2.
    var atlasBand: Int {
        switch self {
        case .yuk: return 0
        case .okay: return 1
        case .good: return 2
        case .veryGood: return 3
        case .wowBest: return 4
        }
    }
}

/// Per-maze accounting needed by the recovered Skill calculation.
///
/// Fields retained from Phase 3 remain useful for gameplay/debugging. Phase 4B
/// adds only measurements that correspond to state in the original 0x1d9600
/// Skill block and to directly observed mutation call sites.
struct AquaDotLevelStats: Equatable, Sendable {
    var initialRequiredDots: Int = 0
    var initialMunchDots: Int = 0

    // Original Skill difficulty input (global 0x81c28). The shipped default
    // campaign's first selected maze begins at 0.30.
    var skillBaseDifficulty: Float = 0.30

    // Damage measurement: cumulative Energy lost while contact measurements are
    // active plus the lowest post-contact Energy observed. These replace Phase
    // 3's provisional single linear damage penalty.
    var damageTaken: Double = 0
    var damageContactOccurred: Bool = false
    var damageMeasurementActive: Bool = false
    var damageMeasurementStartEnergy: Float = 1.0
    var minimumEnergyAfterDamage: Float = 1.0
    var livesLost: Int = 0

    // Munch accounting.
    var munchDotsEaten: Int = 0
    var munchesStarted: Int = 0
    var munchesWithAtLeastOneBug: Int = 0
    var bugsEaten: Int = 0
    var currentMunchEligibleBugs: Int = 0
    var fullBugClearsDuringMunch: Int = 0

    // Goodie accounting retained from Phase 3 plus the original Skill-specific
    // timing/expiry state. Timing samples are normalized [0,1] life-cycle ages
    // for Yummy, Bonus, and Multiplier dots; Yuk uses its own recovered rules.
    var goodiesSpawned: Int = 0
    var goodiesEaten: Int = 0
    var goodieTimingSkillSum: Float = 0
    var goodieTimingSkillSamples: Int = 0

    var yummyEaten: Int = 0
    var yummyExpired: Int = 0
    var activeYummyDots: Int = 0

    var yukSpawned: Int = 0
    var yukEaten: Int = 0
    var yukExpired: Int = 0
    var activeYukDots: Int = 0

    var yummyPowerActivated: Bool = false
}

struct AquaDotLevelResult: Equatable, Sendable {
    let bonus: Int
    let skill: Int
    let multiplier: Int
    let levelAward: Int
    let scoreBefore: Int
    let scoreAfter: Int
    let quality: AquaDotLevelQuality
}

enum AquaDotSkillScoring {
    /// Phase 4B: binary-recovered Skill calculation.
    ///
    /// The original function is the 0x5f3c2...0x5f824 routine in the shipped
    /// i386 executable. It consumes the Skill state block, selects quality 0...4,
    /// floors the final floating-point result, and returns that integer to the
    /// tween-level `(Bonus + Skill) × Multiplier` path.
    static func calculate(state: AquaDotGameState) -> (points: Int, quality: AquaDotLevelQuality) {
        let stats = state.levelStats
        let snapshot = AquaDotRecoveredSkillSnapshot(
            levelDifficulty: stats.skillBaseDifficulty,
            totalMunchDots: stats.initialMunchDots,
            remainingMunchDots: state.remainingMunchDots.count,
            timingSampleSum: stats.goodieTimingSkillSum,
            timingSampleCount: stats.goodieTimingSkillSamples,
            fullBugClearsDuringMunch: stats.fullBugClearsDuringMunch,
            ateAnyBugWithMunch: stats.bugsEaten > 0,
            everyConsumedMunchAteBug: stats.munchesStarted == stats.munchesWithAtLeastOneBug,
            damageContactOccurred: stats.damageContactOccurred,
            cumulativeDamage: Float(stats.damageTaken),
            minimumEnergyAfterDamage: stats.minimumEnergyAfterDamage,
            activatedYummyPower: stats.yummyPowerActivated,
            specialPowerRemaining: Float(state.specialPowerAmount),
            ateAnyYummyDot: stats.yummyEaten > 0,
            missedAnyYummyDot: stats.yummyExpired > 0 || stats.activeYummyDots > 0,
            yukEverSpawned: stats.yukSpawned > 0,
            yukRemainingAtEnd: stats.activeYukDots,
            ateAnyYukDot: stats.yukEaten > 0,
            expiredAnyYukDot: stats.yukExpired > 0,
            deaths: stats.livesLost
        )
        return AquaDotRecoveredSkillScoring.calculate(snapshot)
    }
}
