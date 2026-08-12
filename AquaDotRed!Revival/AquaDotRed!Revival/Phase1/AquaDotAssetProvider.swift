import SpriteKit

/// Stable bridge between game concepts and recovered/remastered texture sets.
/// Remastered mode intentionally falls back to the original until a restored asset
/// exists; no gameplay code knows which texture resolution is active.
struct AquaDotAssetProvider {
    let mode: AquaDotGraphicsMode

    func playerTexture() -> SKTexture {
        texture(original: "OG_Aquadot_Red", remastered: "RM_Aquadot_Red")
    }

    func extraLifeTexture() -> SKTexture {
        texture(original: "OG_Extra_Aquadot", remastered: "RM_Extra_Aquadot")
    }

    func basicDotTexture() -> SKTexture {
        texture(original: "OG_Basic_Dot", remastered: "RM_Basic_Dot")
    }

    func munchDotTexture() -> SKTexture {
        texture(original: "OG_Inert_Dot", remastered: "RM_Inert_Dot")
    }

    func wrapTexture() -> SKTexture {
        texture(original: "OG_Wraparound_Warp", remastered: "RM_Wraparound_Warp")
    }

    func statusPanelTexture() -> SKTexture {
        texture(original: "OG_Status_Panel", remastered: "RM_Status_Panel")
    }

    private func texture(original: String, remastered: String) -> SKTexture {
        let requestedName = mode == .remastered ? remastered : original
        let requested = SKTexture(imageNamed: requestedName)

        // Asset lookup failure produces an empty texture instead of nil. Until all
        // RM_ assets exist, use the original explicitly as the authoritative source.
        let texture: SKTexture
        if mode == .remastered, requested.size() == .zero {
            texture = SKTexture(imageNamed: original)
        } else {
            texture = requested
        }

        texture.filteringMode = mode == .original ? .nearest : .linear
        return texture
    }
}
