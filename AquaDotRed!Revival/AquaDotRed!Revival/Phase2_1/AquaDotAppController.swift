import Foundation
import SpriteKit
import SwiftUI

enum AquaDotAppRoute: String, Sendable {
    case opening
    case game
    case options
    case scores
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
    let preferences = AquaDotPreferences.shared

    private(set) var activeGameScene: MazeGameScene?
    private var returnRoute: AquaDotAppRoute = .opening
    private let campaignStore = AquaDotCampaignStore.shared
    private let highScoreStore = AquaDotHighScoreStore.shared

    /// True for either an in-memory paused session or the original-style
    /// beginning-of-level auto-save persisted across app launches.
    var canResumeGame: Bool { activeGameScene != nil || campaignStore.load() != nil }

    private var defaultCampaignStartIndex: Int {
        AquaDotOriginalLevelCatalog.standardLevels.firstIndex { $0.originalName == "Ewe (1)" } ?? 0
    }

    private func makeGameScene(levelIndex: Int, carry: AquaDotRunCarry) -> MazeGameScene {
        let scene = MazeGameScene()
        scene.size = CGSize(width: 800, height: 700)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        scene.configureCampaignStart(levelIndex: levelIndex, carry: carry)
        return scene
    }

    func startNewGame() {
        activeGameScene?.shutdown()
        campaignStore.clear()
        activeGameScene = makeGameScene(levelIndex: defaultCampaignStartIndex, carry: .fresh)
        route = .game
    }

    func resumeGame() {
        if activeGameScene != nil {
            route = .game
            return
        }

        if let checkpoint = campaignStore.load() {
            activeGameScene = makeGameScene(levelIndex: checkpoint.levelIndex, carry: checkpoint.carry)
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
        route = .opening
    }

    /// Commit the terminal run immediately when Game Over occurs. Doing this
    /// before the presentation delay means force-quitting on the Game Over screen
    /// cannot resurrect the dead run from its last auto-save.
    func commitGameOver(finalScore: Int, levelsCleared: Int) {
        highScoreStore.record(score: finalScore, levelsCleared: levelsCleared)
        campaignStore.clear()
    }

    /// Called after the recovered Game Over artwork has had time to display.
    func finishGameOverPresentation() {
        activeGameScene?.shutdown()
        activeGameScene = nil
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
