import Foundation

/// The original binary explicitly describes its auto-save semantics:
/// a game saved mid-level resumes from the *beginning of that level*, while a
/// save made after completion resumes from the beginning of the next level.
/// This checkpoint intentionally stores campaign-level values only; it is not a
/// modern save-state of every dot/bug position.
struct AquaDotCampaignCheckpoint: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    var version: Int = schemaVersion
    var levelIndex: Int
    var score: Int
    var multiplier: Int
    var lives: Int
    var levelsCleared: Int
    var savedAt: Date

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
              checkpoint.version == AquaDotCampaignCheckpoint.schemaVersion else {
            return nil
        }
        return checkpoint
    }

    @discardableResult
    func saveBeginningOfLevel(levelIndex: Int, carry: AquaDotRunCarry) -> AquaDotCampaignCheckpoint {
        let checkpoint = AquaDotCampaignCheckpoint(
            levelIndex: max(0, levelIndex),
            score: max(0, carry.score),
            multiplier: max(1, carry.multiplier),
            lives: max(0, carry.lives),
            levelsCleared: max(0, carry.levelsCleared),
            savedAt: Date()
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
