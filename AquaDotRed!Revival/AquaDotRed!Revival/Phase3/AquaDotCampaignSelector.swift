import Foundation

/// Numeric difficulty modes recovered from the original selector path.
///
/// The shipped preferences initializer selects raw mode 1. We intentionally keep
/// neutral names here because the exact original UI labels for 0/1/2 are not part
/// of the binary evidence used by this patch.
enum AquaDotCampaignDifficultyMode: Int, Codable, CaseIterable, Sendable {
    case mode0 = 0
    case mode1 = 1
    case mode2 = 2

    static let shippedDefault: AquaDotCampaignDifficultyMode = .mode1
}

/// Everything needed to continue the randomized campaign without rerolling it.
/// This state belongs to campaign selection only and is deliberately separate
/// from bug/goodie/gameplay randomness.
struct AquaDotCampaignSelectorState: Codable, Equatable, Sendable {
    var rngState: UInt64
    var recentFamilies: [Int]
    var recentFamilyCursor: Int
    var previousVariantTier: Int?
    var levelsSelected: Int
    var difficultyMode: AquaDotCampaignDifficultyMode
}

/// Revival-specific deterministic random stream for campaign selection.
///
/// The original executable used its libc random stream; its exact seed/bitstream
/// has not been recovered. The selector algorithm and distributions below are
/// recovered, but this generator is intentionally not claimed bit-identical.
private struct AquaDotCampaignRNG: Sendable {
    var state: UInt64

    init(state: UInt64) {
        self.state = state == 0 ? 0xA51A_D07C_A4D0_7EED : state
    }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    /// Convert the 53 high random bits to [0,1), then scale to an integer range.
    /// This keeps the cumulative selector probabilities explicit and avoids
    /// sharing the game's fixed-step simulation RNG.
    mutating func int(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        let unit = Double(nextUInt64() >> 11) / 9_007_199_254_740_992.0
        return min(upperBound - 1, Int(unit * Double(upperBound)))
    }
}

/// Source-like reconstruction of `selectRandomLevel2` from AquaDot!Red.
struct AquaDotCampaignSelector: Sendable {
    static let familyCount = 41
    static let variantsPerFamily = 5
    static let standardCatalogCount = familyCount * variantsPerFamily
    static let recentFamilyCapacity = 10

    /// The original tests the duplicate retry counter against 0x19. Therefore
    /// 26 duplicate draws can be rejected; the following draw is accepted as an
    /// escape path so selection always terminates.
    static let duplicateFamilyRejectionLimit = 26

    /// Exact cumulative endpoints recovered from the 5x5 table at 0x81c80.
    /// A row is selected by the current difficulty tier; the final non-zero
    /// endpoint is the draw range. Example tier 4: draw 0..<16 and map
    /// 0->0, 1->1, 2...3->2, 4...7->3, 8...15->4.
    static let cumulativeVariantEndpoints = [1, 2, 4, 8, 16]

    private(set) var state: AquaDotCampaignSelectorState

    init(state: AquaDotCampaignSelectorState) {
        var normalized = state
        normalized.recentFamilies = Array(
            normalized.recentFamilies
                .filter { (0..<Self.familyCount).contains($0) }
                .suffix(Self.recentFamilyCapacity)
        )
        normalized.recentFamilyCursor = normalized.recentFamilies.isEmpty
            ? 0
            : ((normalized.recentFamilyCursor % Self.recentFamilyCapacity) + Self.recentFamilyCapacity)
                % Self.recentFamilyCapacity
        normalized.previousVariantTier = normalized.previousVariantTier.flatMap {
            (0..<Self.variantsPerFamily).contains($0) ? $0 : nil
        }
        normalized.levelsSelected = max(0, normalized.levelsSelected)
        if normalized.rngState == 0 {
            normalized.rngState = 0xA51A_D07C_A4D0_7EED
        }
        self.state = normalized
    }

    static func fresh(
        difficultyMode: AquaDotCampaignDifficultyMode = .shippedDefault,
        seed: UInt64 = UInt64.random(in: 1...UInt64.max)
    ) -> AquaDotCampaignSelector {
        AquaDotCampaignSelector(
            state: AquaDotCampaignSelectorState(
                rngState: seed,
                recentFamilies: [],
                recentFamilyCursor: 0,
                previousVariantTier: nil,
                levelsSelected: 0,
                difficultyMode: difficultyMode
            )
        )
    }

    /// Migration path for schema-1 checkpoints. The current maze is preserved;
    /// its family and variant are registered into the selector so the next draw
    /// behaves like continuation rather than an immediate reroll/repeat.
    static func bootstrapped(
        currentCatalogIndex: Int,
        levelsCleared: Int,
        difficultyMode: AquaDotCampaignDifficultyMode = .shippedDefault
    ) -> AquaDotCampaignSelector {
        let clamped = max(0, min(Self.standardCatalogCount - 1, currentCatalogIndex))
        let split = familyAndVariant(forCatalogIndex: clamped)

        // Deterministic migration seed: old saves did not contain selector RNG.
        let mixedSeed =
            UInt64(clamped + 1) &* 0x9E37_79B9_7F4A_7C15
            ^ UInt64(max(0, levelsCleared) + 1) &* 0xD1B5_4A32_D192_ED03
            ^ 0xA51A_D07C_A4D0_7EED

        return AquaDotCampaignSelector(
            state: AquaDotCampaignSelectorState(
                rngState: mixedSeed,
                recentFamilies: [split.family],
                recentFamilyCursor: 1,
                previousVariantTier: split.variant,
                // The currently loaded maze was already selected, even if it has
                // not yet been cleared.
                levelsSelected: max(1, levelsCleared + 1),
                difficultyMode: difficultyMode
            )
        )
    }

    static func catalogIndex(familyIndex: Int, variantIndex: Int) -> Int {
        familyIndex * variantsPerFamily + variantIndex
    }

    static func familyAndVariant(forCatalogIndex index: Int) -> (family: Int, variant: Int) {
        let clamped = max(0, min(standardCatalogCount - 1, index))
        return (clamped / variantsPerFamily, clamped % variantsPerFamily)
    }

    /// Recovered base-difficulty progression. `n` is the number of mazes that
    /// have already been selected when choosing another one.
    static func baseDifficulty(
        forSelectedLevelCount n: Int,
        mode: AquaDotCampaignDifficultyMode
    ) -> Double {
        let count = max(0, n)
        switch mode {
        case .mode0:
            return count <= 20
                ? Double(count) * 0.05
                : Double(count - 20) * 0.03 + 1.0
        case .mode1:
            return count <= 7
                ? Double(count) * 0.10 + 0.30
                : Double(count - 7) * 0.05 + 1.0
        case .mode2:
            return Double(count) * 0.10 + 0.70
        }
    }

    /// Exact threshold behavior recovered from `selectRandomLevel2`.
    static func maximumUnlockedVariant(forBaseDifficulty value: Double) -> Int {
        if value <= 0.25 { return 0 }
        if value <= 0.50 { return 1 }
        if value <= 0.75 { return 2 }
        if value <= 1.00 { return 3 }
        return 4
    }

    /// Pure helper mirroring the recovered cumulative endpoint table.
    static func variantTier(forCumulativeDraw draw: Int, maximumUnlocked: Int) -> Int {
        let maximum = max(0, min(variantsPerFamily - 1, maximumUnlocked))
        let upper = cumulativeVariantEndpoints[maximum]
        let value = max(0, min(upper - 1, draw))
        for tier in 0...maximum where value < cumulativeVariantEndpoints[tier] {
            return tier
        }
        return maximum
    }

    mutating func selectNextCatalogIndex() -> Int {
        var rng = AquaDotCampaignRNG(state: state.rngState)
        let base = Self.baseDifficulty(
            forSelectedLevelCount: state.levelsSelected,
            mode: state.difficultyMode
        )
        let maximumVariant = Self.maximumUnlockedVariant(forBaseDifficulty: base)

        // The recovered routine selects the weighted variant and then the base
        // family. The PRNG stream itself is Revival-specific, but keeping this
        // ordering mirrors the original control flow.
        let variant = selectVariant(maximumUnlocked: maximumVariant, using: &rng)
        let family = selectFamily(using: &rng)

        state.rngState = rng.state
        state.previousVariantTier = variant
        state.levelsSelected += 1
        rememberFamily(family)

        return Self.catalogIndex(familyIndex: family, variantIndex: variant)
    }

    private mutating func selectVariant(
        maximumUnlocked: Int,
        using rng: inout AquaDotCampaignRNG
    ) -> Int {
        let maximum = max(0, min(Self.variantsPerFamily - 1, maximumUnlocked))
        let drawRange = Self.cumulativeVariantEndpoints[maximum]

        while true {
            let draw = rng.int(upperBound: drawRange)
            let candidate = Self.variantTier(
                forCumulativeDraw: draw,
                maximumUnlocked: maximum
            )

            // Original rule: a lower-than-current-maximum tier cannot be chosen
            // twice consecutively. The highest currently unlocked tier may repeat.
            if let previous = state.previousVariantTier,
               candidate == previous,
               candidate < maximum {
                continue
            }
            return candidate
        }
    }

    private mutating func selectFamily(using rng: inout AquaDotCampaignRNG) -> Int {
        var duplicateRejections = 0
        while true {
            let candidate = rng.int(upperBound: Self.familyCount)
            if state.recentFamilies.contains(candidate),
               duplicateRejections < Self.duplicateFamilyRejectionLimit {
                duplicateRejections += 1
                continue
            }
            return candidate
        }
    }

    private mutating func rememberFamily(_ family: Int) {
        if state.recentFamilies.count < Self.recentFamilyCapacity {
            state.recentFamilies.append(family)
            state.recentFamilyCursor = state.recentFamilies.count % Self.recentFamilyCapacity
            return
        }

        let slot = state.recentFamilyCursor % Self.recentFamilyCapacity
        state.recentFamilies[slot] = family
        state.recentFamilyCursor = (slot + 1) % Self.recentFamilyCapacity
    }
}
