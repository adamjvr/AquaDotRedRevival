import Foundation

/// Direct, presentation-independent inputs to the original Skill arithmetic.
/// Keeping this as a value type makes the recovered function executable in tests
/// without constructing an entire SpriteKit/gameplay session.
struct AquaDotRecoveredSkillSnapshot: Equatable, Sendable {
    var levelDifficulty: Float

    var totalMunchDots: Int
    var remainingMunchDots: Int

    var timingSampleSum: Float
    var timingSampleCount: Int

    var fullBugClearsDuringMunch: Int
    var ateAnyBugWithMunch: Bool
    var everyConsumedMunchAteBug: Bool

    var damageContactOccurred: Bool
    var cumulativeDamage: Float
    var minimumEnergyAfterDamage: Float

    var activatedYummyPower: Bool
    var specialPowerRemaining: Float

    var ateAnyYummyDot: Bool
    var missedAnyYummyDot: Bool

    var yukEverSpawned: Bool
    var yukRemainingAtEnd: Int
    var ateAnyYukDot: Bool
    var expiredAnyYukDot: Bool

    var deaths: Int
}

/// Exact arithmetic reconstructed from AquaDot!Red i386 0x5f3c2...0x5f824.
///
/// Evidence boundary:
/// - constants, branching, death factors, final floor, and quality thresholds are
///   binary-proven;
/// - the semantic field names are assigned only where the mutation call sites and
///   shipped strategy guide agree;
/// - the always-on +15 term is preserved without inventing a semantic label,
///   because original flag 0x1d9639 is initialized true and no runtime write was
///   found in the shipped executable.
enum AquaDotRecoveredSkillScoring {
    static let qualityOkayThreshold: Float = 500
    static let qualityGoodThreshold: Float = 1_250
    static let qualityVeryGoodThreshold: Float = 2_500
    static let qualityWowBestThreshold: Float = 3_500

    static func calculate(
        _ input: AquaDotRecoveredSkillSnapshot
    ) -> (points: Int, quality: AquaDotLevelQuality) {
        let difficultyFactor = Double(input.levelDifficulty) + 1.0

        // `_draw`/MazeDots pulsing-dot counters feed this table. Token 8 creates
        // the pulsing Munch dots, so total/remaining map directly to the original
        // `0x959c0`/`0x959bc` pair consumed by the Skill routine.
        var skill = munchRemainderComponent(
            total: input.totalMunchDots,
            remaining: input.remainingMunchDots
        )

        // Yummy / Bonus / Multiplier meal age samples are accumulated by the
        // original helper at 0x5ca18. Their average is cubed and scaled by 100.
        let timingAverage: Float
        if input.timingSampleCount > 0 {
            timingAverage = input.timingSampleSum / Float(input.timingSampleCount)
        } else {
            timingAverage = 0
        }
        var timing = timingAverage * timingAverage
        timing *= timingAverage
        timing *= 100
        skill += timing

        // Count of Munch windows in which every eligible bug was eaten.
        switch input.fullBugClearsDuringMunch {
        case 1: skill += 5
        case 2: skill += 10
        case 3: skill += 30
        case 4: skill += 100
        default: break
        }

        // Original flags 0x1d9633 and 0x1d9632 respectively.
        if !input.ateAnyBugWithMunch { skill += 10 }
        if input.everyConsumedMunchAteBug { skill += 20 }

        // Damage is not a flat subtraction. The original awards a nonlinear
        // preservation term, then separately rewards the minimum Energy trough.
        if !input.damageContactOccurred {
            skill = Float(Double(skill) + 100.0 * difficultyFactor)
        } else if input.cumulativeDamage < 1.0 {
            let preserved = Double(1.0 - input.cumulativeDamage)
            skill = Float(Double(skill) + preserved * (preserved * 100.0) * difficultyFactor)
        }

        var minimumEnergyTerm = input.minimumEnergyAfterDamage
        minimumEnergyTerm *= minimumEnergyTerm
        minimumEnergyTerm *= 100
        skill = Float(Double(skill) + Double(minimumEnergyTerm) * difficultyFactor)

        // All-or-nothing Yummy activation flag.
        if !input.activatedYummyPower { skill += 20 }

        // Remaining special-power meter is squared, scaled by 50, and difficulty
        // weighted before the final whole-skill difficulty multiplier below.
        var specialTerm = input.specialPowerRemaining
        specialTerm *= specialTerm
        specialTerm *= 50
        skill = Float(Double(skill) + Double(specialTerm) * difficultyFactor)

        // Yummy goodie all/none behavior recovered from the eaten/expired flags.
        if !input.ateAnyYummyDot { skill += 50 }
        if !input.missedAnyYummyDot { skill += 15 }

        // Shipped binary state 0x1d9639: initialized true and never mutated by a
        // discovered write. Preserve the resulting contribution as data, not lore.
        skill += 15

        // Yuk: spawning disables the no-Yuk +5 path; remaining Yuk dots at level
        // end receive 40 for one and 100 for more than one. Eating and expiration
        // have independent binary flags.
        if !input.yukEverSpawned {
            skill += 5
        } else if input.yukRemainingAtEnd == 1 {
            skill += 40
        } else if input.yukRemainingAtEnd > 1 {
            skill += 100
        }

        if !input.ateAnyYukDot { skill += 10 }
        if !input.expiredAnyYukDot { skill += 20 }

        // Original global scale before death penalty.
        skill *= 10

        switch input.deaths {
        case 0:
            break
        case 1:
            skill = Float(Double(skill) * 0.8)
        case 2:
            skill *= 0.5
        default:
            skill = Float(Double(skill) * 0.2)
        }

        // The complete Skill is difficulty-weighted once more at the end.
        skill = Float(Double(skill) * difficultyFactor)

        let quality = quality(forRawSkill: skill)
        let points = Int(floorf(skill))
        return (points, quality)
    }

    static func quality(forRawSkill skill: Float) -> AquaDotLevelQuality {
        if skill < qualityOkayThreshold { return .yuk }
        if skill < qualityGoodThreshold { return .okay }
        if skill < qualityVeryGoodThreshold { return .good }
        if skill < qualityWowBestThreshold { return .veryGood }
        return .wowBest
    }

    /// Binary-exact branch table at 0x5f48a...0x5f55f.
    static func munchRemainderComponent(total: Int, remaining: Int) -> Float {
        if total > 3 {
            let ratio = Float(4.0 / Double(total))
            switch remaining {
            case 1: return ratio * 5
            case 2: return ratio * 10
            case 3: return ratio * 20
            case 4: return ratio * 40
            default: return 0
            }
        }

        if total == 3 {
            switch remaining {
            case 1: return 7
            case 2: return 15
            case 3: return 40
            default: return 0
            }
        }

        if total == 2 {
            switch remaining {
            case 1: return 10
            case 2: return 40
            default: return 0
            }
        }

        if total == 1 {
            return remaining == 1 ? 40 : 0
        }

        // The original zero-Munch path falls through to the same 40-point branch.
        return total == 0 ? 40 : 0
    }
}
