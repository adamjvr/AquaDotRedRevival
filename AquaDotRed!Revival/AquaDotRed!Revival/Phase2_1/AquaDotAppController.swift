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

    var canResumeGame: Bool { activeGameScene != nil }

    func startNewGame() {
        activeGameScene?.shutdown()
        let scene = MazeGameScene()
        scene.size = CGSize(width: 800, height: 700)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        activeGameScene = scene
        route = .game
    }

    func resumeGame() {
        if activeGameScene == nil {
            startNewGame()
        } else {
            route = .game
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
