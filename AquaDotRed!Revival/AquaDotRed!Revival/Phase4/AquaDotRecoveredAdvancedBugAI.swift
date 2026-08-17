import Foundation

/// Binary-backed constants and compact state used by the Phase 4F advanced bug
/// restoration. The state-machine transitions and numeric thresholds here come
/// from the shipped i386 executable. Where the original engine's navigation
/// representation does not map 1:1 onto the Revival graph, GameSimulation keeps
/// the adapter at the call site and documents that boundary explicitly.
enum AquaDotRecoveredAdvancedBugAI {
    static func normalizedDifficulty(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    // MARK: Protector (original personality 6)

    static func protectorLowActivity(difficulty: Double) -> Double {
        let d = normalizedDifficulty(difficulty)
        return min(0.60, 0.25 + 0.25 * d)
    }

    static func protectorHighActivity(difficulty: Double) -> Double {
        let d = normalizedDifficulty(difficulty)
        return min(1.40, 1.20 + 0.10 * d)
    }

    static let protectorFrontDistanceSquared = 100
    static let protectorBehindDistanceSquared = 25
    static let protectorNoticeProbability = 0.90
    static let protectorDecisionBudget = 5
    static let protectorTransitionSeconds = 2.0

    static func protectorEarlyReleaseProbability(decisionsRemaining: Int) -> Double {
        min(1.0, max(0.0, 0.30 - 0.03 * Double(decisionsRemaining)))
    }

    // MARK: Mantis (original personality 7)

    static let mantisLowActivity = 0.50
    static let mantisHighActivity = 1.00
    static let mantisFrontDistanceSquared = 225
    static let mantisBehindDistanceSquared = 49
    static let mantisNoticeProbability = 0.30
    static let mantisNoticeGateSeconds = 0.10
    static let mantisAttackTransitionSeconds = 2.0
    static let mantisReturnTransitionSeconds = 1.0
    static let mantisConfusionCounter = 5
    static let mantisStoppedSampleProbability = 0.05

    // The original increments a counter on stopped player-update samples. The
    // Revival simulation runs at a fixed 120 Hz while the historical update
    // cadence is not yet proven, so we deliberately normalize this adapter to
    // 60 samples/s rather than silently doubling the historical counter effect.
    static let mantisStoppedSampleSeconds = 1.0 / 60.0

    // MARK: Hermit (original personality 5)

    static let hermitLowActivity = 0.50

    static func hermitHighActivity(difficulty: Double) -> Double {
        let d = normalizedDifficulty(difficulty)
        return min(1.80, 1.10 + 0.50 * d)
    }

    static let hermitChaseDistance = 10
    static let hermitAttackTransitionSeconds = 0.50
    static let hermitReturnTransitionSeconds = 1.0

    static func hermitContinueProbability(turnCounter: Int) -> Double {
        guard turnCounter > 4 else { return 1.0 }
        return min(1.0, max(0.0, 1.0 - 0.10 * Double(turnCounter - 4)))
    }

    // MARK: Directional notice helpers

    static func squaredGridDistance(from observer: GridPosition, to target: GridPosition) -> Int {
        let dx = target.x - observer.x
        let dy = target.y - observer.y
        return dx * dx + dy * dy
    }

    static func targetIsBehind(
        observer: GridPosition,
        facing: AquaDotDirection?,
        target: GridPosition
    ) -> Bool {
        guard let facing else { return false }
        let dx = target.x - observer.x
        let dy = target.y - observer.y
        return dx * facing.dx + dy * facing.dy < 0
    }

    static func isInsideDirectionalNoticeRange(
        observer: GridPosition,
        facing: AquaDotDirection?,
        target: GridPosition,
        frontDistanceSquared: Int,
        behindDistanceSquared: Int
    ) -> Bool {
        let limit = targetIsBehind(observer: observer, facing: facing, target: target)
            ? behindDistanceSquared
            : frontDistanceSquared
        // The original branches are strict (<), not <=.
        return squaredGridDistance(from: observer, to: target) < limit
    }
}

/// Source-language adaptation of the original enemy activity transition helper
/// at 0x20d92. The executable stores wall-clock transition start/time and scales
/// a newly requested duration by the remaining fraction of the low/high span.
/// Fixed-step linear interpolation here preserves that observable behavior while
/// remaining deterministic inside the Revival simulation.
struct AquaDotRecoveredActivityRamp: Equatable, Sendable {
    let low: Double
    let high: Double

    private(set) var current: Double
    private(set) var target: Double
    private(set) var remainingDuration: Double

    private var start: Double
    private var totalDuration: Double
    private var elapsed: Double

    init(low: Double, high: Double, initial: Double = 1.0) {
        self.low = min(10.0, max(0.0, low))
        self.high = min(10.0, max(0.0, high))
        current = min(10.0, max(0.0, initial))
        target = current
        remainingDuration = 0
        start = current
        totalDuration = 0
        elapsed = 0

        // InitializeEnemyAI immediately requests the low state over one second.
        transition(to: self.low, fullDuration: 1.0)
    }

    mutating func transition(to requestedTarget: Double, fullDuration: Double) {
        let destination = min(10.0, max(0.0, requestedTarget))
        let full = max(0.0, fullDuration)
        let span = abs(high - low)
        let fraction = span > 0.000_000_1
            ? min(1.0, abs(destination - current) / span)
            : 0.0
        let scaledDuration = full * fraction

        start = current
        target = destination
        totalDuration = scaledDuration
        remainingDuration = scaledDuration
        elapsed = 0

        if scaledDuration <= 0.000_000_1 {
            current = destination
            remainingDuration = 0
        }
    }

    mutating func transitionLow(fullDuration: Double) {
        transition(to: low, fullDuration: fullDuration)
    }

    mutating func transitionHigh(fullDuration: Double) {
        transition(to: high, fullDuration: fullDuration)
    }

    mutating func step(deltaTime: Double) {
        guard deltaTime > 0, totalDuration > 0, remainingDuration > 0 else { return }
        elapsed = min(totalDuration, elapsed + deltaTime)
        let t = elapsed / totalDuration
        current = start + (target - start) * t
        remainingDuration = max(0, totalDuration - elapsed)
        if remainingDuration == 0 {
            current = target
        }
    }
}

enum AquaDotRecoveredProtectorMode: Equatable, Sendable {
    case selectingPatrol
    case travellingToPatrol
    case patrolling
    case angry
}

enum AquaDotRecoveredMantisMode: Equatable, Sendable {
    case wandering
    case attacking
    case confused
}

/// Per-enemy Phase 4F state. This intentionally lives beside the Revival bug
/// state instead of repurposing Phase 3B's provisional alert timers. That keeps
/// the recovered machine explicit and makes remaining reconstruction bridges easy
/// to identify in code review.
struct AquaDotRecoveredAdvancedBugRuntime: Equatable, Sendable {
    let personality: AquaDotBugPersonality
    var activity: AquaDotRecoveredActivityRamp

    var protectorMode: AquaDotRecoveredProtectorMode = .selectingPatrol
    var protectorTarget: GridPosition?
    var protectorDecisionsRemaining = 0

    var mantisMode: AquaDotRecoveredMantisMode = .wandering
    var mantisNoticeElapsed = 0.0
    var mantisStoppedAccumulator = 0.0
    var mantisInterruptedMovementSamples = 0
    var mantisConfusionCounter = 0

    var hermitChasing = false
    var hermitTurnCounter = 0
    var hermitWanderDecisionCount = 0

    init?(personality: AquaDotBugPersonality, difficulty: Double) {
        self.personality = personality
        switch personality {
        case .protector:
            activity = AquaDotRecoveredActivityRamp(
                low: AquaDotRecoveredAdvancedBugAI.protectorLowActivity(difficulty: difficulty),
                high: AquaDotRecoveredAdvancedBugAI.protectorHighActivity(difficulty: difficulty)
            )
        case .mantis:
            activity = AquaDotRecoveredActivityRamp(
                low: AquaDotRecoveredAdvancedBugAI.mantisLowActivity,
                high: AquaDotRecoveredAdvancedBugAI.mantisHighActivity
            )
        case .hermit:
            activity = AquaDotRecoveredActivityRamp(
                low: AquaDotRecoveredAdvancedBugAI.hermitLowActivity,
                high: AquaDotRecoveredAdvancedBugAI.hermitHighActivity(difficulty: difficulty)
            )
        case .hunter, .blocker, .sneaker, .houndDog, .loneWolf, .neon:
            return nil
        }
    }
}
