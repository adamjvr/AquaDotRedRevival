import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

private struct AquaDotOGImageButtonStyle: ButtonStyle {
    let normalName: String
    let pressedName: String
    let height: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        Image(configuration.isPressed ? pressedName : normalName)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.96 : 1)
    }
}

private struct AquaDotOGMenuButton: View {
    let baseName: String
    let mode: AquaDotGraphicsMode
    let action: () -> Void
    @State private var hovered = false

    private var suffix: String { mode == .remastered ? "Remastered" : "Original" }
    private var normalColor: String { hovered ? "Green" : "Cyan" }

    var body: some View {
        Button(action: action) { EmptyView() }
            .buttonStyle(
                AquaDotOGImageButtonStyle(
                    normalName: "P21_Menu_\(baseName)_\(normalColor)_\(suffix)",
                    pressedName: "P21_Menu_\(baseName)_Red_\(suffix)",
                    height: 42
                )
            )
            #if os(macOS)
            .onHover { hovered = $0 }
            #endif
            .accessibilityLabel(baseName == "Play" ? "New Game" : baseName)
    }
}

/// Faithful modern shell around the original opening/menu artwork. The button
/// glyphs are direct crops from the shipped Main-Title atlas; no replacement font
/// is used for the primary menu controls.
struct AquaDotOpeningView: View {
    @ObservedObject var controller: AquaDotAppController
    @ObservedObject private var preferences = AquaDotPreferences.shared
    @State private var waitingForClick: Bool
    @State private var dotRotation: Double = 0

    init(controller: AquaDotAppController) {
        self.controller = controller
        _waitingForClick = State(initialValue: AquaDotPreferences.shared.waitForClick)
    }

    private var suffix: String { preferences.graphicsMode == .remastered ? "Remastered" : "Original" }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                Image("P21_OpeningDot_\(suffix)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(proxy.size.width * 0.63, 520))
                    .opacity(0.42)
                    .rotationEffect(.degrees(dotRotation))
                    .offset(x: -min(proxy.size.width * 0.18, 150), y: 10)
                    .onAppear {
                        withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) {
                            dotRotation = 360
                        }
                    }

                VStack(spacing: 9) {
                    Spacer(minLength: 24)

                    Image("P21_Menu_Title_Cyan_\(suffix)")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 330, maxHeight: 72)
                        .padding(.bottom, 16)

                    AquaDotOGMenuButton(baseName: "Play", mode: preferences.graphicsMode) {
                        if controller.canResumeGame {
                            controller.resumeGame()
                        } else {
                            controller.startNewGame()
                        }
                    }

                    if controller.canResumeGame {
                        Button("start new game") { controller.startNewGame() }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.red.opacity(0.86))
                    }

                    AquaDotOGMenuButton(baseName: "Scores", mode: preferences.graphicsMode) {
                        controller.showScores()
                    }
                    AquaDotOGMenuButton(baseName: "Options", mode: preferences.graphicsMode) {
                        controller.showOptions(returnTo: .opening)
                    }
                    AquaDotOGMenuButton(baseName: "Help", mode: preferences.graphicsMode) {
                        controller.showHelp()
                    }

                    #if os(macOS)
                    AquaDotOGMenuButton(baseName: "Quit", mode: preferences.graphicsMode) {
                        NSApplication.shared.terminate(nil)
                    }
                    #endif

                    Spacer(minLength: 10)

                    if preferences.showQuickTips {
                        let tip = (Calendar.current.component(.day, from: Date()) % 10) + 1
                        Image(String(format: "P21_QuickTip_%02d_%@", tip, suffix))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: min(690, proxy.size.width * 0.88), maxHeight: 74)
                            .opacity(0.88)
                    }

                    Button("about aquadot!red") { controller.showAbout() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.cyan.opacity(0.68))
                        .padding(.bottom, 18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if waitingForClick {
                    Color.black.opacity(0.94).ignoresSafeArea()
                    VStack(spacing: 18) {
                        Image("P21_Menu_Title_Cyan_\(suffix)")
                            .resizable().scaledToFit().frame(maxWidth: 360)
                        Image("P21_ClickToContinue_\(suffix)")
                            .resizable().scaledToFit().frame(maxWidth: min(760, proxy.size.width * 0.92))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { waitingForClick = false }
                    #if os(macOS)
                    .onExitCommand { waitingForClick = false }
                    #endif
                }
            }
        }
        .background(Color.black)
    }
}
