import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase3CampaignAuthenticityTests {
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

    private func completionMaze() -> AquaDotMaze {
        AquaDotMaze(
            version: "1.0",
            storedChecksum: 2,
            calculatedChecksum: 2,
            width: 2,
            height: 1,
            vertexRows: [
                [.playerStart, .playerStart, .dot],
                [.empty, .empty, .empty]
            ],
            edgeRows: [[.empty, .empty]]
        )
    }

    @Test func zeroLivesEndsTheRunInsteadOfRespawningForever() {
        let topology = AquaDotMazeTopology(maze: contactMaze())
        var tuning = AquaDotGameSimulation.Tuning()
        tuning.playerCellsPerSecond = 1
        tuning.bugCellsPerSecond = 0
        tuning.passiveEnergyRecoveryPerSecond = 0
        tuning.movingBugDamagePerSecond = 10
        tuning.stoppedBugDamagePerSecond = 10
        tuning.bugCollisionRadiusCells = 0.92

        let simulation = AquaDotGameSimulation(
            topology: topology,
            tuning: tuning,
            seed: 1,
            initialLives: 1
        )
        simulation.request(.right)
        for _ in 0..<100 where !simulation.state.gameOver {
            simulation.step(deltaTime: 0.02)
        }

        #expect(simulation.state.lives == 0)
        #expect(simulation.state.gameOver)
        #expect(simulation.drainEvents().contains { event in
            if case .gameOver = event { return true }
            return false
        })
    }

    @Test func endLevelUsesBonusPlusSkillTimesMultiplier() {
        let topology = AquaDotMazeTopology(maze: completionMaze())
        var tuning = AquaDotGameSimulation.Tuning()
        tuning.playerCellsPerSecond = 2
        tuning.bugCellsPerSecond = 0
        tuning.passiveEnergyRecoveryPerSecond = 0

        let simulation = AquaDotGameSimulation(
            topology: topology,
            tuning: tuning,
            seed: 2,
            initialScore: 5_000,
            initialBonus: 300,
            initialMultiplier: 3,
            initialLives: 3
        )
        for _ in 0..<200 where !simulation.state.levelCompleted {
            simulation.step(deltaTime: 0.02)
        }

        let result = simulation.lastLevelResult
        #expect(simulation.state.levelCompleted)
        #expect(result != nil)
        #expect(result?.scoreBefore == 5_010) // final required normal dot = 10 points
        #expect(result?.levelAward == ((result?.bonus ?? 0) + (result?.skill ?? 0)) * 3)
        #expect(result?.scoreAfter == simulation.state.score)
        #expect(simulation.state.levelsCleared == 1)
    }

    @Test func nextLevelCarryConsumesLevelLocalBonus() {
        var state = AquaDotGameState(
            player: AquaDotPlayerState(currentNode: GridPosition(x: 0, y: 0), nextNode: nil, segmentProgress: 0, movementDirection: nil, requestedDirection: nil),
            dots: [:], remainingMunchDots: [], goodie: nil, goodieSpawnCountdown: 0, multiplierGoodieSpawned: false,
            bugs: [], recentPlayerTrail: [], score: 12_345, bonus: 900, multiplier: 4, energy: 1, lives: 5,
            levelsCleared: 7, levelStats: AquaDotLevelStats(), availableYummyPower: nil, activeSpecialPower: nil,
            specialPowerAmount: 0, munchTimeRemaining: 0, bugsEatenThisMunch: 0, munchStartedWithFullEnergy: false,
            munchExtraLifeAwardedThisLevel: false, levelCompleted: true, gameOver: false, isPaused: false
        )
        state.bonus = 900
        let carry = AquaDotRunCarry.advancingAfterLevel(from: state)
        #expect(carry.score == 12_345)
        #expect(carry.bonus == 0)
        #expect(carry.multiplier == 4)
        #expect(carry.lives == 5)
        #expect(carry.levelsCleared == 7)
    }

    @Test func campaignCheckpointRoundTripsBeginningOfLevelValues() {
        let suite = "AquaDotPhase3Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AquaDotCampaignStore(defaults: defaults)
        let carry = AquaDotRunCarry(score: 9_876, bonus: 444, multiplier: 3, lives: 2, levelsCleared: 6)

        store.saveBeginningOfLevel(levelIndex: 51, carry: carry)
        let loaded = store.load()
        #expect(loaded?.levelIndex == 51)
        #expect(loaded?.score == 9_876)
        #expect(loaded?.multiplier == 3)
        #expect(loaded?.lives == 2)
        #expect(loaded?.levelsCleared == 6)
        #expect(loaded?.carry.bonus == 0)
    }

    @Test func highScoresPersistAndSort() {
        let suite = "AquaDotPhase3Scores.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AquaDotHighScoreStore(defaults: defaults)

        store.record(name: "A", score: 100, levelsCleared: 1)
        store.record(name: "B", score: 5_000, levelsCleared: 3)
        store.record(name: "C", score: 900, levelsCleared: 2)

        #expect(store.bestEver(limit: 3).map(\.score) == [5_000, 900, 100])
        #expect(store.todaysBest(limit: 5).count == 3)
    }
}
