import Foundation

struct AquaDotMaze: Equatable {
    let version: String
    let storedChecksum: UInt16
    let calculatedChecksum: UInt16
    let width: Int
    let height: Int
    let vertexRows: [[AquaDotVertexToken]]
    let edgeRows: [[AquaDotEdgeToken]]

    var checksumIsValid: Bool { storedChecksum == calculatedChecksum }

    var playerStarts: [GridPosition] {
        positions { token in
            if case .playerStart = token { return true }
            return false
        }
    }

    var enemyStarts: [(id: Character, position: GridPosition)] {
        var result: [(Character, GridPosition)] = []
        for (y, row) in vertexRows.enumerated() {
            for (x, token) in row.enumerated() {
                if case let .enemyStart(id) = token {
                    result.append((id, GridPosition(x: x, y: y)))
                }
            }
        }
        return result
    }

    var wraps: [(id: Character, position: GridPosition)] {
        var result: [(Character, GridPosition)] = []
        for (y, row) in vertexRows.enumerated() {
            for (x, token) in row.enumerated() {
                if case let .wrap(id) = token {
                    result.append((id, GridPosition(x: x, y: y)))
                }
            }
        }
        return result
    }

    private func positions(where predicate: (AquaDotVertexToken) -> Bool) -> [GridPosition] {
        var result: [GridPosition] = []
        for (y, row) in vertexRows.enumerated() {
            for (x, token) in row.enumerated() where predicate(token) {
                result.append(GridPosition(x: x, y: y))
            }
        }
        return result
    }
}

enum AquaDotVertexToken: Equatable {
    case empty
    case path
    case dot
    case munchDot
    case playerStart
    case enemyStart(Character)
    case wrap(Character)
    case unknown(String)

    init(rawToken: String) {
        switch rawToken {
        case ":": self = .empty
        case ".": self = .path
        case "•", "Î": self = .dot // Corelibs Foundation may decode MacRoman 0xA5 as Î; Apple platforms decode it as •.
        case "#": self = .munchDot
        case "S": self = .playerStart
        case "E", "F", "G", "H": self = .enemyStart(Character(rawToken))
        case "A", "B", "C", "D": self = .wrap(Character(rawToken))
        default: self = .unknown(rawToken)
        }
    }
}

enum AquaDotEdgeToken: Equatable {
    case empty
    case blocked
    case wrapBoundary
    case wall(Int)
    case unknown(String)

    init(rawToken: String) {
        switch rawToken {
        case "_": self = .empty
        case "X": self = .blocked
        case "^": self = .wrapBoundary
        default:
            if let value = Int(rawToken), (1...14).contains(value) {
                self = .wall(value)
            } else {
                self = .unknown(rawToken)
            }
        }
    }
}
