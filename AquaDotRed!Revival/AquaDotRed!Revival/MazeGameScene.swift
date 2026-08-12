import Foundation
import SpriteKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// Phase 2.1: stabilized OG-derived remaster scene.
///
/// The scene is intentionally a presentation/input shell. Original maze data,
/// player rules, dynamic dot states and bug behavior live in the simulation.
/// Phase 2.1 removes per-dot scene reconstruction, adds a real pause/menu bridge,
/// and renders the recovered thin-vs-solid maze-wall hierarchy faithfully.
final class MazeGameScene: SKScene, AquaDotInputSink {
    private static let fixedStep = 1.0 / 120.0
    private static let maximumFrameDelta = 0.10

    private let preferences = AquaDotPreferences.shared
    private var session: AquaDotGameSession?
    private var layout: AquaDotMazeLayout?
    private var assets = AquaDotAssetProvider(mode: AquaDotPreferences.shared.graphicsMode)
    private let audio = AquaDotAudioSystem()

    private let mazeRoot = SKNode()
    private let collectibleRoot = SKNode()
    private let wrapRoot = SKNode()
    private let actorRoot = SKNode()
    private let hudRoot = SKNode()
    private let debugRoot = SKNode()
    private let pauseRoot = SKNode()

    private var playerNode: SKSpriteNode?
    private var currentPlayerAppearance: AquaDotPlayerAppearance = .normal
    private var bugNodes: [Character: SKSpriteNode] = [:]

    // Persistent collectible nodes. Phase 2 rebuilt the entire field whenever
    // one dot changed; Phase 2.1 mutates only the affected SpriteKit nodes.
    private var dotNodes: [GridPosition: SKSpriteNode] = [:]
    private var renderedDotKinds: [GridPosition: AquaDotDotKind] = [:]
    private var munchNodes: [GridPosition: SKNode] = [:]
    private var goodieNode: SKSpriteNode?
    private var renderedGoodieKind: AquaDotGoodieKind?
    private var renderedGoodiePosition: GridPosition?

    private var energyWave: SKShapeNode?
    private var specialWave: SKShapeNode?
    private var scoreLabel: SKLabelNode?
    private var bonusLabel: SKLabelNode?
    private var specialLabel: SKLabelNode?
    private var livesLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var modeLabel: SKLabelNode?
    private var debugStatusLabel: SKLabelNode?

    private var previousUpdateTime: TimeInterval?
    private var accumulator = 0.0
    private var currentCatalogIndex = 0
    private var debugVisible = false
    private var damageGlowUntil: TimeInterval = 0
    private var nextCollectibleSyncTime: TimeInterval = 0
    private var lastWallPalette = AquaDotPreferences.shared.wallPalette
    private var pauseObserver: NSObjectProtocol?

    private var performanceWindowStart: TimeInterval = 0
    private var performanceFrameCount = 0
    private var measuredFPS: Double = 0
    private var nextDebugRefreshTime: TimeInterval = 0

    #if os(iOS)
    private var touchStart: CGPoint?
    #endif

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        view.preferredFramesPerSecond = preferences.attemptHigherFramerate ? 120 : 60
        #if os(macOS)
        view.window?.makeFirstResponder(view)
        #endif

        if pauseObserver == nil {
            pauseObserver = NotificationCenter.default.addObserver(
                forName: .aquaDotTogglePause,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.send(.pause, source: .keyboard)
            }
        }

        // `didMove(to:)` also runs when an existing scene is reattached after
        // Options/Opening. Never reload the maze in that case: the original game
        // had a resume path and the shell deliberately preserves the live session.
        if session == nil {
            if let index = AquaDotOriginalLevelCatalog.standardLevels.firstIndex(where: { $0.originalName == "Ewe (1)" }) {
                currentCatalogIndex = index
            }
            loadCatalogLevel(at: currentCatalogIndex)
        }
    }

    /// Stop real-time audio while SwiftUI presents the opening/options shell, but
    /// keep every bit of simulation state and every SpriteKit node alive.
    func suspendForShell() {
        audio.stopAll()
        previousUpdateTime = nil
        accumulator = 0
    }

    /// Resume the preserved session without reparsing/rebuilding its maze.
    func resumeFromShell() {
        guard let session else { return }
        previousUpdateTime = nil
        accumulator = 0
        audio.startLevelMusic(variant: (currentCatalogIndex / 5) % 6 + 1)
        if let power = session.state.activeSpecialPower {
            audio.resumeSpecialPower(power)
        }
    }

    func shutdown() {
        if let pauseObserver {
            NotificationCenter.default.removeObserver(pauseObserver)
            self.pauseObserver = nil
        }
        audio.stopAll()
    }

    // MARK: - Session lifecycle

    private func loadCatalogLevel(at index: Int) {
        let catalog = AquaDotOriginalLevelCatalog.standardLevels
        guard !catalog.isEmpty else { showFatalMessage("Recovered level catalog is empty"); return }

        currentCatalogIndex = (index % catalog.count + catalog.count) % catalog.count
        let record = catalog[currentCatalogIndex]

        do {
            let maze = try AquaDotLevelLoader().load(record: record)
            let newSession = AquaDotGameSession(levelRecord: record, maze: maze, graphicsMode: preferences.graphicsMode)
            session = newSession
            layout = AquaDotMazeLayout(maze: maze)
            assets = AquaDotAssetProvider(mode: newSession.graphicsMode)
            previousUpdateTime = nil
            accumulator = 0
            nextCollectibleSyncTime = 0
            lastWallPalette = preferences.wallPalette
            rebuildScene()

            audio.stopMusic()
            audio.startLevelMusic(variant: (currentCatalogIndex / 5) % 6 + 1)
            print("AquaDot Phase 2.1: \(record.originalName), CRC \(maze.storedChecksum) ✓, theme \(newSession.wallThemeIndex), bugs \(newSession.state.bugs.count), mode \(newSession.graphicsMode.rawValue), wall palette \(preferences.wallPalette.displayName)")
        } catch {
            showFatalMessage("Could not load original AquaDot level:\n\(error)")
        }
    }

    private func rebuildScene() {
        removeAllChildren()
        [mazeRoot, collectibleRoot, wrapRoot, actorRoot, hudRoot, debugRoot, pauseRoot].forEach {
            $0.removeAllChildren()
            addChild($0)
        }
        bugNodes.removeAll()
        playerNode = nil
        currentPlayerAppearance = .normal
        dotNodes.removeAll(keepingCapacity: true)
        renderedDotKinds.removeAll(keepingCapacity: true)
        munchNodes.removeAll(keepingCapacity: true)
        goodieNode = nil
        renderedGoodieKind = nil
        renderedGoodiePosition = nil

        guard let session, let layout else { return }
        AquaDotWallRenderer(
            mode: session.graphicsMode,
            themeIndex: session.wallThemeIndex,
            palette: preferences.wallPalette
        ).render(topology: session.topology, layout: layout, into: mazeRoot)
        renderWraps(session: session, layout: layout)
        renderActors(session: session, layout: layout)
        renderHUD(session: session)
        renderDebugOverlay(session: session, layout: layout)
        rebuildCollectibles()
        renderPauseOverlay(session: session)
        debugRoot.isHidden = !debugVisible
    }

    private func showFatalMessage(_ text: String) {
        removeAllChildren()
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = max(300, size.width - 80)
        label.fontSize = 15
        label.fontColor = .red
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
        print("AquaDot Phase 2.1 ERROR: \(text)")
    }

    // MARK: - OG/remastered presentation

    private func renderWraps(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        let texture = assets.wrapTexture()
        for pair in session.topology.wrapPairs {
            for endpoint in [pair.first, pair.second] {
                let node = SKSpriteNode(texture: texture)
                node.size = CGSize(width: 32, height: 32)
                node.position = layout.point(for: endpoint)
                node.alpha = 0.78
                node.zPosition = 8
                wrapRoot.addChild(node)
            }
        }
    }

    private func renderActors(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        let player = SKSpriteNode(texture: assets.playerTexture(appearance: .normal))
        player.size = CGSize(width: 29, height: 29)
        player.position = layout.point(for: session.state.player.renderPosition())
        player.zPosition = 40
        actorRoot.addChild(player)
        playerNode = player

        for bug in session.state.bugs {
            let node = SKSpriteNode(texture: assets.bugTexture(personality: bug.personality))
            node.size = CGSize(width: 31, height: 31)
            node.position = layout.point(for: bug.renderPosition())
            node.zPosition = 35
            actorRoot.addChild(node)
            bugNodes[bug.id] = node
        }
    }

    private func rebuildCollectibles() {
        guard let session else { return }
        collectibleRoot.removeAllChildren()
        dotNodes.removeAll(keepingCapacity: true)
        renderedDotKinds.removeAll(keepingCapacity: true)
        munchNodes.removeAll(keepingCapacity: true)
        goodieNode = nil
        renderedGoodieKind = nil
        renderedGoodiePosition = nil

        for (position, kind) in session.state.dots {
            addDotNode(at: position, kind: kind)
        }
        for position in session.state.remainingMunchDots {
            addMunchNode(at: position)
        }
        synchronizeGoodie()
    }

    private func addDotNode(at position: GridPosition, kind: AquaDotDotKind) {
        guard let layout else { return }
        let node = SKSpriteNode(texture: assets.dotTexture(kind: kind))
        let side: CGFloat = kind == .normal ? 8 : 15
        node.size = CGSize(width: side, height: side)
        node.position = layout.point(for: position)
        node.zPosition = 15
        collectibleRoot.addChild(node)
        dotNodes[position] = node
        renderedDotKinds[position] = kind
    }

    private func addMunchNode(at position: GridPosition) {
        guard let session, let layout else { return }
        let root = SKNode()
        root.position = layout.point(for: position)
        root.zPosition = 17

        let outer = SKShapeNode(circleOfRadius: 7.4)
        outer.strokeColor = SKColor(red: 1, green: 0.05, blue: 0.07, alpha: 1)
        outer.lineWidth = 2.5
        outer.fillColor = .clear
        outer.glowWidth = session.graphicsMode == .remastered ? 2.2 : 0.4
        root.addChild(outer)

        let inner = SKShapeNode(circleOfRadius: 3.6)
        inner.strokeColor = .white
        inner.lineWidth = 1.5
        inner.fillColor = .clear
        root.addChild(inner)

        let pulse = SKAction.sequence([
            .scale(to: 1.24, duration: 0.34),
            .scale(to: 0.90, duration: 0.34),
        ])
        root.run(.repeatForever(pulse), withKey: "munch.pulse")
        collectibleRoot.addChild(root)
        munchNodes[position] = root
    }

    private func synchronizeGoodie() {
        guard let session, let layout else { return }
        let current = session.state.goodie

        if current?.kind == renderedGoodieKind,
           current?.position == renderedGoodiePosition {
            return
        }

        goodieNode?.removeAllActions()
        goodieNode?.removeFromParent()
        goodieNode = nil
        renderedGoodieKind = current?.kind
        renderedGoodiePosition = current?.position

        guard let goodie = current else { return }
        let node = SKSpriteNode(
            texture: assets.goodieTexture(
                kind: goodie.kind,
                multiplier: session.state.multiplier + 1
            )
        )
        node.size = CGSize(width: 25, height: 25)
        node.position = layout.point(for: goodie.position)
        node.zPosition = 22
        node.run(
            .repeatForever(
                .sequence([
                    .scale(to: 1.14, duration: 0.4),
                    .scale(to: 0.94, duration: 0.4),
                ])
            ),
            withKey: "goodie.pulse"
        )
        collectibleRoot.addChild(node)
        goodieNode = node
    }

    /// Diff the simulation state into persistent nodes without tearing down the
    /// whole collectible layer. This is intentionally throttled; dynamic dot-kind
    /// changes grow in discrete goodie-radius steps and do not need a 120 Hz scan.
    private func synchronizeCollectiblesIncrementally() {
        guard let session else { return }

        for position in Array(dotNodes.keys) where session.state.dots[position] == nil {
            dotNodes.removeValue(forKey: position)?.removeFromParent()
            renderedDotKinds.removeValue(forKey: position)
        }

        for (position, kind) in session.state.dots {
            if let node = dotNodes[position] {
                if renderedDotKinds[position] != kind {
                    node.texture = assets.dotTexture(kind: kind)
                    let side: CGFloat = kind == .normal ? 8 : 15
                    node.size = CGSize(width: side, height: side)
                    renderedDotKinds[position] = kind
                }
            } else {
                addDotNode(at: position, kind: kind)
            }
        }

        for position in Array(munchNodes.keys)
            where !session.state.remainingMunchDots.contains(position) {
            munchNodes.removeValue(forKey: position)?.removeFromParent()
        }
        for position in session.state.remainingMunchDots where munchNodes[position] == nil {
            addMunchNode(at: position)
        }

        synchronizeGoodie()
    }

    /// Apply high-frequency removals immediately so eating a dot never waits for
    /// the throttled reconciliation pass.
    private func applyPresentationEvents(_ events: [AquaDotGameEvent]) {
        for event in events {
            switch event {
            case let .dotEaten(_, position):
                dotNodes.removeValue(forKey: position)?.removeFromParent()
                renderedDotKinds.removeValue(forKey: position)
            case let .munchEaten(position):
                munchNodes.removeValue(forKey: position)?.removeFromParent()
            case .goodieSpawned, .goodieEaten:
                synchronizeGoodie()
            case .paused:
                if let session { renderPauseOverlay(session: session) }
            default:
                break
            }
        }
    }

    // MARK: - HUD based on recovered 800px panel

    private func renderHUD(session: AquaDotGameSession) {
        let panel = SKSpriteNode(texture: assets.statusPanelTexture())
        panel.size = CGSize(width: 800, height: 50)
        panel.position = CGPoint(x: 400, y: 25)
        panel.zPosition = 100
        hudRoot.addChild(panel)

        let energy = hudLabel("energy", color: .cyan, size: 15)
        energy.position = CGPoint(x: 122, y: 35)
        hudRoot.addChild(energy)

        let special = hudLabel("special", color: .red, size: 15)
        special.position = CGPoint(x: 122, y: 10)
        hudRoot.addChild(special)
        specialLabel = special

        let ew = SKShapeNode(); ew.zPosition = 110; hudRoot.addChild(ew); energyWave = ew
        let sw = SKShapeNode(); sw.zPosition = 110; hudRoot.addChild(sw); specialWave = sw

        let score = hudLabel("", color: SKColor(red: 0.35, green: 1, blue: 0.22, alpha: 1), size: 12)
        score.horizontalAlignmentMode = .right
        score.position = CGPoint(x: 790, y: 36)
        hudRoot.addChild(score); scoreLabel = score

        let bonus = hudLabel("", color: SKColor(red: 0.35, green: 1, blue: 0.22, alpha: 1), size: 12)
        bonus.horizontalAlignmentMode = .right
        bonus.position = CGPoint(x: 790, y: 11)
        hudRoot.addChild(bonus); bonusLabel = bonus

        let lives = hudLabel("", color: .white, size: 11)
        lives.horizontalAlignmentMode = .left
        lives.position = CGPoint(x: 610, y: 11)
        hudRoot.addChild(lives); livesLabel = lives

        let level = hudLabel("", color: SKColor(red: 0.68, green: 0.94, blue: 1, alpha: 1), size: 10)
        level.horizontalAlignmentMode = .left
        level.position = CGPoint(x: 12, y: 57)
        hudRoot.addChild(level); levelLabel = level

        let mode = hudLabel("", color: SKColor(white: 0.7, alpha: 1), size: 9)
        mode.horizontalAlignmentMode = .right
        mode.position = CGPoint(x: 792, y: 57)
        hudRoot.addChild(mode); modeLabel = mode

        refreshHUD(session: session, time: 0)
    }

    private func hudLabel(_ text: String, color: SKColor, size: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Helvetica-BoldOblique")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.zPosition = 111
        return label
    }

    private func updateWave(_ node: SKShapeNode?, y: CGFloat, fraction: Double, color: SKColor, phase: CGFloat) {
        guard let node else { return }
        let startX: CGFloat = 165
        let maxWidth: CGFloat = 420
        let width = maxWidth * CGFloat(max(0, min(1, fraction)))
        let path = CGMutablePath()
        let samples = max(2, Int(width / 4))
        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            let x = startX + t * width
            let py = y + sin(t * 9 * .pi + phase) * 4.5
            if i == 0 { path.move(to: CGPoint(x: x, y: py)) }
            else { path.addLine(to: CGPoint(x: x, y: py)) }
        }
        node.path = path
        node.strokeColor = color
        node.lineWidth = 2.6
        node.glowWidth = 1.4
        node.lineCap = .round
    }

    private func refreshHUD(session: AquaDotGameSession, time: TimeInterval) {
        let state = session.state
        let beingDamaged = time < damageGlowUntil
        let energyColor: SKColor = state.isMunchActive ? .white : (beingDamaged || state.energy < 0.25 ? .yellow : .cyan)
        updateWave(energyWave, y: 36, fraction: state.energy, color: energyColor, phase: CGFloat(time * 4))

        let specialColor: SKColor
        let specialText: String
        if let active = state.activeSpecialPower {
            switch active {
            case let .yummy(power): specialColor = .green; specialText = power.rawValue
            case let .yuk(power): specialColor = .purple; specialText = power.rawValue
            }
        } else if let available = state.availableYummyPower {
            specialColor = .red; specialText = available.rawValue + " ready"
        } else {
            specialColor = .red; specialText = "special"
        }
        specialLabel?.text = specialText
        specialLabel?.fontColor = specialColor
        updateWave(specialWave, y: 11, fraction: state.specialPowerAmount, color: specialColor, phase: CGFloat(time * 5 + 1.4))

        scoreLabel?.text = "score  \(state.score)"
        bonusLabel?.text = "bonus \(state.bonus)   x\(state.multiplier)"
        livesLabel?.text = "lives \(state.lives)"
        levelLabel?.text = "\(session.levelRecord.originalName)   CRC \(session.maze.storedChecksum) ✓   wall \(session.wallThemeIndex)"
        modeLabel?.text = "\(session.graphicsMode.rawValue)   [ ] levels   O/R graphics   P pause   ` debug"
    }

    // MARK: - Pause / in-game shell

    private func renderPauseOverlay(session: AquaDotGameSession) {
        pauseRoot.removeAllChildren()
        guard session.state.isPaused else { return }

        let shade = SKShapeNode(
            rect: CGRect(x: 0, y: 0, width: size.width, height: size.height)
        )
        shade.fillColor = SKColor.black.withAlphaComponent(0.78)
        shade.strokeColor = .clear
        shade.zPosition = 400
        pauseRoot.addChild(shade)

        let panel = SKShapeNode(
            rectOf: CGSize(width: 390, height: 255),
            cornerRadius: 22
        )
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.fillColor = SKColor.black.withAlphaComponent(0.92)
        panel.strokeColor = .cyan
        panel.lineWidth = 2
        panel.glowWidth = 2
        panel.zPosition = 410
        pauseRoot.addChild(panel)

        func addLabel(
            _ text: String,
            y: CGFloat,
            color: SKColor,
            size: CGFloat,
            name: String? = nil
        ) {
            let label = SKLabelNode(fontNamed: "Helvetica-BoldOblique")
            label.text = text
            label.fontSize = size
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: self.size.width / 2, y: y)
            label.zPosition = 420
            label.name = name
            pauseRoot.addChild(label)
        }

        addLabel("paused", y: size.height / 2 + 74, color: .cyan, size: 34)
        addLabel("resume", y: size.height / 2 + 16, color: .green, size: 22, name: "pause.resume")
        addLabel("options", y: size.height / 2 - 28, color: .cyan, size: 20, name: "pause.options")
        addLabel("return to opening", y: size.height / 2 - 72, color: .red, size: 19, name: "pause.opening")
    }

    @discardableResult
    private func handlePauseTap(at point: CGPoint) -> Bool {
        guard session?.state.isPaused == true else { return false }
        for node in nodes(at: point) {
            switch node.name {
            case "pause.resume":
                send(.pause, source: .pointer)
                return true
            case "pause.options":
                AquaDotAppController.shared.showOptions(returnTo: .game)
                return true
            case "pause.opening":
                AquaDotAppController.shared.showOpening()
                return true
            default:
                continue
            }
        }
        return true
    }

    // MARK: - Debug

    private func renderDebugOverlay(session: AquaDotGameSession, layout: AquaDotMazeLayout) {
        for position in session.topology.traversable {
            let node = SKShapeNode(circleOfRadius: 1.3)
            node.fillColor = .cyan
            node.strokeColor = .clear
            node.position = layout.point(for: position)
            node.zPosition = 200
            debugRoot.addChild(node)
        }
        for cell in session.topology.wallCells {
            guard case let .wall(mask) = cell.kind else { continue }
            let label = SKLabelNode(fontNamed: "Menlo")
            if let frame = mask.recoveredGameLineAtlasFrameIndex {
                label.text = String(format: "%X/%d", mask.rawValue, frame)
            } else {
                label.text = String(format: "%X", mask.rawValue)
            }
            label.fontSize = 5
            label.fontColor = SKColor.white.withAlphaComponent(0.72)
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = layout.wallCellCenter(x: cell.x, y: cell.y)
            label.zPosition = 210
            debugRoot.addChild(label)
        }

        let status = SKLabelNode(fontNamed: "Menlo-Bold")
        status.fontSize = 7
        status.fontColor = .white
        status.horizontalAlignmentMode = .left
        status.verticalAlignmentMode = .top
        status.position = CGPoint(x: 8, y: 695)
        status.zPosition = 230
        debugRoot.addChild(status)
        debugStatusLabel = status
    }

    private func refreshDebug(session: AquaDotGameSession) {
        guard debugVisible else { return }
        let bugs = session.state.bugs.map {
            "\($0.id):\($0.personality.rawValue)/\($0.mode.rawValue)@\($0.currentNode.x),\($0.currentNode.y)"
        }.joined(separator: "   ")
        debugStatusLabel?.text =
            "FPS \(String(format: "%.0f", measuredFPS))  nodes \(recursiveNodeCount(self))  audio \(audio.activeVoiceCount)/10  " +
            "P \(session.state.player.currentNode.x),\(session.state.player.currentNode.y)  dots \(session.state.dots.count)  " +
            "munch \(String(format: "%.1f", session.state.munchTimeRemaining))   \(bugs)"
    }

    private func recursiveNodeCount(_ node: SKNode) -> Int {
        node.children.reduce(1) { $0 + recursiveNodeCount($1) }
    }

    private func toggleDebugOverlay() {
        debugVisible.toggle()
        debugRoot.isHidden = !debugVisible
    }

    private func setGraphicsMode(_ mode: AquaDotGraphicsMode) {
        preferences.graphicsMode = mode
        guard let session, session.graphicsMode != mode else { return }
        session.graphicsMode = mode
        assets = AquaDotAssetProvider(mode: mode)
        rebuildScene()
    }

    // MARK: - Fixed step

    override func update(_ currentTime: TimeInterval) {
        guard let session, let layout else { return }

        performanceFrameCount += 1
        if performanceWindowStart == 0 {
            performanceWindowStart = currentTime
        } else if currentTime - performanceWindowStart >= 1.0 {
            let elapsed = currentTime - performanceWindowStart
            measuredFPS = Double(performanceFrameCount) / max(0.001, elapsed)
            performanceFrameCount = 0
            performanceWindowStart = currentTime
        }

        if session.graphicsMode != preferences.graphicsMode {
            setGraphicsMode(preferences.graphicsMode)
            return
        }
        if lastWallPalette != preferences.wallPalette {
            lastWallPalette = preferences.wallPalette
            rebuildScene()
            return
        }
        if let view {
            let preferred = preferences.attemptHigherFramerate ? 120 : 60
            if view.preferredFramesPerSecond != preferred {
                view.preferredFramesPerSecond = preferred
            }
        }
        audio.synchronizePreferences()

        guard let previousUpdateTime else { self.previousUpdateTime = currentTime; return }

        let frameDelta = min(Self.maximumFrameDelta, max(0, currentTime - previousUpdateTime))
        self.previousUpdateTime = currentTime
        accumulator += frameDelta
        while accumulator >= Self.fixedStep {
            session.simulation.step(deltaTime: Self.fixedStep)
            accumulator -= Self.fixedStep
        }

        let events = session.simulation.drainEvents()
        if events.contains(where: { if case .playerDamaged = $0 { return true }; return false }) {
            // The guide shows both AquaDot and the energy meter glowing/pulsing
            // yellow while a bug is draining energy. Damage events are emitted
            // repeatedly during contact, so this remains continuous while held.
            damageGlowUntil = currentTime + 0.28
        }
        applyPresentationEvents(events)
        audio.handle(events)

        playerNode?.position = layout.point(for: session.state.player.renderPosition())
        updatePlayerAppearance(session: session, time: currentTime)

        let playerPosition = session.state.player.renderPosition()
        let blind: Bool = {
            if case .yuk(.blind)? = session.state.activeSpecialPower { return true }
            return false
        }()

        for bug in session.state.bugs {
            guard let node = bugNodes[bug.id] else { continue }
            let bugPosition = bug.renderPosition()
            node.position = layout.point(for: bugPosition)

            // Guide artwork faces right; rotate that authentic composite into the
            // current maze direction rather than redrawing four invented sprites.
            switch bug.movementDirection {
            case .right: node.zRotation = 0
            case .up: node.zRotation = .pi / 2
            case .left: node.zRotation = .pi
            case .down: node.zRotation = -.pi / 2
            case nil: break
            }

            node.alpha = bug.mode == .returningHome ? 0.34 : 1
            if blind, bug.mode != .returningHome {
                // Strategy guide: Blind means only nearby bugs are readily visible.
                let dx = bugPosition.x - playerPosition.x
                let dy = bugPosition.y - playerPosition.y
                let distance = sqrt(dx * dx + dy * dy)
                if distance > 3.2 { node.alpha = 0.06 }
                else if distance > 1.5 { node.alpha *= max(0.12, (3.2 - distance) / 1.7) }
            }

            if bug.mode == .returningHome {
                node.color = .gray
                node.colorBlendFactor = 0.78
            } else if bug.mode == .frightened || session.state.isMunchActive {
                let pulse = CGFloat((sin(currentTime * 11 + Double(bug.id.unicodeScalars.first?.value ?? 0)) + 1) / 2)
                node.color = SKColor(red: pulse, green: 1 - pulse * 0.35, blue: 1, alpha: 1)
                node.colorBlendFactor = 0.68
            } else {
                node.colorBlendFactor = 0
            }
        }

        if currentTime >= nextCollectibleSyncTime {
            synchronizeCollectiblesIncrementally()
            nextCollectibleSyncTime = currentTime + 0.10
        }
        refreshHUD(session: session, time: currentTime)
        if debugVisible, currentTime >= nextDebugRefreshTime {
            refreshDebug(session: session)
            nextDebugRefreshTime = currentTime + 0.25
        }
    }

    private func updatePlayerAppearance(session: AquaDotGameSession, time: TimeInterval) {
        guard let node = playerNode else { return }
        let state = session.state

        var pulseScale: CGFloat = 1
        let appearance: AquaDotPlayerAppearance
        if time < damageGlowUntil {
            appearance = .damaged
            let speed = 6.0 + (1.0 - state.energy) * 12.0
            pulseScale = 0.92 + CGFloat((sin(time * speed) + 1) * 0.055)
        } else if state.isMunchActive {
            appearance = .munch
        } else if let active = state.activeSpecialPower {
            switch active {
            case .yummy: appearance = .yummy
            case .yuk: appearance = .yuk
            }
            // Shipped guide: green/purple AquaDot glow pulses faster as the
            // special-power meter approaches empty.
            let speed = 4.0 + (1.0 - state.specialPowerAmount) * 10.0
            pulseScale = 0.96 + CGFloat((sin(time * speed) + 1) * 0.035)
        } else {
            appearance = .normal
            if state.energy < 0.2 {
                pulseScale = 0.88 + CGFloat((sin(time * 14) + 1) * 0.08)
            }
        }

        // Use the recovered five-state underlay palette directly instead of
        // tinting one red sprite. This is closer to the shipped rendering path.
        if appearance != currentPlayerAppearance {
            currentPlayerAppearance = appearance
            node.texture = assets.playerTexture(appearance: appearance)
        }
        node.colorBlendFactor = 0
        node.setScale(pulseScale)
    }

    // MARK: - Input

    func handleAquaDotInput(_ event: AquaDotInputEvent) {
        guard event.isPressed, let session else { return }
        if let direction = event.action.movementDirection {
            // Recovered option: when pretapping is disabled, a direction request
            // is accepted only when AquaDot is actually at an intersection/node.
            if !preferences.allowPretapping, session.state.player.nextNode != nil {
                return
            }
            session.simulation.request(direction)
            return
        }
        switch event.action {
        case .confirm:
            session.simulation.activateAvailableSpecial()
        case .pause:
            session.simulation.togglePause()
        case .cancel:
            if session.state.isPaused { session.simulation.togglePause() }
        case .moveUp, .moveRight, .moveDown, .moveLeft:
            break
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
        case 49: send(.confirm, source: .keyboard)       // Original Space = activate Yummy power.
        case 53: send(.pause, source: .keyboard)        // Escape
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
            case "o": setGraphicsMode(.original)
            case "r": setGraphicsMode(.remastered)
            case "m":
                if session?.state.isPaused == true {
                    audio.stopAll()
                    AquaDotAppController.shared.showOpening()
                } else {
                    super.keyDown(with: event)
                }
            default: super.keyDown(with: event)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = event.location(in: self)
        if handlePauseTap(at: point) { return }
        super.mouseDown(with: event)
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
        if max(abs(dx), abs(dy)) < 12 {
            if handlePauseTap(at: end) { return }
            send(.confirm, source: .touch)
        } else if abs(dx) > abs(dy) {
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
            case .keyboardUpArrow, .keyboardW: send(.moveUp, source: .keyboard); handled = true
            case .keyboardRightArrow, .keyboardD: send(.moveRight, source: .keyboard); handled = true
            case .keyboardDownArrow, .keyboardS: send(.moveDown, source: .keyboard); handled = true
            case .keyboardLeftArrow, .keyboardA: send(.moveLeft, source: .keyboard); handled = true
            case .keyboardSpacebar: send(.confirm, source: .keyboard); handled = true
            case .keyboardP, .keyboardEscape: send(.pause, source: .keyboard); handled = true
            default: break
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }
    #endif
}
