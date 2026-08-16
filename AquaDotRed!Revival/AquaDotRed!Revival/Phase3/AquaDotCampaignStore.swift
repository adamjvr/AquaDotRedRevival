import Foundation

/// The original binary's beginning-of-level autosave semantics are preserved:
/// a mid-level save resumes from the beginning of that maze; after completion,
/// the already-selected next maze is the checkpoint.
///
/// Schema 2 adds random-campaign selector state. Schema-1 Phase-3 saves remain
/// readable and are migrated by MazeGameScene without changing their current maze.
struct AquaDotCampaignCheckpoint: Codable, Equatable, Sendable {
    static let schemaVersion = 2
    static let readableSchemaVersions: Set<Int> = [1, 2]

    var version: Int = schemaVersion
    var levelIndex: Int
    var score: Int
    var multiplier: Int
    var lives: Int
    var levelsCleared: Int
    var savedAt: Date
    var selectorState: AquaDotCampaignSelectorState? = nil

    var carry: AquaDotRunCarry {
        AquaDotRunCarry(
            score: score,
            bonus: 0,
            multiplier: multiplier,
            lives: lives,
            levelsCleared: levelsCleared
        )
    }
}

final class AquaDotCampaignStore {
    static let shared = AquaDotCampaignStore()

    private let defaults: UserDefaults
    private let key = "revival.phase3.campaignCheckpoint"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> AquaDotCampaignCheckpoint? {
        guard let data = defaults.data(forKey: key),
              let checkpoint = try? decoder.decode(AquaDotCampaignCheckpoint.self, from: data),
              AquaDotCampaignCheckpoint.readableSchemaVersions.contains(checkpoint.version) else {
            return nil
        }
        return checkpoint
    }

    @discardableResult
    func saveBeginningOfLevel(
        levelIndex: Int,
        carry: AquaDotRunCarry,
        selectorState: AquaDotCampaignSelectorState? = nil
    ) -> AquaDotCampaignCheckpoint {
        let checkpoint = AquaDotCampaignCheckpoint(
            version: AquaDotCampaignCheckpoint.schemaVersion,
            levelIndex: max(0, levelIndex),
            score: max(0, carry.score),
            multiplier: max(1, carry.multiplier),
            lives: max(0, carry.lives),
            levelsCleared: max(0, carry.levelsCleared),
            savedAt: Date(),
            selectorState: selectorState
        )
        if let data = try? encoder.encode(checkpoint) {
            defaults.set(data, forKey: key)
        }
        return checkpoint
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
