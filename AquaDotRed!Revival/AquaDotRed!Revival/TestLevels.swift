enum TestLevels {

    static let levelOne: Level = {

        // Wide rectangular prototype maze.
        //
        // Legend:
        // # = wall
        // . = path with dot
        // space = path without dot

        let mapRows: [String] = [
            "#######################",
            "#.....................#",
            "#.###..####...####..#.#",
            "#.....................#",
            "#.########...########.#",
            "#.....................#",
            "#.####..##...##..####.#",
            "#.....................#",
            "#.....##.......##.....#",
            "#####.##..###..##.#####",
            "    #.....# #.....#    ",
            "#####.##..###..##.#####",
            "#.....##.......##.....#",
            "#.....................#",
            "#.####..##...##..####.#",
            "#.....................#",
            "#.########...########.#",
            "#.....................#",
            "#.#..####...####..###.#",
            "#.....................#",
            "#######################"
        ]

        let height = mapRows.count
        let width = mapRows.map { $0.count }.max() ?? 0

        var tiles: [Tile] = []
        var dots: [GridPosition] = []

        for y in 0..<height {

            let row = Array(mapRows[y])

            for x in 0..<width {

                let character = x < row.count ? row[x] : "#"

                switch character {
                case "#":
                    tiles.append(.wall)

                case ".":
                    tiles.append(.path)
                    dots.append(GridPosition(x: x, y: y))

                default:
                    tiles.append(.path)
                }
            }
        }

        return Level(
            title: "Rectangular Prototype Level",
            gridWidth: width,
            gridHeight: height,
            tiles: tiles,
            dots: dots
        )
    }()
}
