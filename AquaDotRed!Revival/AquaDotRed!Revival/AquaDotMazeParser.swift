import Foundation

enum AquaDotMazeParserError: Error, Equatable, CustomStringConvertible {
    case unsupportedEncoding
    case invalidHeader
    case unsupportedVersion(String)
    case malformedMetadata(String)
    case invalidDimensions(width: Int, height: Int)
    case truncatedGrid(expected: Int, actual: Int)
    case invalidVertexRow(row: Int, expected: Int, actual: Int)
    case invalidEdgeRow(row: Int, expected: Int, actual: Int)
    case checksumMismatch(stored: UInt16, calculated: UInt16)

    var description: String {
        switch self {
        case .unsupportedEncoding: return "Maze is not valid MacRoman text."
        case .invalidHeader: return "Maze does not begin with the aquadot!red signature."
        case let .unsupportedVersion(version): return "Unsupported maze format version: \(version)."
        case let .malformedMetadata(field): return "Missing or malformed maze metadata: \(field)."
        case let .invalidDimensions(width, height): return "Invalid maze dimensions \(width)x\(height); recovered editor limits are 1...40 by 1...30."
        case let .truncatedGrid(expected, actual): return "Maze grid is truncated: expected \(expected) rows, got \(actual)."
        case let .invalidVertexRow(row, expected, actual): return "Vertex row \(row) has \(actual) tokens; expected \(expected)."
        case let .invalidEdgeRow(row, expected, actual): return "Edge row \(row) has \(actual) tokens; expected \(expected)."
        case let .checksumMismatch(stored, calculated): return "Checksum mismatch: stored \(stored), calculated \(calculated)."
        }
    }
}

struct AquaDotMazeParser {
    static let signature = "aquadot!red"
    static let formatPrefix = "Maze Description Format Version "
    static let supportedVersion = "1.0"

    static func parse(data: Data, requireValidChecksum: Bool = true) throws -> AquaDotMaze {
        guard let text = String(data: data, encoding: .macOSRoman) else {
            throw AquaDotMazeParserError.unsupportedEncoding
        }

        let normalizedText = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalizedText.components(separatedBy: "\n")

        guard lines.count >= 9, lines[0] == signature else {
            throw AquaDotMazeParserError.invalidHeader
        }

        guard lines[1].hasPrefix(formatPrefix) else {
            throw AquaDotMazeParserError.malformedMetadata("format version")
        }
        let version = String(lines[1].dropFirst(formatPrefix.count))
        guard version == supportedVersion else {
            throw AquaDotMazeParserError.unsupportedVersion(version)
        }

        let checksumInt = try decimalValue(prefix: "Checksum:", line: lines[3], field: "Checksum")
        guard let storedChecksum = UInt16(exactly: checksumInt) else {
            throw AquaDotMazeParserError.malformedMetadata("Checksum")
        }

        let width = try decimalValue(prefix: "Width:", line: lines[5], field: "Width")
        let height = try decimalValue(prefix: "Height:", line: lines[6], field: "Height")
        guard (1...40).contains(width), (1...30).contains(height) else {
            throw AquaDotMazeParserError.invalidDimensions(width: width, height: height)
        }

        let gridRowCount = (2 * height) + 1
        let gridStart = 8
        guard lines.count >= gridStart + gridRowCount else {
            throw AquaDotMazeParserError.truncatedGrid(
                expected: gridRowCount,
                actual: max(0, lines.count - gridStart)
            )
        }

        var vertexRows: [[AquaDotVertexToken]] = []
        var edgeRows: [[AquaDotEdgeToken]] = []

        for gridIndex in 0..<gridRowCount {
            let tokens = lines[gridStart + gridIndex].split(whereSeparator: { $0.isWhitespace }).map(String.init)

            if gridIndex.isMultiple(of: 2) {
                let expected = width + 1
                guard tokens.count == expected else {
                    throw AquaDotMazeParserError.invalidVertexRow(
                        row: gridIndex / 2,
                        expected: expected,
                        actual: tokens.count
                    )
                }
                vertexRows.append(tokens.map(AquaDotVertexToken.init(rawToken:)))
            } else {
                let expected = width
                guard tokens.count == expected else {
                    throw AquaDotMazeParserError.invalidEdgeRow(
                        row: gridIndex / 2,
                        expected: expected,
                        actual: tokens.count
                    )
                }
                edgeRows.append(tokens.map(AquaDotEdgeToken.init(rawToken:)))
            }
        }

        guard let widthMarker = data.range(of: Data("Width:".utf8))?.lowerBound else {
            throw AquaDotMazeParserError.malformedMetadata("Width")
        }
        let checksumPayload = normalizeLineEndings(in: data.subdata(in: widthMarker..<data.endIndex))
        let calculatedChecksum = aquaDotCRC16(checksumPayload)

        if requireValidChecksum, storedChecksum != calculatedChecksum {
            throw AquaDotMazeParserError.checksumMismatch(stored: storedChecksum, calculated: calculatedChecksum)
        }

        return AquaDotMaze(
            version: version,
            storedChecksum: storedChecksum,
            calculatedChecksum: calculatedChecksum,
            width: width,
            height: height,
            vertexRows: vertexRows,
            edgeRows: edgeRows
        )
    }

    static func aquaDotCRC16(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0xFFFF

        for byte in data {
            var current = byte
            for _ in 0..<8 {
                let crcBit = crc & 1
                let dataBit = UInt16(current & 1)
                if crcBit != dataBit {
                    crc = (crc >> 1) ^ 0x8408
                } else {
                    crc >>= 1
                }
                current >>= 1
            }
        }

        crc = ~crc
        return (crc << 8) | (crc >> 8)
    }

    private static func decimalValue(prefix: String, line: String, field: String) throws -> Int {
        guard line.hasPrefix(prefix), let value = Int(line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)) else {
            throw AquaDotMazeParserError.malformedMetadata(field)
        }
        return value
    }

    private static func normalizeLineEndings(in data: Data) -> Data {
        var result = Data()
        result.reserveCapacity(data.count)

        var index = data.startIndex
        while index < data.endIndex {
            let byte = data[index]
            if byte == 0x0D {
                let next = data.index(after: index)
                if next < data.endIndex, data[next] == 0x0A {
                    index = next
                }
                result.append(0x0A)
            } else {
                result.append(byte)
            }
            index = data.index(after: index)
        }
        return result
    }
}
