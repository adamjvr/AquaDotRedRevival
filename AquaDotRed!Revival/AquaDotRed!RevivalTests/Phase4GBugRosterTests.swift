import Testing
@testable import AquaDotRed_Revival

struct Phase4GBugRosterTests {
    @Test func recoveredColorToPersonalityMappingMatchesSetupEnemy() {
        #expect(AquaDotRecoveredEnemyColor.red.personality == .hunter)
        #expect(AquaDotRecoveredEnemyColor.blue.personality == .blocker)
        #expect(AquaDotRecoveredEnemyColor.yellow.personality == .sneaker)
        #expect(AquaDotRecoveredEnemyColor.orange.personality == .houndDog)
        #expect(AquaDotRecoveredEnemyColor.indigo.personality == .loneWolf)
        #expect(AquaDotRecoveredEnemyColor.green.personality == .hermit)
        #expect(AquaDotRecoveredEnemyColor.magenta.personality == .protector)
        #expect(AquaDotRecoveredEnemyColor.cyan.personality == .mantis)
        #expect(AquaDotRecoveredEnemyColor.nightReaper.personality == nil)
    }

    @Test func neonIsAppearanceProbabilityNotANinthStrategy() {
        #expect(AquaDotRecoveredBugRoster.neonAppearanceProbability(difficulty: 0.49) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.neonAppearanceProbability(difficulty: 0.50) - 0.10) < 0.000001)
        #expect(abs(AquaDotRecoveredBugRoster.neonAppearanceProbability(difficulty: 1.0) - 0.20) < 0.000001)
        #expect(abs(AquaDotRecoveredBugRoster.neonAppearanceProbability(difficulty: 2.0) - 0.20) < 0.000001)
    }

    @Test func recoveredFullVersionAvailabilityThresholdsAreLocked() {
        #expect(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .indigo, difficulty: 0.09) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .indigo, difficulty: 0.10) - 0.40) < 0.000001)

        #expect(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .green, difficulty: 0.29) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .green, difficulty: 0.30) - 0.45) < 0.000001)

        #expect(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .magenta, difficulty: 0.49) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .magenta, difficulty: 0.50) - 0.75) < 0.000001)

        #expect(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .cyan, difficulty: 0.69) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .cyan, difficulty: 0.70) - 0.70) < 0.000001)

        // Reaper availability is recovered and recorded even though Phase 4G does
        // not generate Reaper until its special movement/contact behavior exists.
        #expect(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .nightReaper, difficulty: 0.69) == 0)
        #expect(abs(AquaDotRecoveredBugRoster.fullVersionAvailabilityProbability(color: .nightReaper, difficulty: 0.70) - 0.70) < 0.000001)
    }

    @Test func recoveredFourEnemyCompositionRollMatchesBinaryThresholds() {
        #expect(AquaDotRecoveredBugRoster.compositionUpperBound(difficulty: 0.0) == 8)
        #expect(AquaDotRecoveredBugRoster.compositionUpperBound(difficulty: 0.5) == 13)
        #expect(AquaDotRecoveredBugRoster.compositionUpperBound(difficulty: 1.0) == 16)
        #expect(AquaDotRecoveredBugRoster.compositionUpperBound(difficulty: 9.0) == 16)

        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 8) == [0, 1, 2, 3])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 9) == [0, 0, 1, 2])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 11) == [0, 0, 1, 2])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 12) == [0, 0, 1, 1])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 13) == [0, 0, 1, 1])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 14) == [0, 0, 0, 1])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 15) == [0, 0, 0, 1])
        #expect(AquaDotRecoveredBugRoster.multiplicityPattern(compositionDraw: 16) == [0, 0, 0, 0])
    }

    @Test func generatedPlansUseRealStrategiesAndNeverEncodeNeonAsPersonality() {
        for difficulty in [0.0, 0.3, 0.5, 0.7, 1.0, 2.0] {
            for seed in 1...64 {
                var random = AquaDotSeededRandom(seed: UInt64(seed))
                let plan = AquaDotRecoveredBugRoster.makeSpawnPlan(
                    difficulty: difficulty,
                    random: &random
                )
                #expect(plan.count == 4)
                #expect(!plan.contains { $0.personality == .neon })
                #expect(!plan.contains { $0.sourceColor == .nightReaper })
                #expect(plan.allSatisfy { $0.sourceColor.personality == $0.personality })
            }
        }
    }

    @Test func neonFlagNeverChangesUnderlyingStrategy() {
        let normal = AquaDotRecoveredBugSpawn(
            sourceColor: .indigo,
            personality: .loneWolf,
            isNeonAppearance: false
        )
        let disguised = AquaDotRecoveredBugSpawn(
            sourceColor: .indigo,
            personality: .loneWolf,
            isNeonAppearance: true
        )
        #expect(normal.personality == disguised.personality)
        #expect(normal.sourceColor == disguised.sourceColor)
        #expect(normal.isNeonAppearance != disguised.isNeonAppearance)
    }
}
