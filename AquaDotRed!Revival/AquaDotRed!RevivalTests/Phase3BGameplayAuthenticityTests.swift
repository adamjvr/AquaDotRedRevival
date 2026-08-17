import Testing
@testable import AquaDotRed_Revival

struct Phase3BGameplayAuthenticityTests {
    @Test func bugRosterReflectsPhase4GCorrectionWhileRetainingLegacyNeonDecode() {
        // Phase 4G recovered Lone Wolf as the missing eighth real strategy and
        // proved Neon is a presentation disguise. The `.neon` enum case remains
        // only so pre-4G state/source can still decode, hence nine Codable cases.
        #expect(AquaDotBugPersonality.allCases.count == 9)
        #expect(Set(AquaDotBugPersonality.basicRoster) == Set([
            .hunter, .blocker, .sneaker, .houndDog, .loneWolf,
        ]))
        #expect(Set(AquaDotBugPersonality.advancedRoster) == Set([
            .protector, .mantis, .hermit,
        ]))
        #expect(!AquaDotBugPersonality.neonEmulationCandidates.contains(.neon))
    }

    @Test func recoveredDifficultyFunctionMatchesBinaryConstants() {
        #expect(abs(AquaDotRecoveredDifficulty.factor(forDifficultyValue: 1) - 0.05) < 0.000001)
        #expect(abs(AquaDotRecoveredDifficulty.factor(forDifficultyValue: 2) - 0.25) < 0.000001)
        #expect(abs(AquaDotRecoveredDifficulty.factor(forDifficultyValue: 3) - 0.45) < 0.000001)
        #expect(abs(AquaDotRecoveredDifficulty.factor(forDifficultyValue: 4) - 0.65) < 0.000001)
        #expect(abs(AquaDotRecoveredDifficulty.factor(forDifficultyValue: 5) - 0.85) < 0.000001)
    }

    @Test func recoveredMazeSproutLimitsAndCureWindowsAreLocked() {
        #expect(AquaDotRecoveredSproutMechanics.maximumActiveSproutSprites == 200)
        #expect(AquaDotRecoveredSproutMechanics.maximumInfectionRecords == 1000)
        #expect(abs(AquaDotRecoveredSproutMechanics.fastCureDelay.lowerBound - 0.075) < 0.000001)
        #expect(abs(AquaDotRecoveredSproutMechanics.fastCureDelay.upperBound - 0.125) < 0.000001)
        #expect(abs(AquaDotRecoveredSproutMechanics.slowCureDelay.lowerBound - 0.5625) < 0.000001)
        #expect(abs(AquaDotRecoveredSproutMechanics.slowCureDelay.upperBound - 0.9375) < 0.000001)
    }

    @Test func legacyPhase3BRosterHelperStillReturnsFourOrdinaryStrategies() {
        // This helper is retained for historical tests/migration only. Normal
        // Phase 4G level creation uses AquaDotRecoveredBugRoster instead.
        var random = AquaDotSeededRandom(seed: 1234)
        let roster = AquaDotGameSimulation.phase3BBugRoster(
            levelsCleared: 0,
            enemyCount: 4,
            random: &random
        )
        #expect(roster.count == 4)
        #expect(roster.allSatisfy { AquaDotBugPersonality.basicRoster.contains($0) })
    }

    @Test func legacyPhase3BRosterHelperCanStillExerciseAdvancedStrategies() {
        var random = AquaDotSeededRandom(seed: 1234)
        let roster = AquaDotGameSimulation.phase3BBugRoster(
            levelsCleared: 6,
            enemyCount: 4,
            random: &random
        )
        #expect(roster.count == 4)
        #expect(roster.contains { AquaDotBugPersonality.advancedRoster.contains($0) })
    }
}
