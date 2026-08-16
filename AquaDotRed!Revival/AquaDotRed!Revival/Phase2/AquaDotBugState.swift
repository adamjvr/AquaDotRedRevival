import Foundation

enum AquaDotBugPersonality: String, Codable, CaseIterable, Sendable {
    case hunter
    case blocker
    case sneaker
    case houndDog
    case protector
    case mantis
    case hermit
    case neon

    /// The four personalities already reconstructed in Phase 2.
    static let basicRoster: [AquaDotBugPersonality] = [
        .hunter, .blocker, .sneaker, .houndDog,
    ]

    /// The four additional named personalities documented by the shipped guide.
    static let advancedRoster: [AquaDotBugPersonality] = [
        .protector, .mantis, .hermit, .neon,
    ]

    /// Guide: Neon impersonates another ordinary bug strategy, but never Reaper.
    /// We limit its emulation to the seven playable named strategies implemented
    /// by the revival; Neon never recursively selects itself.
    static let neonEmulationCandidates: [AquaDotBugPersonality] = [
        .hunter, .blocker, .sneaker, .houndDog, .protector, .mantis, .hermit,
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

    // Phase 3B advanced-personality state. These remain simulation state, not
    // SpriteKit state, so behavior is deterministic at the 120 Hz fixed step.
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
        self.emulatedPersonality = emulatedPersonality
        self.alertTimeRemaining = alertTimeRemaining
        self.awarenessCooldown = awarenessCooldown
        self.turnsWhileAlerted = turnsWhileAlerted
        self.lastSegmentWasTurn = lastSegmentWasTurn
    }

    /// Neon chooses one non-Reaper strategy at level creation and keeps it for
    /// that maze. Ordinary bugs simply return their own physical personality.
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
