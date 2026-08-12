import Foundation

/// Tiny deterministic generator used only to make Phase 2 reconstruction/debugging
/// reproducible. The original game also used random goodie and wall-theme choices;
/// exact RNG details remain a later binary-matching target.
struct AquaDotSeededRandom: Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xA51A_D07A_5EED : seed
    }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func int(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(nextUInt64() % UInt64(upperBound))
    }

    mutating func double() -> Double {
        Double(nextUInt64() >> 11) / Double(1 << 53)
    }
}
