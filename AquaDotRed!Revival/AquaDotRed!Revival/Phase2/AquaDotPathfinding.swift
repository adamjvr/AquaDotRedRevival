import Foundation

/// Cached shortest-path table over the recovered maze graph.
///
/// Phase 2 ran a fresh BFS for nearly every bug decision and scent-distance
/// query. The original binary contains `setupDistanceMatrix` and predecessor-
/// matrix helpers, so caching graph distances is both faster and architecturally
/// closer to the shipped game. Tables are created lazily per start node and then
/// reused for the rest of the level.
final class AquaDotPathfinding: @unchecked Sendable {
    let topology: AquaDotMazeTopology
    private var distanceCache: [GridPosition: [GridPosition: Int]] = [:]

    init(topology: AquaDotMazeTopology) {
        self.topology = topology
    }

    var cachedSourceCount: Int { distanceCache.count }

    func shortestDistance(from start: GridPosition, to goal: GridPosition) -> Int? {
        if start == goal { return 0 }
        return distances(from: start)[goal]
    }

    func shortestDirection(
        from start: GridPosition,
        to goal: GridPosition,
        avoiding reverse: AquaDotDirection? = nil
    ) -> AquaDotDirection? {
        guard start != goal else { return nil }
        let candidates = topology.edges(from: start).filter { edge in
            guard let reverse else { return true }
            return edge.direction != reverse
        }
        let usable = candidates.isEmpty ? topology.edges(from: start) : candidates
        return usable.min { lhs, rhs in
            let ld = shortestDistance(from: lhs.destination, to: goal) ?? Int.max
            let rd = shortestDistance(from: rhs.destination, to: goal) ?? Int.max
            if ld != rd { return ld < rd }
            return lhs.direction.rawValue < rhs.direction.rawValue
        }?.direction
    }

    func directionAway(
        from start: GridPosition,
        threat: GridPosition,
        avoiding reverse: AquaDotDirection? = nil
    ) -> AquaDotDirection? {
        let candidates = topology.edges(from: start).filter { edge in
            guard let reverse else { return true }
            return edge.direction != reverse
        }
        let usable = candidates.isEmpty ? topology.edges(from: start) : candidates
        return usable.max { lhs, rhs in
            let ld = shortestDistance(from: lhs.destination, to: threat) ?? Int.max / 2
            let rd = shortestDistance(from: rhs.destination, to: threat) ?? Int.max / 2
            if ld != rd { return ld < rd }
            return lhs.direction.rawValue > rhs.direction.rawValue
        }?.direction
    }

    func projectedNode(from start: GridPosition, direction: AquaDotDirection?, steps: Int) -> GridPosition {
        guard let direction else { return start }
        var node = start
        for _ in 0..<max(0, steps) {
            guard let edge = topology.edge(from: node, direction: direction) else { break }
            node = edge.destination
        }
        return node
    }

    private func distances(from start: GridPosition) -> [GridPosition: Int] {
        if let cached = distanceCache[start] { return cached }

        var distance: [GridPosition: Int] = [start: 0]
        var queue: [GridPosition] = [start]
        var cursor = 0

        while cursor < queue.count {
            let current = queue[cursor]
            cursor += 1
            let nextDistance = (distance[current] ?? 0) + 1
            for edge in topology.edges(from: current) where distance[edge.destination] == nil {
                distance[edge.destination] = nextDistance
                queue.append(edge.destination)
            }
        }

        distanceCache[start] = distance
        return distance
    }
}
