import Foundation

/// Run-level values that survive a normal level transition. Maze-local state
/// is rebuilt for each maze.
struct AquaDotRunCarry: Equatable, Sendable {
    var score: Int
    var bonus: Int
    var multiplier: Int
    var lives: Int
    var levelsCleared: Int

    static let fresh = AquaDotRunCarry(score: 0, bonus: 0, multiplier: 1, lives: 3, levelsCleared: 0)

    init(score: Int, bonus: Int, multiplier: Int, lives: Int, levelsCleared: Int = 0) {
        self.score = max(0, score)
        self.bonus = max(0, bonus)
        self.multiplier = max(1, multiplier)
        self.lives = max(0, lives)
        self.levelsCleared = max(0, levelsCleared)
    }

    init(state: AquaDotGameState) {
        self.init(
            score: state.score,
            bonus: state.bonus,
            multiplier: state.multiplier,
            lives: state.lives,
            levelsCleared: state.levelsCleared
        )
    }

    /// Carry used after a successfully completed maze. The strategy guide is
    /// explicit that Bonus is consumed by the end-level calculation, so it is
    /// level-local and must not leak into the next maze.
    static func advancingAfterLevel(from state: AquaDotGameState) -> AquaDotRunCarry {
        AquaDotRunCarry(
            score: state.score,
            bonus: 0,
            multiplier: state.multiplier,
            lives: state.lives,
            levelsCleared: state.levelsCleared
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
            initialLives: carry.lives,
            initialLevelsCleared: carry.levelsCleared
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
