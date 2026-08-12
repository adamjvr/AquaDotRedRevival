import Testing
@testable import AquaDotRed_Revival

struct Phase2RemasterTests {
    private func testMaze(munchFirst: Bool, includeBugs: Bool = false) -> AquaDotMaze {
        var row: [AquaDotVertexToken] = [.playerStart, .playerStart]
        row += munchFirst ? [.munchDot, .dot] : [.dot, .munchDot]
        if includeBugs {
            row += [.enemyStart("E"), .enemyStart("F"), .enemyStart("G"), .enemyStart("H")]
        }
        let width = row.count - 1
        return AquaDotMaze(
            version: "1.0", storedChecksum: 1, calculatedChecksum: 1,
            width: width, height: 1,
            vertexRows: [row, Array(repeating: .empty, count: width + 1)],
            edgeRows: [Array(repeating: .empty, count: width)]
        )
    }

    @Test func munchDotIsOptionalAndUsesRecoveredScore() {
        let topology = AquaDotMazeTopology(maze: testMaze(munchFirst: true))
        let sim = AquaDotGameSimulation(topology: topology)
        sim.request(.right)
        for _ in 0..<120 { sim.step(deltaTime: 1.0 / 120.0) }

        #expect(sim.state.levelCompleted)
        #expect(sim.state.score == 260) // 250 Munch + 10 normal.
        #expect(!sim.state.isMunchActive) // Level completion terminates active temporary powers.
    }

    @Test func fourOriginalBugStartsReceiveDistinctBasicRoster() {
        let topology = AquaDotMazeTopology(maze: testMaze(munchFirst: false, includeBugs: true))
        let sim = AquaDotGameSimulation(topology: topology)
        #expect(Set(sim.state.bugs.map(\.personality)) == Set([.hunter, .blocker, .sneaker, .houndDog]))
    }

    @Test func pathfindingUsesRecoveredMazeGraph() {
        let topology = AquaDotMazeTopology(maze: testMaze(munchFirst: false, includeBugs: true))
        let pathfinding = AquaDotPathfinding(topology: topology)
        #expect(pathfinding.shortestDistance(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 7, y: 0)) == 7)
        #expect(pathfinding.shortestDirection(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 7, y: 0)) == .right)
    }
    @Test func goodieSystemSpawnsOnOriginalDotGraph() {
        let row: [AquaDotVertexToken] = [
            .playerStart, .dot, .dot, .dot, .dot, .dot, .dot, .dot, .dot, .dot, .dot
        ]
        let width = row.count - 1
        let maze = AquaDotMaze(
            version: "1.0", storedChecksum: 2, calculatedChecksum: 2,
            width: width, height: 1,
            vertexRows: [row, Array(repeating: .empty, count: width + 1)],
            edgeRows: [Array(repeating: .empty, count: width)]
        )
        let sim = AquaDotGameSimulation(topology: AquaDotMazeTopology(maze: maze), seed: 1234)
        for _ in 0..<750 { sim.step(deltaTime: 1.0 / 120.0) }
        #expect(sim.state.goodie != nil)
        #expect(sim.drainEvents().contains { event in
            if case .goodieSpawned = event { return true }
            return false
        })
    }

    @Test func recoveredGameLineAtlasFrameMapMatchesDisassembly() {
        let expected: [UInt8: Int] = [
            0x08: 0, 0x01: 1, 0x02: 2, 0x04: 3,
            0x09: 8, 0x03: 9, 0x06: 10, 0x0C: 11,
            0x0B: 24, 0x07: 25, 0x0E: 26, 0x0D: 27,
            0x05: 40, 0x0A: 41, 0x0F: 44,
        ]
        for (mask, frame) in expected {
            #expect(AquaDotWallGeometry(rawValue: mask).recoveredGameLineAtlasFrameIndex == frame)
        }
    }

    @Test func guideScoreAndPowerTablesAreLocked() {
        #expect(AquaDotDotKind.normal.scoreValue == 10)
        #expect(AquaDotDotKind.candy.scoreValue == 50)
        #expect(AquaDotDotKind.crusty.scoreValue == 30)
        #expect(AquaDotDotKind.petrified.scoreValue == 100)
        #expect(AquaDotGoodieKind.yummy.scoreValue == 250)
        #expect(AquaDotGoodieKind.yuk.scoreValue == 1000)
        #expect(AquaDotYummyPower.allCases.count == 6)
        #expect(AquaDotYukPower.allCases.count == 4)
    }

}
