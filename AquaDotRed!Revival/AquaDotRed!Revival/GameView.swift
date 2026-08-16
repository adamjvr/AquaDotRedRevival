import SwiftUI
import SpriteKit

#if canImport(GameController)
import GameController
#endif

struct GameView: View {
    @ObservedObject var controller = AquaDotAppController.shared
    @StateObject private var controllerBridge = AquaDotGameControllerBridge()

    var body: some View {
        Group {
            if let scene = controller.activeGameScene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .background(Color.black)
                    .focusable()
                    .onAppear {
                        scene.resumeFromShell()
                        controllerBridge.attach(to: scene)
                    }
                    .onDisappear {
                        controllerBridge.detach(from: scene)
                    }
            } else {
                Color.black
                    .onAppear { controller.startNewGame() }
            }
        }
    }
}

/// Modern transport for the game's already platform-neutral logical input layer.
///
/// The original release linked a classic HID utility layer and contained joystick
/// polling/configuration code. Exact historical controller button assignments have
/// not been recovered, so this bridge intentionally makes a modern, documented
/// mapping without claiming that the physical mapping is original:
///
/// - D-pad / left stick -> movement
/// - A / primary button -> activate available special power
/// - B / secondary button -> cancel/unpause
/// - Menu -> pause
///
/// MazeGameScene still receives only AquaDotInputEvent values, so controller input
/// cannot fork or contaminate simulation rules.
@MainActor
final class AquaDotGameControllerBridge: ObservableObject {
    private weak var scene: MazeGameScene?

    #if canImport(GameController)
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?
    #endif

    init() {
        #if canImport(GameController)
        connectObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            Task { @MainActor [weak self] in self?.configure(controller) }
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { _ in }

        for controller in GCController.controllers() {
            configure(controller)
        }
        #endif
    }

    deinit {
        #if canImport(GameController)
        if let connectObserver { NotificationCenter.default.removeObserver(connectObserver) }
        if let disconnectObserver { NotificationCenter.default.removeObserver(disconnectObserver) }
        #endif
    }

    func attach(to scene: MazeGameScene) {
        self.scene = scene
        #if canImport(GameController)
        for controller in GCController.controllers() {
            configure(controller)
        }
        #endif
    }

    func detach(from scene: MazeGameScene) {
        if self.scene === scene {
            self.scene = nil
        }
    }

    #if canImport(GameController)
    private func configure(_ controller: GCController) {
        if let gamepad = controller.extendedGamepad {
            bind(gamepad.dpad)
            bind(gamepad.leftThumbstick)
            gamepad.buttonA.pressedChangedHandler = handler(for: .confirm)
            gamepad.buttonB.pressedChangedHandler = handler(for: .cancel)
            gamepad.buttonMenu.pressedChangedHandler = handler(for: .pause)
            return
        }

        if let gamepad = controller.microGamepad {
            bind(gamepad.dpad)
            gamepad.buttonA.pressedChangedHandler = handler(for: .confirm)
            gamepad.buttonX.pressedChangedHandler = handler(for: .cancel)
            gamepad.buttonMenu.pressedChangedHandler = handler(for: .pause)
        }
    }

    private func bind(_ pad: GCControllerDirectionPad) {
        pad.up.pressedChangedHandler = handler(for: .moveUp)
        pad.right.pressedChangedHandler = handler(for: .moveRight)
        pad.down.pressedChangedHandler = handler(for: .moveDown)
        pad.left.pressedChangedHandler = handler(for: .moveLeft)
    }

    private func handler(for action: AquaDotInputAction) -> GCControllerButtonValueChangedHandler {
        { [weak self] _, _, pressed in
            guard pressed else { return }
            Task { @MainActor [weak self] in
                self?.scene?.handleAquaDotInput(
                    AquaDotInputEvent(
                        action: action,
                        isPressed: true,
                        source: .gameController
                    )
                )
            }
        }
    }
    #endif
}
