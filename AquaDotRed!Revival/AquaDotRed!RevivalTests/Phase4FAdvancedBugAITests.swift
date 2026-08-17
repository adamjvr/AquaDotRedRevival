import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase4FAdvancedBugAITests {
    @Test func protectorDifficultyInterpolationMatchesRecoveredParameters() {
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorLowActivity(difficulty: 0.0) - 0.25) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorLowActivity(difficulty: 0.5) - 0.375) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorLowActivity(difficulty: 1.0) - 0.50) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorLowActivity(difficulty: 8.0) - 0.50) < 0.000001)

        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorHighActivity(difficulty: 0.0) - 1.20) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorHighActivity(difficulty: 0.5) - 1.25) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorHighActivity(difficulty: 1.0) - 1.30) < 0.000001)
    }

    @Test func mantisAndHermitActivityParametersMatchRecoveredValues() {
        #expect(AquaDotRecoveredAdvancedBugAI.mantisLowActivity == 0.50)
        #expect(AquaDotRecoveredAdvancedBugAI.mantisHighActivity == 1.00)

        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitHighActivity(difficulty: 0.0) - 1.10) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitHighActivity(difficulty: 0.5) - 1.35) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitHighActivity(difficulty: 1.0) - 1.60) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitHighActivity(difficulty: 9.0) - 1.60) < 0.000001)
    }

    @Test func directionalNoticeRangesUseOriginalStrictSquaredThresholds() {
        let origin = GridPosition(x: 0, y: 0)

        // Protector: front <100, behind <25.
        #expect(AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: 9, y: 0),
            frontDistanceSquared: 100, behindDistanceSquared: 25
        ))
        #expect(!AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: 10, y: 0),
            frontDistanceSquared: 100, behindDistanceSquared: 25
        ))
        #expect(AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: -4, y: 0),
            frontDistanceSquared: 100, behindDistanceSquared: 25
        ))
        #expect(!AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: -5, y: 0),
            frontDistanceSquared: 100, behindDistanceSquared: 25
        ))

        // Mantis: front <225, behind <49.
        #expect(AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: 14, y: 0),
            frontDistanceSquared: 225, behindDistanceSquared: 49
        ))
        #expect(!AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: 15, y: 0),
            frontDistanceSquared: 225, behindDistanceSquared: 49
        ))
        #expect(AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: -6, y: 0),
            frontDistanceSquared: 225, behindDistanceSquared: 49
        ))
        #expect(!AquaDotRecoveredAdvancedBugAI.isInsideDirectionalNoticeRange(
            observer: origin, facing: .right, target: GridPosition(x: -7, y: 0),
            frontDistanceSquared: 225, behindDistanceSquared: 49
        ))
    }

    @Test func recoveredDecisionProbabilitiesMatchMachineCode() {
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorEarlyReleaseProbability(decisionsRemaining: 4) - 0.18) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.protectorEarlyReleaseProbability(decisionsRemaining: 0) - 0.30) < 0.000001)

        #expect(AquaDotRecoveredAdvancedBugAI.hermitContinueProbability(turnCounter: 4) == 1.0)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitContinueProbability(turnCounter: 5) - 0.90) < 0.000001)
        #expect(abs(AquaDotRecoveredAdvancedBugAI.hermitContinueProbability(turnCounter: 8) - 0.60) < 0.000001)
        #expect(AquaDotRecoveredAdvancedBugAI.hermitContinueProbability(turnCounter: 14) == 0.0)
    }

    @Test func activityTransitionScalesDurationByRemainingLowHighFraction() {
        var ramp = AquaDotRecoveredActivityRamp(low: 0.25, high: 1.20, initial: 1.0)
        let expectedInitialDuration = (1.0 - 0.25) / (1.20 - 0.25)
        #expect(abs(ramp.remainingDuration - expectedInitialDuration) < 0.000001)

        ramp.step(deltaTime: expectedInitialDuration)
        #expect(abs(ramp.current - 0.25) < 0.000001)
        #expect(ramp.remainingDuration == 0)

        ramp.transitionHigh(fullDuration: 2.0)
        #expect(abs(ramp.remainingDuration - 2.0) < 0.000001)
        ramp.step(deltaTime: 1.0)
        #expect(abs(ramp.current - 0.725) < 0.000001)
        ramp.step(deltaTime: 1.0)
        #expect(abs(ramp.current - 1.20) < 0.000001)
    }
}
