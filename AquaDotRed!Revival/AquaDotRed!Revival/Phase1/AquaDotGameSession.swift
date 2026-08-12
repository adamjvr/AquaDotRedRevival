import Foundation

/// Owns the active original level and its independent simulation state.
/// SpriteKit observes this object; it does not own the rules.
final class AquaDotGameSession {
    let levelRecord: AquaDotLevelRecord
    let maze: AquaDotMaze
    let topology: AquaDotMazeTopology
    let simulation: AquaDotGameSimulation
    var graphicsMode: AquaDotGraphicsMode

    var state: AquaDotGameState { simulation.state }

    init(
        levelRecord: AquaDotLevelRecord,
        maze: AquaDotMaze,
        graphicsMode: AquaDotGraphicsMode = .original
    ) {
        self.levelRecord = levelRecord
        self.maze = maze
        self.topology = AquaDotMazeTopology(maze: maze)
        self.simulation = AquaDotGameSimulation(topology: topology)
        self.graphicsMode = graphicsMode
    }

    static func loadOriginal(
        named name: String = "Ewe (1)",
        bundle: Bundle = .main,
        graphicsMode: AquaDotGraphicsMode = .original
    ) throws -> AquaDotGameSession {
        let loaded = try AquaDotLevelLoader(bundle: bundle).load(named: name)
        return AquaDotGameSession(
            levelRecord: loaded.record,
            maze: loaded.maze,
            graphicsMode: graphicsMode
        )
    }
}
