import CoreGraphics
import Testing
@testable import AquaDotRed_Revival

struct Phase4ASolidWallSelectorTests {
    @Test func isolatedSolidCellUsesRecoveredFourCornerFrames() throws {
        let selection = try #require(AquaDotOriginalSolidWallSelector.selection(forFlagKey: 0))
        #expect(selection.pieces.map(\.atlasType.rawValue) == [3, 3, 3, 3])
        #expect(selection.pieces.map(\.frameIndex) == [3, 23, 43, 63])
    }

    @Test func fourSolidCardinalNeighborsUseRecoveredNineByNineFrames() throws {
        // W/E/N/S are bits 0...3; diagonal and numeric-continuation flags are clear.
        let selection = try #require(AquaDotOriginalSolidWallSelector.selection(forFlagKey: 0x000F))
        #expect(selection.pieces.map(\.atlasType.rawValue) == [0, 0, 0, 0])
        #expect(selection.pieces.map(\.frameIndex) == [0, 1, 2, 3])
    }

    @Test func spriteWorldCenteredFrameGridAndExpansionRectsMatchBinary() {
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .nineByNine, frameIndex: 0) == CGRect(x: 18, y: 18, width: 9, height: 9))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByNine, frameIndex: 8) == CGRect(x: 20, y: 108, width: 20, height: 9))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByNine, frameIndex: 10) == CGRect(x: 110, y: 108, width: 20, height: 9))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .nineByTen, frameIndex: 8) == CGRect(x: 18, y: 110, width: 9, height: 20))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .nineByTen, frameIndex: 10) == CGRect(x: 108, y: 120, width: 9, height: 20))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByTen, frameIndex: 4) == CGRect(x: 10, y: 60, width: 20, height: 20))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByTen, frameIndex: 24) == CGRect(x: 20, y: 310, width: 20, height: 20))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByTen, frameIndex: 44) == CGRect(x: 20, y: 570, width: 20, height: 20))
        #expect(AquaDotOriginalSolidWallRenderer.sourcePixelRect(atlasType: .tenByTen, frameIndex: 64) == CGRect(x: 10, y: 820, width: 20, height: 20))
    }

    @Test func destinationRectsReproduceRecoveredOverhangMath() {
        #expect(AquaDotOriginalSolidWallRenderer.destinationPixelRect(atlasType: .nineByNine, frameIndex: 0, quadrant: 0) == CGRect(x: 0, y: 0, width: 9, height: 9))
        #expect(AquaDotOriginalSolidWallRenderer.destinationPixelRect(atlasType: .nineByNine, frameIndex: 2, quadrant: 2) == CGRect(x: 9, y: 9, width: 9, height: 9))
        #expect(AquaDotOriginalSolidWallRenderer.destinationPixelRect(atlasType: .tenByTen, frameIndex: 3, quadrant: 0) == CGRect(x: -1, y: -1, width: 10, height: 10))
        #expect(AquaDotOriginalSolidWallRenderer.destinationPixelRect(atlasType: .tenByTen, frameIndex: 4, quadrant: 1) == CGRect(x: 9, y: -11, width: 20, height: 20))
    }
}
