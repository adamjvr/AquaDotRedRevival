struct Level: Codable {

    var title: String
    var gridWidth: Int
    var gridHeight: Int
    var tiles: [Tile]
    var dots: [GridPosition]

    func tileAt(x: Int, y: Int) -> Tile {

        guard x >= 0,
              y >= 0,
              x < gridWidth,
              y < gridHeight else {
            return .wall
        }

        let index = y * gridWidth + x
        return tiles[index]
    }
}
