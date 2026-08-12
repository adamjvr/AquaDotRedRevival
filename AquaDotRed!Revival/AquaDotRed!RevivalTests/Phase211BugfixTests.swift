import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase211BugfixTests {
    private func contactMaze() -> AquaDotMaze {
        AquaDotMaze(
            version: "1.0",
            storedChecksum: 1,
            calculatedChecksum: 1,
            width: 2,
            height: 1,
            vertexRows: [
                [.playerStart, .enemyStart("E"), .dot],
                [.empty, .empty, .empty]
            ],
            edgeRows: [[.empty, .empty]]
        )
    }

    @Test func visuallyOverlappingBugDrainsEnergy() {
        let topology = AquaDotMazeTopology(maze: contactMaze())
        var tuning = AquaDotGameSimulation.Tuning()
        tuning.playerCellsPerSecond = 1.0
        tuning.bugCellsPerSecond = 0
        tuning.passiveEnergyRecoveryPerSecond = 0
        tuning.movingBugDamagePerSecond = 1.0
        tuning.stoppedBugDamagePerSecond = 1.0
        tuning.bugCollisionRadiusCells = 0.92

        let simulation = AquaDotGameSimulation(topology: topology, tuning: tuning, seed: 1)
        simulation.request(.right)
        for _ in 0..<10 { simulation.step(deltaTime: 0.02) }

        #expect(simulation.state.energy < 0.99)
        #expect(simulation.drainEvents().contains { event in
            if case .playerDamaged = event { return true }
            return false
        })
    }

    @Test func runCarryPreservesCampaignValues() {
        let carry = AquaDotRunCarry(score: 12345, bonus: 678, multiplier: 4, lives: 7)
        #expect(carry.score == 12345)
        #expect(carry.bonus == 678)
        #expect(carry.multiplier == 4)
        #expect(carry.lives == 7)
    }
}
