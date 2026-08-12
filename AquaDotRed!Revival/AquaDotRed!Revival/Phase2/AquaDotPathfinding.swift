import Foundation

struct AquaDotPathfinding: Sendable {
    let topology: AquaDotMazeTopology

    func shortestDistance(from start: GridPosition, to goal: GridPosition) -> Int? {
        guard start != goal else { return 0 }
        var distance: [GridPosition: Int] = [start: 0]
        var queue: [GridPosition] = [start]
        var cursor = 0

        while cursor < queue.count {
            let current = queue[cursor]
            cursor += 1
            let nextDistance = (distance[current] ?? 0) + 1
            for edge in topology.edges(from: current) where distance[edge.destination] == nil {
                if edge.destination == goal { return nextDistance }
                distance[edge.destination] = nextDistance
                queue.append(edge.destination)
            }
        }
        return nil
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
}
