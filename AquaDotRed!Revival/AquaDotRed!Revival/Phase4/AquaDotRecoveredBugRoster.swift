import Foundation

/// Phase 4G recovery of the ordinary enemy-colour roster and Neon presentation
/// wrapper from the shipped i386 executable.
///
/// Historical model recovered from `EnemyDraw.cc`:
/// - colours 0...7 select eight *real* strategy personalities,
/// - colour 8 is the special Night/Reaper path,
/// - colour 11 / Neon is not a ninth strategy: `setupEnemy` may substitute the
///   Neon sprite while preserving the original colour/personality internally.
///
/// The selector below restores the full-version ordinary roster (0...7), exact
/// colour/personality mapping, difficulty-gated availability tests, the recovered
/// four-enemy duplicate distribution, and per-enemy Neon disguise probability.
/// Phase 4 authenticity closure additionally restores colour 8: the full-version
/// 50/50 Hunter-vs-random Reaper split, Reaper-only graphics, and the no-Neon rule.
/// Absolute legacy velocity units and libc-rand bitstream identity remain explicit
/// translation boundaries.
enum AquaDotRecoveredEnemyColor: Int, CaseIterable, Sendable {
    case red = 0
    case blue = 1
    case yellow = 2
    case orange = 3
    case magenta = 4
    case cyan = 5
    case green = 6
    case indigo = 7
    case nightReaper = 8

    var personality: AquaDotBugPersonality? {
        switch self {
        case .red: return .hunter
        case .blue: return .blocker
        case .yellow: return .sneaker
        case .orange: return .houndDog
        case .magenta: return .protector
        case .cyan: return .mantis
        case .green: return .hermit
        case .indigo: return .loneWolf
        case .nightReaper: return nil
        }
    }
}

struct AquaDotRecoveredBugSpawn: Equatable, Sendable {
    let sourceColor: AquaDotRecoveredEnemyColor
    let personality: AquaDotBugPersonality
    let isNeonAppearance: Bool
    let reaperBehavior: AquaDotReaperBehavior?

    init(
        sourceColor: AquaDotRecoveredEnemyColor,
        personality: AquaDotBugPersonality,
        isNeonAppearance: Bool,
        reaperBehavior: AquaDotReaperBehavior? = nil
    ) {
        self.sourceColor = sourceColor
        self.personality = personality
        self.isNeonAppearance = isNeonAppearance
        self.reaperBehavior = reaperBehavior
    }
}

enum AquaDotRecoveredBugRoster {
    static let enemyCount = 4

    /// Normal gameplay `setupEnemy(..., forceNeon: false)` applies this chance
    /// independently to every non-Reaper enemy after its underlying colour has
    /// already selected the strategy. Exact binary shape:
    ///   D < 0.5 -> 0
    ///   otherwise min(D * 0.2, 0.2)
    static func neonAppearanceProbability(difficulty: Double) -> Double {
        guard difficulty >= 0.5 else { return 0 }
        return min(difficulty * 0.2, 0.2)
    }

    /// Probability with which the original full-version availability routine
    /// enables an ordinary colour for this level. Values above 1 are intentional:
    /// the original helper compares p against a normalized libc rand sample, so
    /// p >= 1 makes the colour unconditionally available.
    static func fullVersionAvailabilityProbability(
        color: AquaDotRecoveredEnemyColor,
        difficulty: Double
    ) -> Double {
        let d = max(0, difficulty)
        switch color {
        case .red, .blue, .yellow, .orange:
            return 1
        case .indigo:
            return d >= 0.1 ? d * 4.0 : 0
        case .green:
            return d >= 0.3 ? d * 1.5 : 0
        case .magenta:
            return d >= 0.5 ? d * 1.5 : 0
        case .cyan:
            return d >= 0.7 ? d : 0
        case .nightReaper:
            return d >= 0.7 ? d : 0
        }
    }

    /// The original clamps difficulty only for the duplicate-composition roll,
    /// then draws inclusively from 1...floor(8 + 10*d), capped at 16.
    static func compositionUpperBound(difficulty: Double) -> Int {
        let d = min(1.0, max(0, difficulty))
        return min(16, Int(floor(8.0 + 10.0 * d)))
    }

    /// Source-like multiplicity pattern before the original 10-swap shuffle.
    /// Values identify which distinct colour draw occupies each enemy slot.
    static func multiplicityPattern(compositionDraw: Int) -> [Int] {
        let draw = min(16, max(1, compositionDraw))
        switch draw {
        case 1...8: return [0, 1, 2, 3]
        case 9...11: return [0, 0, 1, 2]
        case 12...13: return [0, 0, 1, 1]
        case 14...15: return [0, 0, 0, 1]
        default: return [0, 0, 0, 0]
        }
    }

    /// Full-version ordinary selector. RNG *distribution* and draw order mirror
    /// the executable, while the Revival intentionally retains its deterministic
    /// RNG rather than claiming libc-rand bitstream identity.
    static func makeSpawnPlan(
        difficulty: Double,
        random: inout AquaDotSeededRandom
    ) -> [AquaDotRecoveredBugSpawn] {
        var available: Set<AquaDotRecoveredEnemyColor> = [
            .red, .blue, .yellow, .orange,
        ]

        // Exact full-version availability-test order in 0x2000a. Preserve the
        // random draw even when p >= 1 because the original helper still calls
        // rand(); this keeps the reconstructed deterministic stream closer in
        // structure even though it is not libc-rand bit-identical.
        for color in [
            AquaDotRecoveredEnemyColor.indigo,
            .green, .magenta, .cyan, .nightReaper,
        ] {
            let probability = fullVersionAvailabilityProbability(color: color, difficulty: difficulty)
            if probability > 0, random.double() <= probability {
                available.insert(color)
            }
        }


        let upper = compositionUpperBound(difficulty: difficulty)
        let compositionDraw = 1 + random.int(upperBound: upper)
        let pattern = multiplicityPattern(compositionDraw: compositionDraw)
        let distinctNeeded = (pattern.max() ?? 0) + 1

        var distinct: [AquaDotRecoveredEnemyColor] = []
        distinct.reserveCapacity(distinctNeeded)
        while distinct.count < distinctNeeded {
            // Original helper 0x20210 repeatedly draws a raw color index 0...8
            // until it lands on an enabled color. Use the same rejection shape.
            guard let candidate = AquaDotRecoveredEnemyColor(rawValue: random.int(upperBound: 9)) else {
                continue
            }
            guard available.contains(candidate), !distinct.contains(candidate) else { continue }
            distinct.append(candidate)
        }

        var colors = pattern.map { distinct[$0] }
        if compositionDraw >= 9 && compositionDraw <= 15 {
            recoveredTenSwapShuffle(&colors, random: &random)
        }

        let neonProbability = neonAppearanceProbability(difficulty: difficulty)
        return colors.map { color in
            if color == .nightReaper {
                // Full registered build `setupEnemy`: Reaper chooses strategy 0
                // (Hunter) with p=.5, otherwise strategy 12 (random). The Reaper
                // flag is set after strategy selection and Neon substitution is
                // bypassed entirely for source colour 8.
                let behavior: AquaDotReaperBehavior = random.double() < 0.5
                    ? .hunter
                    : .random
                return AquaDotRecoveredBugSpawn(
                    sourceColor: color,
                    personality: .hunter,
                    isNeonAppearance: false,
                    reaperBehavior: behavior
                )
            }

            let personality = color.personality ?? .hunter
            let neon = neonProbability > 0 && random.double() <= neonProbability
            return AquaDotRecoveredBugSpawn(
                sourceColor: color,
                personality: personality,
                isNeonAppearance: neon
            )
        }
    }

    /// Original helper 0x1ff08 performs exactly ten swaps. Each swap chooses two
    /// different indices from 0...3. This is not a Fisher-Yates shuffle.
    static func recoveredTenSwapShuffle<T>(
        _ values: inout [T],
        random: inout AquaDotSeededRandom
    ) {
        guard values.count == enemyCount else { return }
        for _ in 0..<10 {
            let first = random.int(upperBound: enemyCount)
            var second = random.int(upperBound: enemyCount)
            while second == first {
                second = random.int(upperBound: enemyCount)
            }
            values.swapAt(first, second)
        }
    }
}
