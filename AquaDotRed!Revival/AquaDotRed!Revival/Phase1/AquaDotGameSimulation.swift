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

        // Phase 4F replaces the guessed Protector/Mantis/Hermit speed, radius
        // and timer constants with recovered state machines and activity ramps.
        // The guide explicitly says Hermit is *very slow* in warps, but the exact
        // historical warp delay has not yet been isolated in the binary. Keep this
        // one compatibility bridge explicit rather than pretending it is recovered.
        var hermitWarpSlowdown: Double = 0.95

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

    // Phase 4F recovered advanced bug AI runtime.
    // Kept separate from Phase 3B's provisional timer fields so the recovered
    // state machines and the remaining translation boundaries stay auditable.
    private var advancedBugRuntime: [Character: AquaDotRecoveredAdvancedBugRuntime] = [:]

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
        dotTuning: AquaDotDotSystem.Tuning = AquaDotDotSystem.Tuning(),
        seed: UInt64 = 0xA51AD07,
        initialScore: Int = 0,
        initialBonus: Int = 0,
        initialMultiplier: Int = 1,
        initialLives: Int = 3,
        initialLevelsCleared: Int = 0,
        skillBaseDifficulty: Double = 0.30
    ) {
        self.topology = topology
        self.tuning = tuning
        var setupRandom = AquaDotSeededRandom(seed: seed)
        self.dotSystem = AquaDotDotSystem(topology: topology, tuning: dotTuning)
        self.pathfinding = AquaDotPathfinding(topology: topology)

        let starts = topology.playerStarts
        let first = starts.first ?? topology.traversable.first ?? GridPosition(x: 0, y: 0)
        var initialDirection: AquaDotDirection?
        var initialNext: GridPosition?
        if starts.count >= 2, let direction = AquaDotDirection(from: starts[0], to: starts[1]) {
            initialDirection = direction
            initialNext = starts[1]
        }

        // Phase 4G recovered original bug roster. Enemy colors 0...7 map to
        // eight real strategies; Neon is a sprite disguise applied *after* the
        // underlying color/personality is chosen. Reaper/color 8 remains an
        // explicit later target because its special contact/movement path is not
        // yet restored and must not be silently treated as an ordinary bug.
        let spawnPlan = AquaDotRecoveredBugRoster.makeSpawnPlan(
            difficulty: skillBaseDifficulty,
            random: &setupRandom
        )
        precondition(spawnPlan.count == AquaDotRecoveredBugRoster.enemyCount)
        let bugs = topology.enemyStarts.enumerated().map { index, start in
            let spawn = spawnPlan[index % spawnPlan.count]
            return AquaDotBugState(
                id: start.id,
                personality: spawn.personality,
                homeNode: start.position,
                currentNode: start.position,
                nextNode: nil,
                segmentProgress: 0,
                movementDirection: nil,
                mode: .hunting,
                recoveryDelay: 0,
                isNeonAppearance: spawn.isNeonAppearance
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
            goodieSpawnCountdown: dotTuning.firstGoodieDelay,
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
                initialMunchDots: topology.munchDots.count,
                skillBaseDifficulty: Float(skillBaseDifficulty)
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

        // Initialize the recovered personality-specific AI at the same level
        // difficulty already supplied to original Skill/campaign logic. The
        // executable clamps this input to 1.0 before interpolating AI parameters.
        advancedBugRuntime.removeAll(keepingCapacity: true)
        for bug in state.bugs {
            if let runtime = AquaDotRecoveredAdvancedBugRuntime(
                personality: bug.effectivePersonality,
                difficulty: skillBaseDifficulty
            ) {
                advancedBugRuntime[bug.id] = runtime
            }
        }

        collect(at: first)
    }

    /// Testable reconstructed campaign availability layer. The new campaign keeps
    /// the original Phase-2 basic four; advanced guide personalities phase in as
    /// levels are cleared. This schedule is not labeled binary-exact.
    static func phase3BBugRoster(
        levelsCleared: Int,
        enemyCount: Int,
        random: inout AquaDotSeededRandom
    ) -> [AquaDotBugPersonality] {
        guard enemyCount > 0 else { return [] }
        var pool = AquaDotBugPersonality.basicRoster
        if levelsCleared > 0 {
            let unlockedCount = min(
                AquaDotBugPersonality.advancedRoster.count,
                max(1, 1 + (levelsCleared - 1) / 2)
            )
            pool.append(contentsOf: AquaDotBugPersonality.advancedRoster.prefix(unlockedCount))
        }

        if pool.count > 1 {
            for i in stride(from: pool.count - 1, through: 1, by: -1) {
                let j = random.int(upperBound: i + 1)
                pool.swapAt(i, j)
            }
        }

        var result: [AquaDotBugPersonality] = []
        result.reserveCapacity(enemyCount)
        for index in 0..<enemyCount {
            result.append(pool[index % pool.count])
        }

        if levelsCleared > 0,
           !result.contains(where: { AquaDotBugPersonality.advancedRoster.contains($0) }),
           !result.isEmpty {
            let unlockedCount = min(
                AquaDotBugPersonality.advancedRoster.count,
                max(1, 1 + (levelsCleared - 1) / 2)
            )
            result[result.count - 1] = AquaDotBugPersonality.advancedRoster[
                random.int(upperBound: unlockedCount)
            ]
        }
        return result
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
            notifyProtectorsOfDotEaten(at: position)
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
            // Original 0x94a0c snapshots the number of bugs eligible for this
            // Munch window; 0x94a10 counts the ones eaten before the window ends.
            state.levelStats.currentMunchEligibleBugs = state.bugs.reduce(into: 0) { count, bug in
                if bug.mode != .returningHome { count += 1 }
            }
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
                if collectedKind == .yummy { state.levelStats.yummyEaten += 1 }
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
        updateRecoveredAdvancedBugState(deltaTime: deltaTime)

        for index in state.bugs.indices {
            if state.bugs[index].recoveryDelay > 0 {
                state.bugs[index].recoveryDelay = max(0, state.bugs[index].recoveryDelay - deltaTime)
                if state.bugs[index].recoveryDelay == 0 {
                    state.bugs[index].mode = state.isMunchActive ? .frightened : .hunting
                }
                continue
            }

            let bug = state.bugs[index]
            var speed = tuning.bugCellsPerSecond
            switch bug.effectivePersonality {
            case .hunter, .blocker, .loneWolf:
                break
            case .sneaker:
                // Guide-backed behavior; exact basic-personality speed constants
                // remain outside Phase 4F's advanced-personality recovery scope.
                speed *= bug.lastSegmentWasTurn ? 1.38 : 0.58
            case .houndDog:
                speed *= houndDogHasRecentScent(bug) ? 1.32 : 0.92
            case .protector, .mantis, .hermit:
                // Phase 4F: original low/high enemy activity factors and timed
                // ramps replace the Phase 3B guessed speed multipliers.
                speed *= advancedBugRuntime[bug.id]?.activity.current ?? 1.0
            case .neon:
                // `effectivePersonality` normally dispatches Neon to its emulated
                // strategy. This is only a malformed-state fallback.
                break
            }

            if case .yummy(.dreamy)? = state.activeSpecialPower { speed *= 0.48 }
            if bug.mode == .returningHome { speed *= 1.75 }
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

        let turned = bug.movementDirection != nil && bug.movementDirection != direction
        state.bugs[index].lastSegmentWasTurn = turned
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

            // Guide and binary architecture prove generic warp slowdown. Hermit is
            // explicitly "very slow" in warps, but Phase 4F did not yet recover
            // the exact Hermit warp-delay scalar, so this one compatibility value
            // intentionally remains isolated in Tuning.
            let warpDelay = state.bugs[index].effectivePersonality == .hermit
                ? tuning.hermitWarpSlowdown
                : tuning.bugWarpSlowdown
            state.bugs[index].recoveryDelay = max(state.bugs[index].recoveryDelay, warpDelay)
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
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        let target: GridPosition
        switch bug.effectivePersonality {
        case .hunter, .loneWolf:
            // The shipped guide identifies Lone Wolf as a distinct strategy but
            // gives the same top-level contract as Hunter: take the shortest
            // route to AquaDot. The cached graph implements that recovered target
            // without claiming unrecovered lower-level turn nuance is bit-exact.
            target = player
        case .blocker:
            target = pathfinding.projectedNode(
                from: player,
                direction: state.player.movementDirection,
                steps: 5
            )
        case .sneaker:
            target = pathfinding.projectedNode(
                from: player,
                direction: state.player.movementDirection?.opposite,
                steps: 4
            )
        case .houndDog:
            let scented = state.recentPlayerTrail.reversed().first { point in
                (pathfinding.shortestDistance(from: bug.currentNode, to: point) ?? Int.max) <= 2
            }
            if let scented {
                target = scented
            } else {
                return randomBugDirection(from: bug.currentNode, avoiding: reverse)
            }
        case .protector:
            return chooseRecoveredProtectorDirection(for: bug, avoiding: reverse)
        case .mantis:
            return chooseRecoveredMantisDirection(for: bug, avoiding: reverse)
        case .hermit:
            return chooseRecoveredHermitDirection(for: bug, avoiding: reverse)
        case .neon:
            // Neon is normally dispatched through `effectivePersonality`. Exact
            // original Neon strategy-dispatch code remains a later RE target.
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }
        return pathfinding.shortestDirection(from: bug.currentNode, to: target, avoiding: reverse)
    }

    // MARK: - Phase 4F recovered advanced bug AI

    /// The original Protector receives this event directly when a required dot is
    /// eaten. It uses squared grid distance, a front/behind range split, a 90%
    /// notice test, a five-decision anger budget and a two-second activity ramp.
    private func notifyProtectorsOfDotEaten(at position: GridPosition) {
        for index in state.bugs.indices {
            let bug = state.bugs[index]
            guard bug.mode == .hunting,
                  bug.effectivePersonality == .protector,
                  var runtime = advancedBugRuntime[bug.id] else { continue }

            if runtime.protectorMode == .angry {
                // Original handler only refreshes a nearly-expired anger budget.
                if runtime.protectorDecisionsRemaining <= 4 {
                    runtime.protectorDecisionsRemaining = AquaDotRecoveredAdvancedBugAI.protectorDecisionBudget
                }
                advancedBugRuntime[bug.id] = runtime
                continue
            }

            let observer = roundedBugGridPosition(bug)
            guard AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
                observer: observer,
                facing: bug.movementDirection,
                target: position,
                frontDistanceSquared: AquaDotRecoveredAdvancedBugAI.protectorFrontDistanceSquared,
                behindDistanceSquared: AquaDotRecoveredAdvancedBugAI.protectorBehindDistanceSquared
            ), random.double() < AquaDotRecoveredAdvancedBugAI.protectorNoticeProbability else {
                advancedBugRuntime[bug.id] = runtime
                continue
            }

            runtime.protectorMode = .angry
            runtime.protectorTarget = nil
            runtime.protectorDecisionsRemaining = AquaDotRecoveredAdvancedBugAI.protectorDecisionBudget
            runtime.activity.transitionHigh(
                fullDuration: AquaDotRecoveredAdvancedBugAI.protectorTransitionSeconds
            )
            advancedBugRuntime[bug.id] = runtime
        }
    }

    /// Per-fixed-step adapter around the event/timer portions of the recovered
    /// advanced state. Activity interpolation is exact in shape and deterministic;
    /// Mantis' historical stopped-player *sample* counter is normalized to 60 Hz
    /// because the shipped executable's outer update cadence is not yet proven.
    private func updateRecoveredAdvancedBugState(deltaTime: Double) {
        let player = state.player.currentNode
        let playerMoving = state.player.nextNode != nil

        for index in state.bugs.indices {
            let bug = state.bugs[index]
            guard var runtime = advancedBugRuntime[bug.id] else { continue }
            runtime.activity.step(deltaTime: deltaTime)

            guard bug.mode == .hunting else {
                advancedBugRuntime[bug.id] = runtime
                continue
            }

            if bug.effectivePersonality == .mantis {
                if playerMoving {
                    runtime.mantisStoppedAccumulator = 0
                    runtime.mantisNoticeElapsed += deltaTime

                    while runtime.mantisNoticeElapsed >= AquaDotRecoveredAdvancedBugAI.mantisNoticeGateSeconds {
                        runtime.mantisNoticeElapsed -= AquaDotRecoveredAdvancedBugAI.mantisNoticeGateSeconds

                        // The original timestamp gate continues to advance while
                        // attacking, but only wandering Mantis can acquire here.
                        guard runtime.mantisMode == .wandering else { continue }
                        let observer = roundedBugGridPosition(bug)
                        guard AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
                            observer: observer,
                            facing: bug.movementDirection,
                            target: player,
                            frontDistanceSquared: AquaDotRecoveredAdvancedBugAI.mantisFrontDistanceSquared,
                            behindDistanceSquared: AquaDotRecoveredAdvancedBugAI.mantisBehindDistanceSquared
                        ), random.double() < AquaDotRecoveredAdvancedBugAI.mantisNoticeProbability else {
                            continue
                        }

                        runtime.mantisMode = .attacking
                        runtime.mantisInterruptedMovementSamples = 0
                        runtime.activity.transitionHigh(
                            fullDuration: AquaDotRecoveredAdvancedBugAI.mantisAttackTransitionSeconds
                        )
                    }
                } else if runtime.mantisMode == .attacking {
                    runtime.mantisStoppedAccumulator += deltaTime
                    while runtime.mantisStoppedAccumulator >= AquaDotRecoveredAdvancedBugAI.mantisStoppedSampleSeconds {
                        runtime.mantisStoppedAccumulator -= AquaDotRecoveredAdvancedBugAI.mantisStoppedSampleSeconds
                        runtime.mantisInterruptedMovementSamples += 1
                    }
                }
            }

            advancedBugRuntime[bug.id] = runtime
        }
    }

    private func chooseRecoveredProtectorDirection(
        for bug: AquaDotBugState,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        guard var runtime = advancedBugRuntime[bug.id] else {
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        if runtime.protectorMode == .angry {
            runtime.protectorDecisionsRemaining -= 1
            if runtime.protectorDecisionsRemaining < 0 {
                releaseProtectorToPatrol(&runtime)
                let direction = chooseProtectorPatrolDirection(
                    for: bug,
                    runtime: &runtime,
                    avoiding: reverse
                )
                advancedBugRuntime[bug.id] = runtime
                return direction
            }

            // 0x1bb6e is the original shared aggressive chooser. The Revival's
            // cached shortest-path direction is our explicit graph-level adapter.
            let aggressive = pathfinding.shortestDirection(
                from: bug.currentNode,
                to: state.player.currentNode,
                avoiding: reverse
            ) ?? randomBugDirection(from: bug.currentNode, avoiding: reverse)

            if let aggressive,
               let current = bug.movementDirection,
               aggressive != current,
               random.double() < AquaDotRecoveredAdvancedBugAI.protectorEarlyReleaseProbability(
                    decisionsRemaining: runtime.protectorDecisionsRemaining
               ) {
                // Original 0x1b5f4 selects an alternate direction before dropping
                // back to patrol. Current graph random selection is the adapter.
                let alternate = randomBugDirection(from: bug.currentNode, avoiding: reverse) ?? aggressive
                releaseProtectorToPatrol(&runtime)
                advancedBugRuntime[bug.id] = runtime
                return alternate
            }

            advancedBugRuntime[bug.id] = runtime
            return aggressive
        }

        let direction = chooseProtectorPatrolDirection(for: bug, runtime: &runtime, avoiding: reverse)
        advancedBugRuntime[bug.id] = runtime
        return direction
    }

    private func releaseProtectorToPatrol(_ runtime: inout AquaDotRecoveredAdvancedBugRuntime) {
        runtime.protectorMode = .selectingPatrol
        runtime.protectorTarget = nil
        runtime.protectorDecisionsRemaining = 0
        runtime.activity.transitionLow(
            fullDuration: AquaDotRecoveredAdvancedBugAI.protectorTransitionSeconds
        )
    }

    private func chooseProtectorPatrolDirection(
        for bug: AquaDotBugState,
        runtime: inout AquaDotRecoveredAdvancedBugRuntime,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        switch runtime.protectorMode {
        case .selectingPatrol:
            guard let target = recoveredProtectorPatrolTarget() else {
                return randomBugDirection(from: bug.currentNode, avoiding: reverse)
            }
            runtime.protectorTarget = target
            runtime.protectorMode = .travellingToPatrol
            if target == bug.currentNode {
                runtime.protectorMode = .patrolling
                return recoveredProtectorDotBiasedDirection(from: bug.currentNode, avoiding: reverse)
            }
            return pathfinding.shortestDirection(from: bug.currentNode, to: target, avoiding: reverse)
                ?? randomBugDirection(from: bug.currentNode, avoiding: reverse)

        case .travellingToPatrol:
            guard let target = runtime.protectorTarget else {
                runtime.protectorMode = .selectingPatrol
                return randomBugDirection(from: bug.currentNode, avoiding: reverse)
            }
            if target == bug.currentNode {
                runtime.protectorMode = .patrolling
                return recoveredProtectorDotBiasedDirection(from: bug.currentNode, avoiding: reverse)
            }
            return pathfinding.shortestDirection(from: bug.currentNode, to: target, avoiding: reverse)
                ?? randomBugDirection(from: bug.currentNode, avoiding: reverse)

        case .patrolling:
            if let direction = recoveredProtectorDotBiasedDirection(from: bug.currentNode, avoiding: reverse) {
                return direction
            }
            runtime.protectorMode = .selectingPatrol
            runtime.protectorTarget = nil
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)

        case .angry:
            return nil
        }
    }

    /// Original 0x33cf2 sorts intersections by remaining-dot count, considers
    /// through index floor(n*0.5), drops zero-weight tail entries and chooses from
    /// that top group weighted by count. The original maze engine owns explicit
    /// intersection records; the Revival translates those records to graph nodes
    /// with at least three corridor exits and assigns each normal dot to its
    /// nearest such node using the cached distance matrix.
    private func recoveredProtectorPatrolTarget() -> GridPosition? {
        var candidates = Array(topology.traversable.filter { position in
            topology.edges(from: position).reduce(into: 0) { count, edge in
                if case .corridor = edge.kind { count += 1 }
            } >= 3
        })
        if candidates.isEmpty { candidates = Array(topology.traversable) }
        guard !candidates.isEmpty else { return nil }

        let stableCandidates = candidates.sorted(by: stableGridOrder)
        var weights = Dictionary(uniqueKeysWithValues: stableCandidates.map { ($0, 0) })
        let normalDots = state.dots.compactMap { position, kind in
            kind == .normal ? position : nil
        }

        for dot in normalDots {
            guard let nearest = stableCandidates.min(by: { lhs, rhs in
                let ld = pathfinding.shortestDistance(from: lhs, to: dot) ?? Int.max
                let rd = pathfinding.shortestDistance(from: rhs, to: dot) ?? Int.max
                if ld != rd { return ld < rd }
                return stableGridOrder(lhs, rhs)
            }) else { continue }
            weights[nearest, default: 0] += 1
        }

        let ranked = stableCandidates.sorted { lhs, rhs in
            let lw = weights[lhs, default: 0]
            let rw = weights[rhs, default: 0]
            if lw != rw { return lw > rw }
            return stableGridOrder(lhs, rhs)
        }
        let topCount = min(ranked.count, Int(floor(Double(ranked.count) * 0.5)) + 1)
        let top = Array(ranked.prefix(topCount)).filter { weights[$0, default: 0] > 0 }
        guard !top.isEmpty else { return nil }
        return weightedGridChoice(top, weights: weights)
    }

    /// Graph-level translation of Protector state 1's per-direction remaining-dot
    /// counts. Each normal dot contributes to the outgoing branch that reaches it
    /// with the shortest cached distance; weighted choice then mirrors the original
    /// dot-density bias without inventing a fixed patrol destination.
    private func recoveredProtectorDotBiasedDirection(
        from position: GridPosition,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        let allEdges = topology.edges(from: position)
        let filtered = allEdges.filter { $0.direction != reverse }
        let usable = (filtered.isEmpty ? allEdges : filtered).sorted {
            $0.direction.rawValue < $1.direction.rawValue
        }
        guard !usable.isEmpty else { return nil }

        var weights = Array(repeating: 0, count: usable.count)
        for (dot, kind) in state.dots where kind == .normal {
            var bestIndex: Int?
            var bestDistance = Int.max
            for (index, edge) in usable.enumerated() {
                let distance = pathfinding.shortestDistance(from: edge.destination, to: dot) ?? Int.max
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndex = index
                }
            }
            if let bestIndex, bestDistance < Int.max {
                weights[bestIndex] += 1
            }
        }

        let total = weights.reduce(0, +)
        guard total > 0 else { return nil }
        var draw = random.int(upperBound: total)
        for (index, weight) in weights.enumerated() where weight > 0 {
            if draw < weight { return usable[index].direction }
            draw -= weight
        }
        return usable.last?.direction
    }

    private func chooseRecoveredMantisDirection(
        for bug: AquaDotBugState,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        guard var runtime = advancedBugRuntime[bug.id] else {
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        switch runtime.mantisMode {
        case .wandering:
            advancedBugRuntime[bug.id] = runtime
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)

        case .attacking:
            let playerMoving = state.player.nextNode != nil
            let interruptedChance = min(
                1.0,
                Double(runtime.mantisInterruptedMovementSamples)
                    * AquaDotRecoveredAdvancedBugAI.mantisStoppedSampleProbability
            )
            if !playerMoving ||
                (runtime.mantisInterruptedMovementSamples > 0 && random.double() < interruptedChance) {
                enterMantisConfusion(&runtime)
                let direction = chooseRecoveredMantisConfusionDirection(
                    for: bug,
                    runtime: &runtime,
                    avoiding: reverse
                )
                advancedBugRuntime[bug.id] = runtime
                return direction
            }

            let direction = pathfinding.shortestDirection(
                from: bug.currentNode,
                to: state.player.currentNode,
                avoiding: reverse
            ) ?? randomBugDirection(from: bug.currentNode, avoiding: reverse)
            advancedBugRuntime[bug.id] = runtime
            return direction

        case .confused:
            let direction = chooseRecoveredMantisConfusionDirection(
                for: bug,
                runtime: &runtime,
                avoiding: reverse
            )
            advancedBugRuntime[bug.id] = runtime
            return direction
        }
    }

    private func enterMantisConfusion(_ runtime: inout AquaDotRecoveredAdvancedBugRuntime) {
        runtime.mantisMode = .confused
        runtime.mantisConfusionCounter = AquaDotRecoveredAdvancedBugAI.mantisConfusionCounter
        runtime.mantisInterruptedMovementSamples = 0
        runtime.mantisStoppedAccumulator = 0
        runtime.activity.transitionLow(
            fullDuration: AquaDotRecoveredAdvancedBugAI.mantisReturnTransitionSeconds
        )
    }

    private func chooseRecoveredMantisConfusionDirection(
        for bug: AquaDotBugState,
        runtime: inout AquaDotRecoveredAdvancedBugRuntime,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        // Original 0x1b478 is a probabilistic turn-away chooser whose internal
        // graph weighting is not yet recovered. directionAway preserves the
        // documented "turn away" behavior and keeps that boundary explicit.
        runtime.mantisConfusionCounter -= 1
        let direction = pathfinding.directionAway(
            from: bug.currentNode,
            threat: state.player.currentNode,
            avoiding: reverse
        ) ?? randomBugDirection(from: bug.currentNode, avoiding: reverse)
        if runtime.mantisConfusionCounter < 0 {
            runtime.mantisMode = .wandering
            runtime.mantisNoticeElapsed = 0
        }
        return direction
    }

    private func chooseRecoveredHermitDirection(
        for bug: AquaDotBugState,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        guard var runtime = advancedBugRuntime[bug.id] else {
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        // Original +12 state forces the first four post-abandonment decisions to
        // remain random before distance is reconsidered. At count >=5, distance is
        // checked on every decision so a newly-near AquaDot can be reacquired.
        if (1...4).contains(runtime.hermitWanderDecisionCount) {
            runtime.hermitWanderDecisionCount += 1
            advancedBugRuntime[bug.id] = runtime
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        let player = state.player.currentNode
        let distance = pathfinding.shortestDistance(from: bug.currentNode, to: player) ?? Int.max
        guard distance <= AquaDotRecoveredAdvancedBugAI.hermitChaseDistance,
              let chaseDirection = pathfinding.shortestDirection(
                  from: bug.currentNode,
                  to: player,
                  avoiding: reverse
              ) else {
            abandonHermitChase(&runtime)
            advancedBugRuntime[bug.id] = runtime
            return randomBugDirection(from: bug.currentNode, avoiding: reverse)
        }

        let requiresTurn = bug.movementDirection != nil && bug.movementDirection != chaseDirection
        if requiresTurn {
            let shouldContinue: Bool
            if runtime.hermitTurnCounter <= 4 {
                shouldContinue = true
            } else {
                shouldContinue = random.double() < AquaDotRecoveredAdvancedBugAI.hermitContinueProbability(
                    turnCounter: runtime.hermitTurnCounter
                )
            }
            guard shouldContinue else {
                abandonHermitChase(&runtime)
                advancedBugRuntime[bug.id] = runtime
                return randomBugDirection(from: bug.currentNode, avoiding: reverse)
            }
            runtime.hermitTurnCounter += 1
            runtime.hermitWanderDecisionCount = 0
        } else if runtime.hermitTurnCounter == 0 {
            runtime.hermitTurnCounter = 1
            runtime.hermitWanderDecisionCount = 0
        }

        if !runtime.hermitChasing {
            runtime.hermitChasing = true
            runtime.activity.transitionHigh(
                fullDuration: AquaDotRecoveredAdvancedBugAI.hermitAttackTransitionSeconds
            )
        }
        advancedBugRuntime[bug.id] = runtime
        return chaseDirection
    }

    private func abandonHermitChase(_ runtime: inout AquaDotRecoveredAdvancedBugRuntime) {
        runtime.hermitChasing = false
        runtime.hermitTurnCounter = 0
        runtime.hermitWanderDecisionCount += 1
        runtime.activity.transitionLow(
            fullDuration: AquaDotRecoveredAdvancedBugAI.hermitReturnTransitionSeconds
        )
    }

    private func roundedBugGridPosition(_ bug: AquaDotBugState) -> GridPosition {
        let rendered = bug.renderPosition()
        return GridPosition(
            x: Int(rendered.x.rounded()),
            y: Int(rendered.y.rounded())
        )
    }

    private func randomBugDirection(
        from position: GridPosition,
        avoiding reverse: AquaDotDirection?
    ) -> AquaDotDirection? {
        let candidates = topology.edges(from: position).filter { $0.direction != reverse }
        let usable = candidates.isEmpty ? topology.edges(from: position) : candidates
        return usable.isEmpty ? nil : usable[random.int(upperBound: usable.count)].direction
    }

    private func weightedGridChoice(
        _ positions: [GridPosition],
        weights: [GridPosition: Int]
    ) -> GridPosition? {
        let total = positions.reduce(0) { $0 + max(0, weights[$1, default: 0]) }
        guard total > 0 else { return nil }
        var draw = random.int(upperBound: total)
        for position in positions {
            let weight = max(0, weights[position, default: 0])
            if draw < weight { return position }
            draw -= weight
        }
        return positions.last
    }

    private func stableGridOrder(_ lhs: GridPosition, _ rhs: GridPosition) -> Bool {
        if lhs.y != rhs.y { return lhs.y < rhs.y }
        return lhs.x < rhs.x
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
            if !state.levelStats.damageMeasurementActive {
                // `skill_startDamageMeasurment`: dangerous contact clears the
                // no-damage flag and snapshots the Energy meter once per window.
                state.levelStats.damageContactOccurred = true
                state.levelStats.damageMeasurementActive = true
                state.levelStats.damageMeasurementStartEnergy = Float(state.energy)
            }

            let moving = state.player.nextNode != nil
            var rate = moving ? tuning.movingBugDamagePerSecond : tuning.stoppedBugDamagePerSecond
            if case .yuk(.tasty)? = state.activeSpecialPower { rate *= 4.0 }
            if case .yummy(.energetic)? = state.activeSpecialPower { rate *= 0.45 }
            state.energy = max(0, state.energy - rate * deltaTime)
            if damageEventCooldown <= 0 {
                pendingEvents.append(.playerDamaged)
                damageEventCooldown = 0.22
            }
            if state.energy <= 0 { loseLife() }
        } else {
            finalizeDamageSkillMeasurement()
        }
    }

    /// Mirror the original damage-stop helper: only net Energy loss across a
    /// contact window is accumulated, and the end-of-window Energy updates the
    /// retained minimum. Death and level completion explicitly call this before
    /// resetting/consuming their state.
    private func finalizeDamageSkillMeasurement() {
        guard state.levelStats.damageMeasurementActive else { return }
        let start = state.levelStats.damageMeasurementStartEnergy
        let current = Float(state.energy)
        if current <= start {
            state.levelStats.damageTaken += Double(start - current)
            state.levelStats.minimumEnergyAfterDamage = min(
                state.levelStats.minimumEnergyAfterDamage,
                current
            )
        }
        state.levelStats.damageMeasurementActive = false
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
        if state.levelStats.currentMunchEligibleBugs > 0,
           state.bugsEatenThisMunch >= state.levelStats.currentMunchEligibleBugs {
            state.levelStats.fullBugClearsDuringMunch += 1
            // Prevent a second increment if any malformed event reaches this
            // Munch after all originally eligible bugs have already been eaten.
            state.levelStats.currentMunchEligibleBugs = 0
        }
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
                switch kind {
                case .yummy:
                    state.levelStats.activeYummyDots += 1
                case .yuk:
                    state.levelStats.yukSpawned += 1
                    state.levelStats.activeYukDots += 1
                case .bonus, .multiplier:
                    break
                }
            }
        }
    }

    private func finishMunchSkillWindow() {
        guard state.munchTimeRemaining > 0
                || state.bugsEatenThisMunch > 0
                || state.levelStats.currentMunchEligibleBugs > 0 else { return }
        if state.bugsEatenThisMunch > 0 {
            state.levelStats.munchesWithAtLeastOneBug += 1
        }
        state.levelStats.currentMunchEligibleBugs = 0
    }

    private func completeLevel() {
        guard !state.levelCompleted else { return }

        finalizeDamageSkillMeasurement()
        if state.munchTimeRemaining > 0 { finishMunchSkillWindow() }

        // Phase 4B recovers the original Skill arithmetic and quality thresholds.
        // The surrounding relationship was already guide-proven:
        // (Bonus + Skill) × Multiplier.
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
        // Original death path increments the death counter and explicitly closes
        // an active damage measurement before the Energy meter is reset.
        finalizeDamageSkillMeasurement()
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

        dotSystem.resetAfterLifeLoss(
            state: &state,
            random: &random,
            events: &pendingEvents
        )
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
            state.bugs[index].alertTimeRemaining = 0
            state.bugs[index].awarenessCooldown = 0
            state.bugs[index].turnsWhileAlerted = 0
            state.bugs[index].lastSegmentWasTurn = false
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
