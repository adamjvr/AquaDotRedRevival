import Foundation
import SpriteKit

struct AquaDotWallMaterial {
    let body: SKColor
    let bright: SKColor
    let shadow: SKColor
    let glow: SKColor

    static func originalTheme(_ index: Int) -> AquaDotWallMaterial {
        // The shipped wall atlases are grayscale bevel material; strategy-guide
        // captures show the game colorizing that material into vivid themes.
        // These 13 palettes preserve that OG visual language while the exact
        // historical per-level color table remains a future binary-match target.
        let themes: [(Double, Double, Double)] = [
            (0.12,0.82,0.08), (0.55,0.16,0.92), (0.94,0.76,0.08),
            (0.12,0.72,0.95), (0.94,0.34,0.08), (0.94,0.12,0.55),
            (0.18,0.86,0.72), (0.38,0.46,1.00), (0.72,0.92,0.16),
            (0.90,0.22,0.22), (0.42,0.90,1.00), (0.82,0.40,0.96),
            (0.18,0.88,0.12),
        ]
        let rgb = themes[(max(1, index) - 1) % themes.count]
        let body = SKColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
        let bright = SKColor(
            red: min(1, rgb.0 * 0.55 + 0.55),
            green: min(1, rgb.1 * 0.55 + 0.55),
            blue: min(1, rgb.2 * 0.55 + 0.55), alpha: 0.95)
        let shadow = SKColor(red: rgb.0 * 0.20, green: rgb.1 * 0.20, blue: rgb.2 * 0.20, alpha: 1)
        let glow = SKColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 0.35)
        return AquaDotWallMaterial(body: body, bright: bright, shadow: shadow, glow: glow)
    }
}

/// Scalable reconstruction of the original beveled wall material.
/// Geometry comes only from recovered maze wall masks; this class changes pixels,
/// never collision/topology. The layered strokes mimic the original grayscale
/// bevel atlases at arbitrary Retina resolutions.
final class AquaDotWallRenderer {
    let mode: AquaDotGraphicsMode
    let material: AquaDotWallMaterial
    let themeIndex: Int
    private let originalLineAtlas: SKTexture

    init(mode: AquaDotGraphicsMode, themeIndex: Int) {
        self.mode = mode
        self.themeIndex = max(1, min(13, themeIndex))
        self.material = .originalTheme(themeIndex)
        self.originalLineAtlas = SKTexture(imageNamed: String(format: "P2_WallLineAtlas_%02d_Original", max(1, min(13, themeIndex))))
        self.originalLineAtlas.filteringMode = mode == .original ? .nearest : .linear
    }

    func render(topology: AquaDotMazeTopology, layout: AquaDotMazeLayout, into root: SKNode) {
        for cell in topology.wallCells {
            switch cell.kind {
            case .open, .wrapBoundary, .unknown:
                continue
            case .blocked:
                renderBlocked(center: layout.wallCellCenter(x: cell.x, y: cell.y), pitch: layout.pitch, into: root)
            case let .wall(geometry):
                renderGeometry(geometry, center: layout.wallCellCenter(x: cell.x, y: cell.y), pitch: layout.pitch, into: root)
            }
        }
    }

    private func renderGeometry(_ geometry: AquaDotWallGeometry, center: CGPoint, pitch: CGFloat, into root: SKNode) {
        let half = pitch * 0.54
        let path = CGMutablePath()
        func branch(_ point: CGPoint) {
            path.move(to: center)
            path.addLine(to: point)
        }
        if geometry.contains(.north) { branch(CGPoint(x: center.x, y: center.y + half)) }
        if geometry.contains(.east)  { branch(CGPoint(x: center.x + half, y: center.y)) }
        if geometry.contains(.south) { branch(CGPoint(x: center.x, y: center.y - half)) }
        if geometry.contains(.west)  { branch(CGPoint(x: center.x - half, y: center.y)) }

        let width = mode == .remastered ? pitch * 0.56 : pitch * 0.50
        addTubularPath(path, width: width, into: root)

        // A tiny central cap hides multi-branch seams and matches the rounded,
        // molded-junction appearance of the OG 9w/10w wall pieces.
        if geometry.rawValue.nonzeroBitCount >= 2 {
            let cap = SKShapeNode(circleOfRadius: width * 0.34)
            cap.position = center
            cap.fillColor = material.body
            cap.strokeColor = material.bright
            cap.lineWidth = max(0.8, width * 0.08)
            cap.glowWidth = mode == .remastered ? 1.6 : 0
            cap.zPosition = 2.15
            root.addChild(cap)
        }

        // Layer the *actual recovered game line-atlas frame* on top of the
        // scalable material. The frame index comes from `_drawLineIntersections`
        // disassembly. This preserves original bevel/junction micro-detail while
        // the procedural body stays Retina-clean and arbitrarily scalable.
        if let frame = geometry.recoveredGameLineAtlasFrameIndex {
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
            detail.color = material.bright
            detail.colorBlendFactor = mode == .remastered ? 0.72 : 0.45
            detail.alpha = mode == .remastered ? 0.66 : 0.90
            detail.zPosition = 2.18
            root.addChild(detail)
        }
    }

    private func renderBlocked(center: CGPoint, pitch: CGFloat, into root: SKNode) {
        let side = pitch * 0.78
        let shadow = SKShapeNode(rectOf: CGSize(width: side + 3, height: side + 3), cornerRadius: side * 0.24)
        shadow.position = CGPoint(x: center.x + 1.3, y: center.y - 1.5)
        shadow.fillColor = material.shadow
        shadow.strokeColor = .clear
        shadow.zPosition = 1.0
        root.addChild(shadow)

        let body = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: side * 0.23)
        body.position = center
        body.fillColor = material.body
        body.strokeColor = material.bright
        body.lineWidth = max(1, side * 0.09)
        body.glowWidth = mode == .remastered ? 2.2 : 0.4
        body.zPosition = 1.1
        root.addChild(body)

        let inset = SKShapeNode(rectOf: CGSize(width: side * 0.58, height: side * 0.58), cornerRadius: side * 0.16)
        inset.position = CGPoint(x: center.x - side * 0.04, y: center.y + side * 0.05)
        inset.fillColor = material.shadow.withAlphaComponent(0.42)
        inset.strokeColor = material.bright.withAlphaComponent(0.58)
        inset.lineWidth = max(0.7, side * 0.05)
        inset.zPosition = 1.2
        root.addChild(inset)
    }

    private func addTubularPath(_ path: CGPath, width: CGFloat, into root: SKNode) {
        let shadow = SKShapeNode(path: path)
        shadow.strokeColor = material.shadow
        shadow.lineWidth = width + 4
        shadow.lineCap = .round
        shadow.lineJoin = .round
        shadow.position = CGPoint(x: 1.4, y: -1.7)
        shadow.zPosition = 2.0
        root.addChild(shadow)

        let glow = SKShapeNode(path: path)
        glow.strokeColor = material.glow
        glow.lineWidth = width + 6
        glow.lineCap = .round
        glow.lineJoin = .round
        glow.glowWidth = mode == .remastered ? 4.0 : 0
        glow.zPosition = 2.02
        root.addChild(glow)

        let body = SKShapeNode(path: path)
        body.strokeColor = material.body
        body.lineWidth = width
        body.lineCap = .round
        body.lineJoin = .round
        body.zPosition = 2.05
        root.addChild(body)

        let inner = SKShapeNode(path: path)
        inner.strokeColor = material.shadow.withAlphaComponent(0.38)
        inner.lineWidth = width * 0.53
        inner.lineCap = .round
        inner.lineJoin = .round
        inner.zPosition = 2.08
        root.addChild(inner)

        let highlight = SKShapeNode(path: path)
        highlight.strokeColor = material.bright.withAlphaComponent(0.78)
        highlight.lineWidth = max(1.0, width * 0.12)
        highlight.lineCap = .round
        highlight.lineJoin = .round
        highlight.position = CGPoint(x: -width * 0.11, y: width * 0.12)
        highlight.zPosition = 2.12
        root.addChild(highlight)
    }
}
