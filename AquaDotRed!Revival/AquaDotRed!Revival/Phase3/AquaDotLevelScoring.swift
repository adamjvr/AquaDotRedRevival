import Foundation

/// Evidence-backed end-of-level categories recovered from the original audio/
/// presentation resources (`tween_yuk`, `tween_okay`, `tween_good`,
/// `tween_veryGood`, `tween_wowBest`). The exact original numeric skill weights
/// are not yet recovered, so the score estimator below keeps every provisional
/// weight isolated in one place rather than scattering magic numbers through
/// the simulation.
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

    /// Six recovered 64-pixel message frames exist in each of five visual bands.
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

struct AquaDotLevelStats: Equatable, Sendable {
    var initialRequiredDots: Int = 0
    var initialMunchDots: Int = 0
    var damageTaken: Double = 0
    var livesLost: Int = 0
    var munchDotsEaten: Int = 0
    var munchesStarted: Int = 0
    var munchesWithAtLeastOneBug: Int = 0
    var bugsEaten: Int = 0
    var goodiesSpawned: Int = 0
    var goodiesEaten: Int = 0
    var yukSpawned: Int = 0
    var yukEaten: Int = 0
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
    /// Reconstructed Skill estimator using only factors explicitly described by
    /// the shipped strategy guide. Relative signs are evidence-backed; exact
    /// historical weights remain a reverse-engineering target.
    static func calculate(state: AquaDotGameState) -> (points: Int, quality: AquaDotLevelQuality) {
        let stats = state.levelStats
        var skill = 1_000

        // Strategy guide: leaving Munch and Yuk dots uneaten increases Skill.
        let uneatenMunch = max(0, stats.initialMunchDots - stats.munchDotsEaten)
        let uneatenYuk = max(0, stats.yukSpawned - stats.yukEaten)
        skill += uneatenMunch * 220
        skill += uneatenYuk * 180

        // Strategy guide: eating at least one bug with each Munch increases Skill.
        skill += stats.munchesWithAtLeastOneBug * 350
        if stats.munchesStarted > stats.munchesWithAtLeastOneBug {
            skill -= (stats.munchesStarted - stats.munchesWithAtLeastOneBug) * 180
        }

        // Strategy guide: not activating a Yummy power, and finishing with
        // special power remaining, increase Skill.
        if !stats.yummyPowerActivated { skill += 500 }
        skill += Int(max(0, min(1, state.specialPowerAmount)) * 600)

        // Strategy guide: eating either all goodie dots or none is rewarded,
        // with none worth more. We can measure spawned/eaten goodies exactly.
        if stats.goodiesSpawned > 0 {
            if stats.goodiesEaten == 0 {
                skill += 650
            } else if stats.goodiesEaten == stats.goodiesSpawned {
                skill += 450
            }
        }

        // Strategy guide: damage and deaths reduce Skill.
        skill -= Int(stats.damageTaken * 1_800)
        skill -= stats.livesLost * 1_100

        skill = max(0, skill)

        let quality: AquaDotLevelQuality
        switch skill {
        case ..<700: quality = .yuk
        case ..<1_500: quality = .okay
        case ..<2_700: quality = .good
        case ..<4_200: quality = .veryGood
        default: quality = .wowBest
        }
        return (skill, quality)
    }
}
