import Foundation

/// Shared enemy-motion constants recovered from the shipped i386 `setEnemyV`
/// setup path. These are relative factors, not a claim that Revival's absolute
/// `bugCellsPerSecond` tuning is historically exact.
enum AquaDotRecoveredEnemyLocomotion {
    /// `setupEnemy` initializes ordinary enemies with legacy value 50000 and the
    /// Night/Reaper path with 10000. The ratio is exact even though the legacy
    /// unit has not been mapped one-for-one to SpriteKit cells/second.
    static let reaperBaseVelocityRatio = 10_000.0 / 50_000.0

    /// Reaper damage uses the original 0.15 status-transition time factor. In the
    /// fixed-step Revival this is translated as the inverse damage-rate multiplier
    /// so the Energy loss completes in 15% of an ordinary contact window.
    static let reaperDamageDurationScale = 0.15
    static let reaperDamageRateMultiplier = 1.0 / reaperDamageDurationScale

    /// Exact warpStyle multipliers written by `setEnemyV`:
    /// style 1 = 1.5, style 3 = 0.5, style 4 = 0.25.
    static func warpVelocityMultiplier(
        personality: AquaDotBugPersonality,
        isReaper: Bool
    ) -> Double {
        if isReaper { return 1.5 }
        switch personality {
        case .houndDog, .protector, .mantis, .hermit:
            return 0.25
        case .hunter, .blocker, .sneaker, .loneWolf, .neon:
            return 0.5
        }
    }

    /// Strategy 12 random Reaper chooser recovered from `chooseDirection`:
    /// draw one cardinal start index 0...3, then scan cyclically for at most four
    /// directions until finding a valid one that is not the opposite of travel.
    /// Declaration order of AquaDotDirection is up/right/down/left, preserving
    /// the original 0↔2 and 1↔3 opposite-direction pairing.
    static func randomReaperDirection(
        startIndex: Int,
        validDirections: Set<AquaDotDirection>,
        oppositeDirection: AquaDotDirection?
    ) -> AquaDotDirection? {
        let ordered = AquaDotDirection.allCases
        guard ordered.count == 4 else { return nil }
        let start = ((startIndex % 4) + 4) % 4
        for offset in 0..<4 {
            let direction = ordered[(start + offset) % 4]
            if validDirections.contains(direction), direction != oppositeDirection {
                return direction
            }
        }
        return nil
    }
}
