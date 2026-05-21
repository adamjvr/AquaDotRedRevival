import SwiftUI
import SpriteKit

struct GameView: View {

    var scene: SKScene {
        let scene = MazeGameScene()
        scene.size = CGSize(width: 1024, height: 768)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = SKColor(
            red: 0.02,
            green: 0.04,
            blue: 0.08,
            alpha: 1.0
        )

        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .background(Color.black)
    }
}
