import Foundation
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
    @State private var today: [AquaDotHighScoreRecord] = []
    @State private var allTime: [AquaDotHighScoreRecord] = []

    private var suffix: String { preferences.graphicsMode == .remastered ? "Remastered" : "Original" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    Image("P21_Menu_Scores_Cyan_\(suffix)")
                        .resizable().scaledToFit().frame(height: 52)
                        .padding(.bottom, 4)

                    scoreSection(
                        heading: "P3_TodaysBest_\(suffix)",
                        records: today,
                        emptyText: "no scores yet today"
                    )

                    scoreSection(
                        heading: "P3_BestScoresEver_\(suffix)",
                        records: allTime,
                        emptyText: "no completed runs yet"
                    )

                    Text("Phase 3D restores a dedicated post-Game Over name-entry state while keeping the terminal score durable before entry.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 620)
                        .padding(.top, 4)

                    Button("Back") { controller.closeAuxiliaryScreen() }
                        .buttonStyle(.borderedProminent).tint(.cyan)
                        .padding(.top, 6)
                }
                .frame(maxWidth: 760)
                .padding(32)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { reloadScores() }
    }

    @ViewBuilder
    private func scoreSection(
        heading: String,
        records: [AquaDotHighScoreRecord],
        emptyText: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(heading)
                .resizable().scaledToFit().frame(maxWidth: 330, maxHeight: 48)

            if records.isEmpty {
                Text(emptyText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                        HStack(spacing: 12) {
                            Text(String(format: "%2d", index + 1))
                                .foregroundStyle(.cyan)
                            Text(record.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(record.levelsCleared) lv")
                                .foregroundStyle(Color.white.opacity(0.62))
                            Text("\(record.score)")
                                .foregroundStyle(.green)
                                .frame(minWidth: 92, alignment: .trailing)
                        }
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func reloadScores() {
        let store = AquaDotHighScoreStore.shared
        today = store.todaysBest(limit: 5)
        allTime = store.bestEver(limit: 10)
    }
}



/// The original binary has a dedicated high-score-entry state (`Opening.cc`) and
/// separate preference routines for testing/inserting named scores (`Prefs.cc`).
/// Exact historical entry-screen artwork and text-length rules are not yet proved,
/// so this is deliberately a modern SwiftUI shell around that recovered state
/// transition rather than a claim of pixel-identical presentation.
struct AquaDotHighScoreEntryView: View {
    @ObservedObject var controller: AquaDotAppController
    @State private var playerName = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let record = controller.pendingHighScore {
                VStack(spacing: 20) {
                    Text("high score")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .italic()
                        .foregroundStyle(.cyan)

                    Text("score  \(record.score)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)

                    Text("levels cleared  \(record.levelsCleared)")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.72))

                    Text("enter your name")
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)

                    TextField("anonymous", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                        .focused($nameFieldFocused)
                        .onSubmit { submit() }

                    HStack(spacing: 14) {
                        Button("Keep Anonymous") {
                            controller.keepPendingHighScoreAnonymous()
                        }
                        .buttonStyle(.bordered)

                        Button("Save Name") { submit() }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                    }
                }
                .padding(36)
                .frame(maxWidth: 620)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.cyan.opacity(0.65), lineWidth: 1.5)
                )
                .padding(28)
            } else {
                ProgressView()
                    .tint(.cyan)
                    .onAppear { controller.keepPendingHighScoreAnonymous() }
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    private func submit() {
        controller.submitPendingHighScoreName(playerName)
    }
}
