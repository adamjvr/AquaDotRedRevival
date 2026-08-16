import Foundation

struct AquaDotHighScoreRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var score: Int
    var levelsCleared: Int
    var date: Date

    init(name: String = "anonymous", score: Int, levelsCleared: Int, date: Date = Date()) {
        self.id = UUID()
        self.name = name.isEmpty ? "anonymous" : name
        self.score = max(0, score)
        self.levelsCleared = max(0, levelsCleared)
        self.date = date
    }
}

/// Persistent high-score storage for the revived front end. The original game
/// had separate "Today's Best" and "Best Scores Ever" presentation; both are
/// reconstructed here from one durable score history.
final class AquaDotHighScoreStore {
    static let shared = AquaDotHighScoreStore()

    private let defaults: UserDefaults
    private let key = "revival.phase3.highScores"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    var allRecords: [AquaDotHighScoreRecord] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? decoder.decode([AquaDotHighScoreRecord].self, from: data) else {
            return []
        }
        return decoded.sorted(by: Self.scoreOrder)
    }

    func bestEver(limit: Int = 10) -> [AquaDotHighScoreRecord] {
        Array(allRecords.prefix(max(0, limit)))
    }

    func todaysBest(limit: Int = 5, now: Date = Date()) -> [AquaDotHighScoreRecord] {
        Array(allRecords.filter { calendar.isDate($0.date, inSameDayAs: now) }.prefix(max(0, limit)))
    }

    @discardableResult
    func record(name: String = "anonymous", score: Int, levelsCleared: Int, date: Date = Date()) -> AquaDotHighScoreRecord {
        let record = AquaDotHighScoreRecord(name: name, score: score, levelsCleared: levelsCleared, date: date)
        var records = allRecords
        records.append(record)
        records.sort(by: Self.scoreOrder)
        // Retain a generous history so "Today's Best" remains useful without
        // allowing preferences storage to grow forever.
        records = Array(records.prefix(100))
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: key)
        }
        return record
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private static func scoreOrder(_ lhs: AquaDotHighScoreRecord, _ rhs: AquaDotHighScoreRecord) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        if lhs.levelsCleared != rhs.levelsCleared { return lhs.levelsCleared > rhs.levelsCleared }
        return lhs.date < rhs.date
    }
}
