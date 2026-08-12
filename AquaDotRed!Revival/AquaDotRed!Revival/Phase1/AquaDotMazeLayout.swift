import CoreGraphics

/// Converts original maze coordinates into SpriteKit coordinates.
/// Gameplay never stores pixels, so window scaling and remastered textures cannot
/// silently change collision/pathfinding behavior.
struct AquaDotMazeLayout {
    /// The recovered sprite sheets and original 800-pixel status panel strongly
    /// support a 20-pixel logical maze pitch for the classic presentation.
    static let classicPitch: CGFloat = 20

    let maze: AquaDotMaze
    let pitch: CGFloat
    let origin: CGPoint

    init(
        maze: AquaDotMaze,
        pitch: CGFloat = AquaDotMazeLayout.classicPitch,
        origin: CGPoint = CGPoint(x: 10, y: 650)
    ) {
        self.maze = maze
        self.pitch = pitch
        self.origin = origin
    }

    func point(for position: GridPosition) -> CGPoint {
        point(x: Double(position.x), y: Double(position.y))
    }

    func point(for renderPosition: AquaDotRenderPosition) -> CGPoint {
        point(x: renderPosition.x, y: renderPosition.y)
    }

    func wallCellCenter(x: Int, y: Int) -> CGPoint {
        point(x: Double(x) + 0.5, y: Double(y) + 0.5)
    }

    private func point(x: Double, y: Double) -> CGPoint {
        CGPoint(
            x: origin.x + CGFloat(x) * pitch,
            y: origin.y - CGFloat(y) * pitch
        )
    }
}
