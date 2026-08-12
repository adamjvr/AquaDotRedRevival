import Foundation

enum AquaDotDotKind: String, Codable, CaseIterable, Sendable {
    case normal
    case candy
    case crusty
    case petrified

    var scoreValue: Int {
        switch self {
        case .normal: 10
        case .candy: 50
        case .crusty: 30
        case .petrified: 100
        }
    }
}

enum AquaDotGoodieKind: String, Codable, CaseIterable, Sendable {
    case yummy
    case yuk
    case bonus
    case multiplier

    var scoreValue: Int {
        switch self {
        case .yummy: 250
        case .yuk: 1000
        case .bonus, .multiplier: 0
        }
    }
}

enum AquaDotYummyPower: String, Codable, CaseIterable, Sendable {
    case invisible
    case untouchable
    case quick
    case dreamy
    case energetic
    case scary
}

enum AquaDotYukPower: String, Codable, CaseIterable, Sendable {
    case slow
    case blind
    case sick
    case tasty
}

enum AquaDotSpecialPower: Equatable, Codable, Sendable {
    case yummy(AquaDotYummyPower)
    case yuk(AquaDotYukPower)
}

struct AquaDotGoodieState: Equatable, Codable, Sendable {
    var kind: AquaDotGoodieKind
    var position: GridPosition
    var age: Double
    var lifetime: Double
}

enum AquaDotGameEvent: Equatable, Sendable {
    case dotEaten(kind: AquaDotDotKind, position: GridPosition)
    case munchEaten(position: GridPosition)
    case munchStarted
    case munchEnded
    case goodieSpawned(kind: AquaDotGoodieKind, position: GridPosition)
    case goodieEaten(kind: AquaDotGoodieKind, position: GridPosition)
    case specialPowerAvailable(AquaDotYummyPower)
    case specialPowerActivated(AquaDotSpecialPower)
    case specialPowerEnded
    case bugEaten(id: Character, points: Int)
    case playerDamaged
    case lifeLost
    case lifeGained
    case wrapped(Character)
    case levelCompleted
    case paused(Bool)
}
