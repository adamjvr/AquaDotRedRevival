import SwiftUI

private struct AquaDotOptionGroup<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.cyan)
            content
        }
        .padding(16)
        .background(Color.black.opacity(0.68))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.42), lineWidth: 1.5))
    }
}

struct AquaDotOptionsView: View {
    @ObservedObject var controller: AquaDotAppController
    @ObservedObject private var preferences = AquaDotPreferences.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("aquadot!red   ::   general options")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Button("Done") { controller.closeAuxiliaryScreen() }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                    }

                    AquaDotOptionGroup("Revival graphics") {
                        Picker("Graphics", selection: $preferences.graphicsMode) {
                            Text("Original").tag(AquaDotGraphicsMode.original)
                            Text("Remastered").tag(AquaDotGraphicsMode.remastered)
                        }
                        .pickerStyle(.segmented)
                        Text("Both modes use identical maze geometry, collision, timing and original level data.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    AquaDotOptionGroup("Sound") {
                        Toggle("Mute all game sounds/music", isOn: $preferences.muteAll)
                        Toggle("Disable Music & Ambient Sounds", isOn: $preferences.disableMusic)
                        VStack(alignment: .leading) {
                            Text("Sound Effects:  \(Int(preferences.soundEffectsVolume * 100))%")
                            Slider(value: $preferences.soundEffectsVolume, in: 0...1, step: 0.05)
                        }
                        VStack(alignment: .leading) {
                            Text("Music/Ambient Sounds:  \(Int(preferences.musicVolume * 100))%")
                            Slider(value: $preferences.musicVolume, in: 0...1, step: 0.05)
                        }
                    }

                    AquaDotOptionGroup("What colors should be used to draw maze walls?") {
                        Picker("Wall colors", selection: $preferences.wallPalette) {
                            ForEach(AquaDotWallPalette.allCases) { palette in
                                Text(palette.displayName).tag(palette)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    AquaDotOptionGroup("Opening / performance") {
                        Toggle("Show QuickTips while starting up", isOn: $preferences.showQuickTips)
                        Toggle("Wait for click to continue", isOn: $preferences.waitForClick)
                        Toggle("Attempt Higher Framerate", isOn: $preferences.attemptHigherFramerate)
                        Text("The original dialog noted that the higher-framerate option can make animation smoother. Phase 2.1 also removes the per-dot audio and rendering churn that caused progressive slowdown.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    AquaDotOptionGroup("Controls") {
                        Toggle("Allow direction “pretapping”", isOn: $preferences.allowPretapping)
                        Text("Pretapping lets you request a turn before reaching the next intersection, matching the original option description.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Mac: arrows/WASD • Space: special • P/Esc: pause • iPad: swipe + keyboard/controller-ready input layer")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    AquaDotOptionGroup("Let it Snow!") {
                        Toggle("Rainbow snow", isOn: $preferences.rainbowSnow)
                        VStack(alignment: .leading) {
                            Text("Amount of snow:  \(preferences.snowAmount == 0 ? "off" : ["", "flurry", "snow", "blizzard"][preferences.snowAmount])")
                            Slider(
                                value: Binding(
                                    get: { Double(preferences.snowAmount) },
                                    set: { preferences.snowAmount = Int($0.rounded()) }
                                ),
                                in: 0...3,
                                step: 1
                            )
                        }
                        Text("Why? Because it's pretty! The exact original option and preference are preserved here; the original Snow.cc timing/particle behavior remains a later presentation reconstruction target.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    HStack {
                        Spacer()
                        Button("Restore defaults") { preferences.restoreDefaults() }
                            .buttonStyle(.bordered)
                        Button("OK") { controller.closeAuxiliaryScreen() }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                    }
                }
                .padding(24)
                .frame(maxWidth: 820)
            }
        }
    }
}
