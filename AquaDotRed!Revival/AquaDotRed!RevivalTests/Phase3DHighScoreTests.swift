import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase3DHighScoreTests {
    @Test func terminalScoreCanBePersistedBeforeNameEntryAndRenamedLater() throws {
        let suite = "AquaDotPhase3D.HighScore.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = AquaDotHighScoreStore(defaults: defaults)
        let pending = store.record(score: 42_000, levelsCleared: 7)

        // Crash-safe first step: the score already exists even before a name is entered.
        #expect(store.bestEver(limit: 1).first?.id == pending.id)
        #expect(store.bestEver(limit: 1).first?.name == "anonymous")

        let named = try #require(store.rename(recordID: pending.id, name: "  Ada  "))
        #expect(named.name == "Ada")

        // Reopen the same preference suite to prove the name mutation is durable.
        let reopened = AquaDotHighScoreStore(defaults: defaults)
        #expect(reopened.bestEver(limit: 1).first?.name == "Ada")
        #expect(reopened.bestEver(limit: 1).first?.score == 42_000)
    }

    @Test func blankNameKeepsTheHistoricalFallbackLabel() throws {
        let suite = "AquaDotPhase3D.HighScore.Blank.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = AquaDotHighScoreStore(defaults: defaults)
        let pending = store.record(score: 1_234, levelsCleared: 2)
        let renamed = try #require(store.rename(recordID: pending.id, name: "   \n  "))
        #expect(renamed.name == "anonymous")
    }
}
