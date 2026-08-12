import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase21StabilizationTests {
    private func corridorMaze() -> AquaDotMaze {
        let row: [AquaDotVertexToken] = [.playerStart, .dot, .dot, .dot, .dot, .dot]
        return AquaDotMaze(
            version: "1.0",
            storedChecksum: 1,
            calculatedChecksum: 1,
            width: 5,
            height: 1,
            vertexRows: [row, Array(repeating: .empty, count: 6)],
            edgeRows: [Array(repeating: .empty, count: 5)]
        )
    }

    @Test func shortestPathTablesAreCachedPerSourceNode() {
        let topology = AquaDotMazeTopology(maze: corridorMaze())
        let pathfinding = AquaDotPathfinding(topology: topology)
        let start = GridPosition(x: 0, y: 0)
        let goal = GridPosition(x: 5, y: 0)

        #expect(pathfinding.cachedSourceCount == 0)
        #expect(pathfinding.shortestDistance(from: start, to: goal) == 5)
        #expect(pathfinding.cachedSourceCount == 1)
        #expect(pathfinding.shortestDistance(from: start, to: GridPosition(x: 3, y: 0)) == 3)
        #expect(pathfinding.cachedSourceCount == 1)
    }

    @Test func recoveredOriginalWallPaletteNamesRemainStable() {
        #expect(AquaDotWallPalette.allCases.map(\.displayName) == [
            "Bright Pastels", "Vivid", "Medium Tones", "Dark Tones"
        ])
    }

    @Test func preferencesPersistRecoveredOptions() {
        let suite = "AquaDotPhase21Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let first = AquaDotPreferences(defaults: defaults)
        first.muteAll = true
        first.wallPalette = .darkTones
        first.allowPretapping = false
        first.soundEffectsVolume = 0.45

        let second = AquaDotPreferences(defaults: defaults)
        #expect(second.muteAll)
        #expect(second.wallPalette == .darkTones)
        #expect(!second.allowPretapping)
        #expect(abs(second.soundEffectsVolume - 0.45) < 0.001)
    }
}
