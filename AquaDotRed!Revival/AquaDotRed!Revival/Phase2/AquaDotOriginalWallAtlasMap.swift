import Foundation

/// Exact frame indices recovered from the game's `_drawLineIntersections` path for
/// the 4x13, 40px-per-frame `(lines)` wall atlas. This is separate from the editor
/// tool-frame order stored on AquaDotWallGeometry.
extension AquaDotWallGeometry {
    var recoveredGameLineAtlasFrameIndex: Int? {
        switch rawValue {
        case 0x08: 0   // N
        case 0x01: 1   // E
        case 0x02: 2   // S
        case 0x04: 3   // W
        case 0x09: 8   // N+E
        case 0x03: 9   // E+S
        case 0x06: 10  // S+W
        case 0x0C: 11  // W+N
        case 0x0B: 24  // N+E+S
        case 0x07: 25  // E+S+W
        case 0x0E: 26  // N+S+W
        case 0x0D: 27  // N+E+W
        case 0x05: 40  // E+W straight
        case 0x0A: 41  // N+S straight
        case 0x0F: 44  // all four
        default: nil
        }
    }
}
