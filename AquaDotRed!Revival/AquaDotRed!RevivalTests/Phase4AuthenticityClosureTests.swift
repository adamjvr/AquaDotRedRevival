import Testing
@testable import AquaDotRed_Revival

struct Phase4AuthenticityClosureTests {
    @Test func recoveredLegacyVelocityAndWarpFactorsAreLocked() {
        #expect(abs(AquaDotRecoveredEnemyLocomotion.reaperBaseVelocityRatio - 0.2) < 0.000001)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .hunter, isReaper: false) == 0.5)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .loneWolf, isReaper: false) == 0.5)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .houndDog, isReaper: false) == 0.25)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .protector, isReaper: false) == 0.25)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .mantis, isReaper: false) == 0.25)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .hermit, isReaper: false) == 0.25)
        #expect(AquaDotRecoveredEnemyLocomotion.warpVelocityMultiplier(personality: .hunter, isReaper: true) == 1.5)
    }

    @Test func randomReaperScansCyclicallyAndNeverReverses() {
        let valid: Set<AquaDotDirection> = [.right, .down]
        #expect(AquaDotRecoveredEnemyLocomotion.randomReaperDirection(
            startIndex: 0,
            validDirections: valid,
            oppositeDirection: .down
        ) == .right)
        #expect(AquaDotRecoveredEnemyLocomotion.randomReaperDirection(
            startIndex: 2,
            validDirections: valid,
            oppositeDirection: .down
        ) == .right)
    }

    @Test func recoveredInfectionTopologyIsCardinalNotGraphDistance() {
        let o = GridPosition(x: 10, y: 10)
        let right = GridPosition(x: 11, y: 10)
        let right2 = GridPosition(x: 12, y: 10)
        let down = GridPosition(x: 10, y: 11)
        let diagonal = GridPosition(x: 11, y: 11)
        let isolated = GridPosition(x: 10, y: 8)
        let dots: [GridPosition: AquaDotDotKind] = [
            o: .normal, right: .normal, right2: .normal,
            down: .normal, diagonal: .normal, isolated: .normal,
        ]
        let wave = AquaDotDotSystem.recoveredPropagationPositions(
            around: o,
            radius: 1,
            source: .normal,
            destination: .candy,
            dots: dots
        )
        #expect(wave.contains(o))
        #expect(wave.contains(right))
        #expect(wave.contains(down))
        #expect(!wave.contains(right2))
        #expect(!wave.contains(diagonal))
        #expect(!wave.contains(isolated))
    }
}
