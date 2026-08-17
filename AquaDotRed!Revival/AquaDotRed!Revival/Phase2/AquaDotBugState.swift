import Foundation

enum AquaDotBugPersonality: String, Codable, CaseIterable, Sendable {
    case hunter
    case blocker
    case sneaker
    case houndDog
    case loneWolf
    case protector
    case mantis
    case hermit

    /// Compatibility-only value retained so older Phase-3 source/checkpoints can
    /// still decode. Phase 4G proves Neon was a sprite disguise, not a strategy,
    /// and new levels never generate this case.
    case neon

    /// Ordinary strategies available without the full-version advanced behavior.
    /// Lone Wolf was missing from the Revival before Phase 4G.
    static let basicRoster: [AquaDotBugPersonality] = [
        .hunter, .blocker, .sneaker, .houndDog, .loneWolf,
    ]

    /// The strategy guide marks only these three *strategies* as advanced. Neon is
    /// separately represented by `isNeonAppearance` because the executable keeps
    /// the underlying strategy unchanged when it substitutes Neon graphics.
    static let advancedRoster: [AquaDotBugPersonality] = [
        .protector, .mantis, .hermit,
    ]

    /// Legacy decoder support for the old `.neon + emulatedPersonality` model.
    static let neonEmulationCandidates: [AquaDotBugPersonality] = [
        .hunter, .blocker, .sneaker, .houndDog, .loneWolf,
        .protector, .mantis, .hermit,
    ]
}

enum AquaDotBugMode: String, Codable, Sendable {
    case hunting
    case frightened
    case returningHome
}

struct AquaDotBugState: Equatable, Sendable {
    let id: Character
    let personality: AquaDotBugPersonality
    let homeNode: GridPosition
    var currentNode: GridPosition
    var nextNode: GridPosition?
    var segmentProgress: Double
    var movementDirection: AquaDotDirection?
    var mode: AquaDotBugMode
    var recoveryDelay: Double

    /// Phase 4G: exact recovered Neon architecture. `personality` remains the
    /// actual strategy; this flag changes only the drawn bug sprite.
    var isNeonAppearance: Bool

    // Legacy Phase 3B state retained for source/save compatibility. New Phase 4G
    // spawns never set emulatedPersonality because Neon is no longer generated as
    // a personality.
    var emulatedPersonality: AquaDotBugPersonality?
    var alertTimeRemaining: Double
    var awarenessCooldown: Double
    var turnsWhileAlerted: Int
    var lastSegmentWasTurn: Bool

    init(
        id: Character,
        personality: AquaDotBugPersonality,
        homeNode: GridPosition,
        currentNode: GridPosition,
        nextNode: GridPosition?,
        segmentProgress: Double,
        movementDirection: AquaDotDirection?,
        mode: AquaDotBugMode,
        recoveryDelay: Double,
        isNeonAppearance: Bool = false,
        emulatedPersonality: AquaDotBugPersonality? = nil,
        alertTimeRemaining: Double = 0,
        awarenessCooldown: Double = 0,
        turnsWhileAlerted: Int = 0,
        lastSegmentWasTurn: Bool = false
    ) {
        self.id = id
        self.personality = personality
        self.homeNode = homeNode
        self.currentNode = currentNode
        self.nextNode = nextNode
        self.segmentProgress = segmentProgress
        self.movementDirection = movementDirection
        self.mode = mode
        self.recoveryDelay = recoveryDelay
        self.isNeonAppearance = isNeonAppearance
        self.emulatedPersonality = emulatedPersonality
        self.alertTimeRemaining = alertTimeRemaining
        self.awarenessCooldown = awarenessCooldown
        self.turnsWhileAlerted = turnsWhileAlerted
        self.lastSegmentWasTurn = lastSegmentWasTurn
    }

    /// Phase 4G levels use `personality` directly. This fallback only preserves
    /// compatibility with pre-4G states that encoded Neon as a personality.
    var effectivePersonality: AquaDotBugPersonality {
        personality == .neon ? (emulatedPersonality ?? .hunter) : personality
    }

    func renderPosition() -> AquaDotRenderPosition {
        guard let nextNode else {
            return AquaDotRenderPosition(x: Double(currentNode.x), y: Double(currentNode.y))
        }
        let t = max(0, min(1, segmentProgress))
        return AquaDotRenderPosition(
            x: Double(currentNode.x) + Double(nextNode.x - currentNode.x) * t,
            y: Double(currentNode.y) + Double(nextNode.y - currentNode.y) * t
        )
    }
}
