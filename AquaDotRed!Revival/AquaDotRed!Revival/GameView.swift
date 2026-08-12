import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var scene: MazeGameScene = {
        let scene = MazeGameScene()

        // The recovered original status panel is exactly 800 pixels wide. A
        // 39x30 maze at the recovered/classic 20-pixel pitch occupies 780x600,
        // giving us a compact logical canvas that scales cleanly on Mac and iPad.
        scene.size = CGSize(width: 800, height: 700)
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .background(Color.black)
            .focusable()
    }
}
