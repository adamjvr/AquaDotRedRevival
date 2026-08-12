import Foundation
import Testing
@testable import AquaDotRed_Revival

struct Phase1AuthenticRuntimeTests {
    @Test func recoveredChecksumFixtureParses() throws {
        let fixture = """
        aquadot!red
        Maze Description Format Version 1.0

        Checksum: 53212

        Width: 1
        Height: 1

         :    :
            _
         S    :
        """ + "\n"

        let data = try #require(fixture.data(using: .macOSRoman))
        let maze = try AquaDotMazeParser.parse(data: data)

        #expect(maze.checksumIsValid)
        #expect(maze.width == 1)
        #expect(maze.height == 1)
        #expect(maze.playerStarts == [GridPosition(x: 0, y: 1)])
    }

    @Test func recoveredWallBitDirectionsAndFramesAreStable() {
        #expect(AquaDotWallGeometry.north.rawValue == 0x08)
        #expect(AquaDotWallGeometry.east.rawValue == 0x01)
        #expect(AquaDotWallGeometry.south.rawValue == 0x02)
        #expect(AquaDotWallGeometry.west.rawValue == 0x04)

        #expect(AquaDotWallGeometry(rawValue: 0x08).recoveredEditorFrameIndex == 0)
        #expect(AquaDotWallGeometry(rawValue: 0x01).recoveredEditorFrameIndex == 1)
        #expect(AquaDotWallGeometry(rawValue: 0x0F).recoveredEditorFrameIndex == 14)
    }

    @Test func wrapEndpointCreatesDirectionalTeleportEdge() {
        let maze = AquaDotMaze(
            version: "1.0",
            storedChecksum: 0,
            calculatedChecksum: 0,
            width: 2,
            height: 1,
            vertexRows: [
                [.wrap("A"), .path, .wrap("A")],
                [.empty, .empty, .empty]
            ],
            edgeRows: [[.empty, .empty]]
        )

        let topology = AquaDotMazeTopology(maze: maze)
        let left = GridPosition(x: 0, y: 0)
        let right = GridPosition(x: 2, y: 0)

        #expect(topology.neighbor(from: left, direction: .left) == right)
        #expect(topology.neighbor(from: right, direction: .right) == left)
        #expect(topology.neighbor(from: left, direction: .right) == GridPosition(x: 1, y: 0))
    }
}
