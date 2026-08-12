import Foundation
import SpriteKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Phase 1 authentic AquaDot runtime.
///
/// This scene no longer consumes `TestLevels.levelOne`. It loads an untouched
/// recovered AquaDot maze, verifies its original checksum, builds the recovered
/// graph topology, runs platform-independent movement/collection, and renders the
/// original game's assets over that state.
final class MazeGameScene: SKScene, AquaDotInputSink {
    private static let fixedStep: Double = 1.0 / 120.0
    private static let maximumFrameDelta: Double = 0.10

    private var session: AquaDotGameSession?
    private var layout: AquaDotMazeLayout?
    private var assets = AquaDotAssetProvider(mode: .original)

    private let mazeRoot = SKNode()
    private let collectibleRoot = SKNode()
    private let wrapRoot = SKNode()
    private let playerRoot = SKNode()
    private let hudRoot = SKNode()
    private let debugRoot = SKNode()

    private var playerNode: SKSpriteNode?
    private var dotNodes: [GridPosition: SKNode] = [:]
    private var munchNodes: [GridPosition: SKNode] = [:]
    private var scoreLabel: SKLabelNode?
    private var dotsLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var crcLabel: SKLabelNode?

    private var previousUpdateTime: TimeInterval?
    private var accumulator: Double = 0
    private var currentCatalogIndex: Int = 0
    private var debugVisible = false

    #if os(iOS)
    private var touchStart: CGPoint?
    #endif

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero

        #if os(macOS)
        view.window?.makeFirstResponder(view)
        #endif

        if let eweIndex = AquaDotOriginalLevelCatalog.standardLevels.firstIndex(where: { $0.originalName == "Ewe (1)" }) {
            currentCatalogIndex = eweIndex
        }
        loadCatalogLevel(at: currentCatalogIndex)
    }

    // MARK: - Level/session lifecycle

    private func loadCatalogLevel(at index: Int) {
        let catalog = AquaDotOriginalLevelCatalog.standardLevels
        guard !catalog.isEmpty else {
            showFatalMessage("Recovered level catalog is empty")
            return
        }

        currentCatalogIndex = (index % catalog.count + catalog.count) % catalog.count
        let record = catalog[currentCatalogIndex]

        do {
            let loaded = try AquaDotLevelLoader().load(record: record)
            let newSession = AquaDotGameSession(
                levelRecord: record,
                maze: loaded,
                graphicsMode: .original
            )
            session = newSession
            layout = AquaDotMazeLayout(maze: loaded)
            assets = AquaDotAssetProvider(mode: newSession.graphicsMode)
            previousUpdateTime = nil
            accumulator = 0
            rebuildScene()

            print("AquaDot Phase 1: loaded original level '\(record.originalName)' \(loaded.width)x\(loaded.height), CRC \(loaded.storedChecksum) verified, graph connected=\(newSession.topology.isConnected)")
        } catch {
            showFatalMessage("Could not load original AquaDot level:\n\(error)")
        }
    }

    private func rebuildScene() {
        removeAllChildren()
        [mazeRoot, collectibleRoot, wrapRoot, playerRoot, hudRoot, debugRoot].forEach {
            $0.removeAllChildren()
            addChild($0)
        }

        dotNodes.removeAll(keepingCapacity: true)
        munchNodes.removeAll(keepingCapacity: true)

        guard let session, let layout else { return }

        renderOriginalMaze(session: session, layout: layout)
        renderCollectibles(session: session, layout: layout)
        renderWraps(session: session, layout: layout)
        renderPlayer(session: session, layout: layout)
        renderOriginalHUD(session: session)
        renderDebugOverlay(session: session, layout: layout)
        debugRoot.isHidden = !debugVisible
    }

    private func showFatalMessage(_ text: String) {
        removeAllChildren()
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = max(300, size.width - 80)
        label.fontSize = 16
        label.fontColor = .red
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
        print("AquaDot Phase 1 ERROR: \(text)")
    }

    // MARK: - Authentic maze rendering

    private func renderOriginalMaze(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        // The original game colorized grayscale/beveled wall sprite themes. Until
        // the exact 9w/10w sprite-piece selection table is fully mapped, Phase 1
        // uses the *recovered exact wall masks* and matches the green beveled look
        // visible in the shipped strategy-guide gameplay captures.
        for cell in session.topology.wallCells {
            switch cell.kind {
            case .open, .wrapBoundary, .unknown:
                break

            case .blocked:
                let center = layout.wallCellCenter(x: cell.x, y: cell.y)
                let outer = SKShapeNode(
                    rectOf: CGSize(width: layout.pitch + 1, height: layout.pitch + 1),
                    cornerRadius: 2.5
                )
                outer.position = center
                outer.fillColor = SKColor(red: 0.04, green: 0.43, blue: 0.02, alpha: 1)
                outer.strokeColor = .clear
                outer.zPosition = 0
                mazeRoot.addChild(outer)

                let highlight = SKShapeNode(
                    rectOf: CGSize(width: max(1, layout.pitch - 7), height: max(1, layout.pitch - 7)),
                    cornerRadius: 3
                )
                highlight.position = CGPoint(x: center.x - 1.5, y: center.y + 1.5)
                highlight.fillColor = SKColor(red: 0.18, green: 0.80, blue: 0.08, alpha: 0.72)
                highlight.strokeColor = .clear
                highlight.zPosition = 0.1
                mazeRoot.addChild(highlight)

            case let .wall(geometry):
                renderWallGeometry(geometry, center: layout.wallCellCenter(x: cell.x, y: cell.y), pitch: layout.pitch)
            }
        }
    }

    private func renderWallGeometry(_ geometry: AquaDotWallGeometry, center: CGPoint, pitch: CGFloat) {
        let path = CGMutablePath()
        let half = pitch / 2 + 0.75

        func branch(to point: CGPoint) {
            path.move(to: center)
            path.addLine(to: point)
        }

        if geometry.contains(.north) { branch(to: CGPoint(x: center.x, y: center.y + half)) }
        if geometry.contains(.east)  { branch(to: CGPoint(x: center.x + half, y: center.y)) }
        if geometry.contains(.south) { branch(to: CGPoint(x: center.x, y: center.y - half)) }
        if geometry.contains(.west)  { branch(to: CGPoint(x: center.x - half, y: center.y)) }

        let shadow = SKShapeNode(path: path)
        shadow.strokeColor = SKColor(red: 0.015, green: 0.25, blue: 0.01, alpha: 1)
        shadow.lineWidth = 11
        shadow.lineCap = .round
        shadow.lineJoin = .round
        shadow.zPosition = 1
        mazeRoot.addChild(shadow)

        let body = SKShapeNode(path: path)
        body.strokeColor = SKColor(red: 0.07, green: 0.67, blue: 0.025, alpha: 1)
        body.lineWidth = 8
        body.lineCap = .round
        body.lineJoin = .round
        body.zPosition = 1.1
        mazeRoot.addChild(body)

        let highlight = SKShapeNode(path: path)
        highlight.strokeColor = SKColor(red: 0.30, green: 0.92, blue: 0.12, alpha: 0.55)
        highlight.lineWidth = 2
        highlight.lineCap = .round
        highlight.lineJoin = .round
        highlight.position = CGPoint(x: -1, y: 1)
        highlight.zPosition = 1.2
        mazeRoot.addChild(highlight)
    }

    private func renderCollectibles(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        let dotTexture = assets.basicDotTexture()
        let munchTexture = assets.munchDotTexture()

        for position in session.state.remainingDots {
            let node = SKSpriteNode(texture: dotTexture)
            node.size = CGSize(width: 8, height: 8)
            node.position = layout.point(for: position)
            node.zPosition = 10
            collectibleRoot.addChild(node)
            dotNodes[position] = node
        }

        for position in session.state.remainingMunchDots {
            let node = SKSpriteNode(texture: munchTexture)
            node.size = CGSize(width: 16, height: 16)
            node.position = layout.point(for: position)
            node.zPosition = 11
            collectibleRoot.addChild(node)
            munchNodes[position] = node
        }
    }

    private func renderWraps(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        let texture = assets.wrapTexture()
        for pair in session.topology.wrapPairs {
            for endpoint in [pair.first, pair.second] {
                let node = SKSpriteNode(texture: texture)
                node.size = CGSize(width: 32, height: 32)
                node.position = layout.point(for: endpoint)
                node.alpha = 0.72
                node.zPosition = 8
                wrapRoot.addChild(node)
            }
        }
    }

    private func renderPlayer(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        let node = SKSpriteNode(texture: assets.playerTexture())
        node.size = CGSize(width: 30, height: 30)
        node.position = layout.point(for: session.state.player.renderPosition())
        node.zPosition = 30
        playerRoot.addChild(node)
        playerNode = node
    }

    // MARK: - Original HUD foundation

    private func renderOriginalHUD(session: AquaDotGameSession) {
        let panel = SKSpriteNode(texture: assets.statusPanelTexture())
        panel.size = CGSize(width: 800, height: 50)
        panel.position = CGPoint(x: 400, y: 25)
        panel.zPosition = 100
        hudRoot.addChild(panel)

        let energy = makeHUDLabel("energy", color: SKColor(red: 1, green: 0.95, blue: 0.10, alpha: 1), size: 16)
        energy.position = CGPoint(x: 128, y: 35)
        hudRoot.addChild(energy)

        let quick = makeHUDLabel("quick", color: SKColor(red: 1, green: 0.05, blue: 0.12, alpha: 1), size: 16)
        quick.position = CGPoint(x: 128, y: 10)
        hudRoot.addChild(quick)

        renderWave(y: 36, color: SKColor(red: 1, green: 0.96, blue: 0.02, alpha: 1), phase: 0)
        renderWave(y: 11, color: SKColor(red: 1, green: 0.02, blue: 0.06, alpha: 1), phase: .pi / 2)

        let score = makeHUDLabel("", color: SKColor(red: 0.34, green: 1, blue: 0.24, alpha: 1), size: 13)
        score.horizontalAlignmentMode = .right
        score.position = CGPoint(x: 786, y: 35)
        hudRoot.addChild(score)
        scoreLabel = score

        let dots = makeHUDLabel("", color: SKColor(red: 0.34, green: 1, blue: 0.24, alpha: 1), size: 13)
        dots.horizontalAlignmentMode = .right
        dots.position = CGPoint(x: 786, y: 10)
        hudRoot.addChild(dots)
        dotsLabel = dots

        let level = makeHUDLabel("", color: SKColor(red: 0.65, green: 0.95, blue: 1, alpha: 1), size: 11)
        level.horizontalAlignmentMode = .left
        level.position = CGPoint(x: 160, y: 57)
        hudRoot.addChild(level)
        levelLabel = level

        let crc = makeHUDLabel("", color: SKColor(red: 0.45, green: 0.75, blue: 0.78, alpha: 1), size: 9)
        crc.horizontalAlignmentMode = .right
        crc.position = CGPoint(x: 790, y: 57)
        hudRoot.addChild(crc)
        crcLabel = crc

        refreshHUD(session: session)
    }

    private func makeHUDLabel(_ text: String, color: SKColor, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-BoldOblique")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.zPosition = 110
        return label
    }

    private func renderWave(y: CGFloat, color: SKColor, phase: CGFloat) {
        let path = CGMutablePath()
        let startX: CGFloat = 170
        let endX: CGFloat = 603
        let samples = 96
        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let x = startX + (endX - startX) * t
            let waveY = y + sin(t * 8 * .pi + phase) * 5
            if i == 0 { path.move(to: CGPoint(x: x, y: waveY)) }
            else { path.addLine(to: CGPoint(x: x, y: waveY)) }
        }
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.lineWidth = 2.5
        node.glowWidth = 1.2
        node.zPosition = 109
        hudRoot.addChild(node)
    }

    private func refreshHUD(session: AquaDotGameSession) {
        scoreLabel?.text = "score  \(session.state.score)"
        dotsLabel?.text = session.state.levelCompleted ? "maze clear" : "dots  \(session.state.remainingCollectibleCount)"
        levelLabel?.text = "\(session.levelRecord.originalName)   [ / ] changes original maze"
        crcLabel?.text = "original CRC \(session.maze.storedChecksum) ✓"
    }

    // MARK: - Debug preservation overlay

    private func renderDebugOverlay(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        for position in session.topology.traversable {
            let node = SKShapeNode(circleOfRadius: 1.6)
            node.fillColor = .cyan
            node.strokeColor = .clear
            node.position = layout.point(for: position)
            node.zPosition = 200
            debugRoot.addChild(node)
        }

        for cell in session.topology.wallCells {
            guard case let .wall(mask) = cell.kind else { continue }
            let label = SKLabelNode(fontNamed: "Menlo")
            label.text = String(format: "%X", mask.rawValue)
            label.fontSize = 5.5
            label.fontColor = SKColor.white.withAlphaComponent(0.7)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = layout.wallCellCenter(x: cell.x, y: cell.y)
            label.zPosition = 210
            debugRoot.addChild(label)
        }

        for start in session.topology.enemyStarts {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = String(start.id)
            label.fontSize = 9
            label.fontColor = .magenta
            label.position = layout.point(for: start.position)
            label.zPosition = 220
            debugRoot.addChild(label)
        }
    }

    private func toggleDebugOverlay() {
        debugVisible.toggle()
        debugRoot.isHidden = !debugVisible
    }

    // MARK: - Fixed-step simulation

    override func update(_ currentTime: TimeInterval) {
        guard let session, let layout else { return }

        guard let previousUpdateTime else {
            self.previousUpdateTime = currentTime
            return
        }

        let frameDelta = min(Self.maximumFrameDelta, max(0, currentTime - previousUpdateTime))
        self.previousUpdateTime = currentTime
        accumulator += frameDelta

        while accumulator >= Self.fixedStep {
            session.simulation.step(deltaTime: Self.fixedStep)
            accumulator -= Self.fixedStep
        }

        playerNode?.position = layout.point(for: session.state.player.renderPosition())
        synchronizeCollectibles(with: session.state)
        refreshHUD(session: session)
    }

    private func synchronizeCollectibles(with state: AquaDotGameState) {
        let eatenDots = dotNodes.keys.filter { !state.remainingDots.contains($0) }
        for position in eatenDots {
            dotNodes.removeValue(forKey: position)?.removeFromParent()
        }

        let eatenMunchDots = munchNodes.keys.filter { !state.remainingMunchDots.contains($0) }
        for position in eatenMunchDots {
            munchNodes.removeValue(forKey: position)?.removeFromParent()
        }
    }

    // MARK: - Unified input boundary

    func handleAquaDotInput(_ event: AquaDotInputEvent) {
        guard event.isPressed, let session else { return }

        if let direction = event.action.movementDirection {
            session.simulation.request(direction)
            return
        }

        if event.action == .pause {
            session.simulation.togglePause()
        }
    }

    private func send(_ action: AquaDotInputAction, source: AquaDotInputSource) {
        handleAquaDotInput(AquaDotInputEvent(action: action, isPressed: true, source: source))
    }

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""

        switch event.keyCode {
        case 126: send(.moveUp, source: .keyboard)
        case 124: send(.moveRight, source: .keyboard)
        case 125: send(.moveDown, source: .keyboard)
        case 123: send(.moveLeft, source: .keyboard)
        case 49: send(.pause, source: .keyboard)
        default:
            switch chars {
            case "w": send(.moveUp, source: .keyboard)
            case "d": send(.moveRight, source: .keyboard)
            case "s": send(.moveDown, source: .keyboard)
            case "a": send(.moveLeft, source: .keyboard)
            case "p": send(.pause, source: .keyboard)
            case "`": toggleDebugOverlay()
            case "[": loadCatalogLevel(at: currentCatalogIndex - 1)
            case "]": loadCatalogLevel(at: currentCatalogIndex + 1)
            default: super.keyDown(with: event)
            }
        }
    }
    #endif

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = touches.first?.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = touchStart, let end = touches.first?.location(in: self) else { return }
        touchStart = nil

        let dx = end.x - start.x
        let dy = end.y - start.y
        guard max(abs(dx), abs(dy)) >= 12 else { return }

        if abs(dx) > abs(dy) {
            send(dx > 0 ? .moveRight : .moveLeft, source: .touch)
        } else {
            send(dy > 0 ? .moveUp : .moveDown, source: .touch)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardUpArrow, .keyboardW:
                send(.moveUp, source: .keyboard); handled = true
            case .keyboardRightArrow, .keyboardD:
                send(.moveRight, source: .keyboard); handled = true
            case .keyboardDownArrow, .keyboardS:
                send(.moveDown, source: .keyboard); handled = true
            case .keyboardLeftArrow, .keyboardA:
                send(.moveLeft, source: .keyboard); handled = true
            case .keyboardSpacebar, .keyboardP:
                send(.pause, source: .keyboard); handled = true
            default:
                break
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }
    #endif
}
