import SwiftUI

struct ContentView: View {
    @StateObject private var controller = AquaDotAppController.shared

    var body: some View {
        Group {
            switch controller.route {
            case .opening:
                AquaDotOpeningView(controller: controller)
            case .game:
                GameView()
            case .options:
                AquaDotOptionsView(controller: controller)
            case .scores:
                AquaDotScoresView(controller: controller)
            case .highScoreEntry:
                AquaDotHighScoreEntryView(controller: controller)
            case .help:
                AquaDotHelpView(controller: controller)
            case .about:
                AquaDotAboutView(controller: controller)
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
