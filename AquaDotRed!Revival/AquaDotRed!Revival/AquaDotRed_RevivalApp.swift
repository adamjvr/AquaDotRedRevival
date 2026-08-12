import SwiftUI

@main
struct AquaDotRed_RevivalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .commands {
            AquaDotMacCommands(controller: .shared)
        }
        #endif
    }
}

#if os(macOS)
private struct AquaDotMacCommands: Commands {
    let controller: AquaDotAppController

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Options…") {
                controller.showOptions(returnTo: controller.route == .game ? .game : .opening)
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandMenu("Game") {
            Button("New Game") { controller.startNewGame() }
                .keyboardShortcut("n", modifiers: .command)
            Button("Resume Current Game") { controller.resumeGame() }
            Button("Pause / Resume") {
                if controller.route == .game { controller.requestPauseToggle() }
            }
                .keyboardShortcut("p", modifiers: .command)
            Divider()
            Button("Return to Opening Screen") { controller.showOpening() }
            Button("End Current Game") { controller.endCurrentGameAndShowOpening() }
        }

        CommandMenu("View") {
            Button("Original Graphics") {
                controller.preferences.graphicsMode = .original
            }
            Button("Remastered Graphics") {
                controller.preferences.graphicsMode = .remastered
            }
        }

        CommandGroup(replacing: .help) {
            Button("AquaDot Help") { controller.showHelp() }
            Button("About AquaDot") { controller.showAbout() }
        }
    }
}
#endif
