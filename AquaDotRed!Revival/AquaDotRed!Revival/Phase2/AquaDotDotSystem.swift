import Foundation

/// Reconstructs AquaDot's dynamic dot ecosystem from the shipped strategy guide
/// and the recovered MazeDots/MazeSprouts architecture. Static maze tokens remain
/// authoritative; dynamic goodie timing/radii are centralized as tuning values so
/// they can be replaced as more exact constants are recovered from the binary.
struct AquaDotDotSystem: Sendable {
    struct Tuning: Sendable {
        var firstGoodieDelay: Double = 6.0
        var minimumGoodieInterval: Double = 8.0
        var goodieIntervalJitter: Double = 6.0
        var goodieLifetime: Double = 12.0
        var transformationRadius: Int = 4
    }

    let topology: AquaDotMazeTopology
    let pathfinding: AquaDotPathfinding
    let tuning: Tuning

    init(topology: AquaDotMazeTopology, tuning: Tuning = Tuning()) {
        self.topology = topology
        self.pathfinding = AquaDotPathfinding(topology: topology)
        self.tuning = tuning
    }

    mutating func update(
        state: inout AquaDotGameState,
        deltaTime: Double,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        guard !state.levelCompleted else { return }

        if var goodie = state.goodie {
            goodie.age += deltaTime
            state.goodie = goodie

            // Guide behavior is progressive: nearby dots change as the goodie
            // ages rather than the whole field flipping in one instant.
            let growth = max(1, min(tuning.transformationRadius, Int(ceil((goodie.age / goodie.lifetime) * Double(tuning.transformationRadius)))))
            switch goodie.kind {
            case .yummy:
                transformNearbyDots(around: goodie.position, radius: growth, from: .normal, to: .candy, state: &state)
            case .yuk:
                transformNearbyDots(around: goodie.position, radius: growth, from: .normal, to: .crusty, state: &state)
            case .bonus, .multiplier:
                break
            }

            if goodie.age >= goodie.lifetime {
                expireGoodie(goodie, state: &state)
                state.goodie = nil
                scheduleNextGoodie(state: &state, random: &random)
            }
        } else {
            state.goodieSpawnCountdown -= deltaTime
            if state.goodieSpawnCountdown <= 0 {
                spawnGoodie(state: &state, random: &random, events: &events)
            }
        }
    }

    mutating func collectGoodieIfPresent(
        at position: GridPosition,
        state: inout AquaDotGameState,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        guard let goodie = state.goodie, goodie.position == position else { return }

        state.score += goodie.kind.scoreValue
        events.append(.goodieEaten(kind: goodie.kind, position: position))

        switch goodie.kind {
        case .yummy:
            restoreTransformedDots(.candy, to: .normal, state: &state)
            state.specialPowerAmount = min(1, state.specialPowerAmount + 0.55 + min(0.25, goodie.age / goodie.lifetime * 0.25))

            // Opposite goodies cancel an active special. If a Yummy power is
            // already active, the guide says another Yummy adds power without
            // replacing that active ability.
            if case .yuk? = state.activeSpecialPower {
                state.activeSpecialPower = nil
                events.append(.specialPowerEnded)
            }
            if state.activeSpecialPower == nil {
                let power = AquaDotYummyPower.allCases[random.int(upperBound: AquaDotYummyPower.allCases.count)]
                state.availableYummyPower = power
                events.append(.specialPowerAvailable(power))
            }

        case .yuk:
            restoreTransformedDots(.crusty, to: .normal, state: &state)
            if state.activeSpecialPower != nil {
                state.activeSpecialPower = nil
                events.append(.specialPowerEnded)
            }
            state.availableYummyPower = nil
            let power = AquaDotYukPower.allCases[random.int(upperBound: AquaDotYukPower.allCases.count)]
            state.activeSpecialPower = .yuk(power)
            state.specialPowerAmount = min(1, 0.5 + min(0.4, goodie.age / goodie.lifetime * 0.4))
            events.append(.specialPowerActivated(.yuk(power)))

        case .bonus:
            // The guide describes older Bonus dots as more valuable. Exact bonus
            // curve remains a constant-recovery target; this preserves that rule.
            state.bonus += Int(250 + 1750 * min(1, goodie.age / goodie.lifetime))

        case .multiplier:
            state.multiplier = min(5, state.multiplier + 1)
        }

        state.goodie = nil
        scheduleNextGoodie(state: &state, random: &random)
    }

    mutating func resetAfterLifeLoss(state: inout AquaDotGameState) {
        state.activeSpecialPower = nil
        state.specialPowerAmount = 0
        state.availableYummyPower = nil
        if let goodie = state.goodie {
            expireGoodie(goodie, state: &state)
            state.goodie = nil
        }
    }

    private mutating func spawnGoodie(
        state: inout AquaDotGameState,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        let candidates = state.dots.keys.sorted { lhs, rhs in
            lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
        }
        guard !candidates.isEmpty else { return }

        var kinds = AquaDotGoodieKind.allCases
        if state.multiplierGoodieSpawned {
            kinds.removeAll { $0 == .multiplier }
        }
        let kind = kinds[random.int(upperBound: kinds.count)]
        if kind == .multiplier { state.multiplierGoodieSpawned = true }
        let position = candidates[random.int(upperBound: candidates.count)]
        let goodie = AquaDotGoodieState(kind: kind, position: position, age: 0, lifetime: tuning.goodieLifetime)
        state.goodie = goodie

        switch kind {
        case .yummy:
            transformNearbyDots(around: position, radius: 1, from: .normal, to: .candy, state: &state)
        case .yuk:
            transformNearbyDots(around: position, radius: 1, from: .normal, to: .crusty, state: &state)
        case .bonus, .multiplier:
            break
        }
        events.append(.goodieSpawned(kind: kind, position: position))
    }

    private func expireGoodie(_ goodie: AquaDotGoodieState, state: inout AquaDotGameState) {
        switch goodie.kind {
        case .yummy:
            restoreTransformedDots(.candy, to: .normal, state: &state)
        case .yuk:
            // Strategy guide: if a Yuk disappears uneaten, Crusty dots petrify.
            restoreTransformedDots(.crusty, to: .petrified, state: &state)
        case .bonus, .multiplier:
            break
        }
    }

    private func transformNearbyDots(
        around origin: GridPosition,
        radius: Int,
        from source: AquaDotDotKind,
        to destination: AquaDotDotKind,
        state: inout AquaDotGameState
    ) {
        for position in Array(state.dots.keys) {
            guard state.dots[position] == source,
                  let distance = pathfinding.shortestDistance(from: origin, to: position),
                  distance <= radius else { continue }
            state.dots[position] = destination
        }
    }

    private func restoreTransformedDots(
        _ source: AquaDotDotKind,
        to destination: AquaDotDotKind,
        state: inout AquaDotGameState
    ) {
        for position in Array(state.dots.keys) where state.dots[position] == source {
            state.dots[position] = destination
        }
    }

    private func scheduleNextGoodie(state: inout AquaDotGameState, random: inout AquaDotSeededRandom) {
        state.goodieSpawnCountdown = tuning.minimumGoodieInterval + random.double() * tuning.goodieIntervalJitter
    }
}
