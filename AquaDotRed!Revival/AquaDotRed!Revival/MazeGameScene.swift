import SpriteKit

final class MazeGameScene: SKScene {

    private let level = TestLevels.levelOne

    private let tileSize: CGFloat = 34.0

    private let mazeRoot = SKNode()
    private let uiRoot = SKNode()

    override func didMove(to view: SKView) {

        removeAllChildren()

        addChild(mazeRoot)
        addChild(uiRoot)

        renderBackground()
        renderLevel()

        layoutMazeRoot()

        renderRightExtraPanel()
        renderBottomHUD()
    }

    private func renderBackground() {

        let background = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: size.width, height: size.height),
            cornerRadius: 0
        )

        background.fillColor = SKColor(
            red: 0.0,
            green: 0.0,
            blue: 0.0,
            alpha: 1.0
        )

        background.strokeColor = .clear
        background.zPosition = -100

        addChild(background)
    }

    private func renderLevel() {

        renderPlayfieldBackground()
        renderWalls()
        renderDots()
    }

    private func renderPlayfieldBackground() {

        let mazePixelWidth = CGFloat(level.gridWidth) * tileSize
        let mazePixelHeight = CGFloat(level.gridHeight) * tileSize

        let panel = SKShapeNode(
            rect: CGRect(
                x: 0,
                y: 0,
                width: mazePixelWidth,
                height: mazePixelHeight
            ),
            cornerRadius: 18
        )

        panel.fillColor = SKColor(
            red: 0.0,
            green: 0.0,
            blue: 0.0,
            alpha: 1.0
        )

        panel.strokeColor = SKColor(
            red: 1.0,
            green: 0.02,
            blue: 0.36,
            alpha: 0.9
        )

        panel.lineWidth = 2.0
        panel.glowWidth = 4.0
        panel.zPosition = -20

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

        // A few larger bonus/power dots to match the original mockup feel.
        let powerDotPositions = [
            GridPosition(x: 2, y: 2),
            GridPosition(x: level.gridWidth - 3, y: 2),
            GridPosition(x: 2, y: level.gridHeight - 3),
            GridPosition(x: level.gridWidth - 3, y: level.gridHeight - 3)
        ]

        for powerDot in powerDotPositions {
            let node = makePowerDotNode()
            node.position = pointForTile(x: powerDot.x, y: powerDot.y)
            node.zPosition = 6
            mazeRoot.addChild(node)
        }
    }

    private func makeWallNode() -> SKShapeNode {

        let inset: CGFloat = 2.6

        let rect = CGRect(
            x: -tileSize / 2 + inset,
            y: -tileSize / 2 + inset,
            width: tileSize - inset * 2,
            height: tileSize - inset * 2
        )

        let node = SKShapeNode(rect: rect, cornerRadius: 9)

        node.fillColor = SKColor(
            red: 1.0,
            green: 0.02,
            blue: 0.36,
            alpha: 0.97
        )

        node.strokeColor = SKColor(
            red: 1.0,
            green: 0.50,
            blue: 0.78,
            alpha: 1.0
        )

        node.lineWidth = 1.7
        node.glowWidth = 3.0
        node.zPosition = 1

        let highlight = SKShapeNode(
            rect: CGRect(
                x: rect.minX + 6,
                y: rect.maxY - 9,
                width: max(2, rect.width - 12),
                height: 3.5
            ),
            cornerRadius: 2
        )

        highlight.fillColor = SKColor(
            red: 1.0,
            green: 0.82,
            blue: 0.95,
            alpha: 0.42
        )

        highlight.strokeColor = .clear
        highlight.zPosition = 2
        node.addChild(highlight)

        return node
    }

    private func makeDotNode() -> SKShapeNode {

        let node = SKShapeNode(circleOfRadius: 2.8)

        node.fillColor = SKColor(
            red: 0.96,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
        )

        node.strokeColor = SKColor(
            red: 0.85,
            green: 1.0,
            blue: 1.0,
            alpha: 0.9
        )

        node.lineWidth = 0.8
        node.glowWidth = 1.6

        return node
    }

    private func makePowerDotNode() -> SKNode {

        let root = SKNode()

        let outer = SKShapeNode(circleOfRadius: 12)
        outer.fillColor = SKColor(red: 1.0, green: 0.02, blue: 0.36, alpha: 0.95)
        outer.strokeColor = SKColor(red: 1.0, green: 0.72, blue: 0.90, alpha: 1.0)
        outer.lineWidth = 2.0
        outer.glowWidth = 5.0

        let inner = SKShapeNode(circleOfRadius: 4.5)
        inner.fillColor = SKColor(red: 1.0, green: 0.65, blue: 0.88, alpha: 0.7)
        inner.strokeColor = .clear
        inner.position = CGPoint(x: -3.0, y: 4.0)

        root.addChild(outer)
        root.addChild(inner)

        return root
    }

    private func renderRightExtraPanel() {

        let panelX: CGFloat = 1240
        let panelY: CGFloat = 185
        let panelWidth: CGFloat = 110
        let panelHeight: CGFloat = 610

        let panel = makeNeonPanel(
            rect: CGRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight),
            stroke: SKColor(red: 1.0, green: 0.02, blue: 0.36, alpha: 1.0),
            glow: 5.0
        )

        uiRoot.addChild(panel)

        let divider1 = makeHorizontalLine(x: panelX, y: panelY + panelHeight - 170, width: panelWidth)
        let divider2 = makeHorizontalLine(x: panelX, y: panelY + panelHeight - 380, width: panelWidth)

        uiRoot.addChild(divider1)
        uiRoot.addChild(divider2)

        let letters = ["e", "x", "t", "r", "a"]

        for (index, letter) in letters.enumerated() {
            let label = makeLabel(
                text: letter,
                fontSize: 38,
                color: SKColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 1.0),
                alignment: .center
            )

            label.position = CGPoint(
                x: panelX + panelWidth / 2,
                y: panelY + panelHeight - 60 - CGFloat(index) * 34
            )

            uiRoot.addChild(label)
        }

        for index in 0..<4 {

            let life = makeLifeIcon()

            life.position = CGPoint(
                x: panelX + panelWidth / 2,
                y: panelY + panelHeight - 225 - CGFloat(index) * 58
            )

            uiRoot.addChild(life)
        }
    }

    private func renderBottomHUD() {

        let leftX: CGFloat = 40
        let topY: CGFloat = 105
        let rowHeight: CGFloat = 70
        let labelWidth: CGFloat = 220
        let meterWidth: CGFloat = 760

        renderMeterRow(
            title: "energy",
            titleColor: SKColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 1.0),
            strokeColor: SKColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 0.95),
            waveColor: SKColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 1.0),
            x: leftX,
            y: topY,
            labelWidth: labelWidth,
            meterWidth: meterWidth,
            height: rowHeight
        )

        renderMeterRow(
            title: "energetic",
            titleColor: SKColor(red: 1.0, green: 0.08, blue: 0.18, alpha: 1.0),
            strokeColor: SKColor(red: 1.0, green: 0.02, blue: 0.36, alpha: 0.95),
            waveColor: SKColor(red: 1.0, green: 0.0, blue: 0.05, alpha: 1.0),
            x: leftX,
            y: 30,
            labelWidth: labelWidth,
            meterWidth: meterWidth,
            height: rowHeight
        )

        renderScorePanel(
            title: "score",
            value: "178 702",
            x: 1030,
            y: topY,
            width: 330,
            height: rowHeight
        )

        renderScorePanel(
            title: "bonus",
            value: "5x 1 447",
            x: 1030,
            y: 30,
            width: 330,
            height: rowHeight
        )
    }

    private func renderMeterRow(
        title: String,
        titleColor: SKColor,
        strokeColor: SKColor,
        waveColor: SKColor,
        x: CGFloat,
        y: CGFloat,
        labelWidth: CGFloat,
        meterWidth: CGFloat,
        height: CGFloat
    ) {

        let labelPanel = makeNeonPanel(
            rect: CGRect(x: x, y: y, width: labelWidth, height: height),
            stroke: strokeColor,
            glow: 4.0
        )

        uiRoot.addChild(labelPanel)

        let titleLabel = makeLabel(
            text: title,
            fontSize: 30,
            color: titleColor,
            alignment: .center
        )

        titleLabel.position = CGPoint(x: x + labelWidth / 2, y: y + 22)
        uiRoot.addChild(titleLabel)

        let meterPanel = makeNeonPanel(
            rect: CGRect(x: x + labelWidth, y: y, width: meterWidth, height: height),
            stroke: strokeColor,
            glow: 4.0
        )

        uiRoot.addChild(meterPanel)

        let wave = makeWaveNode(
            x: x + labelWidth + 18,
            y: y + height / 2,
            width: meterWidth - 36,
            amplitude: 12,
            wavelength: 86,
            color: waveColor
        )

        uiRoot.addChild(wave)
    }

    private func renderScorePanel(
        title: String,
        value: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) {

        let panel = makeNeonPanel(
            rect: CGRect(x: x, y: y, width: width, height: height),
            stroke: SKColor(red: 0.1, green: 1.0, blue: 1.0, alpha: 0.95),
            glow: 4.0
        )

        uiRoot.addChild(panel)

        let titleLabel = makeLabel(
            text: title,
            fontSize: 28,
            color: SKColor(red: 0.25, green: 1.0, blue: 0.25, alpha: 1.0),
            alignment: .left
        )

        titleLabel.position = CGPoint(x: x + 26, y: y + 22)
        uiRoot.addChild(titleLabel)

        let valueLabel = makeLabel(
            text: value,
            fontSize: 28,
            color: SKColor(red: 0.25, green: 1.0, blue: 0.25, alpha: 1.0),
            alignment: .right
        )

        valueLabel.position = CGPoint(x: x + width - 28, y: y + 22)
        uiRoot.addChild(valueLabel)
    }

    private func makeNeonPanel(rect: CGRect, stroke: SKColor, glow: CGFloat) -> SKShapeNode {

        let panel = SKShapeNode(rect: rect, cornerRadius: 18)

        panel.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.82)
        panel.strokeColor = stroke
        panel.lineWidth = 2.0
        panel.glowWidth = glow
        panel.zPosition = 30

        return panel
    }

    private func makeHorizontalLine(x: CGFloat, y: CGFloat, width: CGFloat) -> SKShapeNode {

        let path = CGMutablePath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))

        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(red: 1.0, green: 0.02, blue: 0.36, alpha: 1.0)
        line.lineWidth = 2.0
        line.glowWidth = 4.0
        line.zPosition = 35

        return line
    }

    private func makeWaveNode(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        color: SKColor
    ) -> SKShapeNode {

        let path = CGMutablePath()

        let steps = 160

        for index in 0...steps {

            let t = CGFloat(index) / CGFloat(steps)
            let px = x + t * width
            let py = y + sin(t * width / wavelength * CGFloat.pi * 2.0) * amplitude

            if index == 0 {
                path.move(to: CGPoint(x: px, y: py))
            } else {
                path.addLine(to: CGPoint(x: px, y: py))
            }
        }

        let node = SKShapeNode(path: path)

        node.strokeColor = color
        node.lineWidth = 5.0
        node.glowWidth = 5.0
        node.lineCap = .round
        node.zPosition = 40

        return node
    }

    private func makeLifeIcon() -> SKNode {

        let root = SKNode()

        let circle = SKShapeNode(circleOfRadius: 23)
        circle.fillColor = SKColor(red: 1.0, green: 0.14, blue: 0.18, alpha: 1.0)
        circle.strokeColor = SKColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
        circle.lineWidth = 2.0
        circle.glowWidth = 3.0

        root.addChild(circle)

        let spotPositions = [
            CGPoint(x: -7, y: 8),
            CGPoint(x: 8, y: 9),
            CGPoint(x: -10, y: -7),
            CGPoint(x: 8, y: -8)
        ]

        for position in spotPositions {
            let spot = SKShapeNode(circleOfRadius: 6)
            spot.position = position
            spot.fillColor = SKColor.white
            spot.strokeColor = .clear
            root.addChild(spot)
        }

        return root
    }

    private func makeLabel(
        text: String,
        fontSize: CGFloat,
        color: SKColor,
        alignment: SKLabelHorizontalAlignmentMode
    ) -> SKLabelNode {

        let label = SKLabelNode(fontNamed: "MarkerFelt-Thin")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .baseline
        label.zPosition = 50

        return label
    }

    private func pointForTile(x: Int, y: Int) -> CGPoint {

        let sceneX = CGFloat(x) * tileSize + tileSize / 2
        let flippedY = level.gridHeight - 1 - y
        let sceneY = CGFloat(flippedY) * tileSize + tileSize / 2

        return CGPoint(x: sceneX, y: sceneY)
    }

    private func layoutMazeRoot() {

        let mazePixelWidth = CGFloat(level.gridWidth) * tileSize
        let mazePixelHeight = CGFloat(level.gridHeight) * tileSize

        // Layout reserved for:
        // - right panel around x 1240
        // - bottom HUD below y 180
        //
        // Maze gets positioned in the upper-left main play area.
        mazeRoot.position = CGPoint(
            x: 40,
            y: 175 + (650 - mazePixelHeight) / 2
        )
    }
}
