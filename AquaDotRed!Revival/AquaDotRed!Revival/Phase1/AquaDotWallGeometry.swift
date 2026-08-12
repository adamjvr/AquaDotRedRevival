import Foundation

/// Exact four-direction wall bitfield recovered from the AquaDot editor.
///
/// Evidence comes from two independent sources:
/// 1. the editor i386 wall-neighbor routines, and
/// 2. corpus-wide consistency checks across all 205 shipped standard mazes.
///
/// The raw numeric tokens stored in maze files are already this bit mask. They are
/// *not* sprite frame numbers.
struct AquaDotWallGeometry: OptionSet, Hashable, Codable, Sendable {
    let rawValue: UInt8

    static let east  = AquaDotWallGeometry(rawValue: 0x01)
    static let south = AquaDotWallGeometry(rawValue: 0x02)
    static let west  = AquaDotWallGeometry(rawValue: 0x04)
    static let north = AquaDotWallGeometry(rawValue: 0x08)

    static let all: AquaDotWallGeometry = [.north, .east, .south, .west]

    init(rawValue: UInt8) {
        self.rawValue = rawValue & 0x0F
    }

    init?(numericMazeToken value: Int) {
        guard (1...15).contains(value) else { return nil }
        self.init(rawValue: UInt8(value))
    }

    /// Recovered editor sprite/tool-frame order. This is useful when matching the
    /// old wall sprite atlases during the remaster, but gameplay uses `rawValue`.
    var recoveredEditorFrameIndex: Int? {
        switch rawValue {
        case 0x08: 0
        case 0x01: 1
        case 0x02: 2
        case 0x04: 3
        case 0x09: 4
        case 0x03: 5
        case 0x06: 6
        case 0x0C: 7
        case 0x07: 8
        case 0x0E: 9
        case 0x0D: 10
        case 0x0B: 11
        case 0x05: 12
        case 0x0A: 13
        case 0x0F: 14
        default: nil
        }
    }
}

/// A cell in one interleaved wall row of the original maze format.
struct AquaDotWallCell: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case open
        case wall(AquaDotWallGeometry)
        case blocked
        case wrapBoundary
        case unknown(String)
    }

    let x: Int
    let y: Int
    let kind: Kind

    init(x: Int, y: Int, token: AquaDotEdgeToken) {
        self.x = x
        self.y = y

        switch token {
        case .empty:
            kind = .open
        case .blocked:
            kind = .blocked
        case .wrapBoundary:
            kind = .wrapBoundary
        case let .wall(value):
            if let geometry = AquaDotWallGeometry(numericMazeToken: value) {
                kind = .wall(geometry)
            } else {
                kind = .unknown(String(value))
            }
        case let .unknown(raw):
            kind = .unknown(raw)
        }
    }
}
