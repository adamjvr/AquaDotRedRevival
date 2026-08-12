import Foundation

struct AquaDotRenderPosition: Equatable, Sendable {
    var x: Double
    var y: Double
}

struct AquaDotPlayerState: Equatable, Sendable {
    var currentNode: GridPosition
    var nextNode: GridPosition?
    var segmentProgress: Double
    var movementDirection: AquaDotDirection?
    var requestedDirection: AquaDotDirection?

    func renderPosition() -> AquaDotRenderPosition {
        guard let nextNode else {
            return AquaDotRenderPosition(x: Double(currentNode.x), y: Double(currentNode.y))
        }
        let t = max(0, min(1, segmentProgress))
        return AquaDotRenderPosition(
            x: Double(currentNode.x) + Double(nextNode.x - currentNode.x) * t,
            y: Double(currentNode.y) + Double(nextNode.y - currentNode.y) * t
        )
    }
}

struct AquaDotGameState: Equatable, Sendable {
    var player: AquaDotPlayerState

    /// Required-to-clear dots. Their values encode the dynamic original AquaDot
    /// states (Normal/Candy/Crusty/Petrified) described by the strategy guide.
    var dots: [GridPosition: AquaDotDotKind]
    var remainingMunchDots: Set<GridPosition>
    var goodie: AquaDotGoodieState?
    var goodieSpawnCountdown: Double
    var multiplierGoodieSpawned: Bool

    var bugs: [AquaDotBugState]
    var recentPlayerTrail: [GridPosition]

    var score: Int
    var bonus: Int
    var multiplier: Int
    var energy: Double
    var lives: Int

    var availableYummyPower: AquaDotYummyPower?
    var activeSpecialPower: AquaDotSpecialPower?
    var specialPowerAmount: Double

    var munchTimeRemaining: Double
    var bugsEatenThisMunch: Int
    var munchStartedWithFullEnergy: Bool
    var munchExtraLifeAwardedThisLevel: Bool

    var levelCompleted: Bool
    var isPaused: Bool

    var remainingDots: Set<GridPosition> { Set(dots.keys) }
    var remainingCollectibleCount: Int { dots.count + remainingMunchDots.count }
    var isMunchActive: Bool { munchTimeRemaining > 0 }
}
