import SwiftUI
#if os(macOS)
import AppKit
#endif

#if os(macOS)
/// Ensures the running native macOS app uses the recovered AquaDot artwork in
/// its Dock tile. The normal Xcode AppIcon catalog remains authoritative for
/// packaging/Finder/iPadOS; this is an explicit runtime Dock presentation path.
private final class AquaDotMacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        applyRecoveredDockIcon()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        applyRecoveredDockIcon()
    }

    private func applyRecoveredDockIcon() {
        let name = NSImage.Name("AquaDotDockIcon")
        guard let image = NSImage(named: name) else {
            print("AquaDot: recovered Dock icon asset AquaDotDockIcon was not found")
            return
        }
        NSApplication.shared.applicationIconImage = image
    }
}
#endif


@main
struct AquaDotRed_RevivalApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AquaDotMacAppDelegate.self)
    private var appDelegate
    #endif

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
