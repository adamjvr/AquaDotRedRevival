import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase212WrapStabilizationTests {
    /// Minimal same-bottom wrap layout that reproduces the Phase 2.1.1 loop:
    /// AquaDot enters A moving down, appears at the paired bottom A, and the
    /// remembered/requested `down` direction still points outward through the
    /// destination portal.
    private func sameBottomWrapMaze() -> AquaDotMaze {
        AquaDotMaze(
            version: "1.0",
            storedChecksum: 1,
            calculatedChecksum: 1,
            width: 4,
            height: 2,
            vertexRows: [
                [.empty, .playerStart, .empty, .empty, .empty],
                [.empty, .playerStart, .dot, .path, .empty],
                [.empty, .wrap("A"), .empty, .wrap("A"), .empty],
            ],
            edgeRows: [
                [.empty, .empty, .empty, .empty],
                [.empty, .empty, .empty, .empty],
            ]
        )
    }

    @Test func sameSideWrapExitsInwardExactlyOnce() {
        let topology = AquaDotMazeTopology(maze: sameBottomWrapMaze())
        var tuning = AquaDotGameSimulation.Tuning()
        tuning.playerCellsPerSecond = 1.0
        tuning.bugCellsPerSecond = 0
        tuning.passiveEnergyRecoveryPerSecond = 0

        let simulation = AquaDotGameSimulation(topology: topology, tuning: tuning, seed: 1)
        var wrapEvents = 0

        // Do not issue a new direction after spawn. The initial S->S direction is
        // down, so this deliberately leaves the old outward request active.
        for _ in 0..<50 {
            simulation.step(deltaTime: 0.1)
            for event in simulation.drainEvents() {
                if case .wrapped = event { wrapEvents += 1 }
            }
        }

        #expect(wrapEvents == 1)
        #expect(simulation.state.player.currentNode == GridPosition(x: 3, y: 1))
        #expect(simulation.state.player.nextNode == nil)
        #expect(simulation.state.player.movementDirection == .up)
        #expect(simulation.state.player.requestedDirection == .down)
    }

    @Test func wrapEndpointsExposeDeterministicInwardDirection() {
        let topology = AquaDotMazeTopology(maze: sameBottomWrapMaze())
        let first = GridPosition(x: 1, y: 2)
        let second = GridPosition(x: 3, y: 2)

        #expect(topology.outwardDirection(at: first) == .down)
        #expect(topology.outwardDirection(at: second) == .down)
        #expect(topology.inwardDirection(at: first) == .up)
        #expect(topology.inwardDirection(at: second) == .up)
        #expect(topology.corridorEdge(from: second, direction: .up)?.destination == GridPosition(x: 3, y: 1))
    }
}
