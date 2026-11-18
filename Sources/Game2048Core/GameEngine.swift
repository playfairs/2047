import Foundation

public enum MoveDirection: CaseIterable, Sendable {
    case up
    case down
    case left
    case right
}

public struct MoveResult: Equatable, Sendable {
    public let changed: Bool
    public let scoreGained: Int
    public let mergeCount: Int
    public let spawnedTile: (index: Int, value: Int)?
    public let reached2048: Bool
    public let gameOver: Bool

    public static func == (lhs: MoveResult, rhs: MoveResult) -> Bool {
        lhs.changed == rhs.changed
            && lhs.scoreGained == rhs.scoreGained
            && lhs.mergeCount == rhs.mergeCount
            && lhs.spawnedTile?.index == rhs.spawnedTile?.index
            && lhs.spawnedTile?.value == rhs.spawnedTile?.value
            && lhs.reached2048 == rhs.reached2048
            && lhs.gameOver == rhs.gameOver
    }
}

public struct GameEngine: Sendable {
    public static let sideLength = 4
    public static let tileCount = sideLength * sideLength

    public private(set) var tiles: [Int]
    public private(set) var tileIDs: [UUID?]
    public private(set) var score: Int
    public private(set) var hasReached2048: Bool

    public var isGameOver: Bool {
        !hasAvailableMoves
    }

    public init(random: () -> Int = { Int.random(in: 0..<1_000_000) }) {
        tiles = Array(repeating: 0, count: Self.tileCount)
        tileIDs = Array(repeating: nil, count: Self.tileCount)
        score = 0
        hasReached2048 = false
        _ = spawnTile(using: random)
        _ = spawnTile(using: random)
    }

    public init(tiles: [Int], score: Int = 0) {
        precondition(tiles.count == Self.tileCount)
        precondition(tiles.allSatisfy { $0 >= 0 })
        precondition(score >= 0)
        self.tiles = tiles
        tileIDs = tiles.map { $0 == 0 ? nil : UUID() }
        self.score = score
        hasReached2048 = tiles.contains { $0 >= 2048 }
    }

    @discardableResult
    public mutating func move(
        _ direction: MoveDirection,
        random: () -> Int = { Int.random(in: 0..<1_000_000) }
    ) -> MoveResult {
        guard !isGameOver else {
            return MoveResult(
                changed: false,
                scoreGained: 0,
                mergeCount: 0,
                spawnedTile: nil,
                reached2048: false,
                gameOver: true
            )
        }

        var movedTiles = tiles
        var movedTileIDs = tileIDs
        var scoreGained = 0
        var mergeCount = 0

        for lane in 0..<Self.sideLength {
            let indexes = indexes(for: lane, direction: direction)
            let laneTiles = indexes.compactMap { index -> (value: Int, id: UUID)? in
                guard tiles[index] != 0, let id = tileIDs[index] else { return nil }
                return (tiles[index], id)
            }
            var mergedTiles: [(value: Int, id: UUID)] = []
            var valueIndex = 0

            while valueIndex < laneTiles.count {
                if valueIndex + 1 < laneTiles.count, laneTiles[valueIndex].value == laneTiles[valueIndex + 1].value {
                    let mergedValue = laneTiles[valueIndex].value * 2
                    mergedTiles.append((mergedValue, laneTiles[valueIndex].id))
                    scoreGained += mergedValue
                    mergeCount += 1
                    valueIndex += 2
                } else {
                    mergedTiles.append(laneTiles[valueIndex])
                    valueIndex += 1
                }
            }

            for offset in indexes.indices {
                if offset < mergedTiles.count {
                    movedTiles[indexes[offset]] = mergedTiles[offset].value
                    movedTileIDs[indexes[offset]] = mergedTiles[offset].id
                } else {
                    movedTiles[indexes[offset]] = 0
                    movedTileIDs[indexes[offset]] = nil
                }
            }
        }

        guard movedTiles != tiles else {
            return MoveResult(
                changed: false,
                scoreGained: 0,
                mergeCount: 0,
                spawnedTile: nil,
                reached2048: false,
                gameOver: isGameOver
            )
        }

        tiles = movedTiles
        tileIDs = movedTileIDs
        score += scoreGained
        let reached2048 = !hasReached2048 && tiles.contains { $0 >= 2048 }
        hasReached2048 = hasReached2048 || reached2048
        let spawnedTile = spawnTile(using: random)

        return MoveResult(
            changed: true,
            scoreGained: scoreGained,
            mergeCount: mergeCount,
            spawnedTile: spawnedTile,
            reached2048: reached2048,
            gameOver: isGameOver
        )
    }

    private var hasAvailableMoves: Bool {
        for row in 0..<Self.sideLength {
            for column in 0..<Self.sideLength {
                let index = row * Self.sideLength + column
                if tiles[index] == 0 {
                    return true
                }
                if column + 1 < Self.sideLength, tiles[index] == tiles[index + 1] {
                    return true
                }
                if row + 1 < Self.sideLength, tiles[index] == tiles[index + Self.sideLength] {
                    return true
                }
            }
        }
        return false
    }

    private func indexes(for lane: Int, direction: MoveDirection) -> [Int] {
        switch direction {
        case .left:
            (0..<Self.sideLength).map { lane * Self.sideLength + $0 }
        case .right:
            (0..<Self.sideLength).reversed().map { lane * Self.sideLength + $0 }
        case .up:
            (0..<Self.sideLength).map { $0 * Self.sideLength + lane }
        case .down:
            (0..<Self.sideLength).reversed().map { $0 * Self.sideLength + lane }
        }
    }

    @discardableResult
    private mutating func spawnTile(using random: () -> Int) -> (index: Int, value: Int)? {
        let emptyIndexes = tiles.indices.filter { tiles[$0] == 0 }
        guard !emptyIndexes.isEmpty else { return nil }
        let index = emptyIndexes[random() % emptyIndexes.count]
        let value = random() % 10 == 0 ? 4 : 2
        tiles[index] = value
        tileIDs[index] = UUID()
        return (index, value)
    }
}
