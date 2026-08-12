import Foundation

/// Semantic navigation graph derived from an original AquaDot maze.
///
/// The file format is intentionally kept separate from gameplay. Raw tokens remain
/// in `AquaDotMaze`; this type answers questions the simulation actually needs:
/// which vertices are traversable, where a direction leads, which endpoints are
/// wraps, and where the collectible/start markers live.
struct AquaDotMazeTopology: Sendable {
    enum EdgeKind: Hashable, Sendable {
        case corridor
        case wrap(Character)
    }

    struct Edge: Hashable, Sendable {
        let destination: GridPosition
        let direction: AquaDotDirection
        let kind: EdgeKind
    }

    struct EnemyStart: Hashable, Sendable {
        let id: Character
        let position: GridPosition
    }

    struct WrapPair: Hashable, Sendable {
        let id: Character
        let first: GridPosition
        let second: GridPosition
    }

    let width: Int
    let height: Int
    let traversable: Set<GridPosition>
    let adjacency: [GridPosition: [Edge]]
    let wallCells: [AquaDotWallCell]
    let dots: Set<GridPosition>
    let munchDots: Set<GridPosition>
    let playerStarts: [GridPosition]
    let enemyStarts: [EnemyStart]
    let wrapPairs: [WrapPair]

    init(maze: AquaDotMaze) {
        width = maze.width
        height = maze.height

        var pathVertices = Set<GridPosition>()
        var normalDots = Set<GridPosition>()
        var staticMunchDots = Set<GridPosition>()
        var starts: [GridPosition] = []
        var enemies: [EnemyStart] = []
        var wrapPositions: [Character: [GridPosition]] = [:]

        for (y, row) in maze.vertexRows.enumerated() {
            for (x, token) in row.enumerated() {
                let position = GridPosition(x: x, y: y)

                switch token {
                case .empty, .unknown:
                    continue

                case .path:
                    pathVertices.insert(position)

                case .dot:
                    pathVertices.insert(position)
                    normalDots.insert(position)

                case .munchDot:
                    pathVertices.insert(position)
                    staticMunchDots.insert(position)

                case .playerStart:
                    pathVertices.insert(position)
                    starts.append(position)

                case let .enemyStart(id):
                    pathVertices.insert(position)
                    enemies.append(EnemyStart(id: id, position: position))

                case let .wrap(id):
                    pathVertices.insert(position)
                    wrapPositions[id, default: []].append(position)
                }
            }
        }

        traversable = pathVertices
        dots = normalDots
        munchDots = staticMunchDots
        playerStarts = starts
        enemyStarts = enemies.sorted { String($0.id) < String($1.id) }

        var graph: [GridPosition: [Edge]] = [:]
        for position in pathVertices {
            graph[position] = []
        }

        // The shipped corpus proves that adjacent non-empty vertex tokens form the
        // corridor graph. Adding the A-D wrap pairs makes every one of the 205
        // standard mazes connected.
        for position in pathVertices {
            for direction in AquaDotDirection.allCases {
                let candidate = direction.offset(from: position)
                guard pathVertices.contains(candidate) else { continue }
                graph[position, default: []].append(
                    Edge(destination: candidate, direction: direction, kind: .corridor)
                )
            }
        }

        var pairs: [WrapPair] = []
        for id in wrapPositions.keys.sorted(by: { String($0) < String($1) }) {
            guard let endpoints = wrapPositions[id], endpoints.count == 2 else { continue }
            let first = endpoints[0]
            let second = endpoints[1]
            pairs.append(WrapPair(id: id, first: first, second: second))

            if let firstDirection = Self.outwardDirection(for: first, width: maze.width, height: maze.height) {
                graph[first, default: []].append(
                    Edge(destination: second, direction: firstDirection, kind: .wrap(id))
                )
            }
            if let secondDirection = Self.outwardDirection(for: second, width: maze.width, height: maze.height) {
                graph[second, default: []].append(
                    Edge(destination: first, direction: secondDirection, kind: .wrap(id))
                )
            }
        }
        wrapPairs = pairs

        // Stable order makes debugging/tests deterministic.
        adjacency = graph.mapValues { edges in
            edges.sorted {
                if $0.direction.rawValue != $1.direction.rawValue {
                    return $0.direction.rawValue < $1.direction.rawValue
                }
                return String(describing: $0.kind) < String(describing: $1.kind)
            }
        }

        var cells: [AquaDotWallCell] = []
        for (y, row) in maze.edgeRows.enumerated() {
            for (x, token) in row.enumerated() {
                cells.append(AquaDotWallCell(x: x, y: y, token: token))
            }
        }
        wallCells = cells
    }

    func edges(from position: GridPosition) -> [Edge] {
        adjacency[position] ?? []
    }

    func edge(from position: GridPosition, direction: AquaDotDirection) -> Edge? {
        // Corridor has priority over wrap. This matters after a wrap transition:
        // continuing in the same direction should move inward from the far edge,
        // not immediately teleport back.
        let candidates = edges(from: position).filter { $0.direction == direction }
        return candidates.first(where: { $0.kind == .corridor }) ?? candidates.first
    }

    func neighbor(from position: GridPosition, direction: AquaDotDirection) -> GridPosition? {
        edge(from: position, direction: direction)?.destination
    }

    func canMove(from position: GridPosition, direction: AquaDotDirection) -> Bool {
        edge(from: position, direction: direction) != nil
    }

    /// Returns true if the whole traversable graph is reachable from one vertex.
    /// Primarily a preservation/debug assertion; the shipped standard corpus is
    /// connected once wrap edges are included.
    var isConnected: Bool {
        guard let start = traversable.first else { return true }
        var visited: Set<GridPosition> = [start]
        var queue: [GridPosition] = [start]
        var index = 0

        while index < queue.count {
            let current = queue[index]
            index += 1
            for edge in edges(from: current) where !visited.contains(edge.destination) {
                visited.insert(edge.destination)
                queue.append(edge.destination)
            }
        }
        return visited == traversable
    }

    private static func outwardDirection(
        for position: GridPosition,
        width: Int,
        height: Int
    ) -> AquaDotDirection? {
        if position.x == 0 { return .left }
        if position.x == width { return .right }
        if position.y == 0 { return .up }
        if position.y == height { return .down }
        return nil
    }
}
