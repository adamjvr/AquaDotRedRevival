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

        let t = max(0.0, min(1.0, segmentProgress))
        return AquaDotRenderPosition(
            x: Double(currentNode.x) + Double(nextNode.x - currentNode.x) * t,
            y: Double(currentNode.y) + Double(nextNode.y - currentNode.y) * t
        )
    }
}

struct AquaDotGameState: Equatable, Sendable {
    var player: AquaDotPlayerState
    var remainingDots: Set<GridPosition>
    var remainingMunchDots: Set<GridPosition>
    var score: Int
    var levelCompleted: Bool
    var isPaused: Bool

    var remainingCollectibleCount: Int {
        remainingDots.count + remainingMunchDots.count
    }
}
