import Foundation
import SpriteKit

struct AquaDotWallMaterial {
    let body: SKColor
    let bright: SKColor
    let shadow: SKColor
    let glow: SKColor

    static func originalTheme(_ index: Int, palette: AquaDotWallPalette) -> AquaDotWallMaterial {
        let themes: [(CGFloat, CGFloat, CGFloat)] = [
            (0.12,0.82,0.08), (0.55,0.16,0.92), (0.94,0.76,0.08),
            (0.12,0.72,0.95), (0.94,0.34,0.08), (0.94,0.12,0.55),
            (0.18,0.86,0.72), (0.38,0.46,1.00), (0.72,0.92,0.16),
            (0.90,0.22,0.22), (0.42,0.90,1.00), (0.82,0.40,0.96),
            (0.18,0.88,0.12),
        ]
        var rgb = themes[(max(1, index) - 1) % themes.count]

        switch palette {
        case .vivid:
            break
        case .brightPastels:
            rgb = (
                rgb.0 * 0.58 + 0.42,
                rgb.1 * 0.58 + 0.42,
                rgb.2 * 0.58 + 0.42
            )
        case .mediumTones:
            rgb = (rgb.0 * 0.72, rgb.1 * 0.72, rgb.2 * 0.72)
        case .darkTones:
            rgb = (rgb.0 * 0.44, rgb.1 * 0.44, rgb.2 * 0.44)
        }

        let body = SKColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        let bright = SKColor(
            red: min(1, rgb.0 * 0.48 + 0.52),
            green: min(1, rgb.1 * 0.48 + 0.52),
            blue: min(1, rgb.2 * 0.48 + 0.52), alpha: 0.98)
        let shadow = SKColor(red: rgb.0 * 0.16, green: rgb.1 * 0.16, blue: rgb.2 * 0.16, alpha: 1)
        let glow = SKColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 0.25)
        return AquaDotWallMaterial(body: body, bright: bright, shadow: shadow, glow: glow)
    }
}

/// Phase 2.1 maze renderer: semantic correction + OG pixel detail.
///
/// The strategy-guide captures make an important distinction that Phase 2's
/// first pass obscured: numeric wall descriptors form the *thin outline wall*
/// system, while `X` fields form the large glossy/solid wall structures. The old
/// renderer drew both as thick tubes, which is why the maze silhouette felt wrong
/// even though the underlying maze data was authentic.
///
/// Numeric walls now use the exact recovered `(lines)` atlas frame mapping from
/// `_drawLineIntersections`. Contiguous `X` regions are rendered as a batched,
/// scalable recreation of the 9w/10w glossy wall material. This cuts thousands
/// of per-cell SKShapeNodes down to a handful of static paths while matching the
/// visual hierarchy visible in original screenshots.
final class AquaDotWallRenderer {
    let mode: AquaDotGraphicsMode
    let material: AquaDotWallMaterial
    let themeIndex: Int
    let palette: AquaDotWallPalette
    private let originalLineAtlas: SKTexture

    init(
        mode: AquaDotGraphicsMode,
        themeIndex: Int,
        palette: AquaDotWallPalette = .vivid
    ) {
        self.mode = mode
        self.themeIndex = max(1, min(13, themeIndex))
        self.palette = palette
        self.material = .originalTheme(themeIndex, palette: palette)
        self.originalLineAtlas = AquaDotAssetProvider(mode: mode)
            .wallLineAtlasTexture(themeIndex: max(1, min(13, themeIndex)))
    }

    func render(topology: AquaDotMazeTopology, layout: AquaDotMazeLayout, into root: SKNode) {
        let blocked = Set(topology.wallCells.compactMap { cell -> GridPosition? in
            if case .blocked = cell.kind { return GridPosition(x: cell.x, y: cell.y) }
            return nil
        })

        renderSolidNetwork(blocked, layout: layout, into: root)

        if mode == .remastered {
            renderRemasteredLineNetwork(
                topology.wallCells,
                layout: layout,
                into: root
            )
        } else {
            for cell in topology.wallCells {
                guard case let .wall(geometry) = cell.kind else { continue }
                renderOriginalLineFrame(
                    geometry,
                    center: layout.wallCellCenter(x: cell.x, y: cell.y),
                    pitch: layout.pitch,
                    into: root
                )
            }
        }
    }

    /// Batched solid-wall network. One path per bevel layer replaces the Phase 2
    /// design that generated several shape nodes for every X cell.
    private func renderSolidNetwork(
        _ blocked: Set<GridPosition>,
        layout: AquaDotMazeLayout,
        into root: SKNode
    ) {
        guard !blocked.isEmpty else { return }

        let path = CGMutablePath()
        var isolated: [CGPoint] = []

        for position in blocked {
            let center = layout.wallCellCenter(x: position.x, y: position.y)
            let east = GridPosition(x: position.x + 1, y: position.y)
            let north = GridPosition(x: position.x, y: position.y + 1)
            let west = GridPosition(x: position.x - 1, y: position.y)
            let south = GridPosition(x: position.x, y: position.y - 1)

            var hasNeighbor = false
            if blocked.contains(east) {
                hasNeighbor = true
                path.move(to: center)
                path.addLine(to: layout.wallCellCenter(x: east.x, y: east.y))
            }
            if blocked.contains(north) {
                hasNeighbor = true
                path.move(to: center)
                path.addLine(to: layout.wallCellCenter(x: north.x, y: north.y))
            }
            if blocked.contains(west) || blocked.contains(south) { hasNeighbor = true }
            if !hasNeighbor { isolated.append(center) }
        }

        let width = layout.pitch * 0.78

        let shadow = SKShapeNode(path: path)
        shadow.strokeColor = material.shadow
        shadow.lineWidth = width + 3.8
        shadow.lineCap = .round
        shadow.lineJoin = .round
        shadow.isAntialiased = true
        shadow.position = CGPoint(x: 1.35, y: -1.45)
        shadow.zPosition = 1.0
        root.addChild(shadow)

        let body = SKShapeNode(path: path)
        body.strokeColor = material.body
        body.lineWidth = width
        body.lineCap = .round
        body.lineJoin = .round
        body.isAntialiased = true
        body.glowWidth = mode == .remastered ? 0.9 : 0
        body.zPosition = 1.05
        root.addChild(body)

        // The original 9w/10w sheets carry a strong top-left glossy bevel. This
        // offset highlight reproduces that construction at Retina resolution.
        let highlight = SKShapeNode(path: path)
        highlight.strokeColor = material.bright.withAlphaComponent(0.72)
        highlight.lineWidth = width * 0.27
        highlight.lineCap = .round
        highlight.lineJoin = .round
        highlight.isAntialiased = true
        highlight.position = CGPoint(x: -width * 0.16, y: width * 0.18)
        highlight.zPosition = 1.10
        root.addChild(highlight)

        let lowerShade = SKShapeNode(path: path)
        lowerShade.strokeColor = material.shadow.withAlphaComponent(0.38)
        lowerShade.lineWidth = width * 0.22
        lowerShade.lineCap = .round
        lowerShade.lineJoin = .round
        lowerShade.isAntialiased = true
        lowerShade.position = CGPoint(x: width * 0.17, y: -width * 0.18)
        lowerShade.zPosition = 1.11
        root.addChild(lowerShade)

        for center in isolated {
            let side = width
            let node = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: side * 0.34)
            node.position = center
            node.fillColor = material.body
            node.strokeColor = material.bright.withAlphaComponent(0.72)
            node.lineWidth = max(1, side * 0.12)
            node.isAntialiased = true
            node.zPosition = 1.08
            root.addChild(node)
        }
    }

    /// Retina/remastered numeric-wall renderer.
    ///
    /// The four direction bits are recovered game data, so this changes only
    /// presentation fidelity: each wall reaches the same N/E/S/W positions as
    /// the original 40x40 atlas frame, but SpriteKit rasterizes the vector path
    /// at the display backing scale instead of enlarging the recovered pixels.
    private func renderRemasteredLineNetwork(
        _ cells: [AquaDotWallCell],
        layout: AquaDotMazeLayout,
        into root: SKNode
    ) {
        let path = CGMutablePath()
        let reach = layout.pitch

        for cell in cells {
            guard case let .wall(geometry) = cell.kind else { continue }
            let center = layout.wallCellCenter(x: cell.x, y: cell.y)

            func arm(dx: CGFloat, dy: CGFloat) {
                path.move(to: center)
                path.addLine(
                    to: CGPoint(
                        x: center.x + dx * reach,
                        y: center.y + dy * reach
                    )
                )
            }

            if geometry.contains(.north) { arm(dx: 0, dy: 1) }
            if geometry.contains(.east)  { arm(dx: 1, dy: 0) }
            if geometry.contains(.south) { arm(dx: 0, dy: -1) }
            if geometry.contains(.west)  { arm(dx: -1, dy: 0) }
        }

        let bloom = SKShapeNode(path: path)
        bloom.strokeColor = material.body.withAlphaComponent(0.22)
        bloom.lineWidth = 4.0
        bloom.glowWidth = 3.5
        bloom.lineCap = .round
        bloom.lineJoin = .round
        bloom.isAntialiased = true
        bloom.zPosition = 1.94
        root.addChild(bloom)

        let shadow = SKShapeNode(path: path)
        shadow.strokeColor = material.shadow.withAlphaComponent(0.74)
        shadow.lineWidth = 2.0
        shadow.lineCap = .round
        shadow.lineJoin = .round
        shadow.isAntialiased = true
        shadow.position = CGPoint(x: 0.65, y: -0.65)
        shadow.zPosition = 1.96
        root.addChild(shadow)

        let line = SKShapeNode(path: path)
        line.strokeColor = material.body
        line.lineWidth = 1.9
        line.lineCap = .round
        line.lineJoin = .round
        line.isAntialiased = true
        line.zPosition = 2.0
        root.addChild(line)

        let highlight = SKShapeNode(path: path)
        highlight.strokeColor = material.bright.withAlphaComponent(0.72)
        highlight.lineWidth = 0.75
        highlight.lineCap = .round
        highlight.lineJoin = .round
        highlight.isAntialiased = true
        highlight.position = CGPoint(x: -0.30, y: 0.30)
        highlight.zPosition = 2.02
        root.addChild(highlight)
    }

    /// Exact recovered numeric-wall pixel frame. There is deliberately no thick
    /// procedural tube under this sprite anymore; the atlas itself is the wall.
    private func renderOriginalLineFrame(
        _ geometry: AquaDotWallGeometry,
        center: CGPoint,
        pitch: CGFloat,
        into root: SKNode
    ) {
        guard let frame = geometry.recoveredGameLineAtlasFrameIndex else { return }

        let columns: CGFloat = 4
        let rows: CGFloat = 13
        let column = CGFloat(frame % 4)
        let rowFromTop = CGFloat(frame / 4)
        let rect = CGRect(
            x: column / columns,
            y: 1 - (rowFromTop + 1) / rows,
            width: 1 / columns,
            height: 1 / rows
        )

        let frameTexture = SKTexture(rect: rect, in: originalLineAtlas)
        frameTexture.filteringMode = mode == .original ? .nearest : .linear

        let detail = SKSpriteNode(texture: frameTexture)
        detail.size = CGSize(width: pitch * 2, height: pitch * 2)
        detail.position = center
        detail.color = material.body
        detail.colorBlendFactor = mode == .remastered ? 0.86 : 0.76
        detail.alpha = 1
        detail.zPosition = 2.0
        root.addChild(detail)
    }
}
