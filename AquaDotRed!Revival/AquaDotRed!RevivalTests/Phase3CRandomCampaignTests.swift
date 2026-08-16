import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase3CRandomCampaignTests {
    @Test func recoveredCatalogArchitectureIs41FamiliesBy5Variants() {
        #expect(AquaDotCampaignSelector.familyCount == 41)
        #expect(AquaDotCampaignSelector.variantsPerFamily == 5)
        #expect(AquaDotCampaignSelector.standardCatalogCount == 205)

        for family in 0..<41 {
            for variant in 0..<5 {
                let index = AquaDotCampaignSelector.catalogIndex(
                    familyIndex: family,
                    variantIndex: variant
                )
                let split = AquaDotCampaignSelector.familyAndVariant(forCatalogIndex: index)
                #expect(split.family == family)
                #expect(split.variant == variant)
            }
        }
    }

    @Test func cumulativeVariantEndpointTableMatchesRecoveredBinary() {
        #expect(AquaDotCampaignSelector.cumulativeVariantEndpoints == [1, 2, 4, 8, 16])

        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 0, maximumUnlocked: 4) == 0)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 1, maximumUnlocked: 4) == 1)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 2, maximumUnlocked: 4) == 2)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 3, maximumUnlocked: 4) == 2)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 4, maximumUnlocked: 4) == 3)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 7, maximumUnlocked: 4) == 3)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 8, maximumUnlocked: 4) == 4)
        #expect(AquaDotCampaignSelector.variantTier(forCumulativeDraw: 15, maximumUnlocked: 4) == 4)
    }

    @Test func recoveredDifficultyThresholdsAreInclusive() {
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.25) == 0)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.250001) == 1)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.50) == 1)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.500001) == 2)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.75) == 2)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 0.750001) == 3)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 1.00) == 3)
        #expect(AquaDotCampaignSelector.maximumUnlockedVariant(forBaseDifficulty: 1.000001) == 4)
    }

    @Test func shippedDefaultDifficultyCurveMatchesRecoveredMode1() {
        #expect(AquaDotCampaignDifficultyMode.shippedDefault == .mode1)
        #expect(abs(AquaDotCampaignSelector.baseDifficulty(forSelectedLevelCount: 0, mode: .mode1) - 0.30) < 0.000001)
        #expect(abs(AquaDotCampaignSelector.baseDifficulty(forSelectedLevelCount: 1, mode: .mode1) - 0.40) < 0.000001)
        #expect(abs(AquaDotCampaignSelector.baseDifficulty(forSelectedLevelCount: 7, mode: .mode1) - 1.00) < 0.000001)
        #expect(abs(AquaDotCampaignSelector.baseDifficulty(forSelectedLevelCount: 8, mode: .mode1) - 1.05) < 0.000001)
    }

    @Test func freshRunRandomizesFamilyAndUsesOnlyInitiallyUnlockedVariants() {
        var observedFamilies = Set<Int>()
        for seed in 1...64 {
            var selector = AquaDotCampaignSelector.fresh(
                difficultyMode: .shippedDefault,
                seed: UInt64(seed)
            )
            let index = selector.selectNextCatalogIndex()
            let split = AquaDotCampaignSelector.familyAndVariant(forCatalogIndex: index)
            #expect((0..<41).contains(split.family))
            #expect((0...1).contains(split.variant))
            observedFamilies.insert(split.family)
        }
        #expect(observedFamilies.count > 1)
    }

    @Test func recentFamilyRingSuppressesNormalRepeats() {
        var selector = AquaDotCampaignSelector.fresh(
            difficultyMode: .shippedDefault,
            seed: 0xA51A_D07C_1234_5678
        )
        var previousTen: [Int] = []

        for _ in 0..<500 {
            let index = selector.selectNextCatalogIndex()
            let family = AquaDotCampaignSelector.familyAndVariant(forCatalogIndex: index).family
            #expect(!previousTen.contains(family))
            previousTen.append(family)
            if previousTen.count > 10 { previousTen.removeFirst() }
        }
    }

    @Test func serializedSelectorStateProducesIdenticalFutureSequence() {
        var original = AquaDotCampaignSelector.fresh(
            difficultyMode: .shippedDefault,
            seed: 0x1234_5678_9ABC_DEF0
        )
        for _ in 0..<17 { _ = original.selectNextCatalogIndex() }

        var a = AquaDotCampaignSelector(state: original.state)
        var b = AquaDotCampaignSelector(state: original.state)
        let sequenceA = (0..<100).map { _ in a.selectNextCatalogIndex() }
        let sequenceB = (0..<100).map { _ in b.selectNextCatalogIndex() }
        #expect(sequenceA == sequenceB)
    }

    @Test func selectorStateRoundTripsThroughSchema2Checkpoint() throws {
        let suite = "AquaDotPhase3C.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        var selector = AquaDotCampaignSelector.fresh(
            difficultyMode: .shippedDefault,
            seed: 0xBADA_55
        )
        let levelIndex = selector.selectNextCatalogIndex()
        let carry = AquaDotRunCarry(
            score: 1234,
            bonus: 0,
            multiplier: 2,
            lives: 3,
            levelsCleared: 0
        )

        let store = AquaDotCampaignStore(defaults: defaults)
        store.saveBeginningOfLevel(
            levelIndex: levelIndex,
            carry: carry,
            selectorState: selector.state
        )

        let loaded = try #require(store.load())
        #expect(loaded.version == 2)
        #expect(loaded.levelIndex == levelIndex)
        #expect(loaded.selectorState == selector.state)
    }

    @Test func schema1CheckpointRemainsDecodable() throws {
        let json = """
        {
          "version": 1,
          "levelIndex": 48,
          "score": 1000,
          "multiplier": 2,
          "lives": 3,
          "levelsCleared": 4,
          "savedAt": "2026-08-16T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let checkpoint = try decoder.decode(AquaDotCampaignCheckpoint.self, from: json)
        #expect(checkpoint.version == 1)
        #expect(checkpoint.selectorState == nil)
        #expect(checkpoint.levelIndex == 48)
    }
}
