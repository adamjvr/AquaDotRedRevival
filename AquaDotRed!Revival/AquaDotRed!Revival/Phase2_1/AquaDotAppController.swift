import Foundation
import SpriteKit
import SwiftUI

enum AquaDotAppRoute: String, Sendable {
    case opening
    case game
    case options
    case scores
    case highScoreEntry
    case help
    case about
}

extension Notification.Name {
    static let aquaDotTogglePause = Notification.Name("AquaDotRevival.togglePause")
}

/// Application-level state. The SpriteKit simulation remains independent; this
/// object owns the shell around it and keeps an active scene alive while the user
/// temporarily visits Options/Help, matching the original resume-game flow.
final class AquaDotAppController: ObservableObject {
    static let shared = AquaDotAppController()

    @Published var route: AquaDotAppRoute = .opening
    @Published private(set) var pendingHighScore: AquaDotHighScoreRecord?
    let preferences = AquaDotPreferences.shared

    private(set) var activeGameScene: MazeGameScene?
    private var returnRoute: AquaDotAppRoute = .opening
    private let campaignStore = AquaDotCampaignStore.shared
    private let highScoreStore = AquaDotHighScoreStore.shared

    /// True for either an in-memory paused session or the original-style
    /// beginning-of-level auto-save persisted across app launches.
    var canResumeGame: Bool { activeGameScene != nil || campaignStore.load() != nil }

    private func makeGameScene(
        levelIndex: Int? = nil,
        carry: AquaDotRunCarry,
        selectorState: AquaDotCampaignSelectorState? = nil
    ) -> MazeGameScene {
        let scene = MazeGameScene()
        scene.size = CGSize(width: 800, height: 700)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        if let levelIndex {
            scene.configureCampaignStart(
                levelIndex: levelIndex,
                carry: carry,
                selectorState: selectorState
            )
        }
        return scene
    }

    func startNewGame() {
        activeGameScene?.shutdown()
        pendingHighScore = nil
        campaignStore.clear()
        // A fresh scene invokes the recovered random campaign selector itself.
        // There is intentionally no fixed Ewe (1) start anymore.
        activeGameScene = makeGameScene(carry: .fresh)
        route = .game
    }

    func resumeGame() {
        if activeGameScene != nil {
            route = .game
            return
        }

        if let checkpoint = campaignStore.load() {
            activeGameScene = makeGameScene(
                levelIndex: checkpoint.levelIndex,
                carry: checkpoint.carry,
                selectorState: checkpoint.selectorState
            )
            route = .game
        } else {
            startNewGame()
        }
    }

    func showOpening() {
        if route == .game { activeGameScene?.suspendForShell() }
        route = .opening
    }

    func endCurrentGameAndShowOpening() {
        activeGameScene?.shutdown()
        activeGameScene = nil
        pendingHighScore = nil
        route = .opening
    }

    /// Commit the terminal run immediately when Game Over occurs. Doing this
    /// before the presentation delay means force-quitting on the Game Over screen
    /// cannot resurrect the dead run from its last auto-save.
    func commitGameOver(finalScore: Int, levelsCleared: Int) {
        // Preserve Phase 3's crash-safety: the terminal result is durable before
        // the Game Over presentation finishes. Phase 3D then lets the player name
        // this exact UUID-backed record instead of creating a second score later.
        pendingHighScore = highScoreStore.record(
            score: finalScore,
            levelsCleared: levelsCleared
        )
        campaignStore.clear()
    }

    /// Called after the recovered Game Over artwork has had time to display.
    func finishGameOverPresentation() {
        activeGameScene?.shutdown()
        activeGameScene = nil
        returnRoute = .opening
        route = pendingHighScore == nil ? .scores : .highScoreEntry
    }

    func submitPendingHighScoreName(_ name: String) {
        guard let pendingHighScore else {
            route = .scores
            return
        }
        self.pendingHighScore = highScoreStore.rename(
            recordID: pendingHighScore.id,
            name: name
        )
        self.pendingHighScore = nil
        returnRoute = .opening
        route = .scores
    }

    func keepPendingHighScoreAnonymous() {
        pendingHighScore = nil
        returnRoute = .opening
        route = .scores
    }

    func showOptions(returnTo: AquaDotAppRoute? = nil) {
        returnRoute = returnTo ?? route
        if route == .game { activeGameScene?.suspendForShell() }
        route = .options
    }

    func showScores() {
        enterAuxiliary(.scores)
    }

    func showHelp() {
        enterAuxiliary(.help)
    }

    func showAbout() {
        enterAuxiliary(.about)
    }

    private func enterAuxiliary(_ destination: AquaDotAppRoute) {
        returnRoute = route == .game ? .game : .opening
        if route == .game { activeGameScene?.suspendForShell() }
        route = destination
    }

    func closeAuxiliaryScreen() {
        if returnRoute == .game, activeGameScene == nil {
            route = .opening
        } else {
            route = returnRoute
        }
    }

    func requestPauseToggle() {
        NotificationCenter.default.post(name: .aquaDotTogglePause, object: nil)
    }
}
