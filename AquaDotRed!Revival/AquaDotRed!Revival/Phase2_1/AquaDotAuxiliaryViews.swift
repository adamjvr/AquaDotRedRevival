import SwiftUI

struct AquaDotHelpView: View {
    @ObservedObject var controller: AquaDotAppController
    @ObservedObject private var preferences = AquaDotPreferences.shared
    private var suffix: String { preferences.graphicsMode == .remastered ? "Remastered" : "Original" }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            ScrollView([.horizontal, .vertical]) {
                Image("P21_HelpPage_\(suffix)")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 1000)
                    .padding(24)
            }
            Button("Back") { controller.closeAuxiliaryScreen() }
                .buttonStyle(.borderedProminent).tint(.cyan).padding(20)
        }
    }
}

struct AquaDotAboutView: View {
    @ObservedObject var controller: AquaDotAppController
    @ObservedObject private var preferences = AquaDotPreferences.shared
    private var suffix: String { preferences.graphicsMode == .remastered ? "Remastered" : "Original" }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            ScrollView([.horizontal, .vertical]) {
                Image("P21_AboutPage_\(suffix)")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 1000)
                    .padding(24)
            }
            Button("Back") { controller.closeAuxiliaryScreen() }
                .buttonStyle(.borderedProminent).tint(.cyan).padding(20)
        }
    }
}

struct AquaDotScoresView: View {
    @ObservedObject var controller: AquaDotAppController
    @ObservedObject private var preferences = AquaDotPreferences.shared
    private var suffix: String { preferences.graphicsMode == .remastered ? "Remastered" : "Original" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 22) {
                Image("P21_Menu_Scores_Cyan_\(suffix)")
                    .resizable().scaledToFit().frame(height: 58)
                Text("HIGH SCORES")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                Text("The original high-score subsystem is recovered and reserved for the campaign/progression pass.\nThis screen is now part of the real opening flow instead of dropping directly into a maze.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .frame(maxWidth: 560)
                Button("Back") { controller.closeAuxiliaryScreen() }
                    .buttonStyle(.borderedProminent).tint(.cyan)
            }
            .padding(32)
        }
    }
}
