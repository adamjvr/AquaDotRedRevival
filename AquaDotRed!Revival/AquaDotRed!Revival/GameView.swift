import SwiftUI
import SpriteKit

struct GameView: View {
    @ObservedObject var controller = AquaDotAppController.shared

    var body: some View {
        Group {
            if let scene = controller.activeGameScene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .background(Color.black)
                    .focusable()
                    .onAppear { scene.resumeFromShell() }
            } else {
                Color.black
                    .onAppear { controller.startNewGame() }
            }
        }
    }
}
