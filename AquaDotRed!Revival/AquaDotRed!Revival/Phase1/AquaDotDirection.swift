import Foundation

/// Cardinal directions used by the original AquaDot maze graph.
///
/// These are game-space directions, not screen-space vectors. Maze file rows are
/// stored top-to-bottom, so `.up` subtracts one from the file-space y coordinate.
enum AquaDotDirection: String, Codable, CaseIterable, Hashable, Sendable {
    case up
    case right
    case down
    case left

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }

    var opposite: AquaDotDirection {
        switch self {
        case .up: .down
        case .right: .left
        case .down: .up
        case .left: .right
        }
    }

    init?(from: GridPosition, to: GridPosition) {
        let dx = to.x - from.x
        let dy = to.y - from.y

        switch (dx, dy) {
        case (0, -1): self = .up
        case (1, 0): self = .right
        case (0, 1): self = .down
        case (-1, 0): self = .left
        default: return nil
        }
    }

    func offset(from position: GridPosition) -> GridPosition {
        GridPosition(x: position.x + dx, y: position.y + dy)
    }
}

extension AquaDotInputAction {
    var movementDirection: AquaDotDirection? {
        switch self {
        case .moveUp: .up
        case .moveRight: .right
        case .moveDown: .down
        case .moveLeft: .left
        case .pause, .confirm, .cancel: nil
        }
    }
}
