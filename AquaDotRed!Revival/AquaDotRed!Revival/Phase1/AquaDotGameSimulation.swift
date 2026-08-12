import Foundation

/// Phase 1's platform-independent playable core.
///
/// Movement is graph based and fixed-step friendly. The original binary's exact
/// speed/scoring constants will be reconstructed in Phase 2; the provisional
/// values here are isolated so they cannot leak into the file format or renderer.
final class AquaDotGameSimulation {
    struct Tuning: Sendable {
        var cellsPerSecond: Double = 6.0
        var normalDotScore: Int = 10       // Phase 1 provisional.
        var munchDotScore: Int = 50        // Phase 1 provisional.
    }

    let topology: AquaDotMazeTopology
    let tuning: Tuning
    private(set) var state: AquaDotGameState

    init(topology: AquaDotMazeTopology, tuning: Tuning = Tuning()) {
        self.topology = topology
        self.tuning = tuning

        let starts = topology.playerStarts
        let first = starts.first ?? topology.traversable.first ?? GridPosition(x: 0, y: 0)

        var initialDirection: AquaDotDirection?
        var initialNext: GridPosition?

        // Shipped standard levels normally contain two adjacent S markers. Treat
        // them as the starting segment/orientation when possible rather than
        // discarding half of the original level information.
        if starts.count >= 2, let direction = AquaDotDirection(from: starts[0], to: starts[1]) {
            initialDirection = direction
            initialNext = starts[1]
        }

        state = AquaDotGameState(
            player: AquaDotPlayerState(
                currentNode: first,
                nextNode: initialNext,
                segmentProgress: 0,
                movementDirection: initialDirection,
                requestedDirection: initialDirection
            ),
            remainingDots: topology.dots,
            remainingMunchDots: topology.munchDots,
            score: 0,
            levelCompleted: false,
            isPaused: false
        )

        collect(at: first)
    }

    func request(_ direction: AquaDotDirection) {
        state.player.requestedDirection = direction
    }

    func togglePause() {
        state.isPaused.toggle()
    }

    func step(deltaTime: Double) {
        guard deltaTime > 0, !state.isPaused, !state.levelCompleted else { return }

        var distanceToTravel = tuning.cellsPerSecond * deltaTime
        var safety = 0

        while distanceToTravel > 0, safety < 32 {
            safety += 1

            if state.player.nextNode == nil {
                guard beginNextSegmentIfPossible() else { break }

                // Wrap transitions are instantaneous in Phase 1. `begin...` can
                // therefore consume no distance and leave nextNode nil; continue
                // so movement proceeds inward from the paired endpoint.
                if state.player.nextNode == nil { continue }
            }

            let remainingOnSegment = 1.0 - state.player.segmentProgress
            if distanceToTravel < remainingOnSegment {
                state.player.segmentProgress += distanceToTravel
                distanceToTravel = 0
            } else {
                distanceToTravel -= remainingOnSegment
                arriveAtNextNode()
            }
        }
    }

    private func beginNextSegmentIfPossible() -> Bool {
        let position = state.player.currentNode

        let preferred = state.player.requestedDirection
        let continuing = state.player.movementDirection

        let direction: AquaDotDirection?
        if let preferred, topology.canMove(from: position, direction: preferred) {
            direction = preferred
        } else if let continuing, topology.canMove(from: position, direction: continuing) {
            direction = continuing
        } else {
            direction = nil
        }

        guard let direction,
              let edge = topology.edge(from: position, direction: direction) else {
            state.player.nextNode = nil
            state.player.segmentProgress = 0
            return false
        }

        state.player.movementDirection = direction

        switch edge.kind {
        case .corridor:
            state.player.nextNode = edge.destination
            state.player.segmentProgress = 0

        case .wrap:
            // The original renderer hid the transition with dedicated wrap/hide
            // sprites. Phase 1 gets the authentic topology correct first and snaps
            // to the paired endpoint; its visual mask is rendered separately.
            state.player.currentNode = edge.destination
            state.player.nextNode = nil
            state.player.segmentProgress = 0
            collect(at: edge.destination)
        }

        return true
    }

    private func arriveAtNextNode() {
        guard let destination = state.player.nextNode else { return }
        state.player.currentNode = destination
        state.player.nextNode = nil
        state.player.segmentProgress = 0
        collect(at: destination)
    }

    private func collect(at position: GridPosition) {
        if state.remainingDots.remove(position) != nil {
            state.score += tuning.normalDotScore
        }
        if state.remainingMunchDots.remove(position) != nil {
            state.score += tuning.munchDotScore
        }

        state.levelCompleted = state.remainingDots.isEmpty && state.remainingMunchDots.isEmpty
    }
}
