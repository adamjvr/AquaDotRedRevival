import SwiftUI
import SpriteKit

struct GameView: View {

    var scene: SKScene {
        let scene = MazeGameScene()

        // Wide canvas matching the reference-style layout:
        // large rectangular maze, right stats strip, bottom HUD.
        scene.size = CGSize(width: 1400, height: 900)
        scene.scaleMode = .aspectFit

        scene.backgroundColor = SKColor(
            red: 0.005,
            green: 0.006,
            blue: 0.012,
            alpha: 1.0
        )

        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .background(Color.black)
    }
}
