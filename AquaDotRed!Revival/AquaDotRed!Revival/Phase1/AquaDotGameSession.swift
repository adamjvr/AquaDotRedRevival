import Foundation

/// Run-level values that survive a normal level transition. Maze-local state
/// is rebuilt for each maze.
struct AquaDotRunCarry: Equatable, Sendable {
    var score: Int
    var bonus: Int
    var multiplier: Int
    var lives: Int

    static let fresh = AquaDotRunCarry(score: 0, bonus: 0, multiplier: 1, lives: 3)

    init(score: Int, bonus: Int, multiplier: Int, lives: Int) {
        self.score = max(0, score)
        self.bonus = max(0, bonus)
        self.multiplier = max(1, multiplier)
        self.lives = max(0, lives)
    }

    init(state: AquaDotGameState) {
        self.init(
            score: state.score,
            bonus: state.bonus,
            multiplier: state.multiplier,
            lives: state.lives
        )
    }
}

final class AquaDotGameSession {
    let levelRecord: AquaDotLevelRecord
    let maze: AquaDotMaze
    let topology: AquaDotMazeTopology
    let simulation: AquaDotGameSimulation
    var graphicsMode: AquaDotGraphicsMode
    let wallThemeIndex: Int

    var state: AquaDotGameState { simulation.state }

    init(
        levelRecord: AquaDotLevelRecord,
        maze: AquaDotMaze,
        graphicsMode: AquaDotGraphicsMode = .remastered,
        carry: AquaDotRunCarry = .fresh
    ) {
        self.levelRecord = levelRecord
        self.maze = maze
        self.topology = AquaDotMazeTopology(maze: maze)
        self.simulation = AquaDotGameSimulation(
            topology: topology,
            seed: UInt64(maze.storedChecksum) << 16 | UInt64(maze.width * 257 + maze.height),
            initialScore: carry.score,
            initialBonus: carry.bonus,
            initialMultiplier: carry.multiplier,
            initialLives: carry.lives
        )
        self.graphicsMode = graphicsMode

        // Recovered MazeLoad disassembly calls random(1, 13) before loading the
        // wall set. Preserve that behavior: each level load may pick another one
        // of the original thirteen material/color themes.
        self.wallThemeIndex = Int.random(in: 1...13)
    }

    static func loadOriginal(
        named name: String = "Ewe (1)",
        bundle: Bundle = .main,
        graphicsMode: AquaDotGraphicsMode = .remastered
    ) throws -> AquaDotGameSession {
        let loaded = try AquaDotLevelLoader(bundle: bundle).load(named: name)
        return AquaDotGameSession(
            levelRecord: loaded.record,
            maze: loaded.maze,
            graphicsMode: graphicsMode
        )
    }
}
