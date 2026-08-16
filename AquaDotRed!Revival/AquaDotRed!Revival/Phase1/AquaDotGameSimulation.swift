import Foundation

/// Phase 2 platform-independent AquaDot reconstruction.
///
/// Confirmed game rules (scores, power names, bug personalities, Munch behavior,
/// optional Munch dots, dot transformations) come from the shipped strategy guide
/// and recovered source/disassembly structure. Exact timing/speed constants that
/// have not yet been binary-matched are isolated in `Tuning` and explicitly marked.
final class AquaDotGameSimulation {
    struct Tuning: Sendable {
        // Reconstruction constants: gameplay shape is evidence-backed, exact values
        // remain targets for later binary timing comparison.
        var playerCellsPerSecond: Double = 6.2
        var bugCellsPerSecond: Double = 4.65
        var munchDuration: Double = 9.0
        var specialPowerDrainPerSecond: Double = 0.085
        var movingBugDamagePerSecond: Double = 0.34
        var stoppedBugDamagePerSecond: Double = 0.17
        var passiveEnergyRecoveryPerSecond: Double = 0.018
        var bugWarpSlowdown: Double = 0.22
        var postMunchBugRecovery: Double = 1.35

        // Phase 2.1.1 bug fix: the previous collision threshold was much
        // smaller than the visible AquaDot/bug silhouettes, allowing obvious
        // on-screen overlap without registering contact.
        var bugCollisionRadiusCells: Double = 0.92
    }

    let topology: AquaDotMazeTopology
    let tuning: Tuning
    private(set) var state: AquaDotGameState

    private var random: AquaDotSeededRandom
    private var dotSystem: AquaDotDotSystem
    private let pathfinding: AquaDotPathfinding
    private var pendingEvents: [AquaDotGameEvent] = []
    private var damageEventCooldown: Double = 0

    /// Populated exactly once when the required dot field is cleared. The scene
    /// consumes this for the recovered tween-level score presentation.
    private(set) var lastLevelResult: AquaDotLevelResult?

    // Phase 2.1.2 wrap gate. Some original mazes intentionally pair two wrap
    // endpoints on the *same* outer boundary (for example Ewe (4)'s two bottom
    // A endpoints). Holding the outward direction after teleporting must not
    // immediately trigger the destination portal again. We force one inward
    // exit segment and, only when necessary, suppress that same outward request
    // until the player chooses another direction.
    private var blockedPlayerWrapDirection: AquaDotDirection?

    private var extraLifeThresholds = [25_000, 75_000, 150_000, 250_000]
    private var nextRepeatingExtraLife = 350_000

    init(
        topology: AquaDotMazeTopology,
        tuning: Tuning = Tuning(),
        seed: UInt64 = 0xA51AD07,
        initialScore: Int = 0,
        initialBonus: Int = 0,
        initialMultiplier: Int = 1,
        initialLives: Int = 3,
        initialLevelsCleared: Int = 0
    ) {
        self.topology = topology
        self.tuning = tuning
        var setupRandom = AquaDotSeededRandom(seed: seed)
        self.dotSystem = AquaDotDotSystem(topology: topology)
        self.pathfinding = AquaDotPathfinding(topology: topology)

        let starts = topology.playerStarts
        let first = starts.first ?? topology.traversable.first ?? GridPosition(x: 0, y: 0)
        var initialDirection: AquaDotDirection?
        var initialNext: GridPosition?
        if starts.count >= 2, let direction = AquaDotDirection(from: starts[0], to: starts[1]) {
            initialDirection = direction
            initialNext = starts[1]
        }

        // EnemyDraw/setupEnemy proves color/personality is selected separately
        // from the E-H start slot. Phase 2 implements the four guide-confirmed
        // basic colors/personalities and assigns a distinct shuffled roster to the
        // four original starts. Later phases can expand the recovered difficulty-
        // dependent 12-color availability table without changing bug movement.
        var roster: [AquaDotBugPersonality] = [.hunter, .blocker, .sneaker, .houndDog]
        if roster.count > 1 {
            for i in stride(from: roster.count - 1, through: 1, by: -1) {
                let j = setupRandom.int(upperBound: i + 1)
                roster.swapAt(i, j)
            }
        }
        let bugs = topology.enemyStarts.enumerated().map { index, start in
            AquaDotBugState(
                id: start.id,
                personality: roster[index % roster.count],
                homeNode: start.position,
                currentNode: start.position,
                nextNode: nil,
                segmentProgress: 0,
                movementDirection: nil,
                mode: .hunting,
                recoveryDelay: 0
            )
        }

        self.random = setupRandom

        state = AquaDotGameState(
            player: AquaDotPlayerState(
                currentNode: first,
                nextNode: initialNext,
                segmentProgress: 0,
                movementDirection: initialDirection,
                requestedDirection: initialDirection
            ),
            dots: Dictionary(uniqueKeysWithValues: topology.dots.map { ($0, AquaDotDotKind.normal) }),
            remainingMunchDots: topology.munchDots,
            goodie: nil,
            goodieSpawnCountdown: 6.0,
            multiplierGoodieSpawned: false,
            bugs: bugs,
            recentPlayerTrail: [first],
            score: max(0, initialScore),
            bonus: max(0, initialBonus),
            multiplier: max(1, initialMultiplier),
            energy: 1.0,
            lives: max(0, initialLives),
            levelsCleared: max(0, initialLevelsCleared),
            levelStats: AquaDotLevelStats(
                initialRequiredDots: topology.dots.count,
                initialMunchDots: topology.munchDots.count
            ),
            availableYummyPower: nil,
            activeSpecialPower: nil,
            specialPowerAmount: 0,
            munchTimeRemaining: 0,
            bugsEatenThisMunch: 0,
            munchStartedWithFullEnergy: false,
            munchExtraLifeAwardedThisLevel: false,
            levelCompleted: false,
            gameOver: false,
            isPaused: false
        )

        collect(at: first)
    }

    func request(_ direction: AquaDotDirection) {
        if let blockedPlayerWrapDirection, direction != blockedPlayerWrapDirection {
            self.blockedPlayerWrapDirection = nil
        }
        state.player.requestedDirection = direction
    }

    func activateAvailableSpecial() {
        guard !state.isPaused,
              state.specialPowerAmount > 0,
              state.activeSpecialPower == nil,
              let power = state.availableYummyPower else { return }
        state.availableYummyPower = nil
        state.activeSpecialPower = .yummy(power)
        state.levelStats.yummyPowerActivated = true
        pendingEvents.append(.specialPowerActivated(.yummy(power)))
    }

    func togglePause() {
        state.isPaused.toggle()
        pendingEvents.append(.paused(state.isPaused))
    }

    func drainEvents() -> [AquaDotGameEvent] {
        defer { pendingEvents.removeAll(keepingCapacity: true) }
        return pendingEvents
    }

    func step(deltaTime: Double) {
        guard deltaTime > 0, !state.isPaused, !state.levelCompleted, !state.gameOver else { return }

        damageEventCooldown = max(0, damageEventCooldown - deltaTime)
        updateSpecialPower(deltaTime: deltaTime)
        updateMunch(deltaTime: deltaTime)

        let eventStart = pendingEvents.count
        dotSystem.update(state: &state, deltaTime: deltaTime, random: &random, events: &pendingEvents)
        accountForGoodieSpawns(in: pendingEvents[eventStart...])

        advancePlayer(distance: effectivePlayerSpeed() * deltaTime)
        if state.levelCompleted {
            awardScoreExtraLivesIfNeeded()
            return
        }
        updateBugs(deltaTime: deltaTime)
        resolveBugCollisions(deltaTime: deltaTime)
        recoverEnergy(deltaTime: deltaTime)
        awardScoreExtraLivesIfNeeded()
    }

    // MARK: - Player

    private func effectivePlayerSpeed() -> Double {
        var speed = tuning.playerCellsPerSecond

        if let next = state.player.nextNode, let dot = state.dots[next] {
            switch dot {
            case .normal: speed *= 0.86
            case .candy: speed *= 1.12
            case .crusty: speed *= 0.70
            case .petrified: speed *= 0.52
            }
        }

        if let special = state.activeSpecialPower {
            switch special {
            case .yummy(.quick): speed *= 1.55
            case .yuk(.slow): speed *= 0.55
            case .yuk(.sick): speed *= 1.12
            default: break
            }
        }
        return speed
    }

    private func advancePlayer(distance: Double) {
        var distanceToTravel = distance
        var safety = 0
        while distanceToTravel > 0, safety < 32 {
            safety += 1
            if state.player.nextNode == nil {
                guard beginNextPlayerSegmentIfPossible() else { break }
                if state.player.nextNode == nil { continue }
            }

            let remaining = 1.0 - state.player.segmentProgress
            if distanceToTravel < remaining {
                state.player.segmentProgress += distanceToTravel
                distanceToTravel = 0
            } else {
                distanceToTravel -= remaining
                arrivePlayerAtNextNode()
            }
        }
    }

    private func beginNextPlayerSegmentIfPossible() -> Bool {
        let position = state.player.currentNode
        let preferred: AquaDotDirection? = {
            guard let requested = state.player.requestedDirection else { return nil }
            // A same-side wrap may leave the physically held/requested direction
            // pointing straight back out through the portal. Ignore that one
            // request until the player chooses a different direction.
            if let blocked = blockedPlayerWrapDirection, requested == blocked { return nil }
            return requested
        }()
        let continuing = state.player.movementDirection

        let direction: AquaDotDirection?
        if let preferred, topology.canMove(from: position, direction: preferred) {
            direction = preferred
        } else if let continuing, topology.canMove(from: position, direction: continuing) {
            direction = continuing
        } else {
            direction = nil
        }

        guard let direction, let edge = topology.edge(from: position, direction: direction) else {
            state.player.nextNode = nil
            state.player.segmentProgress = 0
            return false
        }

        state.player.movementDirection = direction
        switch edge.kind {
        case .corridor:
            state.player.nextNode = edge.destination
            state.player.segmentProgress = 0
        case let .wrap(id):
            let entryDirection = direction
            state.player.currentNode = edge.destination
            state.player.nextNode = nil
            state.player.segmentProgress = 0
            recordPlayerArrival(edge.destination)
            collect(at: edge.destination)
            pendingEvents.append(.wrapped(id))

            // A wrap is a boundary crossing, not arrival on a second trigger pad.
            // Always leave the destination *inward*. This is essential for the
            // 93 same-side wrap pairs in the recovered corpus and also makes
            // adjacent-side pairs deterministic.
            if let outward = topology.outwardDirection(at: edge.destination),
               let inward = topology.inwardDirection(at: edge.destination),
               let exitEdge = topology.corridorEdge(from: edge.destination, direction: inward) {
                state.player.movementDirection = inward
                state.player.nextNode = exitEdge.destination
                state.player.segmentProgress = 0

                // Only same-facing entries need an input gate. On a normal
                // left↔right or top↔bottom wrap, the held entry direction is
                // already different from the destination's outward trigger.
                blockedPlayerWrapDirection = (
                    entryDirection == outward && state.player.requestedDirection == outward
                ) ? outward : nil
            } else {
                // Corpus validation says this should never happen, but fail safe
                // by stopping rather than teleporting forever if malformed data
                // ever reaches the runtime.
                state.player.movementDirection = nil
                blockedPlayerWrapDirection = nil
            }
        }
        return true
    }

    private func arrivePlayerAtNextNode() {
        guard let destination = state.player.nextNode else { return }
        state.player.currentNode = destination
        state.player.nextNode = nil
        state.player.segmentProgress = 0
        recordPlayerArrival(destination)
        collect(at: destination)
    }

    private func recordPlayerArrival(_ position: GridPosition) {
        if state.recentPlayerTrail.last != position { state.recentPlayerTrail.append(position) }
        if state.recentPlayerTrail.count > 32 {
            state.recentPlayerTrail.removeFirst(state.recentPlayerTrail.count - 32)
        }
    }

    private func collect(at position: GridPosition) {
        let sick: Bool = {
            if case .yuk(.sick)? = state.activeSpecialPower { return true }
            return false
        }()

        if !sick, let dotKind = state.dots.removeValue(forKey: position) {
            addScore(dotKind.scoreValue)
            switch dotKind {
            case .normal: state.energy = min(1, state.energy + 0.018)
            case .candy: state.energy = min(1, state.energy + 0.055)
            case .crusty: state.energy = min(1, state.energy + 0.007)
            case .petrified: break
            }
            pendingEvents.append(.dotEaten(kind: dotKind, position: position))
        }

        // Guide: Sick AquaDot cannot eat *any* dots except Yummy and Yuk.
        // Therefore Munch, Bonus and Multiplier are also unavailable while Sick.
        if !sick, state.remainingMunchDots.remove(position) != nil {
            if state.munchTimeRemaining > 0 { finishMunchSkillWindow() }
            addScore(250)
            state.levelStats.munchDotsEaten += 1
            state.levelStats.munchesStarted += 1
            state.munchStartedWithFullEnergy = state.energy >= 0.999
            state.munchTimeRemaining = tuning.munchDuration
            state.bugsEatenThisMunch = 0
            for index in state.bugs.indices where state.bugs[index].mode != .returningHome {
                state.bugs[index].mode = .frightened
            }
            pendingEvents.append(.munchEaten(position: position))
            pendingEvents.append(.munchStarted)
        }

        if let goodie = state.goodie,
           !sick || goodie.kind == .yummy || goodie.kind == .yuk {
            let collectedKind = goodie.kind
            dotSystem.collectGoodieIfPresent(
                at: position,
                state: &state,
                random: &random,
                events: &pendingEvents
            )
            if state.goodie == nil {
                state.levelStats.goodiesEaten += 1
                if collectedKind == .yuk { state.levelStats.yukEaten += 1 }
            }
        }

        // Munch dots and transient goodies are optional; original level completion
        // is driven by clearing the required normal/dynamic dot field.
        if state.dots.isEmpty, !state.levelCompleted {
            completeLevel()
        }
    }

    // MARK: - Special/Munch

    private func updateSpecialPower(deltaTime: Double) {
        guard state.activeSpecialPower != nil else { return }
        state.specialPowerAmount = max(0, state.specialPowerAmount - tuning.specialPowerDrainPerSecond * deltaTime)
        if state.specialPowerAmount <= 0 {
            state.activeSpecialPower = nil
            pendingEvents.append(.specialPowerEnded)
        }
    }

    private func updateMunch(deltaTime: Double) {
        guard state.munchTimeRemaining > 0 else { return }
        state.munchTimeRemaining = max(0, state.munchTimeRemaining - deltaTime)
        if state.munchTimeRemaining == 0 {
            finishMunchSkillWindow()
            for index in state.bugs.indices where state.bugs[index].mode == .frightened {
                state.bugs[index].mode = .hunting
                // Guide: after a Munch ends, bugs need a short period to regain
                // their bearings before attacking again. Exact duration is tuning.
                state.bugs[index].recoveryDelay = max(state.bugs[index].recoveryDelay, tuning.postMunchBugRecovery)
            }
            pendingEvents.append(.munchEnded)
        }
    }

    // MARK: - Bugs

    private func updateBugs(deltaTime: Double) {
        for index in state.bugs.indices {
            if state.bugs[index].recoveryDelay > 0 {
                state.bugs[index].recoveryDelay = max(0, state.bugs[index].recoveryDelay - deltaTime)
                if state.bugs[index].recoveryDelay == 0 { state.bugs[index].mode = state.isMunchActive ? .frightened : .hunting }
                continue
            }

            var speed = tuning.bugCellsPerSecond
            if state.bugs[index].personality == .sneaker {
                // Guide: Sneaker is relatively slow on straights but turns rapidly.
                speed *= 0.88
            }
            if state.bugs[index].personality == .houndDog, houndDogHasRecentScent(state.bugs[index]) {
                // Guide: Hound Dog accelerates once it finds AquaDot's recent trail.
                speed *= 1.32
            }
            if case .yummy(.dreamy)? = state.activeSpecialPower { speed *= 0.48 }
            if state.bugs[index].mode == .returningHome { speed *= 1.75 }

            advanceBug(at: index, distance: speed * deltaTime)
        }
    }

    private func advanceBug(at index: Int, distance: Double) {
        var distanceToTravel = distance
        var safety = 0
        while distanceToTravel > 0, safety < 24 {
            safety += 1
            if state.bugs[index].nextNode == nil {
                guard beginNextBugSegment(at: index) else { break }
                if state.bugs[index].nextNode == nil { continue }
            }

            let remaining = 1 - state.bugs[index].segmentProgress
            if distanceToTravel < remaining {
                state.bugs[index].segmentProgress += distanceToTravel
                distanceToTravel = 0
            } else {
                distanceToTravel -= remaining
                guard let destination = state.bugs[index].nextNode else { break }
                state.bugs[index].currentNode = destination
                state.bugs[index].nextNode = nil
                state.bugs[index].segmentProgress = 0

                if state.bugs[index].mode == .returningHome, destination == state.bugs[index].homeNode {
                    state.bugs[index].mode = state.isMunchActive ? .frightened : .hunting
                    state.bugs[index].recoveryDelay = 0.75
                    break
                }
            }
        }
    }

    private func beginNextBugSegment(at index: Int) -> Bool {
        let bug = state.bugs[index]
        let reverse = bug.movementDirection?.opposite
        let direction = chooseBugDirection(for: bug, avoiding: reverse)
        guard let direction, let edge = topology.edge(from: bug.currentNode, direction: direction) else { return false }

        state.bugs[index].movementDirection = direction
        switch edge.kind {
        case .corridor:
            state.bugs[index].nextNode = edge.destination
            state.bugs[index].segmentProgress = 0
        case .wrap:
            state.bugs[index].currentNode = edge.destination
            state.bugs[index].nextNode = nil
            state.bugs[index].segmentProgress = 0

            // Bugs obey the same portal semantics as AquaDot: materialize at the
            // paired endpoint, then take the destination's inward corridor. This
            // prevents AI reverse-avoidance from selecting the wrap edge again on
            // same-side pairs and quietly looping a bug forever.
            if let inward = topology.inwardDirection(at: edge.destination),
               let exitEdge = topology.corridorEdge(from: edge.destination, direction: inward) {
                state.bugs[index].movementDirection = inward
                state.bugs[index].nextNode = exitEdge.destination
            } else {
                state.bugs[index].movementDirection = nil
            }

            // Strategy guide explicitly notes that bugs generally slow down in warps.
            state.bugs[index].recoveryDelay = max(state.bugs[index].recoveryDelay, tuning.bugWarpSlowdown)
        }
        return true
    }

    private func houndDogHasRecentScent(_ bug: AquaDotBugState) -> Bool {
        state.recentPlayerTrail.reversed().contains { point in
            (pathfinding.shortestDistance(from: bug.currentNode, to: point) ?? Int.max) <= 2
        }
    }

    private func chooseBugDirection(for bug: AquaDotBugState, avoiding reverse: AquaDotDirection?) -> AquaDotDirection? {
        let player = state.player.currentNode

        if bug.mode == .returningHome {
            return pathfinding.shortestDirection(from: bug.currentNode, to: bug.homeNode, avoiding: reverse)
        }

        let frightenedBySpecial: Bool = {
            if case .yummy(.scary)? = state.activeSpecialPower { return true }
            return false
        }()
        let invisible: Bool = {
            if case .yummy(.invisible)? = state.activeSpecialPower { return true }
            return false
        }()

        if bug.mode == .frightened || frightenedBySpecial {
            return pathfinding.directionAway(from: bug.currentNode, threat: player, avoiding: reverse)
        }

        if invisible {
            let edges = topology.edges(from: bug.currentNode).filter { $0.direction != reverse }
            let usable = edges.isEmpty ? topology.edges(from: bug.currentNode) : edges
            return usable.isEmpty ? nil : usable[random.int(upperBound: usable.count)].direction
        }

        let target: GridPosition
        switch bug.personality {
        case .hunter:
            target = player
        case .blocker:
            target = pathfinding.projectedNode(from: player, direction: state.player.movementDirection, steps: 5)
        case .sneaker:
            target = pathfinding.projectedNode(from: player, direction: state.player.movementDirection?.opposite, steps: 4)
        case .houndDog:
            // Guide: Hound Dog wanders until it encounters AquaDot's recent path,
            // then follows that trail rapidly. Use a short graph-distance scent
            // radius and otherwise choose a non-reversing random corridor.
            let trail = state.recentPlayerTrail
            let scented = trail.reversed().first { point in
                (pathfinding.shortestDistance(from: bug.currentNode, to: point) ?? Int.max) <= 2
            }
            if let scented {
                target = scented
            } else {
                let edges = topology.edges(from: bug.currentNode).filter { $0.direction != reverse }
                let usable = edges.isEmpty ? topology.edges(from: bug.currentNode) : edges
                return usable.isEmpty ? nil : usable[random.int(upperBound: usable.count)].direction
            }
        }
        return pathfinding.shortestDirection(from: bug.currentNode, to: target, avoiding: reverse)
    }

    private func resolveBugCollisions(deltaTime: Double) {
        let playerPosition = state.player.renderPosition()
        var touchingDangerousBug = false

        for index in state.bugs.indices {
            let bug = state.bugs[index]
            guard bug.recoveryDelay <= 0, bug.mode != .returningHome else { continue }
            let bp = bug.renderPosition()
            let dx = playerPosition.x - bp.x
            let dy = playerPosition.y - bp.y
            let collisionRadius = tuning.bugCollisionRadiusCells
            guard dx * dx + dy * dy < collisionRadius * collisionRadius else { continue }

            if state.isMunchActive || bug.mode == .frightened {
                eatBug(at: index)
            } else if case .yummy(.untouchable)? = state.activeSpecialPower {
                continue
            } else {
                touchingDangerousBug = true
            }
        }

        if touchingDangerousBug {
            let moving = state.player.nextNode != nil
            var rate = moving ? tuning.movingBugDamagePerSecond : tuning.stoppedBugDamagePerSecond
            if case .yuk(.tasty)? = state.activeSpecialPower { rate *= 4.0 }
            if case .yummy(.energetic)? = state.activeSpecialPower { rate *= 0.45 }
            let energyBeforeDamage = state.energy
            state.energy = max(0, state.energy - rate * deltaTime)
            state.levelStats.damageTaken += max(0, energyBeforeDamage - state.energy)
            if damageEventCooldown <= 0 {
                pendingEvents.append(.playerDamaged)
                damageEventCooldown = 0.22
            }
            if state.energy <= 0 { loseLife() }
        }
    }

    private func eatBug(at index: Int) {
        guard state.bugs[index].mode != .returningHome else { return }
        let baseValues = [500, 1000, 2000, 4000]
        let sequenceIndex = min(state.bugsEatenThisMunch, baseValues.count - 1)
        var points = baseValues[sequenceIndex]

        if let special = state.activeSpecialPower {
            switch special {
            case .yuk(.sick): points *= 2
            case .yuk(.blind): points *= 3
            case .yuk(.tasty): points *= 5
            case .yuk(.slow): points *= 10
            default: break
            }
        }

        addScore(points)
        state.bugsEatenThisMunch += 1
        state.levelStats.bugsEaten += 1
        state.energy = min(1, state.energy + 0.25)
        state.bugs[index].mode = .returningHome
        state.bugs[index].nextNode = nil
        state.bugs[index].segmentProgress = 0
        pendingEvents.append(.bugEaten(id: state.bugs[index].id, points: points))

        if state.bugsEatenThisMunch >= min(4, state.bugs.count),
           state.munchStartedWithFullEnergy,
           !state.munchExtraLifeAwardedThisLevel {
            state.lives += 1
            state.munchExtraLifeAwardedThisLevel = true
            pendingEvents.append(.lifeGained)
        }
    }

    // MARK: - Phase 3 campaign accounting

    private func accountForGoodieSpawns(in events: ArraySlice<AquaDotGameEvent>) {
        for event in events {
            if case let .goodieSpawned(kind, _) = event {
                state.levelStats.goodiesSpawned += 1
                if kind == .yuk { state.levelStats.yukSpawned += 1 }
            }
        }
    }

    private func finishMunchSkillWindow() {
        guard state.munchTimeRemaining > 0 || state.bugsEatenThisMunch > 0 else { return }
        if state.bugsEatenThisMunch > 0 {
            state.levelStats.munchesWithAtLeastOneBug += 1
        }
    }

    private func completeLevel() {
        guard !state.levelCompleted else { return }

        if state.munchTimeRemaining > 0 { finishMunchSkillWindow() }

        // The guide is explicit: (Bonus + Skill) × Multiplier is added to the
        // score at the end of each level. Exact Skill weights remain isolated in
        // AquaDotSkillScoring until stronger binary evidence is recovered.
        let skill = AquaDotSkillScoring.calculate(state: state)
        let scoreBefore = state.score
        let levelAward = (state.bonus + skill.points) * max(1, state.multiplier)
        state.score += levelAward
        state.levelsCleared += 1
        lastLevelResult = AquaDotLevelResult(
            bonus: state.bonus,
            skill: skill.points,
            multiplier: max(1, state.multiplier),
            levelAward: levelAward,
            scoreBefore: scoreBefore,
            scoreAfter: state.score,
            quality: skill.quality
        )

        if state.activeSpecialPower != nil {
            state.activeSpecialPower = nil
            state.availableYummyPower = nil
            pendingEvents.append(.specialPowerEnded)
        }
        state.specialPowerAmount = 0
        if state.munchTimeRemaining > 0 {
            state.munchTimeRemaining = 0
            pendingEvents.append(.munchEnded)
        }

        state.levelCompleted = true
        pendingEvents.append(.levelCompleted)
    }

    // MARK: - Life / energy / score

    private func recoverEnergy(deltaTime: Double) {
        var rate = tuning.passiveEnergyRecoveryPerSecond
        if case .yummy(.energetic)? = state.activeSpecialPower { rate *= 3.0 }
        state.energy = min(1, state.energy + rate * deltaTime)
    }

    private func loseLife() {
        if state.munchTimeRemaining > 0 { finishMunchSkillWindow() }
        state.lives = max(0, state.lives - 1)
        state.levelStats.livesLost += 1
        state.multiplier = max(1, state.multiplier - 1)
        state.energy = 1
        state.munchTimeRemaining = 0
        state.bugsEatenThisMunch = 0
        state.munchStartedWithFullEnergy = false
        pendingEvents.append(.lifeLost)

        // Strategy guide: when AquaDot is out of lives, the game ends. Earlier
        // revival phases accidentally respawned forever at zero lives.
        if state.lives == 0 {
            state.activeSpecialPower = nil
            state.availableYummyPower = nil
            state.specialPowerAmount = 0
            state.gameOver = true
            pendingEvents.append(.gameOver(finalScore: state.score, levelsCleared: state.levelsCleared))
            return
        }

        dotSystem.resetAfterLifeLoss(state: &state)
        resetActorsToStarts()
    }

    private func resetActorsToStarts() {
        let starts = topology.playerStarts
        let first = starts.first ?? state.player.currentNode
        state.player.currentNode = first
        state.player.nextNode = nil
        state.player.segmentProgress = 0
        state.player.movementDirection = nil
        state.player.requestedDirection = nil
        blockedPlayerWrapDirection = nil
        state.recentPlayerTrail = [first]

        for index in state.bugs.indices {
            state.bugs[index].currentNode = state.bugs[index].homeNode
            state.bugs[index].nextNode = nil
            state.bugs[index].segmentProgress = 0
            state.bugs[index].movementDirection = nil
            state.bugs[index].mode = .hunting
            state.bugs[index].recoveryDelay = 0.8
        }
    }

    private func addScore(_ points: Int) {
        state.score += points
    }

    private func awardScoreExtraLivesIfNeeded() {
        while let threshold = extraLifeThresholds.first, state.score >= threshold {
            extraLifeThresholds.removeFirst()
            state.lives += 1
            pendingEvents.append(.lifeGained)
        }
        while state.score >= nextRepeatingExtraLife {
            state.lives += 1
            nextRepeatingExtraLife += 100_000
            pendingEvents.append(.lifeGained)
        }
    }
}
