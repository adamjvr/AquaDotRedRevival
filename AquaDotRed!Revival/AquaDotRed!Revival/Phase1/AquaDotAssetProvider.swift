import Foundation
import SpriteKit


private enum AquaDotTextureCache {
    static let cache = NSCache<NSString, SKTexture>()

    static func texture(named name: String, filtering: SKTextureFilteringMode) -> SKTexture {
        let key = "\(name)|\(filtering == .nearest ? "nearest" : "linear")" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = filtering
        cache.setObject(texture, forKey: key)
        return texture
    }
}

enum AquaDotPlayerAppearance: String, Sendable {
    case normal = "Normal"
    case munch = "Munch"
    case yummy = "Yummy"
    case yuk = "Yuk"
    case damaged = "Damaged"
}

/// Phase 2 texture bridge. Every remastered texture is derived from recovered OG
/// art; Original mode retains nearest-neighbor presentation of the preservation
/// assets, while Remastered mode uses cleaned/high-resolution equivalents.
struct AquaDotAssetProvider {
    let mode: AquaDotGraphicsMode

    func playerTexture(appearance: AquaDotPlayerAppearance = .normal) -> SKTexture {
        p2Texture(base: "P2_Player_\(appearance.rawValue)")
    }

    func bugTexture(personality: AquaDotBugPersonality) -> SKTexture {
        let key: String
        switch personality {
        case .hunter: key = "Hunter"
        case .blocker: key = "Blocker"
        case .sneaker: key = "Sneaker"
        case .houndDog: key = "HoundDog"
        }
        return p2Texture(base: "P2_Bug_\(key)")
    }

    func dotTexture(kind: AquaDotDotKind) -> SKTexture {
        switch kind {
        case .normal:
            return legacyTexture(original: "OG_Basic_Dot", remastered: "OG_Basic_Dot")
        case .candy:
            return p2Texture(base: "P2_Dot_Candy")
        case .crusty:
            return p2Texture(base: "P2_Dot_Crusty")
        case .petrified:
            return p2Texture(base: "P2_Dot_Petrified")
        }
    }

    func munchDotTexture() -> SKTexture {
        // Phase 2 renders the characteristic expanding/pulsing Munch ring in code;
        // this recovered inert sprite is retained as Original-mode fallback.
        legacyTexture(original: "OG_Inert_Dot", remastered: "OG_Inert_Dot")
    }

    func goodieTexture(kind: AquaDotGoodieKind, multiplier: Int = 2) -> SKTexture {
        switch kind {
        case .yummy: return p2Texture(base: "P2_Goodie_Yummy")
        case .yuk: return p2Texture(base: "P2_Goodie_Yuk")
        case .bonus: return p2Texture(base: "P2_Goodie_Bonus")
        case .multiplier:
            let clamped = max(2, min(5, multiplier))
            return p2Texture(base: "P2_Goodie_Multiplier\(clamped)")
        }
    }

    func extraLifeTexture() -> SKTexture {
        legacyTexture(original: "OG_Extra_Aquadot", remastered: "OG_Extra_Aquadot")
    }

    func wrapTexture() -> SKTexture {
        legacyTexture(original: "OG_Wraparound_Warp", remastered: "OG_Wraparound_Warp")
    }

    func statusPanelTexture() -> SKTexture {
        legacyTexture(original: "OG_Status_Panel", remastered: "OG_Status_Panel")
    }

    func wallLineAtlasTexture(themeIndex: Int) -> SKTexture {
        let clamped = max(1, min(13, themeIndex))
        return AquaDotTextureCache.texture(
            named: String(format: "P2_WallLineAtlas_%02d_Original", clamped),
            filtering: mode == .original ? .nearest : .linear
        )
    }

    private func p2Texture(base: String) -> SKTexture {
        let suffix = mode == .remastered ? "Remastered" : "Original"
        return AquaDotTextureCache.texture(
            named: "\(base)_\(suffix)",
            filtering: mode == .original ? .nearest : .linear
        )
    }

    private func legacyTexture(original: String, remastered: String) -> SKTexture {
        return AquaDotTextureCache.texture(
            named: mode == .remastered ? remastered : original,
            filtering: mode == .original ? .nearest : .linear
        )
    }
}
