import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum AquaDotLevelLoaderError: Error, CustomStringConvertible {
    case unknownLevel(String)
    case resourceMissing(String)
    case catalogMismatch(String)

    var description: String {
        switch self {
        case let .unknownLevel(name):
            return "Original AquaDot level is not in the recovered catalog: \(name)"
        case let .resourceMissing(name):
            return "Recovered AquaDot level resource is missing from the app bundle: \(name)"
        case let .catalogMismatch(message):
            return "Recovered AquaDot level failed catalog verification: \(message)"
        }
    }
}

struct AquaDotLevelLoader {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func load(named originalName: String) throws -> (record: AquaDotLevelRecord, maze: AquaDotMaze) {
        guard let record = AquaDotOriginalLevelCatalog.record(named: originalName) else {
            throw AquaDotLevelLoaderError.unknownLevel(originalName)
        }
        return (record, try load(record: record))
    }

    func load(record: AquaDotLevelRecord) throws -> AquaDotMaze {
        let data: Data

        // Primary shipping path: the untouched maze bytes live in an Xcode data
        // asset. NSDataAsset is available in both AppKit and UIKit, so the exact
        // same original content is selected on native Mac and iPad.
        if let dataAsset = NSDataAsset(name: record.resourceBaseName, bundle: bundle) {
            data = dataAsset.data
        } else if let url = resourceURL(for: record) {
            // Developer/preservation fallback for loose resource copies.
            data = try Data(contentsOf: url)
        } else {
            throw AquaDotLevelLoaderError.resourceMissing(record.originalName)
        }

        let maze = try AquaDotMazeParser.parse(data: data, requireValidChecksum: true)

        guard maze.storedChecksum == record.checksum,
              maze.width == record.width,
              maze.height == record.height else {
            throw AquaDotLevelLoaderError.catalogMismatch(
                "\(record.originalName): expected CRC/dimensions \(record.checksum) \(record.width)x\(record.height), got \(maze.storedChecksum) \(maze.width)x\(maze.height)"
            )
        }

        return maze
    }

    private func resourceURL(for record: AquaDotLevelRecord) -> URL? {
        // PBXFileSystemSynchronizedRootGroup normally preserves these as resources,
        // but Xcode can flatten copied resources depending on project settings.
        // Support both layouts so the original data remains robustly loadable.
        let subdirectories: [String?] = [
            "OriginalContent/Levels",
            "Levels",
            nil
        ]

        for subdirectory in subdirectories {
            if let url = bundle.url(
                forResource: record.resourceBaseName,
                withExtension: "aquadotmaze",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return bundle.urls(forResourcesWithExtension: "aquadotmaze", subdirectory: nil)?
            .first { $0.deletingPathExtension().lastPathComponent == record.resourceBaseName }
    }
}
