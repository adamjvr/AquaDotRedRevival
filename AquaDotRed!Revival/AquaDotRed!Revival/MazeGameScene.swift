import SpriteKit

final class MazeGameScene: SKScene {

    private let level = TestLevels.levelOne

    private let tileSize: CGFloat = 36.0

    private let mazeRoot = SKNode()

    override func didMove(to view: SKView) {

        removeAllChildren()

        addChild(mazeRoot)

        renderLevel()
        centerMazeRoot()
    }

    private func renderLevel() {

        renderBackgroundPanel()
        renderWalls()
        renderDots()
    }

    private func renderBackgroundPanel() {

        let mazePixelWidth = CGFloat(level.gridWidth) * tileSize
        let mazePixelHeight = CGFloat(level.gridHeight) * tileSize

        let panel = SKShapeNode(
            rect: CGRect(
                x: 0,
                y: 0,
                width: mazePixelWidth,
                height: mazePixelHeight
            ),
            cornerRadius: 24
        )

        panel.fillColor = SKColor(
            red: 0.03,
            green: 0.10,
            blue: 0.18,
            alpha: 0.85
        )

        panel.strokeColor = SKColor(
            red: 0.25,
            green: 0.75,
            blue: 1.0,
            alpha: 0.45
        )

        panel.lineWidth = 3
        panel.zPosition = -10

        mazeRoot.addChild(panel)
    }

    private func renderWalls() {

        for y in 0..<level.gridHeight {

            for x in 0..<level.gridWidth {

                guard level.tileAt(x: x, y: y) == .wall else {
                    continue
                }

                let wallNode = makeWallNode()
                wallNode.position = pointForTile(x: x, y: y)

                mazeRoot.addChild(wallNode)
            }
        }
    }

    private func renderDots() {

        for dot in level.dots {

            let dotNode = makeDotNode()
            dotNode.position = pointForTile(x: dot.x, y: dot.y)
            dotNode.zPosition = 5

            mazeRoot.addChild(dotNode)
        }
    }

    private func makeWallNode() -> SKShapeNode {

        let inset: CGFloat = 2.0

        let rect = CGRect(
            x: -tileSize / 2 + inset,
            y: -tileSize / 2 + inset,
            width: tileSize - inset * 2,
            height: tileSize - inset * 2
        )

        let node = SKShapeNode(rect: rect, cornerRadius: 8)

        node.fillColor = SKColor(
            red: 0.00,
            green: 0.42,
            blue: 0.85,
            alpha: 0.82
        )

        node.strokeColor = SKColor(
            red: 0.65,
            green: 0.92,
            blue: 1.0,
            alpha: 0.9
        )

        node.lineWidth = 1.5
        node.glowWidth = 2.0
        node.zPosition = 1

        return node
    }

    private func makeDotNode() -> SKShapeNode {

        let radius: CGFloat = 4.5

        let node = SKShapeNode(circleOfRadius: radius)

        node.fillColor = SKColor(
            red: 0.95,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
        )

        node.strokeColor = SKColor(
            red: 0.55,
            green: 0.95,
            blue: 1.0,
            alpha: 0.8
        )

        node.lineWidth = 1.0
        node.glowWidth = 3.0

        return node
    }

    private func pointForTile(x: Int, y: Int) -> CGPoint {

        let sceneX = CGFloat(x) * tileSize + tileSize / 2

        let flippedY = level.gridHeight - 1 - y

        let sceneY = CGFloat(flippedY) * tileSize + tileSize / 2

        return CGPoint(x: sceneX, y: sceneY)
    }

    private func centerMazeRoot() {

        let mazePixelWidth = CGFloat(level.gridWidth) * tileSize
        let mazePixelHeight = CGFloat(level.gridHeight) * tileSize

        mazeRoot.position = CGPoint(
            x: (size.width - mazePixelWidth) / 2,
            y: (size.height - mazePixelHeight) / 2
        )
    }
}
