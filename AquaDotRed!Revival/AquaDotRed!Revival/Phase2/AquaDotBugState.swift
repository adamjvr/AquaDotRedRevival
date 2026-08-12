import Foundation

enum AquaDotBugPersonality: String, Codable, CaseIterable, Sendable {
    case hunter
    case blocker
    case sneaker
    case houndDog
}

enum AquaDotBugMode: String, Codable, Sendable {
    case hunting
    case frightened
    case returningHome
}

struct AquaDotBugState: Equatable, Sendable {
    let id: Character
    let personality: AquaDotBugPersonality
    let homeNode: GridPosition
    var currentNode: GridPosition
    var nextNode: GridPosition?
    var segmentProgress: Double
    var movementDirection: AquaDotDirection?
    var mode: AquaDotBugMode
    var recoveryDelay: Double

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
