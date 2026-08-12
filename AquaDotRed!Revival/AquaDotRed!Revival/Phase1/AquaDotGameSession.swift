import Foundation

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
        graphicsMode: AquaDotGraphicsMode = .remastered
    ) {
        self.levelRecord = levelRecord
        self.maze = maze
        self.topology = AquaDotMazeTopology(maze: maze)
        self.simulation = AquaDotGameSimulation(
            topology: topology,
            seed: UInt64(maze.storedChecksum) << 16 | UInt64(maze.width * 257 + maze.height)
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
