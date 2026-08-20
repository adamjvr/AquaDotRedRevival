import Foundation

/// AquaDot's dynamic dot ecosystem. Phase 3B ties the already-reconstructed
/// Candy/Crusty/Petrified transformations back to the recovered MazeSprouts
/// infection/cure machinery instead of inventing a separate infection mechanic.
struct AquaDotDotSystem: Sendable {
    struct Tuning: Sendable {
        var firstGoodieDelay: Double = 6.0
        var minimumGoodieInterval: Double = 8.0
        var goodieIntervalJitter: Double = 6.0
        var goodieLifetime: Double = 12.0
        var transformationRadius: Int = 4
    }

    private struct PendingDotTransition: Sendable {
        let position: GridPosition
        let expectedKind: AquaDotDotKind
        let destinationKind: AquaDotDotKind
        let beneficial: Bool
        let delayRange: ClosedRange<Double>
        var delay: Double
    }

    let topology: AquaDotMazeTopology
    let tuning: Tuning
    private var pendingTransitions: [PendingDotTransition] = []

    init(topology: AquaDotMazeTopology, tuning: Tuning = Tuning()) {
        self.topology = topology
        self.tuning = tuning
    }

    mutating func update(
        state: inout AquaDotGameState,
        deltaTime: Double,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        guard !state.levelCompleted else { return }

        updatePendingTransitions(
            state: &state,
            deltaTime: deltaTime,
            random: &random,
            events: &events
        )

        if var goodie = state.goodie {
            goodie.age += deltaTime
            state.goodie = goodie

            let growth = max(
                1,
                min(
                    tuning.transformationRadius,
                    Int(ceil((goodie.age / goodie.lifetime) * Double(tuning.transformationRadius)))
                )
            )
            switch goodie.kind {
            case .yummy:
                transformNearbyDots(
                    around: goodie.position,
                    radius: growth,
                    from: .normal,
                    to: .candy,
                    beneficial: true,
                    state: &state,
                    events: &events
                )
            case .yuk:
                transformNearbyDots(
                    around: goodie.position,
                    radius: growth,
                    from: .normal,
                    to: .crusty,
                    beneficial: false,
                    state: &state,
                    events: &events
                )
            case .bonus, .multiplier:
                break
            }

            if goodie.age >= goodie.lifetime {
                expireGoodie(
                    goodie,
                    state: &state,
                    random: &random,
                    events: &events
                )
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

        // Original Skill helper 0x5ca18 samples normalized lifecycle age for
        // Yummy, Bonus, and Multiplier meals. Yuk has separate early/late flags.
        let timingFraction: Double = goodie.lifetime > 0
            ? max(0.0, min(1.0, goodie.age / goodie.lifetime))
            : 0
        switch goodie.kind {
        case .yummy:
            state.levelStats.activeYummyDots = max(0, state.levelStats.activeYummyDots - 1)
            state.levelStats.goodieTimingSkillSum = Float(
                Double(state.levelStats.goodieTimingSkillSum) + timingFraction
            )
            state.levelStats.goodieTimingSkillSamples += 1
        case .yuk:
            state.levelStats.activeYukDots = max(0, state.levelStats.activeYukDots - 1)
        case .bonus, .multiplier:
            state.levelStats.goodieTimingSkillSum = Float(
                Double(state.levelStats.goodieTimingSkillSum) + timingFraction
            )
            state.levelStats.goodieTimingSkillSamples += 1
        }

        switch goodie.kind {
        case .yummy:
            // Guide + cureDot disassembly: when the parent is eaten, transformed
            // Candy dots cure less abruptly than when the parent simply vanishes.
            scheduleTransitions(
                around: goodie.position,
                from: .candy,
                to: .normal,
                delayRange: AquaDotRecoveredSproutMechanics.slowCureDelay,
                beneficial: true,
                state: state,
                random: &random
            )
            state.specialPowerAmount = min(
                1,
                state.specialPowerAmount + 0.55 + min(0.25, goodie.age / goodie.lifetime * 0.25)
            )

            if case .yuk? = state.activeSpecialPower {
                state.activeSpecialPower = nil
                events.append(.specialPowerEnded)
            }
            if state.activeSpecialPower == nil {
                let power = AquaDotYummyPower.allCases[
                    random.int(upperBound: AquaDotYummyPower.allCases.count)
                ]
                state.availableYummyPower = power
                events.append(.specialPowerAvailable(power))
            }

        case .yuk:
            // Eating Yuk cures the infected Crusty field back to Normal. The
            // longer recovered cure path is used here; an uneaten Yuk follows the
            // guide's Petrified outcome below.
            scheduleTransitions(
                around: goodie.position,
                from: .crusty,
                to: .normal,
                delayRange: AquaDotRecoveredSproutMechanics.slowCureDelay,
                beneficial: true,
                state: state,
                random: &random
            )
            if state.activeSpecialPower != nil {
                state.activeSpecialPower = nil
                events.append(.specialPowerEnded)
            }
            state.availableYummyPower = nil
            let power = AquaDotYukPower.allCases[
                random.int(upperBound: AquaDotYukPower.allCases.count)
            ]
            state.activeSpecialPower = .yuk(power)
            state.specialPowerAmount = min(
                1,
                0.5 + min(0.4, goodie.age / goodie.lifetime * 0.4)
            )
            events.append(.specialPowerActivated(.yuk(power)))

        case .bonus:
            state.bonus += Int(250 + 1750 * min(1, goodie.age / goodie.lifetime))

        case .multiplier:
            state.multiplier = min(5, state.multiplier + 1)
        }

        state.goodie = nil
        scheduleNextGoodie(state: &state, random: &random)
    }

    mutating func resetAfterLifeLoss(
        state: inout AquaDotGameState,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        state.activeSpecialPower = nil
        state.specialPowerAmount = 0
        state.availableYummyPower = nil
        if let goodie = state.goodie {
            // A death removes the parent goodie without collecting it.
            expireGoodie(
                goodie,
                countsAsSkillMiss: false,
                state: &state,
                random: &random,
                events: &events
            )
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
        let goodie = AquaDotGoodieState(
            kind: kind,
            position: position,
            age: 0,
            lifetime: tuning.goodieLifetime
        )
        state.goodie = goodie

        switch kind {
        case .yummy:
            transformNearbyDots(
                around: position,
                radius: 1,
                from: .normal,
                to: .candy,
                beneficial: true,
                state: &state,
                events: &events
            )
        case .yuk:
            transformNearbyDots(
                around: position,
                radius: 1,
                from: .normal,
                to: .crusty,
                beneficial: false,
                state: &state,
                events: &events
            )
        case .bonus, .multiplier:
            break
        }
        events.append(.goodieSpawned(kind: kind, position: position))
    }

    private mutating func expireGoodie(
        _ goodie: AquaDotGoodieState,
        countsAsSkillMiss: Bool = true,
        state: inout AquaDotGameState,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        switch goodie.kind {
        case .yummy:
            state.levelStats.activeYummyDots = max(0, state.levelStats.activeYummyDots - 1)
            if countsAsSkillMiss { state.levelStats.yummyExpired += 1 }
            scheduleTransitions(
                around: goodie.position,
                from: .candy,
                to: .normal,
                delayRange: AquaDotRecoveredSproutMechanics.fastCureDelay,
                beneficial: true,
                state: state,
                random: &random
            )
        case .yuk:
            state.levelStats.activeYukDots = max(0, state.levelStats.activeYukDots - 1)
            if countsAsSkillMiss { state.levelStats.yukExpired += 1 }
            // Shipped guide: an uneaten Yuk leaves Petrified dots behind.
            scheduleTransitions(
                around: goodie.position,
                from: .crusty,
                to: .petrified,
                delayRange: AquaDotRecoveredSproutMechanics.fastCureDelay,
                beneficial: false,
                state: state,
                random: &random
            )
        case .bonus, .multiplier:
            break
        }
    }

    private func transformNearbyDots(
        around origin: GridPosition,
        radius: Int,
        from source: AquaDotDotKind,
        to destination: AquaDotDotKind,
        beneficial: Bool,
        state: inout AquaDotGameState,
        events: inout [AquaDotGameEvent]
    ) {
        // Phase 4 authenticity closure: infectDot/updateDotInfections propagates
        // only to x-1/x+1/y-1/y+1 *normal-dot* neighbors. It does not use maze
        // shortest paths and therefore cannot jump a wrap or an empty corridor.
        let positions = Self.recoveredPropagationPositions(
            around: origin,
            radius: radius,
            source: source,
            destination: destination,
            dots: state.dots
        )
        for position in positions.sorted(by: Self.positionSort) where state.dots[position] == source {
            state.dots[position] = destination
            events.append(.dotTransformed(position: position, kind: destination))
            events.append(.sproutStarted(source: origin, target: position, beneficial: beneficial))
        }
    }

    /// Spatial topology recovered from updateDotInfections (0x4112c): each
    /// infection record fans out to four immediate cardinal dot neighbors. The
    /// current goodie-age radius remains the explicit timing-envelope adapter;
    /// the propagation graph itself is now binary-backed.
    static func recoveredPropagationPositions(
        around origin: GridPosition,
        radius: Int,
        source: AquaDotDotKind,
        destination: AquaDotDotKind,
        dots: [GridPosition: AquaDotDotKind]
    ) -> Set<GridPosition> {
        guard radius >= 0 else { return [] }
        guard dots[origin] == source || dots[origin] == destination else { return [] }

        var visited: Set<GridPosition> = [origin]
        var frontier: [GridPosition] = [origin]
        if radius == 0 { return visited }

        for _ in 0..<radius {
            var next: [GridPosition] = []
            for position in frontier {
                for direction in AquaDotDirection.allCases {
                    let neighbor = direction.offset(from: position)
                    guard !visited.contains(neighbor),
                          dots[neighbor] == source || dots[neighbor] == destination else { continue }
                    visited.insert(neighbor)
                    next.append(neighbor)
                }
            }
            if next.isEmpty { break }
            frontier = next
        }
        return visited
    }

    private mutating func scheduleTransitions(
        around origin: GridPosition,
        from source: AquaDotDotKind,
        to destination: AquaDotDotKind,
        delayRange: ClosedRange<Double>,
        beneficial: Bool,
        state: AquaDotGameState,
        random: inout AquaDotSeededRandom
    ) {
        // cureDot is also record-based and recursively fans to orthogonal source
        // neighbors. Seed at the parent goodie's dot, then enqueue children only
        // as their parent transition fires. This replaces the old global batch.
        if state.dots[origin] == source {
            enqueueTransition(
                position: origin,
                from: source,
                to: destination,
                delayRange: delayRange,
                beneficial: beneficial,
                state: state,
                random: &random
            )
            return
        }

        // Defensive compatibility: if the root dot was consumed by an unusual
        // state edge, seed any cardinal source neighbor rather than curing the
        // entire map instantaneously.
        for direction in AquaDotDirection.allCases {
            let neighbor = direction.offset(from: origin)
            if state.dots[neighbor] == source {
                enqueueTransition(
                    position: neighbor,
                    from: source,
                    to: destination,
                    delayRange: delayRange,
                    beneficial: beneficial,
                    state: state,
                    random: &random
                )
            }
        }
    }

    private mutating func enqueueTransition(
        position: GridPosition,
        from source: AquaDotDotKind,
        to destination: AquaDotDotKind,
        delayRange: ClosedRange<Double>,
        beneficial: Bool,
        state: AquaDotGameState,
        random: inout AquaDotSeededRandom
    ) {
        guard pendingTransitions.count < AquaDotRecoveredSproutMechanics.maximumInfectionRecords,
              state.dots[position] == source,
              !pendingTransitions.contains(where: {
                  $0.position == position &&
                  $0.expectedKind == source &&
                  $0.destinationKind == destination
              }) else { return }
        let delay = delayRange.lowerBound
            + random.double() * (delayRange.upperBound - delayRange.lowerBound)
        pendingTransitions.append(
            PendingDotTransition(
                position: position,
                expectedKind: source,
                destinationKind: destination,
                beneficial: beneficial,
                delayRange: delayRange,
                delay: delay
            )
        )
    }

    private mutating func updatePendingTransitions(
        state: inout AquaDotGameState,
        deltaTime: Double,
        random: inout AquaDotSeededRandom,
        events: inout [AquaDotGameEvent]
    ) {
        guard !pendingTransitions.isEmpty else { return }
        for index in pendingTransitions.indices.reversed() {
            pendingTransitions[index].delay -= deltaTime
            guard pendingTransitions[index].delay <= 0 else { continue }
            let transition = pendingTransitions.remove(at: index)
            guard state.dots[transition.position] == transition.expectedKind else { continue }
            state.dots[transition.position] = transition.destinationKind
            events.append(
                .dotTransformed(
                    position: transition.position,
                    kind: transition.destinationKind
                )
            )
            events.append(
                .sproutStarted(
                    source: transition.position,
                    target: transition.position,
                    beneficial: transition.beneficial
                )
            )

            for direction in AquaDotDirection.allCases {
                let neighbor = direction.offset(from: transition.position)
                if state.dots[neighbor] == transition.expectedKind {
                    enqueueTransition(
                        position: neighbor,
                        from: transition.expectedKind,
                        to: transition.destinationKind,
                        delayRange: transition.delayRange,
                        beneficial: transition.beneficial,
                        state: state,
                        random: &random
                    )
                }
            }
        }
    }

    private func scheduleNextGoodie(
        state: inout AquaDotGameState,
        random: inout AquaDotSeededRandom
    ) {
        state.goodieSpawnCountdown = tuning.minimumGoodieInterval
            + random.double() * tuning.goodieIntervalJitter
    }

    private static func positionSort(_ lhs: GridPosition, _ rhs: GridPosition) -> Bool {
        lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
    }
}
