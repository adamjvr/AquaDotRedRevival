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

/// Texture bridge for recovered/restored AquaDot art. Original mode keeps
/// nearest-neighbor presentation; Remastered mode uses the restored high-res copy.
struct AquaDotAssetProvider {
    let mode: AquaDotGraphicsMode

    func playerTexture(appearance: AquaDotPlayerAppearance = .normal) -> SKTexture {
        modeTexture(base: "P2_Player_\(appearance.rawValue)")
    }

    /// Phase 4G separates strategy from appearance exactly as the original
    /// `setupEnemy` did. Neon substitutes the sprite only; it does not alter AI.
    func bugTexture(
        personality: AquaDotBugPersonality,
        neonAppearance: Bool = false
    ) -> SKTexture {
        let key: String
        if neonAppearance {
            key = "Neon"
        } else {
            switch personality {
            case .hunter: key = "Hunter"
            case .blocker: key = "Blocker"
            case .sneaker: key = "Sneaker"
            case .houndDog: key = "HoundDog"
            case .loneWolf: key = "LoneWolf"
            case .protector: key = "Protector"
            case .mantis: key = "Mantis"
            case .hermit: key = "Hermit"
            case .neon: key = "Neon" // compatibility-only legacy state
            }
        }
        return modeTexture(base: "P2_Bug_\(key)")
    }

    func dotTexture(kind: AquaDotDotKind) -> SKTexture {
        switch kind {
        case .normal:
            if mode == .remastered {
                return AquaDotTextureCache.texture(
                    named: "P4E_Dot_Basic_Remastered",
                    filtering: .linear
                )
            }
            return legacyTexture(original: "OG_Basic_Dot", remastered: "OG_Basic_Dot")
        case .candy:
            return modeTexture(base: "P2_Dot_Candy")
        case .crusty:
            return modeTexture(base: "P2_Dot_Crusty")
        case .petrified:
            return modeTexture(base: "P2_Dot_Petrified")
        }
    }

    func munchDotTexture() -> SKTexture {
        legacyTexture(original: "OG_Inert_Dot", remastered: "OG_Inert_Dot")
    }

    func goodieTexture(kind: AquaDotGoodieKind, multiplier: Int = 2) -> SKTexture {
        switch kind {
        case .yummy: return modeTexture(base: "P2_Goodie_Yummy")
        case .yuk: return modeTexture(base: "P2_Goodie_Yuk")
        case .bonus: return modeTexture(base: "P2_Goodie_Bonus")
        case .multiplier:
            let clamped = max(2, min(5, multiplier))
            return modeTexture(base: "P2_Goodie_Multiplier\(clamped)")
        }
    }

    /// Recovered Sprout-Dots-Big artwork. Good is the original green frame; bad
    /// is the original purple frame. Phase 3B uses it for the MazeSprouts bridge.
    func sproutTexture(beneficial: Bool) -> SKTexture {
        modeTexture(base: beneficial ? "P3B_Sprout_Good" : "P3B_Sprout_Bad")
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

    private func modeTexture(base: String) -> SKTexture {
        let suffix = mode == .remastered ? "Remastered" : "Original"
        return AquaDotTextureCache.texture(
            named: "\(base)_\(suffix)",
            filtering: mode == .original ? .nearest : .linear
        )
    }

    private func legacyTexture(original: String, remastered: String) -> SKTexture {
        AquaDotTextureCache.texture(
            named: mode == .remastered ? remastered : original,
            filtering: mode == .original ? .nearest : .linear
        )
    }
}
