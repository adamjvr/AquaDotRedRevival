import Foundation

/// Long-running executable audit for the Phase 3C campaign selector.
/// Compile together with AquaDotCampaignSelector.swift; this exercises the real
/// production selector rather than a Python reimplementation.
@main
struct AquaDotPhase3DCampaignSoak {
    static func main() throws {
        let requested = CommandLine.arguments.dropFirst().first.flatMap(Int.init) ?? 150_000
        let totalIterations = max(10_000, requested)
        let perMode = max(1, totalIterations / AquaDotCampaignDifficultyMode.allCases.count)

        var grandSelections = 0
        var persistenceChecks = 0
        var recentWindowRepeats = 0

        for (modeOffset, mode) in AquaDotCampaignDifficultyMode.allCases.enumerated() {
            let seed = UInt64(0xA51A_D07C_0000_0001) &+ UInt64(modeOffset) &* 0x9E37_79B9
            var selector = AquaDotCampaignSelector.fresh(difficultyMode: mode, seed: seed)
            var seenCatalog = Set<Int>()
            var seenFamilies = Set<Int>()
            var recentObserved: [Int] = []

            for step in 0..<perMode {
                let before = selector.state
                let maximum = AquaDotCampaignSelector.maximumUnlockedVariant(
                    forBaseDifficulty: AquaDotCampaignSelector.baseDifficulty(
                        forSelectedLevelCount: before.levelsSelected,
                        mode: before.difficultyMode
                    )
                )

                let index = selector.selectNextCatalogIndex()
                guard (0..<AquaDotCampaignSelector.standardCatalogCount).contains(index) else {
                    fatalError("catalog index escaped 0..<205: \(index)")
                }
                let split = AquaDotCampaignSelector.familyAndVariant(forCatalogIndex: index)

                guard selector.state.levelsSelected == before.levelsSelected + 1 else {
                    fatalError("levelsSelected did not advance exactly once")
                }
                guard selector.state.recentFamilies.count <= AquaDotCampaignSelector.recentFamilyCapacity else {
                    fatalError("recent-family ring exceeded capacity")
                }
                guard selector.state.recentFamilies.allSatisfy({ (0..<AquaDotCampaignSelector.familyCount).contains($0) }) else {
                    fatalError("recent-family ring contains invalid family")
                }

                if let previous = before.previousVariantTier,
                   split.variant == previous,
                   split.variant < maximum {
                    fatalError("forbidden lower-tier immediate repeat at step \(step)")
                }

                if recentObserved.contains(split.family) {
                    // The recovered selector has an explicit >26-rejection escape,
                    // so this is a metric rather than an unconditional failure.
                    recentWindowRepeats += 1
                }
                recentObserved.append(split.family)
                if recentObserved.count > AquaDotCampaignSelector.recentFamilyCapacity {
                    recentObserved.removeFirst()
                }

                seenCatalog.insert(index)
                seenFamilies.insert(split.family)
                grandSelections += 1

                // Periodically round-trip the complete selector state through JSON,
                // then prove the restored instance produces an identical future.
                if step % 997 == 0 {
                    let data = try JSONEncoder().encode(selector.state)
                    let decoded = try JSONDecoder().decode(AquaDotCampaignSelectorState.self, from: data)
                    var originalBranch = AquaDotCampaignSelector(state: selector.state)
                    var restoredBranch = AquaDotCampaignSelector(state: decoded)
                    for _ in 0..<64 {
                        let a = originalBranch.selectNextCatalogIndex()
                        let b = restoredBranch.selectNextCatalogIndex()
                        guard a == b, originalBranch.state == restoredBranch.state else {
                            fatalError("checkpoint round-trip changed future campaign sequence")
                        }
                    }
                    persistenceChecks += 1
                }
            }

            guard seenFamilies.count == AquaDotCampaignSelector.familyCount else {
                fatalError("mode \(mode.rawValue) did not visit all 41 families")
            }
            guard seenCatalog.count == AquaDotCampaignSelector.standardCatalogCount else {
                fatalError("mode \(mode.rawValue) did not visit all 205 family/variant combinations")
            }

            print("PASS mode\(mode.rawValue): \(perMode) selections, 41/41 families, 205/205 catalog entries")
        }

        print("PASS selector-state JSON future-equivalence checks: \(persistenceChecks)")
        print("INFO permitted 10-window repeats observed via escape path: \(recentWindowRepeats)")
        print("PHASE3D CAMPAIGN SOAK PASS: \(grandSelections) selections")
    }
}
