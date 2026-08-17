import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase4BSkillScoringTests {
    private func baseline(
        deaths: Int = 0,
        difficulty: Float = 0.30
    ) -> AquaDotRecoveredSkillSnapshot {
        AquaDotRecoveredSkillSnapshot(
            levelDifficulty: difficulty,
            totalMunchDots: 0,
            remainingMunchDots: 0,
            timingSampleSum: 0,
            timingSampleCount: 0,
            fullBugClearsDuringMunch: 0,
            ateAnyBugWithMunch: false,
            everyConsumedMunchAteBug: true,
            damageContactOccurred: false,
            cumulativeDamage: 0,
            minimumEnergyAfterDamage: 1,
            activatedYummyPower: false,
            specialPowerRemaining: 0,
            ateAnyYummyDot: false,
            missedAnyYummyDot: false,
            yukEverSpawned: false,
            yukRemainingAtEnd: 0,
            ateAnyYukDot: false,
            expiredAnyYukDot: false,
            deaths: deaths
        )
    }

    @Test func exactRecoveredQualityBoundaries() {
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 499.999) == .yuk)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 500) == .okay)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 1_249.999) == .okay)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 1_250) == .good)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 2_499.999) == .good)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 2_500) == .veryGood)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 3_499.999) == .veryGood)
        #expect(AquaDotRecoveredSkillScoring.quality(forRawSkill: 3_500) == .wowBest)
    }

    @Test func exactRecoveredMunchRemainderTable() {
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 0, remaining: 0) == 40)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 1, remaining: 1) == 40)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 2, remaining: 1) == 10)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 2, remaining: 2) == 40)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 3, remaining: 1) == 7)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 3, remaining: 2) == 15)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 3, remaining: 3) == 40)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 4, remaining: 1) == 5)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 4, remaining: 2) == 10)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 4, remaining: 3) == 20)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 4, remaining: 4) == 40)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 5, remaining: 1) == 4)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 5, remaining: 2) == 8)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 5, remaining: 3) == 16)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 5, remaining: 4) == 32)
        #expect(AquaDotRecoveredSkillScoring.munchRemainderComponent(total: 5, remaining: 5) == 0)
    }

    @Test func recoveredCanonicalVectorAtDefaultFirstLevelDifficulty() {
        let result = AquaDotRecoveredSkillScoring.calculate(baseline())
        #expect(result.points == 6_045)
        #expect(result.quality == .wowBest)
    }

    @Test func recoveredDeathFactorsAreMultiplicative() {
        #expect(AquaDotRecoveredSkillScoring.calculate(baseline(deaths: 0)).points == 6_045)
        #expect(AquaDotRecoveredSkillScoring.calculate(baseline(deaths: 1)).points == 4_836)
        #expect(AquaDotRecoveredSkillScoring.calculate(baseline(deaths: 2)).points == 3_022)
        #expect(AquaDotRecoveredSkillScoring.calculate(baseline(deaths: 3)).points == 1_209)
        #expect(AquaDotRecoveredSkillScoring.calculate(baseline(deaths: 8)).points == 1_209)
    }

    @Test func recoveredNonlinearDamageVector() {
        var input = baseline()
        input.damageContactOccurred = true
        input.cumulativeDamage = 0.25
        input.minimumEnergyAfterDamage = 0.75
        let result = AquaDotRecoveredSkillScoring.calculate(input)
        #expect(result.points == 4_566)
        #expect(result.quality == .wowBest)
    }

    @Test func recoveredGoodieTimingAndSpecialVector() {
        var input = baseline()
        input.timingSampleSum = 1.5
        input.timingSampleCount = 2
        input.specialPowerRemaining = 0.5
        input.activatedYummyPower = true
        input.ateAnyYummyDot = true
        input.missedAnyYummyDot = true
        input.yukEverSpawned = true
        input.yukRemainingAtEnd = 1
        input.ateAnyYukDot = true
        input.expiredAnyYukDot = true
        let result = AquaDotRecoveredSkillScoring.calculate(input)
        #expect(result.points == 5_764)
        #expect(result.quality == .wowBest)
    }
}
